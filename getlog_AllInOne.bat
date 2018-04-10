::Author: Cyril Taylor
::Update: https://github.com/CyrilTaylor/ScriptTools/blob/master/getlog_AllInOne.bat

@ECHO off
color 8B
SET debug=false
IF NOT "%debug%"=="true" MODE CON cols=80 lines=5
IF "%debug%"=="true" ECHO on
SET iDate=%date%
SET iTime=%time%
SET data_time=%iDate:~0,4%%iDate:~5,2%%iDate:~8,2%_%iTime:~0,2%%iTime:~3,2%%iTime:~6,2%

IF "%debug%"=="true" ECHO param[0] = %0
IF "%debug%"=="true" ECHO param[1] = %1
IF "%debug%"=="true" ECHO param[2] = %2
IF "%debug%"=="true" ECHO param[3] = %3
IF "%debug%"=="true" ECHO param[4] = %4
IF "%debug%"=="true" ECHO param[5] = %5

IF "%1"=="" GOTO Main
IF "%1"=="Logcat" GOTO Logcat
IF "%1"=="KernelLog" GOTO KernelLog
IF "%1"=="TeeLog" GOTO TeeLog
GOTO End

:Main
ECHO waitting for devices...
::adb wait-for-device root
::adb wait-for-device shell SETenforce 0
adb wait-for-device devices
adb devices > "%~dp0\devices.tmp"
set count=0
set IdIndex=0
set DeviceId=0
setlocal enabledelayedexpansion
for /f "skip=1 tokens=1 delims=	" %%i in (%~dp0\devices.tmp) do (
    set /a count+=1
	echo !count!. %%i
)

IF %count%==0 ECHO "Can't get the devices" && GOTO End
IF %count%==1 set IdIndex=1 && GOTO GetDeviceId

:SetIndex
set /p IdIndex=There are more than one device/emulator, please select one by index:

IF %IdIndex% LSS 1 ECHO Index should be 1 ~ %count% && GOTO SetIndex
IF %IdIndex% GTR %count% ECHO Index should be 1 ~ %count% && GOTO SetIndex

:GetDeviceId
for /f "skip=%IdIndex% tokens=1 delims=	" %%i in (%~dp0\devices.tmp) do (
	set DeviceId=%%i
	GOTO StartLog
)

:StartLog
START cmd /k "TITLE logcat %iDate% %iTime:~,8% && %0 Logcat "%iDate%" "%iTime%" "%DeviceId%""
START cmd /k "TITLE Kernel log %iDate% %iTime:~,8% && %0 KernelLog "%iDate%" "%iTime%" "%DeviceId%""
START cmd /k "TITLE tee log %iDate% %iTime:~,8% && %0 TeeLog "%iDate%" "%iTime%" "%DeviceId%""
del %~dp0\devices.tmp
GOTO End

:Logcat
SET iDate=%2
SET iDate=%iDate:~1,10%
SET iTime=%3
SET iTime=%iTime:~1,11%
SET data_time=%iDate:~0,4%%iDate:~5,2%%iDate:~8,2%_%iTime:~0,2%%iTime:~3,2%%iTime:~6,2%
:LogcatLoop
SET DeviceId=%4
IF "%debug%"=="true" ECHO DeviceId = %DeviceId%
ECHO waitting for devices...
adb -s %DeviceId% wait-for-device devices | findstr /r /C:"device$" 1>nul 2>nul && ECHO Catching logcat... && adb -s %DeviceId% logcat -b all -D >> "%~dp0\logcat_%data_time%.log"
GOTO LogcatLoop

:KernelLog
SET iDate=%2
SET iDate=%iDate:~1,10%
SET iTime=%3
SET iTime=%iTime:~1,11%
SET data_time=%iDate:~0,4%%iDate:~5,2%%iDate:~8,2%_%iTime:~0,2%%iTime:~3,2%%iTime:~6,2%
:KernelLogLoop
SET DeviceId=%4
IF "%debug%"=="true" ECHO DeviceId = %DeviceId%
ECHO waitting for devices...
adb -s %DeviceId% wait-for-device shell getprop ro.build.type 2>&1 | findstr /r /C:"^user$" 1>nul 2>nul || ECHO Catching Kernel log... && adb -s %DeviceId% logcat -b kernel >> "%~dp0\kernel_%data_time%.log"
adb -s %DeviceId% devices | findstr /r /C:"device$" 1>nul 2>nul && adb -s %DeviceId% shell getprop ro.build.type 2>&1 | findstr /r /C:"^user$" 1>nul 2>nul && ECHO Catching Kernel log... && adb -s %DeviceId% shell cat /proc/kmsg >> "%~dp0\kernel_%data_time%.log"
GOTO KernelLogLoop

:TeeLog
SET iDate=%2
SET iDate=%iDate:~1,10%
SET iTime=%3
SET iTime=%iTime:~1,11%
SET data_time=%iDate:~0,4%%iDate:~5,2%%iDate:~8,2%_%iTime:~0,2%%iTime:~3,2%%iTime:~6,2%
:TeeLogLoop
SET DeviceId=%4
IF "%debug%"=="true" ECHO DeviceId = %DeviceId%
ECHO waitting for devices...
adb -s %DeviceId% wait-for-device shell ls -l /d/tzdbg/qsee_log 2>&1 | findstr /r /C:" /d/tzdbg/qsee_log$" 1>nul 2>nul || adb -s %DeviceId% shell ls -l /d/tzdbg/qsee_log 2>&1 | findstr /r /C:" /d/tzdbg/qsee_log$" 1>nul 2>nul || exit
adb -s %DeviceId% shell ls -l /d/tzdbg/qsee_log 2>&1 | findstr /r /C:" /d/tzdbg/qsee_log$" 1>nul 2>nul && TITLE qsee log %iDate% %iTime:~,8% && ECHO Catching qsee log... && adb -s %DeviceId% shell cat /d/tzdbg/qsee_log >> "%~dp0\qsee_%data_time%.log"
GOTO TeeLogLoop

:Error
@pause

:End
