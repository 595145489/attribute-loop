@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ========================================
echo   AttributeLoop - Web Export
echo ========================================
echo.

:: ── 1. 找 Godot 可执行文件 ──────────────────────────────────────
set GODOT_EXE=

:: 优先读本地配置（scripts/godot_path.txt）
if exist "%~dp0godot_path.txt" (
    set /p GODOT_EXE=<"%~dp0godot_path.txt"
)

:: 自动搜索常见位置
if not defined GODOT_EXE (
    for %%P in (
        "C:\Godot\Godot_v4*.exe"
        "C:\Program Files\Godot\Godot*.exe"
        "C:\Program Files (x86)\Godot\Godot*.exe"
        "%USERPROFILE%\Downloads\Godot*.exe"
        "%USERPROFILE%\Desktop\Godot*.exe"
        "%APPDATA%\..\Local\Godot\Godot*.exe"
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
    echo.
    echo 请在 scripts\godot_path.txt 里填写 Godot.exe 的完整路径，例如：
    echo   C:\Godot\Godot_v4.4.1-stable_win64.exe
    echo.
    pause
    exit /b 1
)

echo [OK] Godot: %GODOT_EXE%

:: ── 2. 准备输出目录 ──────────────────────────────────────────────
set PROJECT_DIR=%~dp0..
set OUT_DIR=%PROJECT_DIR%\exports\web

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
echo [OK] 输出目录: %OUT_DIR%
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
    echo   2. 编辑器里 export_presets.cfg 预设名为 "Web"
    pause
    exit /b %EXPORT_CODE%
)

echo [OK] 导出成功！
echo.

:: ── 4. 打开输出文件夹 ────────────────────────────────────────────
echo 打开输出目录...
explorer "%OUT_DIR%"

echo.
echo 本地预览（需要 Python）：
echo   cd "%OUT_DIR%" ^&^& python -m http.server 8080
echo   然后访问 http://localhost:8080
echo.
pause