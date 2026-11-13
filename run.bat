@echo off
setlocal
cd /d "%~dp0"
if exist "..\tools\godot\Godot_v4.7.2-stable_win64.exe" (
  "..\tools\godot\Godot_v4.7.2-stable_win64.exe" --path . %*
  exit /b
)
where godot >nul 2>nul
if %errorlevel%==0 (
  godot --path . %*
  exit /b
)
echo Godot 4.7.2 nao encontrado. Abra project.godot no editor ou coloque Godot no PATH.
pause
