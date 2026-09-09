@echo off
setlocal

for %%I in ("%~dp0.") do set "PROJECT_DIR=%%~fI"
rem Prefer an explicit environment variable, then ignored local config, then PATH.
if not defined GODOT_CONSOLE if exist "%PROJECT_DIR%\godot.local.txt" set /p GODOT_CONSOLE=<"%PROJECT_DIR%\godot.local.txt"
if not defined GODOT_CONSOLE for %%E in (godot_console.exe godot.exe) do for /f "delims=" %%G in ('where %%E 2^>nul') do if not defined GODOT_CONSOLE set "GODOT_CONSOLE=%%G"

if not exist "%GODOT_CONSOLE%" goto :missing_godot
if not exist "%PROJECT_DIR%\project.godot" goto :missing_project
if not exist "%PROJECT_DIR%\.godot" mkdir "%PROJECT_DIR%\.godot"

if "%~1"=="" goto :play
if /I "%~1"=="--editor" goto :editor
if /I "%~1"=="--test" goto :test
if /I "%~1"=="--check" goto :check
goto :usage

:play
pushd "%PROJECT_DIR%"
echo Starting Bounce Lite from:
echo   %PROJECT_DIR%
echo.
"%GODOT_CONSOLE%" --log-file "%PROJECT_DIR%\.godot\playtest.log" --path "%PROJECT_DIR%"
set "RESULT=%ERRORLEVEL%"
popd
echo.
echo Bounce Lite exited with code %RESULT%.
pause
exit /b %RESULT%

:editor
pushd "%PROJECT_DIR%"
"%GODOT_CONSOLE%" --log-file "%PROJECT_DIR%\.godot\editor.log" --editor --path "%PROJECT_DIR%"
set "RESULT=%ERRORLEVEL%"
popd
echo.
echo Godot editor exited with code %RESULT%.
pause
exit /b %RESULT%

:test
pushd "%PROJECT_DIR%"
"%GODOT_CONSOLE%" --headless --log-file "%PROJECT_DIR%\.godot\tests.log" --path "%PROJECT_DIR%" --script res://tests/test_runner.gd
set "RESULT=%ERRORLEVEL%"
popd
echo.
echo Test runner exited with code %RESULT%.
pause
exit /b %RESULT%

:check
echo Project:
echo   %PROJECT_DIR%
echo Godot:
echo   %GODOT_CONSOLE%
echo Version:
"%GODOT_CONSOLE%" --version
exit /b %ERRORLEVEL%

:missing_godot
echo ERROR: Godot console executable was not found:
echo   %GODOT_CONSOLE%
echo Set GODOT_CONSOLE or put its full path in ignored godot.local.txt.
pause
exit /b 1

:missing_project
echo ERROR: project.godot was not found:
echo   %PROJECT_DIR%\project.godot
pause
exit /b 1

:usage
echo Usage:
echo   run-playtest.bat           Run the game and keep the console log.
echo   run-playtest.bat --editor  Open the project in the Godot editor.
echo   run-playtest.bat --test    Run deterministic headless tests.
echo   run-playtest.bat --check   Print resolved paths and Godot version.
pause
exit /b 2
