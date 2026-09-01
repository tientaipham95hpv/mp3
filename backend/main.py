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
        'format': 'best',
        'cachedir': False,
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

@app.get("/api/download")
def download_media(
    url: str = Query(..., description="YouTube Video URL"),
    media_type: str = Query("mp3", pattern="^(mp3|mp4)$", description="Media format: mp3 or mp4"),
    quality: str = Query("720p", description="Video quality if mp4: 360p, 720p, 1080p")
):
    """
    Downloads and extracts YouTube video/audio using yt-dlp into a temporary file
    and streams it back to the client as MP3 or MP4 download.
    """
    if not url:
        raise HTTPException(status_code=400, detail="URL is required")

    temp_dir = tempfile.mkdtemp()
    out_template = os.path.join(temp_dir, "%(title)s.%(ext)s")

    if media_type == "mp3":
        ydl_opts = {
            'format': 'bestaudio/best',
            'outtmpl': out_template,
            'quiet': True,
            'no_warnings': True,
            'cachedir': False,
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
        }
    else:  # mp4
        # Format selection for video
        video_format = f'bestvideo[height<={quality[:-1]}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'
        ydl_opts = {
            'format': video_format,
            'outtmpl': out_template,
            'quiet': True,
            'no_warnings': True,
            'cachedir': False,
            'merge_output_format': 'mp4',
        }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            title = info.get('title', 'downloaded_media')
            
            # Find the generated file in temp_dir
            downloaded_files = os.listdir(temp_dir)
            if not downloaded_files:
                raise Exception("File extraction failed, no output file generated")
            
            file_path = os.path.join(temp_dir, downloaded_files[0])
            ext = os.path.splitext(file_path)[1]
            
            content_type = "audio/mpeg" if media_type == "mp3" or ext == ".mp3" else "video/mp4"
            filename = f"{title}{ext}"
            safe_filename = urllib.parse.quote(filename)

            # Cleanup helper when file is served
            def file_iterator():
                with open(file_path, "rb") as f:
                    while chunk := f.read(64 * 1024):
                        yield chunk
                # Delete temp file and dir after streaming finishes
                try:
                    os.remove(file_path)
                    os.rmdir(temp_dir)
                except Exception:
                    pass

            return StreamingResponse(
                file_iterator(),
                media_type=content_type,
                headers={
                    "Content-Disposition": f"attachment; filename*=UTF-8''{safe_filename}",
                    "Content-Type": content_type
                }
            )
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Download extraction error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
