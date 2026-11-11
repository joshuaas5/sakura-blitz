@echo off
cd /d "%~dp0"
where godot >nul 2>nul
if %errorlevel%==0 (
  godot --path .
  goto :eof
)
if exist "C:\Users\Editora Vélos\scoop\shims\godot.exe" (
  "C:\Users\Editora Vélos\scoop\shims\godot.exe" --path .
  goto :eof
)
if exist "C:\tools\godot\Godot_v4.7.1-stable_win64.exe" (
  "C:\tools\godot\Godot_v4.7.1-stable_win64.exe" --path .
  goto :eof
)
echo Godot nao encontrado!
pause
