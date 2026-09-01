import os
import tempfile
import urllib.parse
from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse
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

@app.get("/api/info")
def get_video_info(url: str = Query(..., description="YouTube Video URL")):
    """
    Extracts metadata from YouTube video URL without downloading.
    Returns title, channel/artist, duration (seconds), thumbnail URL.
    """
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty")
    
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        'cachedir': False,
        'nocheckcertificate': True,
        'extractor_args': {'youtube': {'player_client': ['android', 'web']}},
    }
    
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            
            # Duration in seconds
            duration = info.get('duration', 0)
            
            return {
                "id": info.get('id'),
                "title": info.get('title'),
                "artist": info.get('uploader') or info.get('artist') or "Unknown Artist",
                "duration": duration,
                "thumbnail": info.get('thumbnail'),
                "webpage_url": info.get('webpage_url', url),
            }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error extracting video info: {str(e)}")

from fastapi.responses import FileResponse, StreamingResponse, RedirectResponse

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

    if media_type == "mp3":
        ydl_opts = {
            'format': 'bestaudio[ext=m4a]/bestaudio/best',
            'quiet': True,
            'skip_download': True,
            'cachedir': False,
            'nocheckcertificate': True,
            'extractor_args': {'youtube': {'player_client': ['android', 'web']}},
        }
    else:  # mp4
        ydl_opts = {
            'format': 'best[ext=mp4]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best',
            'quiet': True,
            'skip_download': True,
            'cachedir': False,
            'nocheckcertificate': True,
            'extractor_args': {'youtube': {'player_client': ['android', 'web']}},
        }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            
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
