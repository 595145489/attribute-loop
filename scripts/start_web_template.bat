@echo off
setlocal
echo =======================================
echo   AttributeLoop - Local Server
echo =======================================
echo.
echo URL: http://localhost:8080
echo Close this window to stop the server.
echo.
start /b python serve.py 8080
ping -n 2 127.0.0.1 >nul
start "" "http://localhost:8080"
echo.
echo Press any key to stop...
pause >nul
taskkill /f /im python.exe >nul 2>&1