@echo off
title YTMusicPlayer Local Server
echo ===================================================
echo     YTMusicPlayer Backend Server for iOS App
echo ===================================================
echo.
echo [1/2] Checking Python dependencies...
python -m pip install -r requirements.txt
echo.
echo [2/2] Local IP addresses of your PC:
ipconfig | findstr /i "IPv4"
echo.
echo ===================================================
echo   Copy one of the IPv4 addresses above (e.g., 192.168.1.15)
echo   and enter: http://YOUR_IP:8000 in your iPhone App Settings!
echo ===================================================
echo.
python backend/main.py
pause
