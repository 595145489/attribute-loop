@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ========================================
echo   AttributeLoop - Web Export
echo ========================================
echo.

:: ── 1. 找 Godot 可执行文件 ──────────────────────────────────────
set GODOT_EXE=

if exist "%~dp0godot_path.txt" (
    set /p GODOT_EXE=<"%~dp0godot_path.txt"
)

if not defined GODOT_EXE (
    for %%P in (
        "C:\Godot\Godot_v4*.exe"
        "S:\Godot*\Godot_v4*.exe"
        "C:\Program Files\Godot\Godot*.exe"
        "%USERPROFILE%\Downloads\Godot*.exe"
        "%USERPROFILE%\Desktop\Godot*.exe"
    ) do (
        if not defined GODOT_EXE (
            for %%F in (%%P) do (
                if exist "%%F" set GODOT_EXE=%%F
            )
        )
    )
)

if not defined GODOT_EXE (
    echo [ERROR] 找不到 Godot 可执行文件。
    echo 请在 scripts\godot_path.txt 里填写完整路径，例如：
    echo   S:\Godot_v4.6.2-stable_win64_temp\Godot_v4.6.2-stable_win64.exe
    pause
    exit /b 1
)

echo [OK] Godot: %GODOT_EXE%

:: ── 2. 准备输出目录 ──────────────────────────────────────────────
set PROJECT_DIR=%~dp0..
set OUT_DIR=%PROJECT_DIR%\exports\web

if not exist "%OUT_DIR%" (
    mkdir "%OUT_DIR%"
    echo [OK] 已创建输出目录: %OUT_DIR%
) else (
    echo [OK] 输出目录: %OUT_DIR%
)
echo.

:: ── 3. 执行导出 ──────────────────────────────────────────────────
echo 正在导出（headless）...
echo.

"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --export-release "Web" "%OUT_DIR%\index.html"
set EXPORT_CODE=%ERRORLEVEL%

echo.
if %EXPORT_CODE% neq 0 (
    echo [ERROR] 导出失败，错误码: %EXPORT_CODE%
    echo 请确认：
    echo   1. Godot Web 导出模板已安装
    echo   2. export_presets.cfg 里预设名为 "Web"
    pause
    exit /b %EXPORT_CODE%
)

echo [OK] 导出成功！

:: ── 4. 写入 start.bat ────────────────────────────────────────────
echo.
echo 正在生成 start.bat...

(
echo @echo off
echo chcp 65001 ^>nul
echo echo ========================================
echo echo   AttributeLoop - 本地启动
echo echo ========================================
echo echo.
echo echo 服务器地址: http://localhost:8080
echo echo 关闭此窗口即停止服务器
echo echo.
echo :: 先起服务器，再开浏览器
echo start /b python -m http.server 8080
echo ping -n 2 127.0.0.1 ^>nul
echo start "" "http://localhost:8080"
echo echo.
echo echo 按任意键关闭服务器...
echo pause ^>nul
echo taskkill /f /im python.exe ^>nul 2^>^&1
) > "%OUT_DIR%\start.bat"

echo [OK] start.bat 已生成

:: ── 5. 打开输出文件夹 ────────────────────────────────────────────
echo.
explorer "%OUT_DIR%"
echo.
pause