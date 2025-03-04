@echo off
setlocal enabledelayedexpansion

rem Check number of arguments
set argC=0
for %%x in (%*) do set /A argC+=1
if "%argC%" neq "1" (
    if "%argC%" neq "2" (
        echo Usage: %0 config-folder [mode: {check,extract}]
        echo.
        echo Examples:
        echo # Use config folder ^"src^" (assuming default ^"check^" mode^) for immutable files check
        echo %0 src
        echo or explicitly giving the ^"check^" mode
        echo %0 src check
        echo # Use config folder ^"src^" as a destination to extract immutable files into it
        echo %0 src extract
        echo Environment variables available:
        echo IMMUTABLE_FILES_UPDATE:     controls whether immutable files should be updated or not.
        echo                             Valid values are true or false (default is true^)
        exit /B 2
    )
)

rem Check mode
set mode=%2

if [!mode!] equ [] (
	echo empty mode param, assuming mode = 'check'
	set mode=check
) else (
	if [!mode!] neq [check] (
	    if [!mode!] neq [extract] (
	        echo mode '!mode!' is neither 'check' nor 'extract'
	        exit /B 2
	    )
	)
)

echo running in '!mode!' mode

rem Validate config folder
set folder=%~dpfn1
if not exist %folder%\* (
    echo ** error: Config folder not found: %folder%
    exit /B 2
)

rem Verify docker file is available
set repo=adobe
set image=aem-cs/dispatcher-publish
set version=2.0.235
set "imageurl=%repo%/%image%:%version%"

for /F "tokens=* USEBACKQ" %%f in (`docker images -q %imageurl%`) do (
    set location=%%f
)

rem Load docker file
if [%location%] equ [] (
    echo Required image not found, trying to load from archive...
    for %%F in (%0) do set dirname=%%~dpF
    set file=!dirname!..\lib\dispatcher-publish-amd64.tar.gz
    if not exist !file! (
        echo ** error: unable to find archive at expected location: !file!
        exit /B 2
    )
    docker load -i !file!
    if !ERRORLEVEL! neq 0 (
        exit /B 2
    )
)

rem Run docker
set scriptDir=%~dp0

set configVolumeMountMode=rw
if [!mode!] equ [check] (
    set configVolumeMountMode=ro
)

docker run --rm ^
    -v %folder%:/etc/httpd-actual:!configVolumeMountMode! ^
    -v ^"%scriptDir%..\lib\immutability_check.sh:/usr/sbin/immutability_check.sh:ro^" ^
    --entrypoint /bin/sh %imageurl% /usr/sbin/immutability_check.sh /etc/httpd/immutable.files.txt /etc/httpd-actual !mode!

set exitcode=!ERRORLEVEL!

if !exitcode! neq 0 (
    if "!IMMUTABLE_FILES_UPDATE!" == "false" (
        echo ** info: Immutable files were changed.
        exit /B %exitcode%
    )

    :start
    set /p answer="Do you want to update immutable files? (yes/no): "
    if /I "!answer!" == "yes" (
        %scriptDir%/update_maven.cmd %folder%
        echo ** info: User is advised to re-run the validation of immutable files again.
        exit /B 0
    )
    if /I "!answer!" == "no" (
        exit /B 0
    )
    echo ** info: Please answer yes or no.
    goto :start
) else (
    exit /B 0
)
