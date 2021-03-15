@echo off


:: FUNCTION: Main entry point
:: ==========================
:Main

:: Check if running as admin
net session 1>NUL 2>NUL
if %ERRORLEVEL% geq 1 (
    echo Not running as administrator. Exiting...
    exit /B %ERRORLEVEL%
)

:: Change the prompt
set old_prompt=%PROMPT%
set PROMPT=^>^>^>^ 

:: Get Windows version
for /f "tokens=4-5 delims=. " %%i in ('ver') do (
    set version=%%i.%%j
)

:: Install chocolatey
call :InstallChocolatey
if %ERRORLEVEL% geq 1 (
    echo Error installing chocolatey
    goto Cleanup
)

:: Install programs
call :InstallPrograms
if %ERRORLEVEL% geq 1 (
    echo Error installing programs
    goto Cleanup
)

:: Modify registry
call :ModifyRegistry

:: Modify registry (Windows 10 only)
if %version% == 10.0 (
    call :ModifyRegistryWin10
)

:Cleanup
set PROMPT=%old_prompt%
exit /B %ERRORLEVEL%


:: FUNCTION: Installs Chocolatey
:: =============================
:InstallChocolatey

echo Installing Chocolatey...
@echo on
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
@echo off
echo Finished installing Chocolatey.

exit /B %ERRORLEVEL%


:: FUNCTION: Installs programs using Chocolatey
:: ============================================
:InstallPrograms

echo Installing Programs...

:: Setting up the list of programs
set programs=7zip
set programs=%programs% cmake
set programs=%programs% firefox
set programs=%programs% foobar2000
set programs=%programs% keepass
set programs=%programs% krita
set programs=%programs% malwarebytes
set programs=%programs% mpv
set programs=%programs% nextcloud-client
set programs=%programs% obs-studio
set programs=%programs% speccy
set programs=%programs% sublimemerge
set programs=%programs% sublimetext3
set programs=%programs% winrar

:: Install the program
@echo on
choco install -y %programs%
@echo off

:: Git requires specific parameters
set params=/GitOnlyOnPath
set params=%params% /NoShellIntegration
set params=%params% /NoGuiHereIntegration
set params=%params% /NoShellHereIntegration

@echo on
choco install -y git --params "%params%"
@echo off
echo Finished installing programs.
exit /B %ERRORLEVEL%


:: FUNCTION: Modify the registry (Windows 10)
:: ==========================================
:ModifyRegistryWin10

echo Modifying Registry (Windows 10)...

:: Change inactive title bar color
@echo on
reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM /f /v AccentColorInactive /t REG_DWORD /d 0x00c9c9c9
@echo off

:: Remove folders from My Computer

:: Desktop
set folders_guid={B4BFCC3A-DB2C-424C-B029-7FE99A87C641}
:: Documents
set folders_guid=%folders_guid% {A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}
set folders_guid=%folders_guid% {d3162b92-9365-467a-956b-92703aca08af}
:: Downloads
set folders_guid=%folders_guid% {374DE290-123F-4565-9164-39C4925E467B}
set folders_guid=%folders_guid% {088e3905-0323-4b02-9826-5d99428e115f}
:: Music
set folders_guid=%folders_guid% {1CF1260C-4DD0-4ebb-811F-33C572699FDE}
set folders_guid=%folders_guid% {3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}
:: Pictures
set folders_guid=%folders_guid% {3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}
set folders_guid=%folders_guid% {24ad3ad4-a569-4530-98e1-ab02f9417aa8}
:: Videos
set folders_guid=%folders_guid% {A0953C92-50DC-43bf-BE83-3742FED03C9C}
set folders_guid=%folders_guid% {f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}
:: 3D Objects
set folders_guid=%folders_guid% {0DB7E03F-FC29-4DC6-9020-FF41B59E513A}

@echo on
for %%i in (%folders_guid%) do (
    reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\%%i /f
    reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\%%i /f
)
@echo off

echo Finished Modifying Registry (Windows 10)...
exit /B %ERRORLEVEL%


:: From the bottom call the top
call :Main

@echo on