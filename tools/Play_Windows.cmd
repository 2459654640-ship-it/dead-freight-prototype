@echo off
setlocal
cd /d "%~dp0"
if not exist "DeadFreight.pck" (
 echo DeadFreight.pck is missing. Fully extract the PLAY package first.
 echo For source projects use Open_Editor_Windows.cmd instead.
 pause
 exit /b 2
)
if not exist "logs" mkdir "logs"
set "GODOT_EXE=%~1"
if not defined GODOT_EXE set /p "GODOT_EXE=Paste the full path to your Godot 4.7.2 EXE (or drag the EXE onto this CMD): "
set "GODOT_EXE=%GODOT_EXE:"=%"
if not exist "%GODOT_EXE%" (
 echo Godot EXE not found.
 pause
 exit /b 2
)
"%GODOT_EXE%" --version > "logs\engine-version.txt" 2>&1
findstr /b /c:"4.7.2" "logs\engine-version.txt" >nul
if errorlevel 1 (
 echo This game pack was built with Godot 4.7.2. Please select that version.
 type "logs\engine-version.txt"
 pause
 exit /b 2
)
"%GODOT_EXE%" --main-pack "%~dp0DeadFreight.pck" --rendering-method gl_compatibility --rendering-driver opengl3 --log-file "%~dp0logs\game-engine.log" > "logs\game-console.log" 2>&1
set "GAME_RESULT=%ERRORLEVEL%"
echo Game closed with exit code %GAME_RESULT%.
echo Logs are in %~dp0logs
pause
exit /b %GAME_RESULT%
