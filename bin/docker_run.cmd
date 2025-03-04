@echo off
setlocal enabledelayedexpansion

rem Check number of arguments
set argC=0
for %%x in (%*) do set /A argC+=1
if "%argC%" neq "3" (
    echo Usage: %0 deployment-folder aem-host:aem-port localport
    echo or: %0 deployment-folder aem-host:aem-port test
    echo.
    echo Examples:
    echo # Use deployment folder ^"out^", start dispatcher container on port 8080, for AEM running on myhost:4503
    echo %0 out myhost:4503 8080
    echo.
    echo # Same as above, but AEM runs on your macOS machine at port 4503
    echo %0 out host.docker.internal:4503 8080
    echo.
    echo # Same as above, but simulate a stage environment
    echo set DISP_RUN_MODE=stage
    echo %0 out host.docker.internal:4503 8080
    echo.
    echo # Same as above, but set dispatcher log level to debug to see HTTP traffic to the backend
    echo set DISP_LOG_LEVEL=trace1
    echo %0 out host.docker.internal:4503 8080
    echo.
    echo # Same as above, but set rewrite log level to trace2 to see how your RewriteRules get applied
    echo set REWRITE_LOG_LEVEL=trace2
    echo %0 out host.docker.internal:4503 8080
    echo.
    echo # Use deployment folder ^"out^", start httpd -t to test the configuration, dump processed dispatcher.any config
    echo # (note: provided aemhost needs to be resolvable, using ^"localhost^" is possible^)
    echo %0 out localhost:4503 test
    echo.
    echo Environment variables available:
    echo DISP_RUN_MODE:     defines the environment type or run mode. 
    echo                    Valid values are dev, stage or prod (default is dev^)
    echo DISP_LOG_LEVEL:    sets the dispatcher log level
    echo                    Valid values are trace1, debug, info, warn or error (default is warn^)
    echo REWRITE_LOG_LEVEL: sets the rewrite log level
    echo                    Valid values are trace1-trace8, debug, info, warn or error (default is warn^)
    echo ENV_FILE:          specifies a file of environment variables that should be imported.
    echo                    Valid values are paths to files. (e.g. my_envs.env^) (default is not set^)
    echo ALLOW_CACHE_INVALIDATION_GLOBALLY: specifies if the default_invalidate.any file for cache should be overwritten to allow all connections
    echo                                    Valid values: true/false (default is false^)
    echo HTTPD_DUMP_VHOSTS: enable dump of vhosts for debug
    echo                    Valid values are true/false (default is false^)
    echo ENABLE_MANAGED_REWRITE_MAPS_FLAG: enable managed rewrite maps
    echo                                   Valid values are true/false (default is true^)
    echo MANAGED_REWRITE_MAPS_PROBE_CHECK_SKIP: skip probe check for managed rewrite maps
    echo                                        Valid values are true/false (default is false^)
    exit /B 2
)

rem Validate deployment folder
set folder=%~dpfn1
if not exist %folder%\* (
    echo ** error: Deployment folder not found: %folder%
    exit /B 2
)

rem Validate AEM endpoint
set aemhostport=%2
for /f "delims=: tokens=1,2" %%x in ("%2") do (
    if [%%y] == [] (
        echo ** error: host:port combination expected, got: %aemhostport%
        exit /B 2
    )
    set aemhost=%%x
    set aemport=%%y
)

rem Validate local port
set localport=%3

rem Verify docker is installed
where docker.exe >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ** error: docker.exe not found in path.
    exit /B 2
)

rem Process files in deploymentfolder and generate volume argument
set volumes=
set config_dir=/etc/httpd
set customer_dir_mount=/mnt/dev/src
set httpd_dir=%config_dir%/conf.d
set dispatcher_dir=%config_dir%/conf.dispatcher.d
set scriptDir=%~dp0

if exist %folder%\values.csv (
    rem Process files in generated folder and generate volume argument
    echo values.csv found in deployment folder: %folder% - using files listed there

    rem Read contents of values.csv
    for /f "delims=" %%x in (%folder%\values.csv) do set values=%%x

    rem Loop through max possible file count in values.csv
    for /l %%g in (1,1,9) do (
        for /f "delims=, tokens=1,*" %%x in ("!values!") do (
            if %%x equ clientheaders_any (
                set "volumes=-v %folder%\%%x:%dispatcher_dir%/clientheaders/clientheaders.any:ro !volumes!"
            )
            if %%x equ custom_vars (
                set "volumes=-v %folder%\%%x:%httpd_dir%/variables/custom.vars:ro !volumes!"
            )
            if %%x equ farms_any (
                set "volumes=-v %folder%\%%x:%dispatcher_dir%/enabled_farms/farms.any:ro !volumes!"
            )
            if %%x equ filters_any (
                set "volumes=-v %folder%\%%x:%dispatcher_dir%/filters/filters.any:ro !volumes!"
            )
            if %%x equ global_vars (
                set "volumes=-v %folder%\%%x:%httpd_dir%/variables/global.vars:ro !volumes!"
            )
            if %%x equ rewrite_rules (
                set "volumes=-v %folder%\%%x:%httpd_dir%/rewrites/rewrite.rules:ro !volumes!"
            )
            if %%x equ rules_any (
                set "volumes=-v %folder%\%%x:%dispatcher_dir%/cache/rules.any:ro !volumes!"
            )
            if %%x equ virtualhosts_any (
                set "volumes=-v %folder%\%%x:%dispatcher_dir%/virtualhosts/virtualhosts.any:ro !volumes!"
            )
            if %%x equ vhosts_conf (
                set "volumes=-v %folder%\%%x:%httpd_dir%/enabled_vhosts/vhosts.conf:ro !volumes!"
            )
            set "values=%%y"
        )
    )
) else (
    rem Mount customer configuration folder and import script
    
    set volumes=-v ^"%scriptDir%..\lib\import_sdk_config.sh:/docker_entrypoint.d/zzz-import-sdk-config.sh:ro^" !volumes!
    set volumes=-v ^"%scriptDir%..\lib\dummy_gitinit_metadata.sh:/docker_entrypoint.d/zzz-overwrite_gitinit_metadata.sh:ro^" !volumes!
    if "!ALLOW_CACHE_INVALIDATION_GLOBALLY!"=="true" (
        set volumes=-v ^"%scriptDir%..\lib\overwrite_cache_invalidation.sh:/docker_entrypoint.d/zzz-overwrite_cache_invalidation.sh:ro^" !volumes!
    )
    set volumes=-v ^"%folder%:%customer_dir_mount%:ro^" !volumes!
    rem "Windows does not support hot reload due to WSL2 not supporting file system notifications"
)

rem Mount libs
set volumes=-v ^"%scriptDir%..\lib:/usr/lib/dispatcher-sdk:ro^" !volumes!

rem Process environment variables
set "envvars=--env AEM_HOST=%aemhost% --env AEM_PORT=%aemport% --env HOST_OS=windows"

if [%DISP_RUN_MODE%] neq [] (
    for %%a in (dev stage prod) do (
        if [%DISP_RUN_MODE%] equ [%%a] (
            set "envvars=!envvars! --env ENVIRONMENT_TYPE=%%a"
            goto :check_disp_ll
        )
    )
    echo ** error: unknown environment type: %DISP_RUN_MODE% (expected dev, stage or prod^) & exit /B 2
)

:check_disp_ll
if [%DISP_LOG_LEVEL%] neq [] (
    for %%a in (trace1 debug info warn error) do (
        if [%DISP_LOG_LEVEL%] equ [%%a] (
            set "envvars=!envvars! --env DISP_LOG_LEVEL=%%a"
            goto :check_rewrite_ll
        )
    )
    echo ** error: unknown dispatcher log level: %DISP_LOG_LEVEL% expected (trace1 debug info warn error^) & exit /B 2
)

:check_rewrite_ll
if [%REWRITE_LOG_LEVEL%] neq [] (
    for %%a in (trace1 trace2 debug info warn error) do (
        if [%REWRITE_LOG_LEVEL%] equ [%%a] (
            set "envvars=!envvars! --env REWRITE_LOG_LEVEL=%%a"
            goto :check_finished
        )
    )
    echo ** error: unknown rewrite log level: %REWRITE_LOG_LEVEL%  (expected trace1-trace2, debug, info, warn or prod^) & exit /B 2
)

if [%ENV_FILE%] neq [] (
    set envvars=%envvars% --env-file %ENV_FILE%
)

if [%ENABLE_MANAGED_REWRITE_MAPS_FLAG%] equ [] (
    rem Managed rewrite maps enabled by default
    set ENABLE_MANAGED_REWRITE_MAPS_FLAG=true
)
set envvars=%envvars% --env ENABLE_MANAGED_REWRITE_MAPS_FLAG=%ENABLE_MANAGED_REWRITE_MAPS_FLAG%

if [%MANAGED_REWRITE_MAPS_PROBE_CHECK_SKIP%] neq [] (
    set envvars=%envvars% --env MANAGED_REWRITE_MAPS_PROBE_CHECK_SKIP=%MANAGED_REWRITE_MAPS_PROBE_CHECK_SKIP%
)

:check_finished

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
if [%localport%] equ [test] (
    docker run --rm %volumes% %envvars% --env SKIP_BACKEND_WAIT=true --env SKIP_CONFIG_TESTING=true %imageurl% /usr/sbin/httpd-test
    if "!HTTPD_DUMP_VHOSTS!" == "true" (
        docker run --rm --entrypoint test %imageurl% -f /usr/sbin/httpd-vhosts
        if !ERRORLEVEL! NEQ 0 (
            set volumes=-v ^"%scriptDir%..\lib\httpd-vhosts:/usr/sbin/httpd-vhosts:ro^" !volumes!
        )
        docker run --rm !volumes! %envvars% --env SKIP_BACKEND_WAIT=true --env SKIP_CONFIG_TESTING=true %imageurl% /usr/sbin/httpd-vhosts
    )
) else (
    docker run --rm -p %localport%:80 %volumes% %envvars% %imageurl%
)
