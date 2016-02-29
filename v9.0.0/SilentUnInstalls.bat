@echo off
setlocal
set > %TEMP%\%~n0_env1.txt
rem ===============================================================================
set FILE_REV=20151023
rem ===============================================================================
rem SilentUnInstalls.bat: Used to uninstall the IBM WebSphere Transformation Extender
rem                       products.
rem
rem To generate any required response files, set TXINSTALLS_GENRESFILES=1.
rem This will run the specified uninstalls interactively, allowing you to customize
rem your response files.
rem
rem ===============================================================================


set LOCAL_VRMFNUM=
if defined MAJOR_VER                      set LOCAL_VRMFNUM=%MAJOR_VER%
if defined TXINSTALLS_VRMFNUM             set LOCAL_VRMFNUM=%TXINSTALLS_VRMFNUM%
if not defined LOCAL_VRMFNUM                goto :Error_VRMFUndefined
if ("%LOCAL_VRMFNUM:~0,5%") leq ("8.4.0")   goto :MajorVerUses_VR
if defined TXINSTALLS_USE_VR_FOR_MAJOR_VER  goto :MajorVerUses_VR
:MajorVerUses_VRM
set MAJOR_VER=%LOCAL_VRMFNUM:~0,5%
goto :AfterSetMajorVer
:MajorVerUses_VR
set MAJOR_VER=%LOCAL_VRMFNUM:~0,3%
:AfterSetMajorVer

set GENERATE_RESPONSEFILES=
if     defined TXINSTALLS_GENRESFILES     set GENERATE_RESPONSEFILES=1

if     defined TXINSTALLS_RESPONSEDIR     set RESPONSEDIR=%TXINSTALLS_RESPONSEDIR%
if not defined TXINSTALLS_RESPONSEDIR     set RESPONSEDIR=%CD%\Responses
if exist "%RESPONSEDIR%\%LOCAL_VRMFNUM%"  set RESPONSEDIR=%RESPONSEDIR%\%LOCAL_VRMFNUM%
if exist "%RESPONSEDIR%\%MAJOR_VER%"      set RESPONSEDIR=%RESPONSEDIR%\%MAJOR_VER%

if     defined TXINSTALLS_RESULTDIR       set RESULTDIR=%TXINSTALLS_RESULTDIR%
if not defined TXINSTALLS_RESULTDIR       set RESULTDIR=%CD%\Logs\%MAJOR_VER%

set MAKE_EXTRA_CLEAN=1
set MAKE_EXTRA_CLEAN_DIR=1
if defined TXINSTALLS_NOEXTRACLEAN        set MAKE_EXTRA_CLEAN=
if defined TXINSTALLS_NOEXTRACLEAN_DIR    set MAKE_EXTRA_CLEAN_DIR=

set TXINSTALLS_DEBUG=

rem ===============================================================================
rem END: User configurable settings.
rem ===============================================================================

rem ===============================================================================
rem Initialize values that we need.  Use temp filenames that don't include double
rem quotes to prevent syntax issues when using them in "for" commands.
rem Check whether we're running on 64bit Windows or not, as Microsoft stores our
rem registry keys below Wow6432Node on these systems.  Check bocaqaauto1 for
rem details.  Use temp filenames that don't include double quotes to prevent syntax
rem issues when using them in "for" commands.
rem ===============================================================================

if ("%MAJOR_VER%") equ ("9.0.0") goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.5.0") goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.5")   goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.4.1") goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.4.0") goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.4")   goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.3")   goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.2")   goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.1")   goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.0")   goto :AfterCheckMajorVer
goto :Error_MajorVerNotSupported
:AfterCheckMajorVer

if not exist "%RESULTDIR%" mkdir "%RESULTDIR%"

set RESULTDIR_SHORT=%RESULTDIR: =%
if /i ("%RESULTDIR%") equ ("%RESULTDIR_SHORT%") goto :AfterRemoveSpacesInResultDir
for /f "usebackq" %%a in ('echo "%RESULTDIR%"') do set RESULTDIR_SHORT=%%~fsa
if ("%RESULTDIR_SHORT:~-1%") equ ("\") set RESULTDIR_SHORT=%RESULTDIR_SHORT:~0,-1%
:AfterRemoveSpacesInResultDir

set TMPOUTFILE=%RESULTDIR_SHORT%\tmp%~n0_1.txt
set TMPOUTFILE2=%RESULTDIR_SHORT%\tmp%~n0_2.txt
set REG_QUERY_OUTFILE=%RESULTDIR_SHORT%\tmp%~n0_regout.txt

call :SetTimeStamp
set LOGFILE=%RESULTDIR%\%TIMESTAMP%u.txt

if exist %TMPOUTFILE%         del /f /q %TMPOUTFILE%
if exist %TMPOUTFILE2%        del /f /q %TMPOUTFILE2%
if exist %REG_QUERY_OUTFILE%  del /f /q %REG_QUERY_OUTFILE%
set FINAL_STATUS=PASS

reg.exe /? > nul 2>&1
if ERRORLEVEL 9009 goto :Error_NoResKitTools

for /f "tokens=*" %%a in ('echo. ^| wmic os get Caption    ^| findstr /v Caption    ^| findstr /i /r "[a-z0-9]"') do set WIN_CAPTION=%%a
for /f "tokens=*" %%a in ('echo. ^| wmic os get CSDVersion ^| findstr /v CSDVersion ^| findstr /i /r "[a-z0-9]"') do set WIN_CSDVERSION=%%a
for /f            %%a in ('echo. ^| wmic os get Version    ^| findstr /r "[0-9]"')                                do set WIN_VERSION=%%a
for /f "tokens=*" %%a in ('echo. ^| wmic os get TotalVisibleMemorySize ^| findstr /r "^[0-9]"')                   do set WIN_MEM_PHYSICAL=%%a
for /f "tokens=*" %%a in ('echo. ^| wmic os get FreePhysicalMemory     ^| findstr /r "^[0-9]"')                   do set WIN_MEM_PHYSICAL_FREE=%%a
for /f "tokens=*" %%a in ('echo. ^| wmic os get TotalVirtualMemorySize ^| findstr /r "^[0-9]"')                   do set WIN_MEM_VIRTUAL=%%a
for /f "tokens=*" %%a in ('echo. ^| wmic os get FreeVirtualMemory      ^| findstr /r "^[0-9]"')                   do set WIN_MEM_VIRTUAL_FREE=%%a

set TMPWMICFILE="%~dp0\TempWmicBatchFile.bat"
if exist %TMPWMICFILE%  del %TMPWMICFILE%
set TMPWMICFILE=

rem ==================================================
rem Get rid of additional whitespace at the end of the
rem variables holding the memory values.
rem ==================================================
for %%a in (%WIN_MEM_PHYSICAL%)       do set WIN_MEM_PHYSICAL=%%a
for %%a in (%WIN_MEM_PHYSICAL_FREE%)  do set WIN_MEM_PHYSICAL_FREE=%%a
for %%a in (%WIN_MEM_VIRTUAL%)        do set WIN_MEM_VIRTUAL=%%a
for %%a in (%WIN_MEM_VIRTUAL_FREE%)   do set WIN_MEM_VIRTUAL_FREE=%%a

if ("%WIN_VERSION:~0,1%") equ ("6")   set REG_WINVER_USES_SPACES=1
if ("%WIN_VERSION:~0,3%") equ ("5.2") set REG_WINVER_USES_SPACES=1
set OSVERSION=%WIN_CAPTION%
if not defined WIN_CSDVERSION goto :AfterAppendCSDVersion
set OSVERSION=%OSVERSION% %WIN_CSDVERSION%
:AfterAppendCSDVersion
set OSVERSION=%OSVERSION% [%WIN_VERSION%]

set SUBKEY_64BIT=Wow6432Node
set HKLM_BASE=HKLM\Software
call :CheckIfMachineIs64Bit
if     defined MACHINE_IS_64BIT  set HKLM_SOFTWARE=%HKLM_BASE%\%SUBKEY_64BIT%
if not defined MACHINE_IS_64BIT  set HKLM_SOFTWARE=%HKLM_BASE%

set DTXHOME=
call :SetProductName

rem Set to anything for purposes of formatting output
set UNINSTALL_CMD=1

rem ==================================================
rem Define the names of the installs, ESD images and
rem menu entries in the Start -> Program menu.
rem
rem For v8.4 and newer, some of the uninstall keys
rem are the same between the new IS2011 installs and
rem the older IS55 installs.  Therefore, we hunt for
rem the different install types in the following
rem order, since the IS55 installs will be depricated
rem before v8.4 is released:
rem - INSTALL_TYPE_IS2011_64BIT (IS2011 64bit)
rem - INSTALL_TYPE_IS2011_32BIT (IS2011 32bit)
rem - INSTALL_TYPE_IS55 (IS55)
rem ==================================================

set INSTALL_TYPE_IS55=legacy
set INSTALL_TYPE_IS63=IS63
set INSTALL_TYPE_IA=IA
set INSTALL_TYPE_IS2011_32BIT=32
set INSTALL_TYPE_IS2011_64BIT=64

if /i ("%MAJOR_VER%") lss ("8.4")  set INSTALL_TYPE=
if /i ("%MAJOR_VER%") geq ("8.4")  set INSTALL_TYPE=%INSTALL_TYPE_IS2011_64BIT%

call :SetInstallAndMenuNames

call :SetDTXHome
call :SetSleepCmd


call :Log
call :Log ===
call :Log === %0 (v%FILE_REV%): Start: %date% %time%: MAJOR_VER=%MAJOR_VER% (!Done:)
if defined GENERATE_RESPONSEFILES  call :Log ===    *** Generating response files ***
if defined MACHINE_IS_64BIT  call :Log ===    64bit Windows detected
call :Log ===    Run on %COMPUTERNAME% as %USERDOMAIN%\%USERNAME%
call :Log ===    OS Version: %OSVERSION%
call :Log ===    Memory: Physical [Total=%WIN_MEM_PHYSICAL% Free=%WIN_MEM_PHYSICAL_FREE%]  Virtual [Total=%WIN_MEM_VIRTUAL% Free=%WIN_MEM_VIRTUAL_FREE%)]
call :Log ===    Current directory: %CD%

call :Log === User-specified variables:
if     defined TXINSTALLS_VRMFNUM               call :Log ===    TXINSTALLS_VRMFNUM="%TXINSTALLS_VRMFNUM%"
if not defined TXINSTALLS_VRMFNUM               call :Log ===    TXINSTALLS_VRMFNUM not defined
if     defined TXINSTALLS_GENRESFILES           call :Log ===    TXINSTALLS_GENRESFILES="%TXINSTALLS_GENRESFILES%"
if not defined TXINSTALLS_GENRESFILES           call :Log ===    TXINSTALLS_GENRESFILES not defined
if     defined TXINSTALLS_RESPONSEDIR           call :Log ===    TXINSTALLS_RESPONSEDIR="%TXINSTALLS_RESPONSEDIR%"
if not defined TXINSTALLS_RESPONSEDIR           call :Log ===    TXINSTALLS_RESPONSEDIR not defined
if     defined TXINSTALLS_RESULTDIR             call :Log ===    TXINSTALLS_RESULTDIR="%TXINSTALLS_RESULTDIR%"
if not defined TXINSTALLS_RESULTDIR             call :Log ===    TXINSTALLS_RESULTDIR not defined
if     defined TXINSTALLS_NOEXTRACLEAN          call :Log ===    TXINSTALLS_NOEXTRACLEAN="%TXINSTALLS_NOEXTRACLEAN%"
if not defined TXINSTALLS_NOEXTRACLEAN          call :Log ===    TXINSTALLS_NOEXTRACLEAN not defined
if     defined TXINSTALLS_NOEXTRACLEAN_DIR      call :Log ===    TXINSTALLS_NOEXTRACLEAN_DIR="%TXINSTALLS_NOEXTRACLEAN_DIR%"
if not defined TXINSTALLS_NOEXTRACLEAN_DIR      call :Log ===    TXINSTALLS_NOEXTRACLEAN_DIR not defined
if     defined TXINSTALLS_USE_VR_FOR_MAJOR_VER  call :Log ===    TXINSTALLS_USE_VR_FOR_MAJOR_VER="%TXINSTALLS_USE_VR_FOR_MAJOR_VER%"
if not defined TXINSTALLS_USE_VR_FOR_MAJOR_VER  call :Log ===    TXINSTALLS_USE_VR_FOR_MAJOR_VER not defined
if     defined TXINSTALLS_NOPROMPT              call :Log ===    TXINSTALLS_NOPROMPT="%TXINSTALLS_NOPROMPT%"
if not defined TXINSTALLS_NOPROMPT              call :Log ===    TXINSTALLS_NOPROMPT not defined

call :Log === Values resulting from user-specified variables:
if     defined DTXHOME       call :Log ===    DTXHOME being uninstalled: "%DTXHOME%"
if not defined DTXHOME       call :Log ===    DTXHOME is undefined
if     defined DTXVER        call :Log ===    DTXVER being uninstalled:  "%DTXVER%"
if not defined DTXVER        call :Log ===    DTXVER is undefined
if /i ("%MAJOR_VER%") lss ("8.4")  goto :AfterDisplayDTXHome64
if     defined DTXHOME64     call :Log ===    DTXHOME64 being uninstalled: "%DTXHOME64%"
if not defined DTXHOME64     call :Log ===    DTXHOME64 is undefined
if     defined DTXVER64      call :Log ===    DTXVER64 being uninstalled:  "%DTXVER64%"
if not defined DTXVER64      call :Log ===    DTXVER64 is undefined
:AfterDisplayDTXHome64
call :Log ===    RESPONSEDIR=%RESPONSEDIR%
call :Log ===    RESULTDIR=%RESULTDIR%
call :Log ===    SLEEP_CMD=%SLEEP_CMD%
call :Log ===    LOGFILE=%LOGFILE%
call :Log ===
if not defined MAKE_EXTRA_CLEAN goto :AfterCautionMEC
call :Log ===    CAUTION!  MAKE_EXTRA_CLEAN defined - This will delete TX registry entries
call :Log ===
:AfterCautionMEC
if not defined MAKE_EXTRA_CLEAN_DIR goto :AfterCautionMECD
call :Log ===    CAUTION!  MAKE_EXTRA_CLEAN_DIR defined - This will delete the TX install directory if it exists!
call :Log ===
:AfterCautionMECD

if not defined RESPONSEDIR          goto :AfterResponseDirChecks
if exist "%RESPONSEDIR%"            goto :AfterCheckResponseDirExists
if defined GENERATE_RESPONSEFILES   mkdir "%RESPONSEDIR%"
if not exist "%RESPONSEDIR%"        goto :Error_MissingResponseDir
:AfterCheckResponseDirExists
pushd "%RESPONSEDIR%" > nul 2>&1
if ERRORLEVEL 1                     goto :Error_MissingResponseDir
popd
:AfterResponseDirChecks

set > %TEMP%\%~n0_env2.txt

if defined TXINSTALLS_NOPROMPT goto :AfterPause
pause
call :Log
:AfterPause

rem ========================================
rem Additional checking required for systems
rem with WMB installed and running with WTX.
rem If WMB is installed -AND-
rem WMB has a dtxwmqi.cmd being executed -AND-
rem (dtxwmqi.cmd points to the DTXHOME we're
rem  about to install to -OR- we're about to
rem  install TX for IS)
rem Then: Stop WMB
rem Else: Don't touch WMB
rem
rem ========================================

call :IntServ_Initialize
call :IntServ_DisableIfRunning

rem ========================================
rem Run the uninstalls.
rem ========================================

call :ProcessCoreUnInstalls

if defined TXINSTALLS_DEBUG @echo on

rem =========================================
rem NOTE: The following should only be called
rem if you want no trace of the installation
rem left behind on the users machine.  If the
rem user created files below their install
rem directory, they'll be deleted as well!!!
rem
rem Reenable WMB if we stopped it.
rem =========================================

if defined MAKE_EXTRA_CLEAN      call :MakeExtraClean
if defined MAKE_EXTRA_CLEAN_DIR  call :MakeExtraCleanDir

call :IntServ_ReenableIfStopped

goto :Done

rem =========================================
rem Done with main loop.  Messages relating
rem to error handling begin here.
rem =========================================
rem reg.exe not found.  Assume it's because
rem the Windows Server 2003 Resource Kit Tools
rem are not installed.
rem =========================================

:Error_NoResKitTools
call :Log ===
call :Log === %0: ERROR: reg.exe command not found.
call :Log ===
call :Log === The Windows Server 2003 Resource Kit Tools is required for
call :Log === silently uninstalling %DEFAULT_UNINSTKEY_PREFIX%.
call :Log === Details are available at:
call :Log ===
call :Log === http://www.microsoft.com/windowsserver2003/downloads/tools/default.mspx
call :Log ===
call :Log
set FINAL_STATUS=FAIL
goto :Done

rem ========================================
rem Dump usage statement if things are
rem missing...
rem ========================================

:Error_VRMFUndefined
call :Log ===
call :Log === %0: ERROR: Neither TXINSTALLS_VRMFNUM nor MAJOR_VER is defined.
call :Log ===
goto :Usage

:Error_MajorVerNotSupported
call :Log ===
call :Log === %0: ERROR: MAJOR_VER=%MAJOR_VER% is not supported.
call :Log ===
goto :Usage

:Error_MissingResponseDir
call :Log ===
call :Log === %0: ERROR: Missing response dir "%RESPONSEDIR%"
call :Log ===
goto :Usage

:Usage
call :Log
call :Log Variables used to control the uninstall:
call :Log
call :Log TXINSTALLS_VRMFNUM: Version.Release.Maintenance.FixLevel number.  Example: 8.2.0.0
call :Log
call :Log Variables currently set:
call :Log
set LOG_CMD=set MAJOR_
call :Log
set LOG_CMD=set TXINSTALLS_
call :Log
set FINAL_STATUS=FAIL
goto :Done

rem ========================================
rem Done!
rem ========================================

:Done

set > %TEMP%\%~n0_env2.txt

if not defined UNINSTALL_CMD call :Log
call :Log ===
call :Log === %0 (v%FILE_REV%): Done:  %date% %time%: FinalStatus - %FINAL_STATUS%
call :Log ===

if exist %TMPOUTFILE%         del /f /q %TMPOUTFILE%
if exist %TMPOUTFILE2%        del /f /q %TMPOUTFILE2%
if exist %REG_QUERY_OUTFILE%  del /f /q %REG_QUERY_OUTFILE%

goto :EOF


rem ===============================================================================
rem START: Common functions between install/uninstall process.
rem ===============================================================================


:SetTimeStamp

rem [day=%a hour=%b min=%c mon=%d sec=%e year=%f]

for /f "skip=2 tokens=2-7 delims=," %%a in ('wmic Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:CSV') do (
	set TS_DATE_YR=%%f
	set TS_DATE_MO=%%d
	set TS_DATE_DA=%%a
	set TS_TIME_HH=%%b
	set TS_TIME_MM=%%c
	set TS_TIME_SS=%%e
)

if "%TS_DATE_MO:~1,1%" equ "" set TS_DATE_MO=0%TS_DATE_MO%
if "%TS_DATE_DA:~1,1%" equ "" set TS_DATE_DA=0%TS_DATE_DA%
if "%TS_TIME_HH:~1,1%" equ "" set TS_TIME_HH=0%TS_TIME_HH%
if "%TS_TIME_MM:~1,1%" equ "" set TS_TIME_MM=0%TS_TIME_MM%
if "%TS_TIME_SS:~1,1%" equ "" set TS_TIME_SS=0%TS_TIME_SS%

set TIMESTAMP=%TS_DATE_YR%%TS_DATE_MO%%TS_DATE_DA%%TS_TIME_HH%%TS_TIME_MM%%TS_TIME_SS%

goto :EOF


rem ===============================================================================
rem :SetProductName: Set the values that use the product name.  These will vary
rem depending on the version we're trying to install.
rem ===============================================================================

:SetProductName

if ("%MAJOR_VER%") equ ("8.0") goto :SPN_v80

:SPN_Default
set COMPANY_NAME=IBM
set PRODNAME=WebSphere Transformation Extender
set FULL_PRODNAME=%COMPANY_NAME% %PRODNAME%
goto :SPN_Done

:SPN_v80
set COMPANY_NAME=Ascential Software
set PRODNAME=DataStage TX
set FULL_PRODNAME=Ascential %PRODNAME%
goto :SPN_Done

:SPN_Done
set MAJOR_VER_KEY=%HKLM_SOFTWARE%\%COMPANY_NAME%\%PRODNAME%\%MAJOR_VER%
set MAJOR_VER_KEY_HKCU=HKCU\Software\%COMPANY_NAME%\%PRODNAME%\%MAJOR_VER%
if /i ("%MAJOR_VER%") lss ("8.4")  goto :SPN_AfterSet64BitKeys
if not defined MACHINE_IS_64BIT    goto :SPN_AfterSet64BitKeys
set MAJOR_VER_KEY_64=%HKLM_BASE%\%COMPANY_NAME%\%PRODNAME%\%MAJOR_VER%
:SPN_AfterSet64BitKeys
set DEFAULT_UNINSTKEY_PREFIX=%FULL_PRODNAME% %MAJOR_VER%
set DEFAULT_LNCHRAGNT_SRVNAME=la1

if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :CheckIfVRMFUsesIF: Check if the VRMF number uses Interim Fix installs.  If so,
rem set INSTALLS_TOAPPLY_INTERIMFIX with the specified (or default) value.
rem ===============================================================================

:CheckIfVRMFUsesIF

if ("%LOCAL_VRMFNUM%") equ ("8.2.0.2") goto :CIVRMFUIF_UsesIFInstalls
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.0") goto :CIVRMFUIF_UsesIFInstalls
set LOCAL_INTERIMFIX=
goto :CIVRMFUIF_Done
:CIVRMFUIF_UsesIFInstalls
if defined LOCAL_INTERIMFIX  goto :CIVRMFUIF_UsesIFInstalls_IFDefined
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.2") set INSTALLS_TOAPPLY_INTERIMFIX=01
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.0") set INSTALLS_TOAPPLY_INTERIMFIX=01 02
goto :CIVRMFUIF_Done
:CIVRMFUIF_UsesIFInstalls_IFDefined
if /i ("%LOCAL_INTERIMFIX%") equ ("none") set INSTALLS_TOAPPLY_INTERIMFIX=
if /i ("%LOCAL_INTERIMFIX%") neq ("none") set INSTALLS_TOAPPLY_INTERIMFIX=%LOCAL_INTERIMFIX%
:CIVRMFUIF_Done
goto :EOF


rem ===============================================================================
rem :SetDTXHome: Set the value of DTXHOME (and DTXHOME64 for v8.4 and newer) based
rem on the value specified in the registry for this version.  Also determine the
rem value used in the response files.
rem Note: SMH prefix is a throwback from the days of SetMercHome...
rem ===============================================================================

:SetDTXHome

set DTXHOME=
set DTXHOME_REG=
set DTXHOME_RESP=

set DTXHOME64=
set DTXHOME64_REG=
set DTXHOME64_RESP=

set SMH_TMP_OUTPUTFILE=%RESULTDIR%\tmp_SetDTXHome.txt
if exist %SMH_TMP_OUTPUTFILE% del /f /q %SMH_TMP_OUTPUTFILE%

rem ========================================
rem Set DTXHOME based on the value stored in
rem the registry for this version.  If one
rem is found, save it as DTXHOME_REG as well.
rem For v8.4 or higher, if we're on a 64bit
rem Windows machine, check for the IS2011
rem 64bit version of WTX using DTXHOME64.
rem ========================================

if ("%MAJOR_VER%") equ ("8.0") goto :SMH_LookForMERCHOME

:SMH_LookForDTXHOME
set DTXHOME_REGKEY=DTXHOME
set REG_QUERY_KEYNAME=%MAJOR_VER_KEY%
set REG_QUERY_VALUENAME=%DTXHOME_REGKEY%
call :RegQueryKey
if not defined REG_QUERY_VALUE   goto :SMH_AfterDTXHomeReg
set DTXHOME=%REG_QUERY_VALUE%
set DTXHOME_REG=%DTXHOME%
:SMH_AfterDTXHomeReg

if ("%MAJOR_VER%") lss ("8.4")   goto :SMH_AfterDTXHome64Reg
if not defined MACHINE_IS_64BIT  goto :SMH_AfterDTXHome64Reg
set DTXHOME64_REGKEY=DTXHOME64
set REG_QUERY_KEYNAME=%MAJOR_VER_KEY_64%
set REG_QUERY_VALUENAME=%DTXHOME64_REGKEY%
call :RegQueryKey
if not defined REG_QUERY_VALUE   goto :SMH_AfterDTXHome64Reg
set DTXHOME64=%REG_QUERY_VALUE%
set DTXHOME64_REG=%DTXHOME64%
:SMH_AfterDTXHome64Reg

goto :SMH_AfterDTXHOMESearch

:SMH_LookForMERCHOME
set DTXHOME_REGKEY=MERCHOME_INTL
set REG_QUERY_KEYNAME=%MAJOR_VER_KEY%
set REG_QUERY_VALUENAME=%DTXHOME_REGKEY%
call :RegQueryKey
if defined REG_QUERY_VALUE goto :SMH_AfterMercHomeSearch
set DTXHOME_REGKEY=MERCHOME
set REG_QUERY_KEYNAME=%MAJOR_VER_KEY%
set REG_QUERY_VALUENAME=%DTXHOME_REGKEY%
call :RegQueryKey
:SMH_AfterMercHomeSearch
if not defined REG_QUERY_VALUE goto :SMH_AfterDTXHomeReg
set DTXHOME=%REG_QUERY_VALUE%
set DTXHOME_REG=%DTXHOME%
:SMH_AfterDTXHomeReg
goto :SMH_AfterDTXHOMESearch

:SMH_AfterDTXHOMESearch

rem ========================================
rem If response files exist:
rem - Set DTXHOME_RESP using the Design
rem   Studio response file
rem - Set DTXHOME64_RESP using the 64bit
rem   Design Studio response file...
rem   TODO: But which 64bit response file?
rem   We now have 32\64bit\DS.iss and 64\DS.iss...
rem ========================================

if not defined CURRESPONSEDIR goto :SMH_AfterSetValuesFromResponseFiles

set SMH_TMP_INPUTFILE=%CURRESPONSEDIR%\%ESD_INSTNAME_DESSTUD%.iss
if not exist %SMH_TMP_INPUTFILE%  goto :SMH_AfterDTXHomeResp
type %SMH_TMP_INPUTFILE% | "%SystemRoot%\system32\find.exe" "szDir" > %SMH_TMP_OUTPUTFILE%
if ERRORLEVEL 1  goto :SMH_AfterDTXHomeResp
for /f "tokens=1* delims== " %%i in ('type %SMH_TMP_OUTPUTFILE%') do set DTXHOME_RESP=%%j
:SMH_AfterDTXHomeResp

if ("%MAJOR_VER%") lss ("8.4")   goto :SMH_AfterDTXHome64Resp
if not defined MACHINE_IS_64BIT  goto :SMH_AfterDTXHome64Resp
if defined DTXHOME_RESP  set DTXHOME64_RESP=%DTXHOME_RESP%
:SMH_AfterDTXHome64Resp

:SMH_AfterSetValuesFromResponseFiles

rem ========================================
rem If DTXHOME/DTXHOME64 is defined, try to
rem determine what version it is.  Save the
rem value in DTXVER/DTXVER64.
rem ========================================

set DTXVER=
if not defined DTXHOME goto :SMH_AfterDetermineDTXVer

pushd %DTXHOME% > nul 2>&1
if ERRORLEVEL 1        goto :SMH_AfterDetermineDTXVer

if exist mercver.exe  set DTXVERCMD=mercver.exe
if exist dstxver.exe  set DTXVERCMD=dstxver.exe
if exist dtxver.exe   set DTXVERCMD=dtxver.exe

if not defined DTXVERCMD  goto :SMH_AfterSetDTXVer
for /f "tokens=1-2" %%a in ('.\%DTXVERCMD% %DTXVERCMD% ^| findstr bytes') do set DTXVER=%%b
:SMH_AfterSetDTXVer
popd

if defined DTXVER set LOCAL_VRMFNUM=%DTXVER:~0,7%

:SMH_AfterDetermineDTXVer

set DTXVER64=
if not defined DTXHOME64 goto :SMH_AfterDetermineDTXVer64

pushd %DTXHOME64% > nul 2>&1
if ERRORLEVEL 1          goto :SMH_AfterDetermineDTXVer64

if exist dtxver.exe   set DTXVERCMD64=dtxver.exe

if not defined DTXVERCMD64  goto :SMH_AfterSetDTXVer64
for /f "tokens=1-2" %%a in ('.\%DTXVERCMD64% %DTXVERCMD64% ^| findstr bytes') do set DTXVER64=%%b
:SMH_AfterSetDTXVer64
popd

:SMH_AfterDetermineDTXVer64

rem ========================================

:SMH_Done_HKLM

if exist %SMH_TMP_OUTPUTFILE% del /f /q %SMH_TMP_OUTPUTFILE%
set SMH_TMP_INPUTFILE=
set SMH_TMP_OUTPUTFILE=

if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :SetSleepCmd: Specify what command should be used for "sleeping" while
rem while waiting for an install to complete.  Whatever it is, it should be
rem something that doesn't take up too many system resources.
rem
rem ===============================================================================

:SetSleepCmd

set SLEEP_EXE_AVAILABLE=

sleep > nul 2>&1
if not ERRORLEVEL 9009  set SLEEP_EXE_AVAILABLE=1

set SLEEP_CMD=
set SLEEP_CMD_COUNT=5
if     defined SLEEP_EXE_AVAILABLE  set SLEEP_CMD=sleep %SLEEP_CMD_COUNT%
if not defined SLEEP_EXE_AVAILABLE  set SLEEP_CMD=ping -n %SLEEP_CMD_COUNT% -w 1000 localhost

set SLEEP_CMD_AFTERISCOMPLETES=
set SLEEP_CMD_AFTERISCOMPLETES_COUNT=15
if     defined SLEEP_EXE_AVAILABLE  set SLEEP_CMD_AFTERISCOMPLETES=sleep %SLEEP_CMD_AFTERISCOMPLETES_COUNT%
if not defined SLEEP_EXE_AVAILABLE  set SLEEP_CMD_AFTERISCOMPLETES=ping -n %SLEEP_CMD_AFTERISCOMPLETES_COUNT% -w 1000 localhost

goto :EOF


rem ===============================================================================
rem :SetLauncherAgentServiceName: Try to determine the unique name given to the
rem Launcher Agent based on the value in the response file.
rem ===============================================================================

:SetLauncherAgentServiceName

set LNCHRAGNT_SRVNAME=

rem ========================================
rem If response files exist:
rem - Set name of Launcher Agent service
rem   using the Launcher Agent response file
rem ========================================

if not defined CURRESPONSEDIR goto :SLASN_Done

set SLASN_TMP_INPUTFILE=%CURRESPONSEDIR%\%ESD_INSTNAME_LNCHRAGNT%.iss
if not exist %SLASN_TMP_INPUTFILE%  goto :SLASN_Done

set SLASN_TMP_OUTPUTFILE=%RESULTDIR%\tmp_SetLAName.txt
if exist %SLASN_TMP_OUTPUTFILE% del /f /q %SLASN_TMP_OUTPUTFILE%

type %SLASN_TMP_INPUTFILE% | "%SystemRoot%\system32\find.exe" "szEdit1" > %SLASN_TMP_OUTPUTFILE%
if ERRORLEVEL 1  goto :SLASN_AfterLAServiceName
for /f "tokens=1-2 delims== " %%i in ('type %SLASN_TMP_OUTPUTFILE%') do if not defined LNCHRAGNT_SRVNAME  set LNCHRAGNT_SRVNAME=%%j
:SLASN_AfterLAServiceName

if not defined TXINSTALLS_DEBUG goto :SLASN_AfterDebug1
type %SLASN_TMP_OUTPUTFILE%
call :Log %0: LNCHRAGNT_SRVNAME="%LNCHRAGNT_SRVNAME%"
:SLASN_AfterDebug1

if exist %SLASN_TMP_OUTPUTFILE% del /f /q %SLASN_TMP_OUTPUTFILE%
set SLASN_TMP_INPUTFILE=
set SLASN_TMP_OUTPUTFILE=

:SLASN_Done
if not defined TXINSTALLS_DEBUG goto :SLASN_AfterDebugDone
call :Log %0: Setting LNCHRAGNT_SRVNAME=%LNCHRAGNT_SRVNAME% (DEFAULT_LNCHRAGNT_SRVNAME=%DEFAULT_LNCHRAGNT_SRVNAME%)
@rem pause
:SLASN_AfterDebugDone
goto :EOF


rem ===========================================================================
rem :Log: If no special LOG_* environment is set, echo the data being passed
rem in on the command line.  If logging is enabled, echo the same data to the
rem logfile.
rem ===========================================================================

:Log

@if defined TXINSTALLS_DEBUG @echo off

set LOG_ARGS=%*
set LOG_RETURN=

if defined LOG_FUNC  goto :Log_ParseFunc
if defined LOG_CMD   goto :Log_Cmd
goto :Log_Text

rem ========================================
:Log_ParseFunc
rem ========================================

if /i (%LOG_FUNC%) equ (START) goto :Log_Start
if /i (%LOG_FUNC%) equ (DONE)  goto :Log_Done
if /i (%LOG_FUNC%) equ (SEP)   goto :Log_Separator
goto :Log_Separator

rem ========================================
:Log_Start
rem ========================================

if     defined LOG_ARGS echo Start: %date% %time%: %*
if not defined LOG_ARGS echo Start: %date% %time%
echo    Current directory: %CD%
if not defined LOGFILE goto :Log_AfterLogging
if     defined LOG_ARGS echo Start: %date% %time%: %* >> %LOGFILE%
if not defined LOG_ARGS echo Start: %date% %time% >> %LOGFILE%
echo    Current directory: %CD% >> %LOGFILE%
goto :Log_AfterLogging

rem ========================================
:Log_Done
rem ========================================

if     defined LOG_ARGS echo Done: %date% %time%: %*
if not defined LOG_ARGS echo Done: %date% %time%
if not defined LOGFILE goto :Log_AfterLogging
if     defined LOG_ARGS echo Done: %date% %time%: %* >> %LOGFILE%
if not defined LOG_ARGS echo Done: %date% %time% >> %LOGFILE%
goto :Log_AfterLogging

rem ========================================
:Log_Separator
rem ========================================

echo.================================================================================
if not defined LOGFILE goto :Log_AfterLogging
echo.================================================================================>> %LOGFILE%
goto :Log_AfterLogging

rem ========================================
:Log_Cmd
rem ========================================

if     defined LOG_ARGS echo %*: %LOG_CMD%
if not defined LOG_ARGS echo %LOG_CMD%
if not defined LOGFILE goto :Log_Cmd_SkipAppendEcho
if     defined LOG_ARGS echo %*: %LOG_CMD% >> %LOGFILE%
if not defined LOG_ARGS echo %LOG_CMD% >> %LOGFILE%
:Log_Cmd_SkipAppendEcho

if not defined LOGFILE goto :Log_Cmd_SkipAppend
if     defined LOG_STDIN  (echo. | %LOG_CMD%) >> %LOGFILE% 2>&1
if not defined LOG_STDIN  %LOG_CMD% >> %LOGFILE% 2>&1
set LOG_RETURN=%errorlevel%
goto :Log_Cmd_Done

:Log_Cmd_SkipAppend
%LOG_CMD%
set LOG_RETURN=%errorlevel%

:Log_Cmd_Done

if not defined LOG_VERBOSE_RETCODE goto :Log_Cmd_AfterEchoRetCode
echo Return code: %LOG_RETURN%
if not defined LOGFILE goto :Log_Cmd_AfterEchoRetCode
echo Return code: %LOG_RETURN% >> %LOGFILE%
:Log_Cmd_AfterEchoRetCode
goto :Log_AfterLogging

rem ========================================
:Log_Text
rem ========================================

if     defined LOG_PREFIX set TMP_LOGSTR=%LOG_PREFIX%%*
if not defined LOG_PREFIX set TMP_LOGSTR=%*
if     defined LOG_ARGS echo %TMP_LOGSTR%
if not defined LOG_ARGS echo.

if not defined LOGFILE goto :Log_Text_SkipAppendEcho
if     defined LOG_ARGS echo %TMP_LOGSTR% >> %LOGFILE%
if not defined LOG_ARGS echo.>> %LOGFILE%
:Log_Text_SkipAppendEcho
goto :Log_AfterLogging

rem ========================================
:Log_AfterLogging
rem ========================================
set LOG_FUNC=
set LOG_CMD=
set LOG_STDIN=
set TMP_LOGSTR=
if defined TXINSTALLS_DEBUG @echo on
@goto :EOF


rem ===============================================================================
rem :MakeExtraClean: Remove all traces of the installation from the registry.
rem We do this to make the install process more predictable.  The existance of
rem certain registry keys (particularly those pertaining to the file extensions)
rem can cause the InstallShield prompts to change, which means the installs will
rem fail.
rem ===============================================================================

:MakeExtraClean

if not defined UNINSTALL_CMD call :Log
call :Log %0: Start cleaning registry...
if defined TXINSTALLS_DEBUG pause

if exist %TMPOUTFILE%  del /f /q %TMPOUTFILE%
if exist %TMPOUTFILE2% del /f /q %TMPOUTFILE2%

rem ========================================
rem If HKLM MAJOR_VER key exists, delete it.
rem ========================================

set REG_QUERY_KEYNAME=%MAJOR_VER_KEY%
set REG_QUERY_VALUENAME=
call :RegQueryKey
set MEC_QUERY_RC=%REG_QUERY_RETCODE%
if (%MEC_QUERY_RC%) == (0)  goto :MEC_AfterCheck_HKLM_MajorVerExists
call :Log %0: HKLM key for MAJOR_VER=%MAJOR_VER% not found.
goto :MEC_Done_HKLM
:MEC_AfterCheck_HKLM_MajorVerExists

set REG_DEL_KEYNAME=%MAJOR_VER_KEY%
set REG_DEL_VALUENAME=
call :RegDeleteKey
:MEC_Done_HKLM

if not defined MAJOR_VER_KEY_64  goto :MEC_Done_HKLM64

set REG_QUERY_KEYNAME=%MAJOR_VER_KEY_64%
set REG_QUERY_VALUENAME=
call :RegQueryKey
set MEC_QUERY_RC=%REG_QUERY_RETCODE%
if (%MEC_QUERY_RC%) == (0)  goto :MEC_AfterCheck_HKLM_MajorVer64Exists
call :Log %0: 64bit HKLM key for MAJOR_VER=%MAJOR_VER% not found.
goto :MEC_Done_HKLM64
:MEC_AfterCheck_HKLM_MajorVer64Exists

set REG_DEL_KEYNAME=%MAJOR_VER_KEY_64%
set REG_DEL_VALUENAME=
call :RegDeleteKey
:MEC_Done_HKLM64

rem ========================================
rem If HKCU MAJOR_VER key exists, delete it.
rem ========================================

set REG_DEL_KEYNAME=%MAJOR_VER_KEY_HKCU%
set REG_DEL_VALUENAME=
call :RegDeleteKey

:MEC_Done_HKCU

rem ========================================
rem Delete file extension associations.
rem ========================================

call :DeleteTXFileExtensions

rem ========================================
rem Delete Start menu entries.
rem ========================================

set MEC_TMP_REGPATH=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MenuOrder

set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\Start Menu\Programs\%DEFAULT_UNINSTKEY_PREFIX%
call :DeleteTXMenuEntries

set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\Start Menu2\Programs\%DEFAULT_UNINSTKEY_PREFIX%
call :DeleteTXMenuEntries

rem ========================================
rem Try to remove certain artifacts, services
rem and app path based on the version being
rem used.
rem ========================================

if not defined LNCHRAGNT_SRVNAME  set LNCHRAGNT_SRVNAME=%DEFAULT_LNCHRAGNT_SRVNAME%

if ("%MAJOR_VER%") equ ("8.5")  goto :MEC_v85
if ("%MAJOR_VER%") equ ("8.4")  goto :MEC_v84
if ("%MAJOR_VER%") equ ("8.3")  goto :MEC_v83
if ("%MAJOR_VER%") equ ("8.2")  goto :MEC_v82
if ("%MAJOR_VER%") equ ("8.1")  goto :MEC_v81
if ("%MAJOR_VER%") equ ("8.0")  goto :MEC_v80

rem ========================================
rem v8.2 + v8.3 + v8.4 + v8.5
rem ========================================

:MEC_v85
:MEC_v84
:MEC_v83
:MEC_v82

set MEC_TMP_REGPATH=HKCR\Applications

set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\ExtenderStudio.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\ttmakr32.exe
call :RegDeleteKey

set MEC_TMP_REGPATH=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\App Management\ARPCache

set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% with %INSTNAME_CMDSRVR%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_DESSTUD%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LIBRARY%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% with %INSTNAME_LNCHR%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT% - %LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRSTUD%
call :RegDeleteKey
if ("%MAJOR_VER%") geq ("8.3")  goto :MEC_AfterDelMBRegKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_MB%
call :RegDeleteKey
:MEC_AfterDelMBRegKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_SECURE%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_SNMP%
call :RegDeleteKey
if ("%MAJOR_VER%") lss ("8.4") set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% for %INSTNAME_TXAPI%
if ("%MAJOR_VER%") geq ("8.4") set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_TXAPI%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_TXIS%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% SDK
call :RegDeleteKey

set REG_DEL_VALUENAME=

set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dtx%MAJOR_VER:.=%_launcher
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dtx%MAJOR_VER:.=%_lnchagnt_%LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dtx%MAJOR_VER:.=%_snmp
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\EventLog\Application\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT%
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT% - %LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey

set MEC_TMP_REGPATH=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\App Paths

set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\dstx.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\library.pdf
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\lnchagnt.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\mercssl.dll
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\snmpservice.exe
call :RegDeleteKey

rem ========================================
rem v8.1
rem ========================================

:MEC_v81

set MEC_TMP_REGPATH=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\App Management\ARPCache

rem INSTNAME_CMDSRVR
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_CMDSRVR%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_DESSTUD%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LIBRARY%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHR%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT% - %LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRSTUD%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_MB%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_SECURE%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_SNMP%
call :RegDeleteKey
rem INSTNAME_TX
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_TXSDK%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_WEBSRV%
call :RegDeleteKey

set MEC_TMP_REGPATH=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\App Paths

set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\dstx.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\library.pdf
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\lnchagnt.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\mercssl.dll
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\snmpservice.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\wsdlimp.jar
call :RegDeleteKey

set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dtx%MAJOR_VER:.=%_launcher
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dtx%MAJOR_VER:.=%_lnchagnt_%LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dtx%MAJOR_VER:.=%_snmp
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT% - %LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\Eventlog\Application\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT%
call :RegDeleteKey

goto :MEC_Done

rem ========================================
rem v8.0
rem ========================================

:MEC_v80

set MEC_TMP_REGPATH=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\App Management\ARPCache

rem INSTNAME_CMDSRVR
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INTL_SUFFIX%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_DESSTUD%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_DESSTUD% %INTL_SUFFIX%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_JCAG%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LIBRARY%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHR:DataStage TX =%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHR:DataStage TX =% %INTL_SUFFIX%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT% - %LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRSTUD%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_MB%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_SECURE%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_SNMP%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_TXSDK%
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_TXSDK% %INTL_SUFFIX%
call :RegDeleteKey

set MEC_TMP_REGPATH=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\App Paths

set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\dstx.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\evntagnt.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\library.pdf
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\m4jca.jar
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\mercssl.dll
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\snmpservice.exe
call :RegDeleteKey
set REG_DEL_KEYNAME=%MEC_TMP_REGPATH%\wsdlimp.jar
call :RegDeleteKey

set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dstx%MAJOR_VER:.=%_evntagnt_%LNCHRAGNT_SRVNAME%
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dstx%MAJOR_VER:.=%_evntsrvr
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\dstx%MAJOR_VER:.=%_snmp
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey
set REG_DEL_KEYNAME=HKLM\System\ControlSet001\Services\Eventlog\Application\%DEFAULT_UNINSTKEY_PREFIX% %INSTNAME_LNCHRAGNT%
call :RegDeleteKey
set REG_DEL_KEYNAME=%REG_DEL_KEYNAME:ControlSet001=ControlSet002%
call :RegDeleteKey

goto :MEC_Done

rem ========================================
rem Done!
rem ========================================

:MEC_Done
if exist %TMPOUTFILE%  del /f /q %TMPOUTFILE%
if exist %TMPOUTFILE2% del /f /q %TMPOUTFILE2%
set MEC_QUERY_RC=
set MEC_QUERY_MAJOR_VER=
set MEC_TMP_CMD=
set MEC_TMP_REGPATH=
set UNINSTALL_CMD=1
call :Log %0: Done
call :Log

if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :MakeExtraCleanDir: Delete the installation directory.
rem ===============================================================================

:MakeExtraCleanDir

if not defined UNINSTALL_CMD call :Log
call :Log %0: Start cleaning install directory...
if defined TXINSTALLS_DEBUG pause

rem ========================================
rem If DTXHOME exists, delete it.
rem ========================================

if defined DTXHOME    goto :MECD_AfterCheckDTXHOMEDefined
call :Log %0: No directory to clean: DTXHOME is undefined
goto :MECD_AfterDTXHOME
:MECD_AfterCheckDTXHOMEDefined

if exist "%DTXHOME%"  goto :MECD_AfterCheckDTXHOMEExists
call :Log %0: No directory to clean: DTXHOME="%DTXHOME%" does not exist
goto :MECD_AfterDTXHOME
:MECD_AfterCheckDTXHOMEExists

call :Log %0: Deleting DTXHOME=%DTXHOME%
set LOG_CMD=attrib -r "%DTXHOME%" /s /d
call :Log
set LOG_CMD=rmdir /s /q "%DTXHOME%"
call :Log
:MECD_AfterDTXHOME

rem ========================================
rem If DTXHOME64 exists, delete it.
rem ========================================

if not defined MACHINE_IS_64BIT goto :MECD_AfterDTXHOME64

if defined DTXHOME64    goto :MECD_AfterCheckDTXHOME64Defined
call :Log %0: No directory to clean: DTXHOME64 is undefined
goto :MECD_AfterDTXHOME64
:MECD_AfterCheckDTXHOME64Defined

if /i ("%DTXHOME64%") equ ("%DTXHOME%")  goto :MECD_AfterDTXHOME64

if exist "%DTXHOME64%"  goto :MECD_AfterCheckDTXHOME64Exists
call :Log %0: No directory to clean: DTXHOME64="%DTXHOME64%" does not exist
goto :MECD_AfterDTXHOME64
:MECD_AfterCheckDTXHOME64Exists

call :Log %0: Deleting DTXHOME64=%DTXHOME64%
set LOG_CMD=attrib -r "%DTXHOME64%" /s /d
call :Log
set LOG_CMD=rmdir /s /q "%DTXHOME64%"
call :Log
:MECD_AfterDTXHOME64

rem ========================================
rem If deleting the entire directory, then
rem we can delete all the menu items below
rem our keys.
rem ========================================

set MECD_TMP_REGPATH=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MenuOrder

set REG_DEL_KEYNAME=%MECD_TMP_REGPATH%\Start Menu\Programs\%DEFAULT_UNINSTKEY_PREFIX%
call :RegDeleteKey

set REG_DEL_KEYNAME=%MECD_TMP_REGPATH%\Start Menu2\Programs\%DEFAULT_UNINSTKEY_PREFIX%
call :RegDeleteKey

rem ========================================
rem Done!
rem ========================================

:MECD_Done
set MECD_QUERY_RC=
set MECD_TMP_REGPATH=
set UNINSTALL_CMD=1
call :Log %0: Done
call :Log

if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :DeleteTXFileExtensions: Delete the file extensions associated with WTX.
rem ===============================================================================

:DeleteTXFileExtensions

call :DeleteTXFileExtensionsByBits 0

if not defined MACHINE_IS_64BIT goto :DTXFE_AfterDelFileExts
call :DeleteTXFileExtensionsByBits 1
:DTXFE_AfterDelFileExts

:DTXFE_Done
goto :EOF



:DeleteTXFileExtensionsByBits

if ("%1") equ ("0") set DTXFEBB_HKCRKEY=HKCR
if ("%1") neq ("0") set DTXFEBB_HKCRKEY=HKCR\%SUBKEY_64BIT%

set REG_DEL_VALUENAME=

set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.mdq
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.mmc
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.mms
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.msd
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.msl
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.mtr
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.mts
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.mtt
call :RegDeleteKey

set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.mdq
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.mmc
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.mms
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.msd
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.msl
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.mtr
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.mts
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.mtt
call :RegDeleteKey


if ("%MAJOR_VER%") equ ("8.1")  goto :DTXFEBB_AfterDPA
if ("%MAJOR_VER%") equ ("8.0")  goto :DTXFEBB_AfterDPA

set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.dpa
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.dpa
call :RegDeleteKey

:DTXFEBB_AfterDPA
if defined TXINSTALLS_DEBUG pause
goto :EOF



:DeleteTXMenuEntries
set DTXME_ORIG_REG_KEY=%REG_DEL_KEYNAME%

set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_CMDSRVR%
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_DESSTUD%
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_LNCHR%
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_LNCHRSTUD%
call :RegDeleteKey

if ("%MAJOR_VER%") geq ("8.4")  goto :DTXME_AfterDelSNMP
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_SNMP%
call :RegDeleteKey
:DTXME_AfterDelSNMP

if ("%MAJOR_VER%") geq ("8.3")  goto :DTXME_AfterDelSDK
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_TXSDK%
call :RegDeleteKey
:DTXME_AfterDelSDK

if ("%MAJOR_VER%") equ ("8.5")  goto :DTXME_v85
if ("%MAJOR_VER%") equ ("8.4")  goto :DTXME_v84
if ("%MAJOR_VER%") equ ("8.3")  goto :DTXME_v83
if ("%MAJOR_VER%") equ ("8.2")  goto :DTXME_v82
if ("%MAJOR_VER%") equ ("8.1")  goto :DTXME_v81
if ("%MAJOR_VER%") equ ("8.0")  goto :DTXME_v80

:DTXME_v85
:DTXME_v84
:DTXME_v83
:DTXME_v82
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_TXAPI%
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_TXIS%
call :RegDeleteKey
if ("%MAJOR_VER%") geq ("8.3")  goto :DTXME_Done
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_MB%
call :RegDeleteKey
goto :DTXME_Done

:DTXME_v81
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_TX%
call :RegDeleteKey
goto :DTXME_Done

:DTXME_v80
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%\%MENUNAME_MB%
call :RegDeleteKey
goto :DTXME_Done

:DTXME_Done
set REG_DEL_KEYNAME=%DTXME_ORIG_REG_KEY%

if defined TXINSTALLS_DEBUG pause
goto :EOF



:RegQueryKey

set REG_QUERY_VALUE=
set REG_QUERY_RETCODE=1
set RQK_FINDSTR=

if defined REG_QUERY_KEYNAME goto :RQK_AfterCheckKeyDefined
call :Log %0: REG_QUERY_KEYNAME not defined (REG_QUERY_VALUENAME=%REG_QUERY_VALUENAME%).  Nothing done.
goto :RQK_Done
:RQK_AfterCheckKeyDefined



set RQK_CMD=reg query "%REG_QUERY_KEYNAME%"
if not defined REG_QUERY_VALUENAME goto :RQK_AfterAddValueToCmd
if ("%REG_QUERY_VALUENAME%") equ ("@") goto :RQK_FindNoName

:RQK_FindValueName
set RQK_CMD=%RQK_CMD% /v "%REG_QUERY_VALUENAME%"
set RQK_FINDSTR="    %REG_QUERY_VALUENAME%	"
goto :RQK_AfterAddValueToCmd

:RQK_FindNoName
set RQK_CMD=%RQK_CMD% /ve
set RQK_FINDSTR="    <NO NAME>  "
goto :RQK_AfterAddValueToCmd

:RQK_AfterAddValueToCmd



%RQK_CMD% > %REG_QUERY_OUTFILE% 2>&1
set REG_QUERY_RETCODE=%ERRORLEVEL%
if ("%REG_QUERY_RETCODE%") neq ("0") goto :RQK_NoValueFound

if not defined REG_QUERY_VALUENAME goto :RQK_AfterParseQueryOutput

if defined MACHINE_IS_64BIT        goto :RQK_FindReg_ValueName_Spaces
if defined REG_WINVER_USES_SPACES  goto :RQK_FindReg_ValueName_Spaces
:RQK_FindReg_ValueName_Tab
type %REG_QUERY_OUTFILE% | "%SystemRoot%\system32\find.exe" "	REG_" | "%SystemRoot%\system32\find.exe" "    %REG_QUERY_VALUENAME%	" > %TMPOUTFILE%
goto :RQK_AfterFindReg_ValueName
:RQK_FindReg_ValueName_Spaces
type %REG_QUERY_OUTFILE% | "%SystemRoot%\system32\find.exe" " REG_" | "%SystemRoot%\system32\find.exe" "    %REG_QUERY_VALUENAME% " > %TMPOUTFILE%
:RQK_AfterFindReg_ValueName

rem ========================================
rem There's extra parsing required if
rem REG_QUERY_VALUENAME contains whitespace.
rem ========================================
set RQK_TMP_QUERY_VALUENAME=%REG_QUERY_VALUENAME: =_%
set RQK_TMP_QUERY_VALUENAME=%RQK_TMP_QUERY_VALUENAME:	=_%
if ("%REG_QUERY_VALUENAME%") equ ("%RQK_TMP_QUERY_VALUENAME%") goto :RQK_AfterRemoveWhitespaceFromValueName
for /f "tokens=*" %%e in (%TMPOUTFILE%) do set RQK_TMP_VALUE=%%e
echo set RQK_TMP_VALUE=^%%RQK_TMP_VALUE:%REG_QUERY_VALUENAME%=%RQK_TMP_QUERY_VALUENAME%^%%> %TMPBATFILE%
call %TMPBATFILE%
del /f /q %TMPBATFILE%
echo     %RQK_TMP_VALUE% > %TMPOUTFILE%
:RQK_AfterRemoveWhitespaceFromValueName

for /f "tokens=1,2* delims=	 " %%e in (%TMPOUTFILE%) do set REG_QUERY_VALUE=%%g

if ("%REG_QUERY_VALUENAME%") equ ("%RQK_TMP_QUERY_VALUENAME%") goto :RQK_AfterRemoveLastSpaceFromValue


if ("%REG_QUERY_VALUE:~-1%") equ (" ") set REG_QUERY_VALUE=%REG_QUERY_VALUE:~0,-1%
:RQK_AfterRemoveLastSpaceFromValue

:RQK_AfterParseQueryOutput
goto :RQK_Done

:RQK_NoValueFound
if exist %REG_QUERY_OUTFILE%  del /f /q %REG_QUERY_OUTFILE%

:RQK_Done
set RQK_CMD=

if defined TXINSTALLS_DEBUG pause
goto :EOF



:RegDeleteKey

if defined REG_DEL_KEYNAME goto :RDK_AfterCheckKeyDefined
call :Log %0: REG_DEL_KEYNAME not defined.  Nothing done.
goto :RDK_Done
:RDK_AfterCheckKeyDefined

set RDK_CMD=reg query "%REG_DEL_KEYNAME%"
if defined REG_DEL_VALUENAME set RDK_CMD=%RDK_CMD% /v "%REG_DEL_VALUENAME%"
%RDK_CMD% > %TMPOUTFILE2% 2>&1
if ERRORLEVEL 1  goto :RDK_Done

set RDK_CMD=reg delete "%REG_DEL_KEYNAME%"
if defined REG_DEL_VALUENAME set RDK_CMD=%RDK_CMD% /v "%REG_DEL_VALUENAME%"
set RDK_CMD=%RDK_CMD% /f

call :Log %0: Executing: %RDK_CMD%
if defined TXINSTALLS_DEBUG pause

if not defined LOGFILE  goto :RDK_ExecDelete_NoLogfile
%RDK_CMD% >> %LOGFILE% 2>&1
goto :RDK_AfterExecDelete
:RDK_ExecDelete_NoLogfile
%RDK_CMD%
:RDK_AfterExecDelete

:RDK_Done
set RDK_CMD=

goto :EOF




:IntServ_Initialize

set STATUS_UNKNOWN=0
set STATUS_NOTPRESENT=1
set STATUS_PRESENT=2
set STATUS_STOPPED=3
set STATUS_RUNNING=4

set INTSERV_STATUS_WMB=%STATUS_UNKNOWN%
call :WMB_Initialize

goto :EOF



:IntServ_DisplayStatus

set IS_DS_SERVER=
set IS_DS_SERVER_STATUS=
set IS_DS_SERVER_STATUS_TEXT=

if ("%1") neq ("") goto :IS_DS_AfterCheckArgs
call :Log
call :Log === %0: Error: No argument (integration server) specified
call :Log
goto :IS_DS_Done
:IS_DS_AfterCheckArgs

if ("%1") neq ("WMB") goto :IS_DS_AfterWMB
set IS_DS_SERVER=WebSphere Message Broker
set IS_DS_SERVER_STATUS=%INTSERV_STATUS_WMB%
:IS_DS_AfterWMB

if defined IS_DS_SERVER goto :IS_DS_AfterCheckServerDefined
call :Log
call :Log === %0: Error: Unknown integration server specified (server=%1)
call :Log
goto :IS_DS_Done
:IS_DS_AfterCheckServerDefined

if /i (%IS_DS_SERVER_STATUS%) equ (%STATUS_UNKNOWN%)     set IS_DS_SERVER_STATUS_TEXT=Unknown
if /i (%IS_DS_SERVER_STATUS%) equ (%STATUS_NOTPRESENT%)  set IS_DS_SERVER_STATUS_TEXT=Not present
if /i (%IS_DS_SERVER_STATUS%) equ (%STATUS_PRESENT%)     set IS_DS_SERVER_STATUS_TEXT=Present
if /i (%IS_DS_SERVER_STATUS%) equ (%STATUS_STOPPED%)     set IS_DS_SERVER_STATUS_TEXT=Stopped
if /i (%IS_DS_SERVER_STATUS%) equ (%STATUS_RUNNING%)     set IS_DS_SERVER_STATUS_TEXT=Running
if not defined IS_DS_SERVER_STATUS                       set IS_DS_SERVER_STATUS_TEXT=ERROR_UNDEFINED

call :Log Status of %IS_DS_SERVER% = %IS_DS_SERVER_STATUS% (%IS_DS_SERVER_STATUS_TEXT%)

:IS_DS_Done
goto :EOF



:IntServ_DisableIfRunning



if not defined WMB_PROFILE                           goto :IS_DIR_AfterWMB
if /i (%INTSERV_STATUS_WMB%) equ (%STATUS_STOPPED%)  goto :IS_DIR_AfterWMB

set WMB_USER_MSG=Stopping Broker
set WMB_CMD=mqsistop
set WMB_CMD_RETCODE=BIP8071I
set WMB_DBINSTMGR_LAST=1
set LOG_FUNC=SEP
call :Log
call :Log %0: %date% %time%: %WMB_USER_MSG%...
call :Log

call :WMB_RunCommandForAllBrokers

set INTSERV_STATUS_WMB=%STATUS_STOPPED%

call :IntServ_DisplayStatus WMB
set LOG_FUNC=SEP
call :Log

:IS_DIR_AfterWMB

rem ========================================
rem Done stopping integration servers
rem ========================================

:IS_DIR_Done
goto :EOF




:IntServ_ReenableIfStopped



if not defined WMB_PROFILE                           goto :IS_RIS_AfterWMB
if /i (%INTSERV_STATUS_WMB%) neq (%STATUS_STOPPED%)  goto :IS_RIS_AfterWMB

set WMB_USER_MSG=Starting Broker
set WMB_CMD=mqsistart
set WMB_CMD_RETCODE=BIP8096I
set WMB_DBINSTMGR_LAST=
set LOG_FUNC=SEP
call :Log
call :Log %0: %date% %time%: %WMB_USER_MSG%...
call :Log

call :WMB_RunCommandForAllBrokers

set INTSERV_STATUS_WMB=%STATUS_RUNNING%

call :IntServ_DisplayStatus WMB
set LOG_FUNC=SEP
call :Log

:IS_RIS_AfterWMB

rem ========================================
rem Done stopping integration servers
rem ========================================

:IS_RIS_Done
goto :EOF


rem ===============================================================================
rem :WMB_Initialize: Determine if WMB is installed or not.  If it is, find the
rem location of the WMB profile that needs to be run in order to issue WMB commands.
rem ===============================================================================

:WMB_Initialize

set WMB_PROFILE=
set INTSERV_STATUS_WMB=%STATUS_NOTPRESENT%

rem ========================================
rem For now, only interact with WMB when
rem using WTX releases at v8.2 and above.
rem ========================================

if ("%MAJOR_VER%") equ ("8.1") goto :WMB_Init_Exit
if ("%MAJOR_VER%") equ ("8.0") goto :WMB_Init_Exit

rem ========================================
rem Determine where WMB is installed and
rem what version it is.
rem ========================================

set REG_QUERY_KEYNAME=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\Uninstall\mqsi61
set REG_QUERY_VALUENAME=InstallLocation
call :RegQueryKey

if defined REG_QUERY_VALUE  goto :WMB_Init_AfterCheckRQVDefined
goto :WMB_Init_Exit
call :Log
call :Log %0: %date% %time%: Info: WMB not present (registry key not found).
set LOG_PREFIX=   
call :Log REG_QUERY_KEYNAME="%REG_QUERY_KEYNAME%"
call :Log REG_QUERY_VALUENAME="%REG_QUERY_VALUENAME%"
set LOG_PREFIX=
call :Log
goto :WMB_Init_Done
:WMB_Init_AfterCheckRQVDefined

if exist "%REG_QUERY_VALUE%"  goto :WMB_Init_AfterCheckRQVExists
call :Log
call :Log %0: %date% %time%: Warning: Missing WMB directory.
set LOG_PREFIX=   
call :Log Directory="%REG_QUERY_VALUE%"
set LOG_PREFIX=
call :Log
goto :WMB_Init_Done
:WMB_Init_AfterCheckRQVExists

set WMB_PROFILE=%REG_QUERY_VALUE%\bin\mqsiprofile.cmd
if exist "%WMB_PROFILE%"  goto :WMB_Init_AfterCheckExists_Profile
call :Log
call :Log %0: %date% %time%: Warning: Missing WMB profile.
set LOG_PREFIX=   
call :Log Profile="%WMB_PROFILE%"
set LOG_PREFIX=
call :Log
set WMB_PROFILE=
goto :WMB_Init_Done
:WMB_Init_AfterCheckExists_Profile

rem
rem TODO: 08/19/2008: Unset DTXHOME prior to calling WMB_PROFILE to see if
rem it gets set to the same DTXHOME we're using.  If so, we will need to
rem start / stop WMB.  Otherwise:
rem - For installing, we should only need to touch WMB if we're installing
rem   TX for IS.
rem - For uninstalling, we should not have to touch WMB if it's not accessing
rem   this WTX installation.
rem Need to reset DTXHOME back to its original value when we're done!
rem

set LOG_CMD=call "%WMB_PROFILE%"
call :Log Initializing WMB environment
set WMB_PROFILE_RETCODE=%LOG_RETURN%
if ("%WMB_PROFILE_RETCODE%") equ ("0") goto :WMB_Init_AfterCheckRetcode_Profile
if ("%WMB_PROFILE_RETCODE%") equ ("1") goto :WMB_Init_AfterCheckRetcode_Profile
call :Log
call :Log %0: %date% %time%: Warning: Unexpected return code from WMB profile (retcode=%WMB_PROFILE_RETCODE%)
set LOG_PREFIX=   
call :Log Profile="%WMB_PROFILE%"
set LOG_PREFIX=
call :Log
set WMB_PROFILE=
goto :WMB_Init_Done
:WMB_Init_AfterCheckRetcode_Profile

set INTSERV_STATUS_WMB=%STATUS_PRESENT%

:WMB_Init_Done
call :IntServ_DisplayStatus WMB
call :Log
:WMB_Init_Exit
goto :EOF


rem ===============================================================================
rem :WMB_RunCommandForAllBrokers: Run the WMB command stored in WMB_CMD against all
rem the WMB components we find.
rem
rem Run mqsilist to find the list of broker components that need to be controlled.
rem
rem Sample output:
rem
rem BIP8099I: DbInstMgr: DatabaseInstanceMgr6  -
rem BIP8099I: Broker: WBRK61_DEFAULT_BROKER  -  WBRK61_DEFAULT_QUEUE_MANAGER
rem BIP8099I: ConfigMgr: WBRK61_DEFAULT_CONFIGURATION_MANAGER  -  WBRK61_DEFAULT_QUEUE_MANAGER
rem BIP8071I: Successful command completion.
rem
rem Pull out just the "BIP8099I" components from the output that we're interested in.
rem - All but ConfigMgr: are required to be stopped for updating WTX.
rem - All are required to be stopped for updating WMB.
rem
rem Per George Blue of the WMB team: When stopping WMB, we should stop the
rem DbInstMgr: component last.  Other than this, the order should not matter.
rem
rem Stopping just the "Broker:" causes uninstall problems due to ConfigMgr still
rem holding dtxwmqi.jar.  SysInternals "handle" command can be used to verify this.
rem ===============================================================================

:WMB_RunCommandForAllBrokers

set WMB_RCFAB_TMPCMD=mqsilist
echo === %WMB_RCFAB_TMPCMD% >> %LOGFILE%
%WMB_RCFAB_TMPCMD% > %TMPOUTFILE% 2>&1
set WMB_RCFAB_RETCODE=%ERRORLEVEL%
type %TMPOUTFILE% >> %LOGFILE%
if ("%WMB_RCFAB_RETCODE%") equ ("0") goto :WMB_RCFAB_AfterCheckRetcode_MQSIList
call :Log
call :Log %0: %date% %time%: Error returned by %WMB_RCFAB_TMPCMD% (retcode=%WMB_RCFAB_RETCODE%).
call :Log
goto :WMB_RCFAB_Done
:WMB_RCFAB_AfterCheckRetcode_MQSIList

set WMB_RCFAB_SUCCESSFUL_CMD=
for /f "tokens=1,3*" %%b in (%TMPOUTFILE%) do if ("%%b") equ ("BIP8071I:") set WMB_RCFAB_SUCCESSFUL_CMD=1
for /f "tokens=1,3*" %%b in (%TMPOUTFILE%) do set WMB_RCFAB_RETCODE=%%b
if defined WMB_RCFAB_SUCCESSFUL_CMD goto :WMB_RCFAB_AfterCheckSuccessfulCmd
call :Log
call :Log %0: %date% %time%: Error: %WMB_RCFAB_TMPCMD% failed (retcode=%WMB_RCFAB_RETCODE%).
call :Log
goto :WMB_RCFAB_Done
:WMB_RCFAB_AfterCheckSuccessfulCmd

@rem These WMB components are required to be stopped for updating WTX.
@rem echo Broker:> %TMPINFILE%
@rem echo ConfigMgr:>> %TMPINFILE%
@rem findstr BIP8099I: %TMPOUTFILE% | findstr /g:%TMPINFILE% > %TMPOUTFILE2%

@rem These WMB components are required to be stopped for updating WMB.
echo. | findstr BIP8099I: %TMPOUTFILE% > %TMPOUTFILE2%

copy /y %TMPOUTFILE2% %TMPOUTFILE% > NUL 2>&1
del /f /q %TMPINFILE% %TMPOUTFILE2%

for /f "usebackq tokens=1" %%b in (`type %TMPOUTFILE% ^| %SystemRoot%\system32\find.exe "BIP8099I:" /c`) do set WMB_NUM_COMPONENTS=%%b
call :Log Number of WMB components to control: %WMB_NUM_COMPONENTS%

if defined WMB_DBINSTMGR_LAST goto :WMB_RCFAB_DbInstMgr_Last

:WMB_RCFAB_DbInstMgr_First
for /f "usebackq tokens=1,3*" %%b in (`echo. ^| findstr    DbInstMgr: %TMPOUTFILE%`)  do call :WMB_RunCommand %%c
for /f "usebackq tokens=1,3*" %%b in (`echo. ^| findstr /v DbInstMgr: %TMPOUTFILE%`)  do call :WMB_RunCommand %%c
goto :WMB_RCFAB_Done

:WMB_RCFAB_DbInstMgr_Last
for /f "usebackq tokens=1,3*" %%b in (`echo. ^| findstr /v DbInstMgr: %TMPOUTFILE%`)  do call :WMB_RunCommand %%c
for /f "usebackq tokens=1,3*" %%b in (`echo. ^| findstr    DbInstMgr: %TMPOUTFILE%`)  do call :WMB_RunCommand %%c
goto :WMB_RCFAB_Done

:WMB_RCFAB_Done
goto :EOF


rem ===============================================================================
rem :WMB_RunCommand: Run the WMB command stored in WMB_CMD, passing in Arg1 as the
rem broker name.  Verify that the command had a return code of 0 and generated the
rem WMB return code stored in WMB_CMD_RETCODE.
rem
rem Note: SLEEP_CMD added after the execution of WMB_CMD only as a precaution.
rem Per George Blue of the WMB team: mqsistart will return before the broker is
rem completely started.  He said that this should normally not matter to us, but it
rem was useful to be aware of.
rem ===============================================================================

:WMB_RunCommand

if defined WMB_CMD goto :WMB_RC_AfterCheckCmd
call :Log
call :Log === %0: Error: No command specified
call :Log
goto :WMB_RC_Exit
:WMB_RC_AfterCheckCmd

if ("%1") neq ("") goto :WMB_RC_AfterCheckArgs
call :Log
call :Log === %0: Error: No argument (WMB component name) specified
call :Log
goto :WMB_RC_Exit
:WMB_RC_AfterCheckArgs

call :Log === %WMB_CMD% %1

rem mqsistop WBRK61_DEFAULT_BROKER
rem BIP8071I: Successful command completion.
rem BIP8019E: Component stopped.
rem   A previous command was issued to stop this component or it has never been started.
rem   This component may be started, changed or deleted.
rem BIP8016E: Unable to stop component.
rem   A request to stop this component was refused.

%WMB_CMD% %1 > %TMPOUTFILE2% 2>&1
set WMB_RETCODE=%ERRORLEVEL%
type %TMPOUTFILE2% >> %LOGFILE%
if ("%WMB_RETCODE%") equ ("0") goto :WMB_RC_AfterCheckRetcode_BrokerCmd
call :Log
call :Log %0: %date% %time%: Error returned by %WMB_CMD% (retcode=%WMB_RETCODE%)
call :Log
goto :WMB_RC_Exit
:WMB_RC_AfterCheckRetcode_BrokerCmd
%SLEEP_CMD% > nul 2>&1

set WMB_RC_SUCCESSFUL_CMD=
for /f "tokens=1,3*" %%e in (%TMPOUTFILE2%) do if ("%%e") equ ("%WMB_CMD_RETCODE%:") set WMB_SUCCESSFUL_CMD=1
if defined WMB_SUCCESSFUL_CMD goto :WMB_RC_AfterCheckSuccessfulCmd
call :Log
call :Log === Info: %WMB_CMD% did not return "%WMB_CMD_RETCODE%" (Successful command completion.)
type %TMPOUTFILE2%
call :Log
goto :WMB_RC_Exit
:WMB_RC_AfterCheckSuccessfulCmd

:WMB_RC_Exit
goto :EOF

rem ===============================================================================
rem DONE: Common functions between install/uninstall process.
rem ===============================================================================


rem ===============================================================================
rem :SetInstallAndMenuNames: Define the names of the installs, ESD images and menu
rem entries below the Start -> Program menu.
rem
rem NOTE: The values set in this routine are different between the install and the
rem       uninstall scripts!
rem
rem The values for INSTNAME_ represent the name of the install image during
rem the install process, and a portion of the string used for the uninstall key
rem during the uninstall process.  (It would be nice if they were identical, but...)
rem Since they are different between the two processes, the MENUNAME_ values need
rem to be set differently depending on which script we're in.  We'll try our best
rem to reuse INSTNAME_ when setting MENUNAME_ values.
rem - The TX for Message Broker install is included in the v8.2 section, as it was
rem   built in the v8.2.0.0 and v8.2.0.1 releases.
rem ===============================================================================

:SetInstallAndMenuNames

if ("%MAJOR_VER%") equ ("8.5.0") goto :SIAMN_v85
if ("%MAJOR_VER%") equ ("8.5")   goto :SIAMN_v85
if ("%MAJOR_VER%") equ ("8.4.1") goto :SIAMN_v84
if ("%MAJOR_VER%") equ ("8.4.0") goto :SIAMN_v84
if ("%MAJOR_VER%") equ ("8.4")   goto :SIAMN_v84
if ("%MAJOR_VER%") equ ("8.3")   goto :SIAMN_v83
if ("%MAJOR_VER%") equ ("8.2")   goto :SIAMN_v82
if ("%MAJOR_VER%") equ ("8.1")   goto :SIAMN_v81
if ("%MAJOR_VER%") equ ("8.0")   goto :SIAMN_v80

:SIAMN_Default
:SIAMN_v85

set INSTNAME_CMDSRVR=Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=
set INSTNAME_LNCHR=Launcher
set INSTNAME_LNCHRAGNT=
set INSTNAME_LNCHRSTUD=%INSTNAME_LNCHR% Studio
set INSTNAME_SECURE=
set INSTNAME_TXAPI=Application Programming
set INSTNAME_TXIS=Integration Servers

if not defined INSTALL_TYPE  set %INSTALL_TYPE_IS2011_64BIT%

set ESD_INSTNAME_CMDSRVR=wsdtxcs
set ESD_INSTNAME_DESSTUD=wsdtxds
set ESD_INSTNAME_LIBRARY=
set ESD_INSTNAME_LNCHR=wsdtxl
set ESD_INSTNAME_LNCHRAGNT=
set ESD_INSTNAME_LNCHRSTUD=wsdtxls
set ESD_INSTNAME_SECURE=
set ESD_INSTNAME_TXAPI=wsdtxapi
set ESD_INSTNAME_TXIS=wsdtxis

@REM set ESD_INSTNAME_INTERIMFIX=intfix%INTERIMFIXNUM% - Set by :GetInterimFixInfo

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_TXAPI=%INSTNAME_TXAPI%
set MENUNAME_TXIS=%INSTNAME_TXIS%

set INSTALLS_DEFAULT_CORE=
set INSTALLS_DEFAULT_CORE_32=
set INSTALLS_DEFAULT_CORE_64=%ESD_INSTNAME_DESSTUD% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_TXAPI% %ESD_INSTNAME_TXIS%

goto :SIAMN_AfterSetNames

:SIAMN_v84

set INSTNAME_CMDSRVR=Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=Online Library
set INSTNAME_LNCHR=Launcher
set INSTNAME_LNCHRAGNT=%INSTNAME_LNCHR% Agent
set INSTNAME_LNCHRSTUD=%INSTNAME_LNCHR% Studio
set INSTNAME_SECURE=Secure Adapter Collection
set INSTNAME_TXAPI=Application Programming
set INSTNAME_TXIS=Integration Servers

if not defined INSTALL_TYPE                           goto :SIAMN_v84_ESD_IS55
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS55%")  goto :SIAMN_v84_ESD_IS55
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS63%")  goto :SIAMN_v84_ESD_IS55

:SIAMN_v84_ESD_IS2011
set ESD_INSTNAME_CMDSRVR=wsdtxcs
set ESD_INSTNAME_DESSTUD=wsdtxds
set ESD_INSTNAME_LIBRARY=wsdtxol
set ESD_INSTNAME_LNCHR=wsdtxl
set ESD_INSTNAME_LNCHRAGNT=wsdtxla
set ESD_INSTNAME_LNCHRSTUD=wsdtxls
set ESD_INSTNAME_SECURE=wsdtxsac
set ESD_INSTNAME_TXAPI=wsdtxapi
set ESD_INSTNAME_TXIS=wsdtxis
goto :SIAMN_v84_AfterSetESD

:SIAMN_v84_ESD_IS55
set ESD_INSTNAME_CMDSRVR=txcs
set ESD_INSTNAME_DESSTUD=design
set ESD_INSTNAME_LIBRARY=library
set ESD_INSTNAME_LNCHR=txlnch
set ESD_INSTNAME_LNCHRAGNT=txla
set ESD_INSTNAME_LNCHRSTUD=launchtools
set ESD_INSTNAME_SECURE=sac
set ESD_INSTNAME_TXAPI=txapi
set ESD_INSTNAME_TXIS=txis
goto :SIAMN_v84_AfterSetESD

:SIAMN_v84_AfterSetESD
rem set ESD_INSTNAME_INTERIMFIX=intfix%INTERIMFIXNUM% - Set by :GetInterimFixInfo

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_TXAPI=%INSTNAME_TXAPI%
set MENUNAME_TXIS=%INSTNAME_TXIS%

set INSTALLS_DEFAULT_CORE=
set INSTALLS_DEFAULT_CORE_32=%ESD_INSTNAME_DESSTUD%

if not defined MACHINE_IS_64BIT  set INSTALLS_DEFAULT_CORE_32=%INSTALLS_DEFAULT_CORE_32% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_TXAPI% %ESD_INSTNAME_TXIS%
if     defined MACHINE_IS_64BIT  set INSTALLS_DEFAULT_CORE_64=%ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_TXAPI% %ESD_INSTNAME_TXIS%

goto :SIAMN_AfterSetNames

:SIAMN_v83
:SIAMN_v82

set INSTNAME_CMDSRVR=Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=Online Library
set INSTNAME_LNCHR=Launcher
set INSTNAME_LNCHRAGNT=%INSTNAME_LNCHR% Agent
set INSTNAME_LNCHRSTUD=%INSTNAME_LNCHR% Studio
set INSTNAME_MB=Message Broker
set INSTNAME_SECURE=Secure Adapters Collection
set INSTNAME_SNMP=SNMP Collection
set INSTNAME_TXAPI=Application Programming
set INSTNAME_TXIS=Integration Servers
set INSTNAME_TXSDK=Transformation Extender SDK
set INSTNAME_INTERIMFIX=TX InterimFix

set ESD_INSTNAME_CMDSRVR=txcs
set ESD_INSTNAME_DESSTUD=design
set ESD_INSTNAME_LIBRARY=library
set ESD_INSTNAME_LNCHR=txlnch
set ESD_INSTNAME_LNCHRAGNT=txla
set ESD_INSTNAME_LNCHRSTUD=launchtools
set ESD_INSTNAME_MB=txmb
set ESD_INSTNAME_SECURE=sac
set ESD_INSTNAME_SNMP=snmp
set ESD_INSTNAME_TXAPI=txapi
set ESD_INSTNAME_TXIS=txis
set ESD_INSTNAME_TXSDK=txsdk
rem set ESD_INSTNAME_INTERIMFIX=intfix%INTERIMFIXNUM% - Set by :GetInterimFixInfo

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_MB=%INSTNAME_MB%
set MENUNAME_TXSDK=%INSTNAME_TXSDK%
set MENUNAME_SNMP=%INSTNAME_SNMP%
set MENUNAME_TXAPI=%INSTNAME_TXAPI%
set MENUNAME_TXIS=%INSTNAME_TXIS%

set INSTALLS_DEFAULT_CORE=%ESD_INSTNAME_DESSTUD% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_TXSDK% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SNMP% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_TXIS% %ESD_INSTNAME_LIBRARY%
goto :SIAMN_AfterSetNames

:SIAMN_v81

set INSTNAME_CMDSRVR=Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=Online Library
set INSTNAME_LNCHR=Launcher
set INSTNAME_LNCHRAGNT=%INSTNAME_LNCHR% Agent
set INSTNAME_LNCHRSTUD=%INSTNAME_LNCHR% Studio
set INSTNAME_MB=Message Broker
set INSTNAME_SECURE=Secure Adapters Collection
set INSTNAME_SNMP=SNMP Collection
set INSTNAME_TX=Transformation Extender
set INSTNAME_TXSDK=%INSTNAME_TX% SDK
set INSTNAME_WEBSRV=Web Services
set INSTNAME_INTERIMFIX=TX InterimFix

set ESD_INSTNAME_CMDSRVR=txcs
set ESD_INSTNAME_DESSTUD=design
set ESD_INSTNAME_LIBRARY=library
set ESD_INSTNAME_LNCHR=txlnch
set ESD_INSTNAME_LNCHRAGNT=txla
set ESD_INSTNAME_LNCHRSTUD=launchtools
set ESD_INSTNAME_MB=txmb
set ESD_INSTNAME_SECURE=sac
set ESD_INSTNAME_SNMP=snmp
set ESD_INSTNAME_TX=tx
set ESD_INSTNAME_TXSDK=txsdk
set ESD_INSTNAME_WEBSRV=web_pack

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_SNMP=%INSTNAME_SNMP%
set MENUNAME_TX=%INSTNAME_TX%
set MENUNAME_TXSDK=%INSTNAME_TXSDK%

set INSTALLS_DEFAULT_CORE=%ESD_INSTNAME_DESSTUD% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_TXSDK% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SNMP% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_WEBSRV% %ESD_INSTNAME_LIBRARY%
goto :SIAMN_AfterSetNames

:SIAMN_v80

set INSTNAME_CMDSRVR=DataStage TX
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_JCAG=JCA Gateway
set INSTNAME_LIBRARY=Online Library
set INSTNAME_LNCHR=DataStage TX Extended Edition
set INSTNAME_LNCHRAGNT=Event Agent
set INSTNAME_LNCHRSTUD=Management Tools
set INSTNAME_MB=Extender for Message Broker
set INSTNAME_SECURE=Security Collection
set INSTNAME_SNMP=SNMP Collection
set INSTNAME_TXSDK=Development Kit
set INSTNAME_WEBLOGIC=Control for BEA WebLogic
set INSTNAME_WEBSRV=Pack for Web Services

set INTL_SUFFIX=for Japan
set INSTNAME_CMDSRVR_INTL=%INSTNAME_CMDSRVR% %INTL_SUFFIX%
set INSTNAME_DESSTUD_INTL=%INSTNAME_DESSTUD% %INTL_SUFFIX%
set INSTNAME_LNCHR_INTL=%INSTNAME_LNCHR% %INTL_SUFFIX%
set INSTNAME_TXSDK_INTL=%INSTNAME_TXSDK% %INTL_SUFFIX%

set ESD_INSTNAME_CMDSRVR=dstx
set ESD_INSTNAME_DESSTUD=design
set ESD_INSTNAME_JCAG=jcagsrv
set ESD_INSTNAME_LIBRARY=library
set ESD_INSTNAME_LNCHR=dstxxt
set ESD_INSTNAME_LNCHRAGNT=ea_dstx
set ESD_INSTNAME_LNCHRSTUD=manage
set ESD_INSTNAME_MB=emb_dstx
set ESD_INSTNAME_SECURE=sc_dstx
set ESD_INSTNAME_SNMP=snmp_dstx
set ESD_INSTNAME_TXSDK=dk
set ESD_INSTNAME_WEBLOGIC=dstxbeawl
set ESD_INSTNAME_WEBSRV=web_pack

set INTL_SUFFIX_ESD=j
set ESD_INSTNAME_CMDSRVR_INTL=%ESD_INSTNAME_CMDSRVR%%INTL_SUFFIX_ESD%
set ESD_INSTNAME_DESSTUD_INTL=%ESD_INSTNAME_DESSTUD%%INTL_SUFFIX_ESD%
set ESD_INSTNAME_LNCHR_INTL=%ESD_INSTNAME_LNCHR%%INTL_SUFFIX_ESD%
set ESD_INSTNAME_TXSDK_INTL=%ESD_INSTNAME_TXSDK%%INTL_SUFFIX_ESD%

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR:DataStage TX =%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_MB=%INSTNAME_MB%
set MENUNAME_SNMP=%INSTNAME_SNMP%
set MENUNAME_TXSDK=%INSTNAME_TXSDK%

set INSTALLS_DEFAULT_CORE=%ESD_INSTNAME_DESSTUD% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_TXSDK% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SNMP% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_WEBSRV% %ESD_INSTNAME_JCAG% %ESD_INSTNAME_WEBLOGIC% %ESD_INSTNAME_LIBRARY%
goto :SIAMN_AfterSetNames

:SIAMN_AfterSetNames
if defined TXINSTALLS_CORE_64  goto :SIAMN_AfterTXInstallsCoreDefined
if defined TXINSTALLS_CORE_32  goto :SIAMN_AfterTXInstallsCoreDefined
if defined TXINSTALLS_CORE     goto :SIAMN_AfterTXInstallsCoreDefined
set INSTALLS_TOAPPLY_CORE=%INSTALLS_DEFAULT_CORE%
goto :SIAMN_AfterCheckTXInstallsCore
:SIAMN_AfterTXInstallsCoreDefined
if /i ("%TXINSTALLS_CORE_64%") equ ("none")  set INSTALLS_TOAPPLY_CORE_64=
if /i ("%TXINSTALLS_CORE_64%") neq ("none")  set INSTALLS_TOAPPLY_CORE_64=%TXINSTALLS_CORE_64%
if /i ("%TXINSTALLS_CORE_32%") equ ("none")  set INSTALLS_TOAPPLY_CORE_32=
if /i ("%TXINSTALLS_CORE_32%") neq ("none")  set INSTALLS_TOAPPLY_CORE_32=%TXINSTALLS_CORE_32%
if /i ("%TXINSTALLS_CORE%")    equ ("none")  set INSTALLS_TOAPPLY_CORE=
if /i ("%TXINSTALLS_CORE%")    neq ("none")  set INSTALLS_TOAPPLY_CORE=%TXINSTALLS_CORE%
:SIAMN_AfterCheckTXInstallsCore

:SIAMN_Done
if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :ProcessCoreUnInstalls: Try uninstalling all core products that we know about.
rem ===============================================================================

:ProcessCoreUnInstalls

if ("%MAJOR_VER%") geq ("8.5.0") goto :PCUI_v85
if ("%MAJOR_VER%") geq ("8.5")   goto :PCUI_v85
if ("%MAJOR_VER%") geq ("8.4.1") goto :PCUI_v84
if ("%MAJOR_VER%") geq ("8.4.0") goto :PCUI_v84
if ("%MAJOR_VER%") geq ("8.4")   goto :PCUI_v84
if ("%MAJOR_VER%") equ ("8.3")   goto :PCUI_v83
if ("%MAJOR_VER%") equ ("8.2")   goto :PCUI_v82
if ("%MAJOR_VER%") equ ("8.1")   goto :PCUI_v81
if ("%MAJOR_VER%") equ ("8.0")   goto :PCUI_v80

:PCUI_Default
:PCUI_v85

set INSTALL_TYPE=%INSTALL_TYPE_IS2011_64BIT%
call :GetCurResponseDirForThisInstall
call :SetInstallAndMenuNames
@rem call :SetLauncherAgentServiceName
call :Log
call :Log %0: Checking INSTALL_TYPE=%INSTALL_TYPE%
call :Log

if not defined MACHINE_IS_64BIT  goto :PCUI_v85_After64BitChecking
call :UninstallProduct "%INSTNAME_TXIS%"
@rem call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
@rem call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TXAPI%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
call :UninstallProduct "%INSTNAME_DESSTUD%"
:PCUI_v85_After64BitChecking

goto :PCUI_Done

:PCUI_v84

set INSTALL_TYPE=%INSTALL_TYPE_IS2011_64BIT%
call :GetCurResponseDirForThisInstall
call :SetInstallAndMenuNames
call :SetLauncherAgentServiceName
call :Log
call :Log %0: Checking INSTALL_TYPE=%INSTALL_TYPE%
call :Log

if not defined MACHINE_IS_64BIT  goto :PCUI_v84_After64BitChecking
call :UninstallProduct "%INSTNAME_TXIS%"
call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TXAPI%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
:PCUI_v84_After64BitChecking

set INSTALL_TYPE=%INSTALL_TYPE_IS2011_32BIT%
call :GetCurResponseDirForThisInstall
call :SetInstallAndMenuNames
call :SetLauncherAgentServiceName
call :Log
call :Log %0: Checking INSTALL_TYPE=%INSTALL_TYPE%
call :Log

call :UninstallProduct "%INSTNAME_LIBRARY%"
call :UninstallProduct "%INSTNAME_TXIS%"
call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TXAPI%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
call :UninstallProduct "%INSTNAME_DESSTUD%"

if ("%MAJOR_VER%") geq ("8.4.1") goto :PCUI_v84_AfterCheckForIS55
set INSTALL_TYPE=%INSTALL_TYPE_IS55%
call :GetCurResponseDirForThisInstall
call :SetInstallAndMenuNames
call :SetLauncherAgentServiceName
call :Log
call :Log %0: Checking INSTALL_TYPE=%INSTALL_TYPE%
call :Log

call :UninstallProduct "%INSTNAME_LIBRARY%"
call :UninstallProduct "%INSTNAME_TXIS%"
call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TXAPI%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
call :UninstallProduct "%INSTNAME_DESSTUD%"
:PCUI_v84_AfterCheckForIS55

goto :PCUI_Done

:PCUI_v83
call :GetCurResponseDirForThisInstall
call :SetLauncherAgentServiceName
call :UninstallProduct "%INSTNAME_LIBRARY%"
call :UninstallProduct "%INSTNAME_TXIS%"
call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_SNMP%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TXAPI%"
call :UninstallProduct "%INSTNAME_TXSDK%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
call :UninstallProduct "%INSTNAME_DESSTUD%"
goto :PCUI_Done

:PCUI_v82
call :GetCurResponseDirForThisInstall
call :SetLauncherAgentServiceName
call :UninstallProduct "%INSTNAME_LIBRARY%"
call :UninstallProduct "%INSTNAME_TXIS%"
call :UninstallProduct "%INSTNAME_MB%"
call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_SNMP%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TXAPI%"
call :UninstallProduct "%INSTNAME_TXSDK%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
call :UninstallProduct "%INSTNAME_DESSTUD%"
goto :PCUI_Done

:PCUI_v81
call :GetCurResponseDirForThisInstall
call :SetLauncherAgentServiceName
call :UninstallProduct "%INSTNAME_LIBRARY%"
call :UninstallProduct "%INSTNAME_MB%"
call :UninstallProduct "%INSTNAME_WEBSRV%"
call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_SNMP%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TX%"
call :UninstallProduct "%INSTNAME_TXSDK%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
call :UninstallProduct "%INSTNAME_DESSTUD%"
goto :PCUI_Done

:PCUI_v80
call :GetCurResponseDirForThisInstall
call :SetLauncherAgentServiceName
call :UninstallProduct "%INSTNAME_LIBRARY%"
call :UninstallProduct "%INSTNAME_MB%"
call :UninstallProduct "%INSTNAME_WEBLOGIC%"
call :UninstallProduct "%INSTNAME_WEBSRV%"
call :UninstallProduct "%INSTNAME_JCAG%"
call :UninstallProduct "%INSTNAME_SECURE%"
call :UninstallProduct "%INSTNAME_SNMP%"
call :UninstallProduct "%INSTNAME_LNCHRSTUD%"
call :UninstallProduct "%INSTNAME_LNCHRAGNT%" %LNCHRAGNT_SRVNAME%
call :UninstallProduct "%INSTNAME_TXSDK_INTL%"
call :UninstallProduct "%INSTNAME_CMDSRVR_INTL%"
call :UninstallProduct "%INSTNAME_LNCHR_INTL%"
call :UninstallProduct "%INSTNAME_DESSTUD_INTL%"
call :UninstallProduct "%INSTNAME_TXSDK%"
call :UninstallProduct "%INSTNAME_CMDSRVR%"
call :UninstallProduct "%INSTNAME_LNCHR%"
call :UninstallProduct "%INSTNAME_DESSTUD%"
goto :PCUI_Done

:PCUI_Done

if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :UninstallProduct: If the product is currently installed, uninstall it.
rem
rem Assumptions:
rem ===============================================================================

:UninstallProduct

rem ========================================
rem Make sure the args passed in are right.
rem If they're OK, get the "uninstall"
rem registry key to check for this install.
rem ========================================

set UNINSTALL_RC=

if (%1) neq () goto :UP_AfterCheckArgs
call :Log
call :Log === %0: Warning: No arguments specified.  Nothing done.
call :Log
goto :UP_Exit
:UP_AfterCheckArgs

set UP_MOREUNINSTALLKEYSTOCHECK=

:UP_UninstallLoop

call :GetUninstallKey %*

if not defined UNINSTALL_KEY  goto :UP_Exit

rem ========================================
rem Generating response files, but this
rem install does not use one.
rem ========================================

if not defined GENERATE_RESPONSEFILES                         goto :UP_AfterCheckGenResponseFiles
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%")  goto :UP_AfterCheckGenResponseFiles
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  goto :UP_AfterCheckGenResponseFiles
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS63%")          goto :UP_AfterCheckGenResponseFiles
@rem call :Log %0: %1: Response file not used.  Nothing done.
@rem goto :UP_Exit
:UP_AfterCheckGenResponseFiles

rem ========================================
rem Get the uninstall command to run from
rem the registry.
rem Set UNINSTALL_CMD to anything for
rem purposes of formatting output.
rem ========================================

set REG_QUERY_KEYNAME=%HKLM_SOFTWARE%\Microsoft\Windows\CurrentVersion\Uninstall\%UNINSTALL_KEY%
set REG_QUERY_VALUENAME=UninstallString
call :RegQueryKey
if not defined REG_QUERY_VALUE  goto :UP_UninstallStringNotFound

if defined MACHINE_IS_64BIT     goto :UP_AfterCheckUninstallKeyIsForThisInstallType
if ("%MAJOR_VER%") lss ("8.4")  goto :UP_AfterCheckUninstallKeyIsForThisInstallType
set UP_REG_QUERY_VALUE1=%REG_QUERY_VALUE:"=%
set UP_REG_QUERY_VALUE2=%UP_REG_QUERY_VALUE1: -runfromtemp =%
if /i ("%UP_REG_QUERY_VALUE1%") equ ("%UP_REG_QUERY_VALUE2%")  set UP_INSTALL_TYPE=%INSTALL_TYPE_IS55%
if /i ("%UP_REG_QUERY_VALUE1%") neq ("%UP_REG_QUERY_VALUE2%")  set UP_INSTALL_TYPE=%INSTALL_TYPE_IS2011_32BIT%
if /i ("%UP_INSTALL_TYPE%") neq ("%INSTALL_TYPE%")  goto :UP_UninstallStringNotFound
:UP_AfterCheckUninstallKeyIsForThisInstallType

if not defined UNINSTALL_CMD call :Log
set UNINSTALL_CMD=%REG_QUERY_VALUE%
call :Log === %0: Start: %date% %time%: %*
call :Log

rem ========================================
rem For 64bit Windows, the uninstall string
rem may need repair if the path to UnInst.exe
rem contains spaces.
rem ========================================

if not defined MACHINE_IS_64BIT                               goto :UP_After64BitUninstallStringRepair
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%")  goto :UP_After64BitUninstallStringRepair
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  goto :UP_After64BitUninstallStringRepair
for /f "usebackq tokens=1*" %%i in (`echo %REG_QUERY_VALUE%`) do set UNINSTALL_EXE=%%i
if exist "%UNINSTALL_EXE%" goto :UP_After64BitUninstallStringRepair
set UNINSTALL_EXE=
set UNINSTALL_CMD=
set REG_QUERY_VALUE=%REG_QUERY_VALUE:"=!%
for /f "tokens=*" %%i in ("%REG_QUERY_VALUE%") do for %%j in (%%i) do call :RepairUninstString %%j
set UNINSTALL_CMD=%UNINSTALL_CMD:!="%
:UP_After64BitUninstallStringRepair

@rem call :Log UNINSTALL_EXE=[%UNINSTALL_EXE%]
@rem call :Log UNINSTALL_CMD=[%UNINSTALL_CMD%]

rem ========================================
rem Add the "silent" options to the command
rem line, based on what tool was used to
rem create the install.
rem ========================================

set UNINSTALL_SUFFIX=_uninstall

if not defined INSTALL_TYPE                                   goto :UP_AddIS55Options
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS55%")          goto :UP_AddIS55Options
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%")  goto :UP_AddISResponseFileOptions
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  goto :UP_AddISResponseFileOptions
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS63%")          goto :UP_AddISResponseFileOptions
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IA%")            goto :UP_AfterGetUninstallString

:UP_AddIS55Options
set UNINSTALL_CMD=%UNINSTALL_CMD% -a -x -y
set GUILockFile=
set RESPONSEFILE=
set RESULTLOG=
goto :UP_AfterGetUninstallString

:UP_AddISResponseFileOptions

set GUILockFile="%RESULTDIR%\%UNINSTALL_ESD_INSTNAME%%UNINSTALL_SUFFIX%.lck"
set RESPONSEFILE="%CURRESPONSEDIR%\%UNINSTALL_ESD_INSTNAME%%UNINSTALL_SUFFIX%.iss"
set RESULTLOG="%RESULTDIR%\%UNINSTALL_ESD_INSTNAME%%UNINSTALL_SUFFIX%.log"

if not defined RESPONSEFILE            goto :UP_ISRFO_AfterCheckResponseFileExists
if     defined GENERATE_RESPONSEFILES  goto :UP_ISRFO_DeleteResponseFile
if exist %RESPONSEFILE%                goto :UP_ISRFO_AfterCheckResponseFileExists
call :Log %0: %1: Missing required response file %RESPONSEFILE%.  Nothing done.
goto :UP_Exit
:UP_ISRFO_DeleteResponseFile
if exist %RESPONSEFILE%  del /f /q %RESPONSEFILE%
:UP_ISRFO_AfterCheckResponseFileExists

if     defined GUILockFile            set UNINSTALL_CMD=%UNINSTALL_CMD% -a %GUILockFile%
if     defined GENERATE_RESPONSEFILES set UNINSTALL_CMD=%UNINSTALL_CMD% -r -f1%RESPONSEFILE%
if not defined GENERATE_RESPONSEFILES set UNINSTALL_CMD=%UNINSTALL_CMD% -s -f1%RESPONSEFILE%
if     defined RESULTLOG              set UNINSTALL_CMD=%UNINSTALL_CMD% -f2%RESULTLOG%

if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%")  goto :UP_AddFlag_TXLOG
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  goto :UP_AddFlag_TXLOG
goto :UP_AfterTXLOG_Flag
:UP_AddFlag_TXLOG
if     defined TXINSTALLS_DEBUG       set UNINSTALL_CMD=%UNINSTALL_CMD% -txlog "%RESULTDIR%\txlog_%UNINSTALL_ESD_INSTNAME%%UNINSTALL_SUFFIX%.log"
:UP_AfterTXLOG_Flag

goto :UP_AfterGetUninstallString

:UP_AfterGetUninstallString
del /f /q %TMPOUTFILE% %TMPOUTFILE2%

if not defined GUILockFile  goto :UP_AfterCheckForLockFile
if not exist %GUILockFile%  goto :UP_AfterCheckForLockFile
call :Log %0: GUILockFile=%GUILockFile% exists.
rem 01/16/2008: gbc: Removing all interactive checks for automation purposes.
rem set /p ASKYN=Delete lockfile (y/n)?
set ASKYN=y
if /i "%ASKYN%" equ "yes"  set ASKYN=y
if /i "%ASKYN%" neq "y"    goto :UP_IS_WaitForInstall
call :Log %0: Deleting GUILockFile=%GUILockFile%...
call :Log
del /f /q %GUILockFile%
:UP_AfterCheckForLockFile

rem ========================================
rem Launch the uninstall.
rem ========================================

:UP_LaunchUninstall
call :Log %UNINSTALL_CMD%

if defined TXINSTALLS_DEBUG @echo on
if defined TXINSTALLS_DEBUG pause

if not defined GUILockFile goto :UP_LaunchIS_AfterCreateLockFile
echo %0: Start: %date% %time%: Silent uninstall of %* > %GUILockFile%
:UP_LaunchIS_AfterCreateLockFile

if not defined LOGFILE  goto :UP_LU_NoLogfile
%UNINSTALL_CMD% >> %LOGFILE% 2>&1
goto :UP_LU_AfterRunCmd
:UP_LU_NoLogfile
%UNINSTALL_CMD%
:UP_LU_AfterRunCmd

rem ========================================
rem If using a lockfile, wait for the
rem uninstall to delete it.
rem ========================================

if not defined GUILockFile  goto :UP_IS_AfterWaitForGUILockFile

:UP_IS_WaitForInstall
call :Log

call :Log %0: %date% %time%: Please wait while the uninstall completes...

:UP_IS_WaitForInstall_Loop
if not exist %GUILockFile%   goto :UP_IS_AfterWaitForGUILockFile

%SLEEP_CMD% > nul 2>&1
goto :UP_IS_WaitForInstall_Loop

:UP_IS_AfterWaitForGUILockFile



:UP_WaitForUninstall
call :RegQueryKey
if ("%REG_QUERY_RETCODE%") neq ("0") goto :UP_AfterWaitForUninstall
call :Log %0: %date% %time%: Waiting for registry key to be cleared...
:UP_WaitForUninstall_Loop
call :RegQueryKey
if ("%REG_QUERY_RETCODE%") neq ("0") goto :UP_AfterWaitForUninstall
%SLEEP_CMD% > nul 2>&1
goto :UP_WaitForUninstall_Loop
:UP_AfterWaitForUninstall

if defined GENERATE_RESPONSEFILES                     goto :UP_IS_SetRCTo0
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS55%")  goto :UP_IS_SetRCTo0
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IA%")    goto :UP_IS_SetRCTo0
if not defined UNINSTALL_RC  call :GetISRC
call :DisplayISRC %UNINSTALL_RC%
goto :UP_AfterLaunchUninstall

:UP_IS_SetRCTo0
set UNINSTALL_RC=0
goto :UP_AfterLaunchUninstall

:UP_UninstallStringNotFound
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :UP_UninstallLoop

if     defined INSTALL_TYPE  call :Log %0: Install not present: %*  (install_type=%INSTALL_TYPE%)
if not defined INSTALL_TYPE  call :Log %0: Install not present: %*
set UNINSTALL_CMD=
goto :UP_Exit

rem ========================================
rem Done
rem ========================================

:UP_AfterLaunchUninstall
%SLEEP_CMD_AFTERISCOMPLETES% > nul 2>&1
if     defined INSTALL_TYPE  call :Log === %0: Done: %date% %time%: %*  (install_type=%INSTALL_TYPE%)
if not defined INSTALL_TYPE  call :Log === %0: Done: %date% %time%: %*
call :Log

:UP_Exit
set MYCMD=
set UP_REG_QUERY_VALUE1=
set UP_REG_QUERY_VALUE2=
set UP_INSTALL_TYPE=
set QUERYKEY_CMD=
set UNINSTALL_KEY=
set UNINSTALL_ESD_INSTNAME=
set UNINSTALL_SUFFIX=
set GUILockFile=
set RESPONSEFILE=
set RESULTLOG=

if defined TXINSTALLS_DEBUG pause
goto :EOF



:GetUninstallKey

set UNINSTALL_KEY=
set UNINSTALL_ESD_INSTNAME=


set CURINSTALL=%INSTNAME_CMDSRVR%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterCmdSrvr
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_CMDSRVR%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_CmdSrvr_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_CmdSrvr_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_CmdSrvr_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
if ("%MAJOR_VER%") equ ("8.0") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX%
if ("%MAJOR_VER%") equ ("8.1") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
if ("%MAJOR_VER%") lss ("8.4")   goto :GUK_CmdSrvr_After84AndAbove
if /i ("%INSTALL_TYPE%") neq ("%INSTALL_TYPE_IS55%") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
:GUK_CmdSrvr_After84AndAbove
if not defined UNINSTALL_KEY   set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% with %CURINSTALL%
goto :GUK_Done
:GUK_AfterCmdSrvr



set CURINSTALL=%INSTNAME_CMDSRVR_INTL%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterCmdSrvrIntl
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_CMDSRVR_INTL%
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %INTL_SUFFIX%
goto :GUK_Done
:GUK_AfterCmdSrvrIntl



set CURINSTALL=%INSTNAME_DESSTUD%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterDesignStudio
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_DESSTUD%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_DesignStudio_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_DesignStudio_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_DesignStudio_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterDesignStudio


set CURINSTALL=%INSTNAME_DESSTUD_INTL%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterDesignStudioIntl
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_DESSTUD_INTL%
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterDesignStudioIntl

rem ========================================
rem v8.0: Install="JCA Gateway"
rem ========================================

set CURINSTALL=%INSTNAME_JCAG%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterJCAGateway
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_JCAG%
set UNINSTALL_KEY={21E1BC0A-D8FB-40F0-B5C1-5C2AD12CBBC4}
set INSTALL_TYPE=%INSTALL_TYPE_IS63%
goto :GUK_Done
:GUK_AfterJCAGateway


set CURINSTALL=%INSTNAME_LIBRARY%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterOnlineLibrary
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_LIBRARY%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_OnlineLibrary_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_OnlineLibrary_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_OnlineLibrary_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
if ("%MAJOR_VER%") neq ("8.0")   goto :GUK_OnlineLibrary_Post80
set UNINSTALL_KEY={C4B4AD5E-0B53-46BD-941A-89C642796124}
set INSTALL_TYPE=%INSTALL_TYPE_IS63%
goto :GUK_Done
:GUK_OnlineLibrary_Post80
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterOnlineLibrary

set CURINSTALL=%INSTNAME_LNCHR%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterLauncher
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_LNCHR%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_Launcher_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_Launcher_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_Launcher_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
if ("%MAJOR_VER%") equ ("8.0") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL:DataStage TX =%
if ("%MAJOR_VER%") equ ("8.1") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
if ("%MAJOR_VER%") lss ("8.4")   goto :GUK_Launcher_After84AndAbove
if /i ("%INSTALL_TYPE%") neq ("%INSTALL_TYPE_IS55%") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
:GUK_Launcher_After84AndAbove
if not defined UNINSTALL_KEY   set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% with %CURINSTALL%
goto :GUK_Done
:GUK_AfterLauncher

rem ========================================
rem v8.0: Install="DataStage TX Extended Edition for Japan"  Uninstall="Ascential DataStage TX 8.0 Extended Edition for Japan"
rem ========================================

set CURINSTALL=%INSTNAME_LNCHR_INTL%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterLauncherIntl
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_LNCHR_INTL%
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL:DataStage TX =%
goto :GUK_Done
:GUK_AfterLauncherIntl

rem ========================================
rem v8.0: Install="Event Agent"  UninstallKey="Ascential DataStage TX 8.0 Event Agent - <AgentName>"
rem !8.0: Install="Launcher Agent"  UninstallKey="IBM WebSphere Transformation Extender <MAJOR_VER> Launcher Agent - <AgentName>"
rem ========================================

set CURINSTALL=%INSTNAME_LNCHRAGNT%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterLauncherAgent
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_LNCHRAGNT%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_LauncherAgent_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_LauncherAgent_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %*
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_LauncherAgent_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
if (%2) neq ()  set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL% - %2
if (%2) equ ()  set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL% - %DEFAULT_LNCHRAGNT_SRVNAME%
goto :GUK_Done
:GUK_AfterLauncherAgent

rem ========================================
rem v8.0: Install="Management Tools"  UninstallKey="Ascential DataStage TX 8.0 Management Tools"
rem !8.0: Install="Launcher Studio"  UninstallKey="IBM WebSphere Transformation Extender <MAJOR_VER> Launcher Studio"
rem ========================================

set CURINSTALL=%INSTNAME_LNCHRSTUD%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterLauncherStudio
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_LNCHRSTUD%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_LauncherStudio_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_LauncherStudio_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_LauncherStudio_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterLauncherStudio

rem ========================================
rem v8.0: Install="Extender for Message Broker"  UninstallKey="IBM WebSphere DataStage TX 8.0 Extender for Message Broker"
rem v8.1: Install="TX for Message Broker"  UninstallKey="IBM WebSphere Transformation Extender 8.1 Message Broker"
rem ========================================

set CURINSTALL=%INSTNAME_MB%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterExtenderMB
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_MB%
if ("%MAJOR_VER%") equ ("8.0") set UNINSTALL_KEY=IBM WebSphere DataStage TX 8.0 %CURINSTALL%
if not defined UNINSTALL_KEY   set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterExtenderMB

rem ========================================
rem v8.0: Install="Security Collection"  UninstallKey="{BAD22E52-6EDC-4B45-B327-779B2377E19D}"
rem !8.0: Install="Secure Adapters Collection"  UninstallKey="IBM WebSphere Transformation Extender <MAJOR_VER> Secure Adapters Collection"
rem ========================================

set CURINSTALL=%INSTNAME_SECURE%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterSecurityCollection
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_SECURE%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_SecurityCollection_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_SecurityCollection_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_SecurityCollection_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
if ("%MAJOR_VER%") neq ("8.0")   goto :GUK_SecurityCollection_Post80
set UNINSTALL_KEY={BAD22E52-6EDC-4B45-B327-779B2377E19D}
set INSTALL_TYPE=%INSTALL_TYPE_IS63%
goto :GUK_Done
:GUK_SecurityCollection_Post80
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterSecurityCollection

rem ========================================
rem Install="SNMP Collection"
rem ========================================

set CURINSTALL=%INSTNAME_SNMP%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterSNMPCollection
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_SNMP%
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterSNMPCollection

rem ========================================
rem v8.0: Install="DataStage TX" (Command Server - see INSTNAME_CMDSRVR)
rem v8.1: Install="TX" (DK Runtime)  UninstallKey="IBM WebSphere Transformation Extender 8.1"
rem ========================================

set CURINSTALL=%INSTNAME_TX%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterDevelopmentKit
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_TX%
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX%
goto :GUK_Done
:GUK_AfterDevelopmentKit

rem ========================================
rem v8.2-8.4:    Install="TX for Application Programming"  UninstallKey="IBM WebSphere Transformation Extender <MAJOR_VER> for Application Programming"
rem v8.4 IS2011: Install="TX with Launcher"  UninstallKey="IBM WebSphere Transformation Extender 8.4 Application Programming"
rem ========================================

set CURINSTALL=%INSTNAME_TXAPI%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterTXAPI
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_TXAPI%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_TXAPI_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_TXAPI_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_TXAPI_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
if ("%MAJOR_VER%") lss ("8.4")   goto :GUK_TXAPI_After84AndAbove
if /i ("%INSTALL_TYPE%") neq ("%INSTALL_TYPE_IS55%") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
:GUK_TXAPI_After84AndAbove
if not defined UNINSTALL_KEY   set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% for Application Programming
goto :GUK_Done
:GUK_AfterTXAPI

rem ========================================
rem v8.2-8.4:    Install="TX for Integration Servers"  UninstallKey="IBM WebSphere Transformation Extender <MAJOR_VER> for Integration Servers"
rem v8.4 IS2011: Install="TX for Integration Servers"  UninstallKey="IBM WebSphere Transformation Extender <MAJOR_VER> Integration Servers"
rem ========================================

set CURINSTALL=%INSTNAME_TXIS%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterTXIS
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_TXIS%

if ("%MAJOR_VER%") lss ("8.4")          goto :GUK_TXIS_AfterCheckForGUID
if defined UP_MOREUNINSTALLKEYSTOCHECK  goto :GUK_TXIS_AfterCheckForGUID
if ("%MAJOR_VER%") equ ("8.4")  set UP_MOREUNINSTALLKEYSTOCHECK=1
call :GetUninstallKeyGUID %1
if ("%MAJOR_VER%") gtr ("8.4")  goto :GUK_Done_AfterAppendBitVariation
if defined UNINSTALL_KEY        goto :GUK_Done_AfterAppendBitVariation

:GUK_TXIS_AfterCheckForGUID
set UP_MOREUNINSTALLKEYSTOCHECK=
if ("%MAJOR_VER%") lss ("8.4")   goto :GUK_TXIS_After84AndAbove
if /i ("%INSTALL_TYPE%") neq ("%INSTALL_TYPE_IS55%") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
:GUK_TXIS_After84AndAbove
if not defined UNINSTALL_KEY set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% for Integration Servers
goto :GUK_Done
:GUK_AfterTXIS

rem ========================================
rem v8.0: Install="Development Kit"  UninstallKey="Ascential DataStage TX 8.0 Development Kit"
rem v8.1: Install="TX SDK" (DK Design-time)  UninstallKey="IBM WebSphere Transformation Extender 8.1 Transformation Extender SDK"
rem v8.2: Install="TX SDK"  UninstallKey="IBM WebSphere Transformation Extender 8.2 SDK"
rem ========================================

set CURINSTALL=%INSTNAME_TXSDK%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterSDK
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_TXSDK%
if ("%MAJOR_VER%") equ ("8.0") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
if ("%MAJOR_VER%") equ ("8.1") set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
if not defined UNINSTALL_KEY   set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% SDK
goto :GUK_Done
:GUK_AfterSDK

rem ========================================
rem v8.0: Install="Development Kit for Japan"  UninstallKey="Ascential DataStage TX 8.0 Development Kit for Japan"
rem ========================================

set CURINSTALL=%INSTNAME_TXSDK_INTL%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterSDKIntl
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_TXSDK_INTL%
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL% 
goto :GUK_Done
:GUK_AfterSDKIntl

rem ========================================
rem Control for BEA WebLogic is only in WTX v8.0
rem ========================================

set CURINSTALL=%INSTNAME_WEBLOGIC%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterWebLogic
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_WEBLOGIC%
set UNINSTALL_KEY={2177BFE0-2265-4660-9085-43A5244DB4D9}
set INSTALL_TYPE=%INSTALL_TYPE_IS63%
goto :GUK_Done
:GUK_AfterWebLogic

rem ========================================
rem v8.0: Install="PACK for Web Services" UninstallKey="{3DDF81F3-D8E8-43B4-8B42-2BEBF553ACCC}"
rem v8.1: Install="PACK for Web Services" UninstallKey="IBM WebSphere Transformation Extender 8.1 Web Services"
rem ========================================

set CURINSTALL=%INSTNAME_WEBSRV%
if /i (%1) neq ("%CURINSTALL%")  goto :GUK_AfterWebServices
set UNINSTALL_ESD_INSTNAME=%ESD_INSTNAME_WEBSRV%
if ("%MAJOR_VER%") neq ("8.0")   goto :GUK_WebServices_Post80
set UNINSTALL_KEY={3DDF81F3-D8E8-43B4-8B42-2BEBF553ACCC}
set INSTALL_TYPE=%INSTALL_TYPE_IS63%
goto :GUK_Done
:GUK_WebServices_Post80
set UNINSTALL_KEY=%DEFAULT_UNINSTKEY_PREFIX% %CURINSTALL%
goto :GUK_Done
:GUK_AfterWebServices

rem ========================================
rem Errors
rem ========================================

:GUK_UnknownInstall
call :Log
call :Log %0: ERROR: Unknown install: %*
call :Log
goto :GUK_Done

:GUK_UnknownInstallVersion
call :Log
call :Log %0: ERROR: Unrecognized version for install: %*
call :Log
goto :GUK_Done

rem ========================================
rem Done
rem ========================================

:GUK_Done

rem ========================================
rem The IS2011 installs will include the bit
rem variation at the end of the uninstall
rem string for the situations:
rem - the IS2011 64bit installs 
rem - the IS2011 32bit installs, but only
rem   when they are being installed on a
rem   64bit platform.
rem ========================================
if not defined UNINSTALL_KEY                                  goto :GUK_Done_AfterAppendBitVariation
if /i ("%MAJOR_VER%") lss ("8.4")                             goto :GUK_Done_AfterAppendBitVariation
if not defined INSTALL_TYPE                                   goto :GUK_Done_AfterAppendBitVariation
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  goto :GUK_Done_AppendBitVariation
if /i ("%INSTALL_TYPE%") neq ("%INSTALL_TYPE_IS2011_32BIT%")  goto :GUK_Done_AfterAppendBitVariation
if not defined MACHINE_IS_64BIT                               goto :GUK_Done_AfterAppendBitVariation
:GUK_Done_AppendBitVariation
set UNINSTALL_KEY=%UNINSTALL_KEY% %INSTALL_TYPE% bit variation
:GUK_Done_AfterAppendBitVariation

set GUK_TMPPREFIX=

set > %TEMP%\%~n0_env2.txt
if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :GetUninstallKeyGUID: Starting with v8.4.0.3, the uninstall key changed from
rem being the product name (defined by INSTNAME_*) to being the GUID.  The GUID can
rem be determined by getting it from the InstanceInfo registry key that DaveR
rem creates for each product below %MAJOR_VER_KEY% (for INSTALL_TYPE_IS2011_32BIT)
rem or %MAJOR_VER_KEY_64% (for INSTALL_TYPE_IS2011_64BIT).  If InstanceInfo is
rem present, return that value in the UNINSTALL_KEY env var.  Otherwise, return 
rem without defining UNINSTALL_KEY.
rem - Arg1: Product name being uninstalled, surrounded by double quotes
rem - Arg2: For Launcher Agent, this is the service name we are looking for
rem ===============================================================================

:GetUninstallKeyGUID

set UNINSTALL_KEY=

if ("%MAJOR_VER%") lss ("8.4")   goto :GUKGUID_Done
if (%1) equ ()                   goto :GUKGUID_Done

set REG_QUERY_KEYNAME=
for %%a in (%1) do set GUKGUID_PRODUCTNAME=%%~a

if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%")  goto :GUKGUID_InstallIs32Bit
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  goto :GUKGUID_InstallIs64Bit
goto :GUKGUID_Done

:GUKGUID_InstallIs32Bit
if (%2) equ () set REG_QUERY_KEYNAME=%MAJOR_VER_KEY%\%GUKGUID_PRODUCTNAME%\0
if (%2) neq () set REG_QUERY_KEYNAME=%MAJOR_VER_KEY%\%GUKGUID_PRODUCTNAME%\%2\0
goto :GUKGUID_AfterSetRegQueryKey

:GUKGUID_InstallIs64Bit
if not defined MACHINE_IS_64BIT  goto :GUKGUID_Done
if (%2) equ () set REG_QUERY_KEYNAME=%MAJOR_VER_KEY_64%\%GUKGUID_PRODUCTNAME%\0
if (%2) neq () set REG_QUERY_KEYNAME=%MAJOR_VER_KEY_64%\%GUKGUID_PRODUCTNAME%\%2\0
goto :GUKGUID_AfterSetRegQueryKey

:GUKGUID_AfterSetRegQueryKey
if not defined REG_QUERY_KEYNAME  goto :GUKGUID_Done
set REG_QUERY_VALUENAME=InstanceInfo
call :RegQueryKey
if not defined REG_QUERY_VALUE    goto :GUKGUID_Done

set UNINSTALL_KEY=%REG_QUERY_VALUE%

:GUKGUID_Done
@rem if defined UNINSTALL_KEY  call :Log Install=%*  GUID="%UNINSTALL_KEY%"  (install_type=%INSTALL_TYPE%)
goto :EOF


rem ===============================================================================
rem :RepairUninstString: For 64bit Windows, the IsUninst.exe command may contain
rem a space in the path.  This function tries to rectify that problem.  After
rem parsing the entire string from the UninstallString value in the registry:
rem
rem UNINSTALL_EXE: Should contain the path to IsUninst.exe, surrounded by
rem                double quotes.  Currently unused, but handy for debugging.
rem UNINSTALL_CMD: The repaired uninstall command string.
rem ===============================================================================

:RepairUninstString

set RUS_ARG=%*
if ("%RUS_ARG:~-1%") equ ("!") set RUS_ARG=%RUS_ARG:~0,-1%
if /i ("%RUS_ARG:~-12%") equ ("IsUninst.exe") goto :RUS_FoundUninstExe
set RUS_ARG=%*

:RUS_NotUninstExe
if defined UNINSTALL_CMD  goto :RUS_NotUninstExe_Append

:RUS_NotUninstExe_Set
set UNINSTALL_CMD=%RUS_ARG%
goto :RUS_Done

:RUS_NotUninstExe_Append
set UNINSTALL_CMD=%UNINSTALL_CMD% %RUS_ARG%
goto :RUS_Done

:RUS_FoundUninstExe
if defined UNINSTALL_CMD  goto :RUS_FoundUninstExe_Append

:RUS_FoundUninstExe_Set
set UNINSTALL_CMD=%RUS_ARG%
goto :RUS_AfterFoundUninstExe

:RUS_FoundUninstExe_Append
set UNINSTALL_CMD=%UNINSTALL_CMD% %RUS_ARG%
goto :RUS_AfterFoundUninstExe

:RUS_AfterFoundUninstExe
set UNINSTALL_CMD="%UNINSTALL_CMD%"
set UNINSTALL_EXE=%UNINSTALL_CMD%
if not exist %UNINSTALL_EXE% goto :RUS_Done
@rem call :Log %0: Found: UNINSTALL_EXE=%UNINSTALL_EXE%
goto :RUS_Done

:RUS_Done

if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :GetCurResponseDirForThisInstall: Determine CURRESPONSEDIR to use based on
rem RESPONSEDIR and the install currently being installed.
rem
rem NOTE: The "64bit" response subdirectories are used for installing 32bit
rem installs on 64bit platforms, as the response files are slightly different
rem between the 32bit and 64bit platforms.  So "\64bit" is only used for installing
rem 32bit apps on a 64bit machine.  It is not appended to the response directory if
rem we're not on a 64bit machine or if we're are installing 64bit installs.
rem ===============================================================================

:GetCurResponseDirForThisInstall

set CURRESPONSEDIR=%RESPONSEDIR%

if /i ("%MAJOR_VER%") lss ("8.4")  goto :GCRDFTI_AfterCheckFor84
if defined INSTALL_TYPE  set CURRESPONSEDIR=%CURRESPONSEDIR%\%INSTALL_TYPE%
:GCRDFTI_AfterCheckFor84

if not defined MACHINE_IS_64BIT    goto :GCRDFTI_CheckCurrResponseDir
if not defined INSTALL_TYPE        goto :GCRDFTI_AfterCheckFor64BitInstallType
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  goto :GCRDFTI_CheckCurrResponseDir
:GCRDFTI_AfterCheckFor64BitInstallType
set CURRESPONSEDIR=%CURRESPONSEDIR%\64bit

:GCRDFTI_CheckCurrResponseDir
if exist "%CURRESPONSEDIR%"         goto :GCRDFTI_AfterCheckResponseDirExists
if defined GENERATE_RESPONSEFILES   mkdir "%CURRESPONSEDIR%"
if not exist "%CURRESPONSEDIR%"     goto :GCRDFTI_Error_MissingResponseDir
:GCRDFTI_AfterCheckResponseDirExists
pushd "%CURRESPONSEDIR%" > nul 2>&1
if ERRORLEVEL 1                     goto :GCRDFTI_Error_MissingResponseDir
popd
goto :GCRDFTI_Done

:GCRDFTI_Error_MissingResponseDir
call :Log ===
call :Log === %0: ERROR: Missing current response dir "%CURRESPONSEDIR%"
call :Log ===

:GCRDFTI_Done
goto :EOF


rem ===============================================================================
rem :GetISRC: Get the InstallShield return code from the file specified
rem by RESULTLOG.
rem ===============================================================================

:GetISRC

set UNINSTALL_RC=

if not defined RESULTLOG  goto :GISRC_Done

if exist %RESULTLOG%      goto :GISRC_ResultLogExists
rem ========================================
rem Timing issue: Wait a moment if the
rem result log is not available yet...
rem ========================================
%SLEEP_CMD% > nul 2>&1
if not exist %RESULTLOG%  goto :GISRC_Done
:GISRC_ResultLogExists

type %RESULTLOG% | "%SystemRoot%\system32\find.exe" "ResultCode" > %TMPOUTFILE%
if ERRORLEVEL 1  goto :GISRC_Done
for /f "tokens=1,2 delims== " %%i in ('type %TMPOUTFILE%') do set UNINSTALL_RC=%%j

:GISRC_Done
goto :EOF




:DisplayISRC

if /i ("%1") equ ("") set DISRC_PREFIX====    Uninstall Return Code = UNDEFINED:
if /i ("%1") neq ("") set DISRC_PREFIX====    Uninstall Return Code = %1:
set DISRC_RESULT=%DISRC_PREFIX%

if /i ("%1") neq ("")  goto :DISRC_AfterNull
set DISRC_RESULT=%DISRC_RESULT% No return code supplied
goto :DISRC_AfterSetResult
:DISRC_AfterNull

if /i ("%1") neq ("0")  goto :DISRC_After0
set DISRC_RESULT=%DISRC_RESULT% Success
goto :DISRC_AfterSetResult
:DISRC_After0

if /i ("%1") neq ("-1")  goto :DISRC_AfterNeg1
set DISRC_RESULT=%DISRC_RESULT% General error
goto :DISRC_AfterSetResult
:DISRC_AfterNeg1

if /i ("%1") neq ("-2") goto :DISRC_AfterNeg2
set DISRC_RESULT=%DISRC_RESULT% Invalid mode
:DISRC_AfterNeg2

if /i ("%1") neq ("-3") goto :DISRC_AfterNeg3
set DISRC_RESULT=%DISRC_RESULT% Required data not found in the Setup.iss file
goto :DISRC_AfterSetResult
:DISRC_AfterNeg3

if /i ("%1") neq ("-4") goto :DISRC_AfterNeg4
set DISRC_RESULT=%DISRC_RESULT% Not enough memory available
goto :DISRC_AfterSetResult
:DISRC_AfterNeg4

if /i ("%1") neq ("-5") goto :DISRC_AfterNeg5
set DISRC_RESULT=%DISRC_RESULT% File does not exist
goto :DISRC_AfterSetResult
:DISRC_AfterNeg5

if /i ("%1") neq ("-6") goto :DISRC_AfterNeg6
set DISRC_RESULT=%DISRC_RESULT% Cannot write to the response file
goto :DISRC_AfterSetResult
:DISRC_AfterNeg6

if /i ("%1") neq ("-7") goto :DISRC_AfterNeg7
set DISRC_RESULT=%DISRC_RESULT% Unable to write to the log file
goto :DISRC_AfterSetResult
:DISRC_AfterNeg7

if /i ("%1") neq ("-8") goto :DISRC_AfterNeg8
set DISRC_RESULT=%DISRC_RESULT% Invalid path to the InstallShield Silent response file
goto :DISRC_AfterSetResult
:DISRC_AfterNeg8

if /i ("%1") neq ("-9") goto :DISRC_AfterNeg9
set DISRC_RESULT=%DISRC_RESULT% Not a valid list type (string or number)
goto :DISRC_AfterSetResult
:DISRC_AfterNeg9

if /i ("%1") neq ("-10") goto :DISRC_AfterNeg10
set DISRC_RESULT=%DISRC_RESULT% Data type is invalid
goto :DISRC_AfterSetResult
:DISRC_AfterNeg10

if /i ("%1") neq ("-11") goto :DISRC_AfterNeg11
set DISRC_RESULT=%DISRC_RESULT% Unknown error during setup
goto :DISRC_AfterSetResult
:DISRC_AfterNeg11

if /i ("%1") neq ("-12") goto :DISRC_AfterNeg12
set DISRC_RESULT=%DISRC_RESULT% Dialog boxes are out of order
goto :DISRC_AfterSetResult
:DISRC_AfterNeg12

if /i ("%1") neq ("-51") goto :DISRC_AfterNeg51
set DISRC_RESULT=%DISRC_RESULT% Cannot create the specified folder
goto :DISRC_AfterSetResult
:DISRC_AfterNeg51

if /i ("%1") neq ("-52") goto :DISRC_AfterNeg52
set DISRC_RESULT=%DISRC_RESULT% Cannot access the specified file or folder
goto :DISRC_AfterSetResult
:DISRC_AfterNeg52

if /i ("%1") neq ("-53") goto :DISRC_AfterNeg53
set DISRC_RESULT=%DISRC_RESULT% Invalid option selected
goto :DISRC_AfterSetResult
:DISRC_AfterNeg53

if /i ("%1") neq ("-105") goto :DISRC_AfterNeg105
set DISRC_RESULT=%DISRC_RESULT% Component tree entry specified in response file not found
goto :DISRC_AfterSetResult
:DISRC_AfterNeg105

if /i ("%DISRC_RESULT%") equ ("%DISRC_PREFIX%") set DISRC_RESULT=%DISRC_RESULT% Unknown result code

:DISRC_AfterSetResult
call :Log %DISRC_RESULT%

:DISRC_Done
set DISRC_PREFIX=
set DISRC_RESULT=
goto :EOF


rem ===============================================================================
rem :GetIARC: Get the InstallAnywhere return code from the file specified
rem by RESULTLOG_IA.
rem ===============================================================================

:GetIARC

set UNINSTALL_RC=

if not defined RESULTLOG_IA  goto :GIARC_AfterGetRC
if not exist %RESULTLOG_IA%  goto :GIARC_AfterGetRC

type %RESULTLOG_IA% | "%SystemRoot%\system32\find.exe" "Installation:" > %TMPOUTFILE%
if ERRORLEVEL 1  goto :GIARC_AfterGetRC
for /f "tokens=1,2 " %%i in ('type %TMPOUTFILE%') do set UNINSTALL_RC=%%j

:GIARC_AfterGetRC
if not defined UNINSTALL_RC               set UNINSTALL_RC=UNDEFINED
if ("%UNINSTALL_RC%") == ("Successful.")  set UNINSTALL_RC=0

:GIARC_Done
goto :EOF


rem ===============================================================================
rem :DisplayIARC: Log the InstallAnywhere return code passed in.
rem - Arg1: InstallAnywhere return code to be logged
rem ===============================================================================

:DisplayIARC

if /i ("%1") equ ("0") set DIARC_RESULT====    Install Return Code = Success
if /i ("%1") neq ("0") set DIARC_RESULT====    Install Return Code = Error (%1)

call :Log %DIARC_RESULT%

:DIARC_Done
set DIARC_RESULT=
goto :EOF


:CheckIfMachineIs64Bit

set MACHINE_IS_64BIT=

if not defined CIMI64B_DEBUG  goto :CIMI64B_AfterDebug
set LOG_CMD=set PROCESSOR_
call :Log %0: All PROCESSOR_ variables
call :Log PROCESSOR_ARCHITECTURE="%PROCESSOR_ARCHITECTURE%"
if     defined PROCESSOR_ARCHITEW6432  call :Log PROCESSOR_ARCHITEW6432="%PROCESSOR_ARCHITEW6432%"
if not defined PROCESSOR_ARCHITEW6432  call :Log PROCESSOR_ARCHITEW6432 not defined
:CIMI64B_AfterDebug

if /i ("%PROCESSOR_ARCHITECTURE%") equ ("x86")    goto :CIMI64B_AfterCheckProcessorArchitecture
if /i ("%PROCESSOR_ARCHITECTURE%") equ ("amd64")  goto :CIMI64B_ProcessorIs64Bit
if /i ("%PROCESSOR_ARCHITECTURE%") equ ("ia64")   goto :CIMI64B_ProcessorIs64Bit
:CIMI64B_AfterCheckProcessorArchitecture
if not defined PROCESSOR_ARCHITEW6432             goto :CIMI64B_AfterCheckFor64BitProcessor
if /i ("%PROCESSOR_ARCHITEW6432%") equ ("amd64")  goto :CIMI64B_ProcessorIs64Bit
if /i ("%PROCESSOR_ARCHITEW6432%") equ ("ia64")   goto :CIMI64B_ProcessorIs64Bit
goto :CIMI64B_AfterCheckFor64BitProcessor
:CIMI64B_ProcessorIs64Bit
set MACHINE_IS_64BIT=1
:CIMI64B_AfterCheckFor64BitProcessor

goto :CIMI64B_Done
if not defined CIMI64B_DEBUG  goto :CIMI64B_Done
if     defined MACHINE_IS_64BIT  call :Log %0: Platform is 64bit
if not defined MACHINE_IS_64BIT  call :Log %0: Platform is NOT 64bit
:CIMI64B_Done
goto :EOF

