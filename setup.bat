@echo off


:: FUNCTION: Main entry point
:: ==========================
:Main

:: Parse arguments
call :ParseArgs %*
if %ERRORLEVEL% geq 1 (
    goto Cleanup
)

:: Check if running as admin
net session 1>NUL 2>NUL
if %ERRORLEVEL% geq 1 (
    echo ::: Not running as administrator. Exiting...
    exit /B %ERRORLEVEL%
)

:: Get Windows version
:: From Tronscript
for /f "tokens=3*" %%i IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion ^| findstr "CurrentVersion"') do set version=%%i

:: Install chocolatey
call :InstallChocolatey
if %ERRORLEVEL% geq 1 (
    echo ::: Error installing chocolatey
    goto Cleanup
)

:: Install programs
call :InstallPrograms
if %ERRORLEVEL% geq 1 (
    echo ::: Error installing programs
    goto Cleanup
)

:: Modify registry (Windows 10 only)
if %version% == 6.3 (
    call :ModifyRegistryWin10
)

:Cleanup
exit /B %ERRORLEVEL%


:: FUNCTION: Print help message
:: ============================
:PrintHelp

echo Usage: setup.bat [options]
echo     /D    Don't execute any commands
echo     /H    Prints this message
exit /B


:: FUNCTION: Parse Arguments
:: =========================
:ParseArgs

:: Set arguments to undefined
set ARG_DRY=undefined

:ParseArgsLoop
    if "%~1" == "" (
        goto ParseArgsEnd
    )

    if "%~1" == "/D" (
        set ARG_DRY=1
    )

    if "%~1" == "/H" (
        call :PrintHelp
        exit /B 1
    )

    shift
    goto ParseArgsLoop

:ParseArgsEnd
exit /B 0


:: FUNCTION: Execute command
:: ===========================
:RunCmd

echo ^>^>^> %*
if %ARG_DRY% == 1 (
    exit /B
)

%*
exit /B %ERRORLEVEL%


:: FUNCTION: Installs Chocolatey
:: =============================
:InstallChocolatey

echo ::: Installing Chocolatey...
call :RunCmd powershell -NoProfile -ExecutionPolicy Bypass -Command ^"Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
call :RunCmd SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
call :RunCmd choco feature enable -n useRememberedArgumentsForUpgrades
echo ::: Finished installing Chocolatey.

exit /B %ERRORLEVEL%


:: FUNCTION: Installs programs using Chocolatey
:: ============================================
:InstallPrograms

echo ::: Installing Programs...

:: Setting up the list of programs
set programs=7zip
set programs=%programs% altsnap
set programs=%programs% cmake
set programs=%programs% firefox
set programs=%programs% foobar2000
set programs=%programs% gnupg
set programs=%programs% keepass
set programs=%programs% krita
set programs=%programs% mpv
set programs=%programs% nextcloud-client
set programs=%programs% procexp
set programs=%programs% speccy
set programs=%programs% sublimemerge
set programs=%programs% sublimetext4
set programs=%programs% sumatrapdf
set programs=%programs% windirstat
set programs=%programs% winrar
set programs=%programs% youtube-dl

:: Setting up the list of programs for Windows 10
if %version% == 6.3 (
    set programs=%programs% python
    set programs=%programs% obs-studio.install
)

:: Install the program
call :RunCmd choco install -y %programs%

:: Windows 7 specific programs
if %version% == 6.1 (
    call :RunCmd choco install -y python --version 3.8.10
    call :RunCmd choco install -y obs-studio.install --version 27.2.4.20220520

    :: Pin packages to prevent upgrades
    call :RunCmd choco pin add -y --name python --version 3.8.10
    call :RunCmd choco pin add -y --name python3 --version 3.8.10
    call :RunCmd choco pin add -y --name obs-studio.install --version 27.2.4.20220520
)

:: Git requires specific parameters
set params=/GitOnlyOnPath
set params=%params% /NoShellIntegration

call :RunCmd choco install -y git --params ^"%params%^"
echo ::: Finished installing programs.

exit /B %ERRORLEVEL%


:: FUNCTION: Modify the registry (Windows 10)
:: ==========================================
:ModifyRegistryWin10

echo ::: Modifying Registry (Windows 10)...

:: Change inactive title bar color
call :RunCmd reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\DWM /f /v AccentColorInactive /t REG_DWORD /d 0x00c9c9c9

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

for %%i in (%folders_guid%) do (
    call :RunCmd reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\%%i /f
    call :RunCmd reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\%%i /f
)

echo ::: Finished Modifying Registry (Windows 10)...
exit /B %ERRORLEVEL%


:: From the bottom call the top
call :Main

@echo on
