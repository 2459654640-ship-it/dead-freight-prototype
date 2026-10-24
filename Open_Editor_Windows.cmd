@echo off
setlocal
cd /d "%~dp0"
if not exist ".runtime\logs" mkdir ".runtime\logs"
set "GODOT_EXE=%~1"
if not defined GODOT_EXE set /p "GODOT_EXE=Paste the full path to your Godot 4.7.2 EXE (or drag the EXE onto this CMD): "
set "GODOT_EXE=%GODOT_EXE:"=%"
if not exist "%GODOT_EXE%" (
 echo Godot EXE not found. No files were changed.
 pause
 exit /b 2
)
"%GODOT_EXE%" --version > ".runtime\logs\engine-version.txt" 2>&1
echo Importing assets first. This may take several minutes on the first launch.
"%GODOT_EXE%" --headless --path "%~dp0." --editor --import --log-file "%~dp0.runtime\logs\import-engine.log" > ".runtime\logs\import-console.log" 2>&1
set "IMPORT_RESULT=%ERRORLEVEL%"
if not "%IMPORT_RESULT%"=="0" (
 echo Import failed with exit code %IMPORT_RESULT%.
 echo Logs are in %~dp0.runtime\logs
 pause
 exit /b %IMPORT_RESULT%
)
echo Import completed. Opening the Compatibility editor.
"%GODOT_EXE%" --path "%~dp0." --editor --rendering-method gl_compatibility --rendering-driver opengl3 --log-file "%~dp0.runtime\logs\editor-engine.log" > ".runtime\logs\editor-console.log" 2>&1
set "EDITOR_RESULT=%ERRORLEVEL%"
echo Editor closed with exit code %EDITOR_RESULT%.
echo Logs are in %~dp0.runtime\logs
pause
exit /b %EDITOR_RESULT%
