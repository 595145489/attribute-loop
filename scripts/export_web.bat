@echo off
setlocal EnableDelayedExpansion

echo =======================================
echo   AttributeLoop ^- Web Export
echo =======================================
echo.

:: Find Godot exe
set GODOT_EXE=
if exist "%~dp0godot_path.txt" set /p GODOT_EXE=<"%~dp0godot_path.txt"

if not defined GODOT_EXE (
    for %%P in ("S:\Godot*\Godot_v4*.exe" "C:\Godot\Godot_v4*.exe" "%USERPROFILE%\Downloads\Godot*.exe") do (
        if not defined GODOT_EXE for %%F in (%%P) do if exist "%%F" set GODOT_EXE=%%F
    )
)

if not defined GODOT_EXE (
    echo [ERROR] Godot not found.
    echo Edit scripts\godot_path.txt with the full path to Godot.exe
    pause & exit /b 1
)
echo [OK] Godot: %GODOT_EXE%

:: Output directory
set PROJECT_DIR=%~dp0..
set OUT_DIR=%PROJECT_DIR%\exports\web
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
echo [OK] Output: %OUT_DIR%
echo.

:: Export
echo Exporting...
"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --export-release "Web" "%OUT_DIR%\index.html"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Export failed. Make sure Web export template is installed.
    pause & exit /b 1
)
echo [OK] Export done!

:: Copy start.bat template
copy /y "%~dp0start_web_template.bat" "%OUT_DIR%\start.bat" >nul
echo [OK] start.bat copied.

echo.
echo All done! Opening output folder...
explorer "%OUT_DIR%"
pause