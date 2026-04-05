@echo off
setlocal

setlocal ENABLEDELAYEDEXPANSION

SET BASEDIR=%~dp0

if not exist "%CARGOKIT_TOOL_TEMP_DIR%" (
    mkdir "%CARGOKIT_TOOL_TEMP_DIR%"
)
cd /D "%CARGOKIT_TOOL_TEMP_DIR%"

SET BUILD_TOOL_PKG_DIR=%BASEDIR%build_tool
SET DART=%FLUTTER_ROOT%\bin\cache\dart-sdk\bin\dart
echo DEBUG: Checking for Dart at "%DART%.exe"
if not exist "%DART%.exe" (
    echo ERROR: Dart SDK not found at "%DART%.exe".
    echo Please ensure FLUTTER_ROOT is set correctly.
    exit /b 1
)

set BUILD_TOOL_PKG_DIR_POSIX=%BUILD_TOOL_PKG_DIR:\=/%

SET "L1=name: build_tool_runner"
SET "L2=version: 1.0.0"
SET "L3=publish_to: none"
SET "L4=environment:"
SET "L5=  sdk: '>=3.0.0 <4.0.0'"
SET "L6=dependencies:"
SET "L7=  build_tool:"
SET "L8=    path: %BUILD_TOOL_PKG_DIR_POSIX%"

echo !L1! >pubspec.yaml
echo !L2! >>pubspec.yaml
echo !L3! >>pubspec.yaml
echo. >>pubspec.yaml
echo !L4! >>pubspec.yaml
echo !L5! >>pubspec.yaml
echo. >>pubspec.yaml
echo !L6! >>pubspec.yaml
echo !L7! >>pubspec.yaml
echo !L8! >>pubspec.yaml

if not exist bin (
    mkdir bin
)

echo import 'package:build_tool/build_tool.dart' as build_tool; >bin\build_tool_runner.dart
echo void main^(List^<String^> args^) ^{ >>bin\build_tool_runner.dart
echo    build_tool.runMain^(args^); >>bin\build_tool_runner.dart
echo ^} >>bin\build_tool_runner.dart

SET PRECOMPILED=bin\build_tool_runner.dill

REM To detect changes in package we compare output of DIR /s (recursive)
set PREV_PACKAGE_INFO=.dart_tool\package_info.prev
set CUR_PACKAGE_INFO=.dart_tool\package_info.cur

SET CUR_PACKAGE_INFO_ORIG=%CUR_PACKAGE_INFO%_orig

if not exist .dart_tool (
    mkdir .dart_tool
)

DIR "%BUILD_TOOL_PKG_DIR%" /s > "%CUR_PACKAGE_INFO_ORIG%" 2>nul

REM Last line in dir output is free space on harddrive. That is bound to
REM change between invocation so we need to remove it
Set "Line="
if exist "%CUR_PACKAGE_INFO_ORIG%" (
    if exist "%CUR_PACKAGE_INFO%" del "%CUR_PACKAGE_INFO%"
    For /F "UseBackQ Delims=" %%A In ("%CUR_PACKAGE_INFO_ORIG%") Do (
        SetLocal EnableDelayedExpansion
        If Defined Line Echo !Line! >>"%CUR_PACKAGE_INFO%"
        EndLocal
        Set "Line=%%A"
    )
    DEL "%CUR_PACKAGE_INFO_ORIG%"
)

REM Compare current directory listing with previous
FC /B "%CUR_PACKAGE_INFO%" "%PREV_PACKAGE_INFO%" > nul 2>&1

If %ERRORLEVEL% neq 0 (
    REM Changed - copy current to previous and remove precompiled kernel
    if exist "%PREV_PACKAGE_INFO%" (
        DEL "%PREV_PACKAGE_INFO%"
    )
    MOVE /Y "%CUR_PACKAGE_INFO%" "%PREV_PACKAGE_INFO%"
    if exist "%PRECOMPILED%" (
        DEL "%PRECOMPILED%"
    )
)

REM There is no CUR_PACKAGE_INFO it was renamed in previous step to %PREV_PACKAGE_INFO%
REM which means  we need to do pub get and precompile
if not exist "%PRECOMPILED%" (
    echo Running pub get in "%cd%"
    "%DART%.exe" pub get --no-precompile
    "%DART%.exe" compile kernel bin/build_tool_runner.dart
)

"%DART%.exe" "%PRECOMPILED%" %*

REM 253 means invalid snapshot version.
If %ERRORLEVEL% equ 253 (
    "%DART%" pub get --no-precompile
    "%DART%" compile kernel bin/build_tool_runner.dart
    "%DART%" "%PRECOMPILED%" %*
)
