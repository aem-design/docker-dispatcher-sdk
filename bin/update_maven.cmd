@echo off
setlocal enabledelayedexpansion

rem Check number of arguments
set argC=0
for %%x in (%*) do set /A argC+=1
if "%argC%" neq "1" (
    if "%argC%" neq "2" (
        echo Usage: %0 config-folder [mode: {--overwrite,--printOnly}]
        echo.
        echo Examples:
        echo # Use config folder ^"src^" (assuming default ^"--overwrite^" mode^) to overwrite immutable files and adapt pom.xml in ../src
        echo %0 src
        echo or explicitly giving the ^"--overwrite^" mode
        echo %0 src --overwrite
        echo # Use config folder ^"src^" to overwrite immutable files and print changes that should be applied to the pom.xml file
        echo %0 src --printOnly
        exit /B 2
    )
)

rem Check overwrite mode
set vmode=%2

if [!vmode!] equ [] (
	echo empty mode param, assuming mode = '--overwrite'
	set vmode=--overwrite
) else (
	if [!vmode!] neq [--overwrite] (
	    if [!vmode!] neq [--printOnly] (
	        echo mode '!vmode!' is neither '--overwrite' nor '--printOnly'
	        exit /B 2
	    )
	)
)

rem Validate config folder
set folder=%~dpfn1
if not exist %folder%\* (
    echo ** error: Config folder not found: %folder%
    exit /B 2
)

for %%F in (%0) do set dirname=%%~dpF
call !dirname!docker_immutability_check.cmd %folder% extract

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

for /F "tokens=* USEBACKQ" %%f in (`docker create %imageurl%`) do (
    set tmpcontainer=%%f
)

docker cp %tmpcontainer%:/etc/httpd/immutable.files.txt immutable.files.txt
docker rm -v %tmpcontainer%

rem Run validator in mvn mode

for %%F in (%0) do set dirname=%%~dpF
!dirname!validator.exe mvn immutable.files.txt %folder% !vmode!

del /f immutable.files.txt

