@echo off
setlocal
set "GEOMETRY_GODOT=%GODOT_CONSOLE%"
if not defined GEOMETRY_GODOT if exist "%~dp0.local\godot.local.txt" set /p GEOMETRY_GODOT=<"%~dp0.local\godot.local.txt"
if not defined GEOMETRY_GODOT set "GEOMETRY_GODOT=godot"
"%GEOMETRY_GODOT%" --path "%~dp0." --log-file "%~dp0.godot\geometry-play.log" -- --geometry-only %*
