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

@app.get("/")
def read_root():
    return {"message": "YouTube Media Extractor API is running!", "health": "/api/health"}

@app.get("/api/health")
def health_check():
    return {"status": "ok", "yt_dlp_version": yt_dlp.version.__version__}

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
        'extractor_args': {'youtube': {'player_client': ['android', 'ios']}},
    }
    
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
            req = urllib.request.Request(oembed_url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
            with urllib.request.urlopen(req, timeout=5) as response:
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

    if media_type == "mp3":
        ydl_opts = {
            'format': 'ba/b',
            'quiet': True,
            'skip_download': True,
            'cachedir': False,
            'nocheckcertificate': True,
        }
    else:  # mp4
        ydl_opts = {
            'format': 'b/ba',
            'quiet': True,
            'skip_download': True,
            'cachedir': False,
            'nocheckcertificate': True,
        }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(clean_url, download=False)
            
            direct_url = info.get('url')
            if not direct_url and 'requested_formats' in info and len(info['requested_formats']) > 0:
                direct_url = info['requested_formats'][0].get('url')

            if not direct_url:
                raise HTTPException(status_code=500, detail="Could not extract direct stream URL")

            return RedirectResponse(url=direct_url, status_code=302)
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Download extraction error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
