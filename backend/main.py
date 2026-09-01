import os
import tempfile
import urllib.parse
import urllib.request
import json
import re
from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse, RedirectResponse
import yt_dlp

# Detect PythonAnywhere environment
is_pythonanywhere = "PYTHONANYWHERE_DOMAIN" in os.environ or os.path.exists("/home/augustvn") or "pythonanywhere" in os.environ.get("SERVER_SOFTWARE", "")
if is_pythonanywhere:
    proxy_url = "http://proxy.server:3128"
    os.environ["HTTP_PROXY"] = proxy_url
    os.environ["HTTPS_PROXY"] = proxy_url
    os.environ["http_proxy"] = proxy_url
    os.environ["https_proxy"] = proxy_url

app = FastAPI(
    title="YouTube Audio/Video Extractor API for iOS App",
    description="Backend microservice using yt-dlp to extract MP3 & MP4 from YouTube links",
    version="1.0.0"
)

# Enable CORS for iOS App and local network testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def clean_youtube_url(url: str) -> str:
    """
    Extracts video ID from any YouTube URL (watch, shorts, youtu.be, tracking params)
    and normalizes it to clean watch URL.
    """
    pattern = r'(?:v=|\/([0-9A-Za-z_-]{11})|embed\/|youtu\.be\/)([0-9A-Za-z_-]{11})'
    match = re.search(pattern, url)
    if match:
        video_id = match.group(2) if match.group(2) else match.group(1)
        if video_id:
            return f"https://www.youtube.com/watch?v={video_id}"
    return url

def extract_best_media_url(info, media_type: str) -> str:
    """
    Extracts valid direct audio/video stream URL while filtering out storyboard JPG/WEBP images.
    """
    direct_url = info.get('url')
    if direct_url and not direct_url.endswith('.jpg') and not direct_url.endswith('.webp'):
        return direct_url
        
    if 'requested_formats' in info and len(info['requested_formats']) > 0:
        for f in info['requested_formats']:
            u = f.get('url')
            if u and not u.endswith('.jpg') and not u.endswith('.webp'):
                return u

    formats = info.get('formats', [])
    valid_formats = [
        f for f in formats 
        if f.get('url') and 
        f.get('acodec') != 'none' and 
        f.get('ext') in ['m4a', 'mp4', 'webm', 'opus', 'aac', '3gp'] and
        not f.get('url', '').endswith('.jpg') and
        not f.get('url', '').endswith('.webp')
    ]
    
    if media_type == "mp3":
        audio_only = [f for f in valid_formats if f.get('vcodec') == 'none']
        if audio_only:
            return audio_only[-1].get('url')
            
    if valid_formats:
        return valid_formats[-1].get('url')
        
    return None

@app.get("/")
def read_root():
    return {"message": "YouTube Media Extractor API is running!", "health": "/api/health"}

@app.get("/api/health")
def health_check():
    return {"status": "ok", "yt_dlp_version": yt_dlp.version.__version__}

@app.get("/api/info")
def get_video_info(url: str = Query(..., description="YouTube Video URL")):
    """
    Extracts metadata from YouTube video URL without downloading.
    Returns title, channel/artist, duration (seconds), thumbnail URL.
    """
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty")
    
    clean_url = clean_youtube_url(url)
    
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        'cachedir': False,
        'nocheckcertificate': True,
        'extractor_args': {'youtube': {'player_client': ['android']}},
    }
    if is_pythonanywhere:
        ydl_opts['proxy'] = "http://proxy.server:3128"
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(clean_url, download=False)
            duration = info.get('duration', 0)
            
            return {
                "id": info.get('id', 'video'),
                "title": info.get('title', 'YouTube Video'),
                "artist": info.get('uploader') or info.get('artist') or "Unknown Artist",
                "duration": duration,
                "thumbnail": info.get('thumbnail'),
                "webpage_url": info.get('webpage_url', clean_url),
            }
    except Exception:
        # Fallback: YouTube Official oEmbed API (100% IP resilient)
        try:
            encoded_url = urllib.parse.quote(clean_url, safe='')
            oembed_url = f"https://www.youtube.com/oembed?url={encoded_url}&format=json"
            
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
            if is_pythonanywhere:
                proxy_handler = urllib.request.ProxyHandler({'http': 'http://proxy.server:3128', 'https': 'http://proxy.server:3128'})
                opener = urllib.request.build_opener(proxy_handler)
                req = urllib.request.Request(oembed_url, headers=headers)
                response = opener.open(req, timeout=5)
            else:
                req = urllib.request.Request(oembed_url, headers=headers)
                response = urllib.request.urlopen(req, timeout=5)

            data = json.loads(response.read().decode('utf-8'))
            
            vid_match = re.search(r'v=([0-9A-Za-z_-]{11})', clean_url)
            video_id = vid_match.group(1) if vid_match else "unknown"
            
            return {
                "id": video_id,
                "title": data.get('title', 'YouTube Video'),
                "artist": data.get('author_name', 'YouTube Artist'),
                "duration": 0.0,
                "thumbnail": data.get('thumbnail_url'),
                "webpage_url": clean_url,
            }
        except Exception as e2:
            raise HTTPException(status_code=400, detail=f"Error extracting video info: {str(e2)}")

@app.get("/api/download")
def download_media(
    url: str = Query(..., description="YouTube Video URL"),
    media_type: str = Query("mp3", pattern="^(mp3|mp4)$", description="Media format: mp3 or mp4"),
    quality: str = Query("720p", description="Video quality if mp4: 360p, 720p, 1080p")
):
    """
    Extracts direct YouTube media stream URL and redirects client (HTTP 302).
    Allows iOS URLSession to download directly from YouTube CDN with zero serverless timeout.
    """
    if not url:
        raise HTTPException(status_code=400, detail="URL is required")

    clean_url = clean_youtube_url(url)
    target_format = 'ba/b/best' if media_type == "mp3" else 'b/ba/best'

    ydl_opts = {
        'format': target_format,
        'quiet': True,
        'skip_download': True,
        'cachedir': False,
        'nocheckcertificate': True,
        'extractor_args': {'youtube': {'player_client': ['android']}},
    }
    if is_pythonanywhere:
        ydl_opts['proxy'] = "http://proxy.server:3128"

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(clean_url, download=False)
            
            direct_url = extract_best_media_url(info, media_type)

            if not direct_url:
                raise HTTPException(status_code=500, detail="Could not extract direct stream URL")

            return RedirectResponse(url=direct_url, status_code=302)
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Download extraction error: {str(e)}")

# Native Flask WSGI Application for PythonAnywhere 100% instant response
try:
    from flask import Flask, request as flask_request, jsonify, redirect as flask_redirect
    
    flask_app = Flask(__name__)
    
    @flask_app.route('/')
    def flask_home():
        return jsonify({"message": "YouTube Media Extractor API is running!", "health": "/api/health"})

    @flask_app.route('/api/health')
    def flask_health():
        return jsonify({"status": "ok", "yt_dlp_version": yt_dlp.version.__version__})

    @flask_app.route('/api/info')
    def flask_info():
        url = flask_request.args.get('url')
        if not url:
            return jsonify({"detail": "URL cannot be empty"}), 400
        clean_url = clean_youtube_url(url)
        ydl_opts = {
            'quiet': True, 'no_warnings': True, 'skip_download': True, 'cachedir': False, 'nocheckcertificate': True,
            'extractor_args': {'youtube': {'player_client': ['android']}}
        }
        if is_pythonanywhere:
            ydl_opts['proxy'] = "http://proxy.server:3128"
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(clean_url, download=False)
                return jsonify({
                    "id": info.get('id', 'video'),
                    "title": info.get('title', 'YouTube Video'),
                    "artist": info.get('uploader') or info.get('artist') or "Unknown Artist",
                    "duration": info.get('duration', 0),
                    "thumbnail": info.get('thumbnail'),
                    "webpage_url": info.get('webpage_url', clean_url)
                })
        except Exception:
            try:
                encoded_url = urllib.parse.quote(clean_url, safe='')
                oembed_url = f"https://www.youtube.com/oembed?url={encoded_url}&format=json"
                headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
                if is_pythonanywhere:
                    proxy_handler = urllib.request.ProxyHandler({'http': 'http://proxy.server:3128', 'https': 'http://proxy.server:3128'})
                    opener = urllib.request.build_opener(proxy_handler)
                    req = urllib.request.Request(oembed_url, headers=headers)
                    response = opener.open(req, timeout=5)
                else:
                    req = urllib.request.Request(oembed_url, headers=headers)
                    response = urllib.request.urlopen(req, timeout=5)
                data = json.loads(response.read().decode('utf-8'))
                vid_match = re.search(r'v=([0-9A-Za-z_-]{11})', clean_url)
                return jsonify({
                    "id": vid_match.group(1) if vid_match else "unknown",
                    "title": data.get('title', 'YouTube Video'),
                    "artist": data.get('author_name', 'YouTube Artist'),
                    "duration": 0.0,
                    "thumbnail": data.get('thumbnail_url'),
                    "webpage_url": clean_url
                })
            except Exception as e2:
                return jsonify({"detail": f"Error: {str(e2)}"}), 400

    @flask_app.route('/api/download')
    def flask_download():
        url = flask_request.args.get('url')
        media_type = flask_request.args.get('media_type', 'mp3')
        if not url:
            return jsonify({"detail": "URL is required"}), 400
        clean_url = clean_youtube_url(url)
        target_format = 'ba/b/best' if media_type == "mp3" else 'b/ba/best'
        ydl_opts = {
            'format': target_format, 'quiet': True, 'skip_download': True, 'cachedir': False, 'nocheckcertificate': True,
            'extractor_args': {'youtube': {'player_client': ['android']}}
        }
        if is_pythonanywhere:
            ydl_opts['proxy'] = "http://proxy.server:3128"
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(clean_url, download=False)
                direct_url = extract_best_media_url(info, media_type)
                if not direct_url:
                    return jsonify({"detail": "Could not extract direct stream URL"}), 500
                return flask_redirect(direct_url, code=302)
        except Exception as e:
            return jsonify({"detail": f"Download extraction error: {str(e)}"}), 500
except ImportError:
    pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
