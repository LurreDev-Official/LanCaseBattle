@echo off
REM Double-click or run from cmd: LanCast.bat
cd /d "%~dp0"
if exist "config\lancast.env" (
  for /f "usebackq tokens=1,* delims==" %%A in (`findstr /R /V "^#" "config\lancast.env"`) do (
    if not "%%A"=="" set "%%A=%%B"
  )
)
if "%LANCAST_DEVICE%"=="" set LANCAST_DEVICE=windows
if "%LANCAST_AUTO_ROOM%"=="" set LANCAST_AUTO_ROOM=true

where flutter >nul 2>&1
if errorlevel 1 (
  echo ERROR: flutter not found in PATH.
  echo Install Flutter for Windows, then reopen this terminal.
  pause
  exit /b 1
)

echo Starting LanCast Viewer + Sender on %LANCAST_DEVICE% ...
start "LanCast Viewer" cmd /c "cd apps\viewer && flutter run -d %LANCAST_DEVICE% --dart-define=AUTO_ROOM=%LANCAST_AUTO_ROOM%"
timeout /t 3 /nobreak >nul
start "LanCast Sender" cmd /c "cd apps\sender && flutter run -d %LANCAST_DEVICE%"
echo Both apps launching. Close the two console windows to stop.
pause
