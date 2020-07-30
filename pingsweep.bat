@echo off
SETLOCAL EnablEextensions EnableDelayedExpansion

for /F "skip=2 tokens=2,4 delims=,;" %%A in ('wmic NICCONFIG WHERE IPEnabled^=true GET IPAddress^,IPSubnet /format:csv') do (
    set IP=%%A
    set SNM=%%B

    REM Clean up IP and Subnet Mask strings
    set IP=!IP:{=!
    set SNM=!SNM:{=!

    REM Calculate CIDR from Subnet Mask
    for /f "tokens=1-4 delims=." %%a in ("!SNM!") do (
        set o1=%%a
        set o2=%%b
        set o3=%%c
        set o4=%%d
    )
    set CIDR=0
    for %%o in (!o1!, !o2!, !o3!, !o4!) do (
        if "%%o"=="255" set /a CIDR=!CIDR! + 8
        if "%%o"=="254" set /a CIDR=!CIDR! + 7
        if "%%o"=="252" set /a CIDR=!CIDR! + 6
        if "%%o"=="248" set /a CIDR=!CIDR! + 5
        if "%%o"=="240" set /a CIDR=!CIDR! + 4
        if "%%o"=="224" set /a CIDR=!CIDR! + 3
        if "%%o"=="192" set /a CIDR=!CIDR! + 2
        if "%%o"=="128" set /a CIDR=!CIDR! + 1
    )
    
    REM Extract each IP octet
    for /f "tokens=1-4 delims=." %%a in ("!IP!") do (
        set o1=%%a
        set o2=%%b
        set o3=%%c
        set o4=%%d
    )

    REM Convert IP to integer
    set /a "BinIP=(!o2!<<16) + (!o3!<<8) + !o4!"
    
    REM Convert CIDR to Binary Mask
    set /a "BinMask=0xFFFFFFFF<<(32-!CIDR!)"

    REM Get first IP
    set /a "FirstIP=!BinIP!&!BinMask!"

    REM Get last IP
    set /a "LastIP=(!FirstIP!|(~!BinMask!))&0x7FFFFFFF"

    REM Loop through each IP integer between the start and stop
    for /l %%i in (!FirstIP!,1,!LastIP!) do (
        REM Display Progress Bar
        set /a "PercentComplete=((%%i - !FirstIP!) * 100 / (!LastIP! - !FirstIP!))"
        title !PercentComplete! %% Completed

        REM Convert each octet to an integer
        set /a "o2=(%%i & 0xFF0000) >> 16"
        set /a "o3=(%%i & 0xFF00) >> 8"
        set /a "o4=(%%i & 0xFF)"

        REM Create the IP string
        set "HOST= !o1!.!o2!.!o3!.!o4!"

        REM Ping the IP once with a timeout of 100 milliseconds
        for /f %%C in ('ping -n 1 -w 100 !HOST!') do (
            if /I "%%C" == "Reply" (
                echo !HOST! is alive  !REPLY!
            )
        )
    )
)
