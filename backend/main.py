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

CLIENT_LISTS = [
    ['android'],
    ['ios'],
    ['tvhtml5'],
    ['android_creator'],
    ['web_embedded']
]

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

def extract_best_media_url(info) -> str:
    """
    Extracts valid direct media stream URL while filtering out storyboard JPG/WEBP images.
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
        f.get('ext') in ['m4a', 'mp4', 'webm', 'opus', 'aac', '3gp'] and
        not f.get('url', '').endswith('.jpg') and
        not f.get('url', '').endswith('.webp')
    ]
    
    if valid_formats:
        return valid_formats[-1].get('url')
        
    return None

def extract_with_fallback(clean_url: str, target_format: str, is_pythonanywhere: bool) -> str:
    """
    Iterates through multiple YouTube client signatures to guarantee stream extraction on cloud servers.
    """
    last_error = None
    for client in CLIENT_LISTS:
        ydl_opts = {
            'format': target_format,
            'quiet': True,
            'skip_download': True,
            'cachedir': False,
            'nocheckcertificate': True,
            'extractor_args': {'youtube': {'player_client': client}},
        }
        if is_pythonanywhere:
            ydl_opts['proxy'] = "http://proxy.server:3128"
            
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(clean_url, download=False)
                url = extract_best_media_url(info)
                if url:
                    return url
        except Exception as e:
            last_error = e
            continue
            
    raise Exception(f"All extraction clients failed. Last error: {str(last_error)}")

@app.get("/")
def read_root():
    return {"message": "YouTube Media Extractor API is running!", "health": "/api/health"}

@app.get("/api/health")
def health_check():
    return {"status": "ok", "yt_dlp_version": yt_dlp.version.__version__}

@app.get("/api/info")
def get_video_info(url: str = Query(..., description="YouTube Video URL")):
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty")
    
    clean_url = clean_youtube_url(url)
    
    for client in CLIENT_LISTS:
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'cachedir': False,
            'nocheckcertificate': True,
            'extractor_args': {'youtube': {'player_client': client}},
        }
        if is_pythonanywhere:
            ydl_opts['proxy'] = "http://proxy.server:3128"
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(clean_url, download=False)
                return {
                    "id": info.get('id', 'video'),
                    "title": info.get('title', 'YouTube Video'),
                    "artist": info.get('uploader') or info.get('artist') or "Unknown Artist",
                    "duration": info.get('duration', 0),
                    "thumbnail": info.get('thumbnail'),
                    "webpage_url": info.get('webpage_url', clean_url),
                }
        except Exception:
            continue
            
    # Fallback to oEmbed API
    try:
        encoded_url = urllib.parse.quote(clean_url, safe='')
        oembed_url = f"https://www.youtube.com/oembed?url={encoded_url}&format=json"
        
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
        req = urllib.request.Request(oembed_url, headers=headers)
        response = urllib.request.urlopen(req, timeout=5)
        data = json.loads(response.read().decode('utf-8'))
        
        vid_match = re.search(r'v=([0-9A-Za-z_-]{11})', clean_url)
        return {
            "id": vid_match.group(1) if vid_match else "unknown",
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
    if not url:
        raise HTTPException(status_code=400, detail="URL is required")

    clean_url = clean_youtube_url(url)
    target_format = 'b/ba/best'

    try:
        direct_url = extract_with_fallback(clean_url, target_format, is_pythonanywhere)
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

    @flask_app.route('/api/download')
    def flask_download():
        url = flask_request.args.get('url')
        media_type = flask_request.args.get('media_type', 'mp3')
        if not url:
            return jsonify({"detail": "URL is required"}), 400
        clean_url = clean_youtube_url(url)
        target_format = 'b/ba/best'
        try:
            direct_url = extract_with_fallback(clean_url, target_format, is_pythonanywhere)
            return flask_redirect(direct_url, code=302)
        except Exception as e:
            return jsonify({"detail": f"Download extraction error: {str(e)}"}), 500
except ImportError:
    pass

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
