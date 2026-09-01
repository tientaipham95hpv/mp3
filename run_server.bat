@echo off
title YTMusicPlayer Local Server + Cloudflare Tunnel
echo ===================================================
echo     YTMusicPlayer Backend Server for iOS App
echo ===================================================
echo.
echo [1/3] Checking Python dependencies...
python -m pip install -r requirements.txt
echo.
echo [2/3] Local IP addresses of your PC (Use if iPhone is on SAME Wi-Fi):
ipconfig | findstr /i "IPv4"
echo.
echo [3/3] Starting Cloudflare Tunnel for 4G/Remote Access...
start /b npx --yes cloudflared tunnel --url http://localhost:8000
echo.
echo ===================================================
echo   If on SAME Wi-Fi: enter http://192.168.2.92:8000
echo   If on 4G/Outside: copy the https://...trycloudflare.com URL below!
echo ===================================================
echo.
python backend/main.py
pause
