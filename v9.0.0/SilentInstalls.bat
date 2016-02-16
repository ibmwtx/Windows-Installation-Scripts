@echo off
setlocal
set > %TEMP%\%~n0_env1.txt
rem ===============================================================================
set FILE_REV=20151023
rem ===============================================================================
rem SilentInstalls.bat: Used to install the IBM WebSphere Transformation Extender
rem                     products.
rem
rem To generate the required response files, set TXINSTALLS_GENRESFILES=1.
rem This will run the specified installs interactively, allowing you to customize
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

if     defined TXINSTALLS_ROOTDIR         set LOCAL_ROOTDIR=%TXINSTALLS_ROOTDIR%
if not defined TXINSTALLS_ROOTDIR         set LOCAL_ROOTDIR=I:

if     defined TXINSTALLS_ROOTDIR_ALT     set LOCAL_ROOTDIR_ALT=%TXINSTALLS_ROOTDIR_ALT%
if not defined TXINSTALLS_ROOTDIR_ALT     set LOCAL_ROOTDIR_ALT=

if     defined TXINSTALLS_CURBLDNUM       set LOCAL_CURBLDNUM=%TXINSTALLS_CURBLDNUM%
if not defined TXINSTALLS_CURBLDNUM       set LOCAL_CURBLDNUM=

if     defined TXINSTALLS_INTERIMFIX      set LOCAL_INTERIMFIX=%TXINSTALLS_INTERIMFIX%
if not defined TXINSTALLS_INTERIMFIX      set LOCAL_INTERIMFIX=

set GENERATE_RESPONSEFILES=
if     defined TXINSTALLS_GENRESFILES     set GENERATE_RESPONSEFILES=1

if     defined TXINSTALLS_GENFILELIST     set FILELIST_PREFIX=%~n0_FileList
if not defined TXINSTALLS_GENFILELIST     set FILELIST_PREFIX=

if     defined TXINSTALLS_RESPONSEDIR     set RESPONSEDIR=%TXINSTALLS_RESPONSEDIR%
if not defined TXINSTALLS_RESPONSEDIR     set RESPONSEDIR=%CD%\Responses
if exist "%RESPONSEDIR%\%LOCAL_VRMFNUM%"  set RESPONSEDIR=%RESPONSEDIR%\%LOCAL_VRMFNUM%
if exist "%RESPONSEDIR%\%MAJOR_VER%"      set RESPONSEDIR=%RESPONSEDIR%\%MAJOR_VER%

if     defined TXINSTALLS_RESULTDIR       set RESULTDIR=%TXINSTALLS_RESULTDIR%
if not defined TXINSTALLS_RESULTDIR       set RESULTDIR=%CD%\Logs\%MAJOR_VER%

set MAKE_EXTRA_CLEAN=1
set MAKE_EXTRA_CLEAN_FILEEXT=
set MAKE_EXTRA_CLEAN_DIR=1
if defined TXINSTALLS_NOEXTRACLEAN  set MAKE_EXTRA_CLEAN=
if defined MAKE_EXTRA_CLEAN         goto :AfterSettingCleanFileExt
if defined TXINSTALLS_CLEANFILEEXT  set MAKE_EXTRA_CLEAN_FILEEXT=1
:AfterSettingCleanFileExt
if defined TXINSTALLS_NOEXTRACLEAN_DIR  set MAKE_EXTRA_CLEAN_DIR=

set SKIP_REMAINING_INSTALLS=

set TXINSTALLS_DEBUG=


if ("%MAJOR_VER%") equ ("9.0.0")  goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.5.0")  goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.5")    goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.4.1")  goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.4.0")  goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.4")    goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.3")    goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.2")    goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.1")    goto :AfterCheckMajorVer
if ("%MAJOR_VER%") equ ("8.0")    goto :AfterCheckMajorVer
goto :Error_MajorVerNotSupported
:AfterCheckMajorVer

if not exist "%RESULTDIR%" mkdir "%RESULTDIR%"

set RESULTDIR_SHORT=%RESULTDIR: =%
if /i ("%RESULTDIR%") equ ("%RESULTDIR_SHORT%") goto :AfterRemoveSpacesInResultDir
for /f "usebackq" %%a in ('echo "%RESULTDIR%"') do set RESULTDIR_SHORT=%%~fsa
if ("%RESULTDIR_SHORT:~-1%") equ ("\") set RESULTDIR_SHORT=%RESULTDIR_SHORT:~0,-1%
:AfterRemoveSpacesInResultDir

set TMPOUTFILE=%RESULTDIR_SHORT%\tmp%~n0.txt
set TMPOUTFILE2=%RESULTDIR_SHORT%\tmp%~n0_2.txt
set REG_QUERY_OUTFILE=%RESULTDIR_SHORT%\tmp%~n0_regout.txt

call :SetTimeStamp
set LOGFILE=%RESULTDIR%\%TIMESTAMP%.txt

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

rem ==================================================
rem Determine if there's a batch file to run on this
rem machine to initialize anything.  If so, run it.
rem Need to do this after LOGFILE has been defined,
rem but before we try to access the installs (in case
rem the batch file is for mapping network drives.)
rem ==================================================

if not defined   TXINSTALLS_RUNFIRST    goto :AfterAutoRunFirst
if not exist   "%TXINSTALLS_RUNFIRST%"  goto :ARF_NotFound

set LOG_VERBOSE_RETCODE=1
set LOG_CMD=call "%TXINSTALLS_RUNFIRST%"
call :Log
call :Log
set LOG_VERBOSE_RETCODE=
goto :AfterAutoRunFirst

:ARF_NotFound
call :Log ===
call :Log === %0: Warning: Batch file not found: TXINSTALLS_RUNFIRST="%TXINSTALLS_RUNFIRST%"
call :Log ===
goto :AfterAutoRunFirst

:AfterAutoRunFirst

rem ==================================================
rem Define the names of the installs, ESD images and
rem menu entries in the Start -> Program menu.
rem Also define where the installs can be found:
rem - LOCAL_BASEINSTALLDIR: IS55 "legacy" installs.
rem   Starting with v8.4, these are below legacy dir
rem - LOCAL_BASEINSTALLDIR_32: IS2011 32bit installs
rem - LOCAL_BASEINSTALLDIR_64: IS2011 64bit installs
rem ==================================================

call :SetInstallAndMenuNames

set LOCAL_BASEINSTALLDIR=
set LOCAL_BASEINSTALLDIR_32=
set LOCAL_BASEINSTALLDIR_64=

if not defined INSTALLS_TOAPPLY_CORE      goto :AfterCheckDefinedBaseInstallDir
if not defined TXINSTALLS_BASEINSTALLDIR  goto :DetermineBaseInstallDir
set LOCAL_BASEINSTALLDIR=%TXINSTALLS_BASEINSTALLDIR:"=%
goto :CheckBaseInstDirForLegacy
:DetermineBaseInstallDir
if not defined LOCAL_ROOTDIR       goto :Error_MissingEnvVars
if not exist "%LOCAL_ROOTDIR%"     goto :Error_RootDirDoesNotExist
if not defined LOCAL_VRMFNUM       goto :Error_MissingEnvVars
if not defined LOCAL_CURBLDNUM     goto :Error_MissingEnvVars
set LOCAL_BASEINSTALLDIR=%LOCAL_ROOTDIR%\%LOCAL_VRMFNUM%.%LOCAL_CURBLDNUM%
:CheckBaseInstDirForLegacy
if exist "%LOCAL_BASEINSTALLDIR%\Release\windows"  set LOCAL_BASEINSTALLDIR=%LOCAL_BASEINSTALLDIR%\Release\windows
if /i ("%MAJOR_VER%") lss ("8.4")  goto :AfterCheckDefinedBaseInstallDir
if exist "%LOCAL_BASEINSTALLDIR%\legacy"           set LOCAL_BASEINSTALLDIR=%LOCAL_BASEINSTALLDIR%\legacy
:AfterCheckDefinedBaseInstallDir

if not defined INSTALLS_TOAPPLY_CORE_32   goto :AfterCheckDefinedBaseInstallDir_32
if not defined TXINSTALLS_BASEINSTALLDIR  goto :DetermineBaseInstallDir_32
set LOCAL_BASEINSTALLDIR_32=%TXINSTALLS_BASEINSTALLDIR:"=%
goto :CheckBaseInstDirFor32
:DetermineBaseInstallDir_32
if not defined LOCAL_ROOTDIR       goto :Error_MissingEnvVars
if not exist "%LOCAL_ROOTDIR%"     goto :Error_RootDirDoesNotExist
if not defined LOCAL_VRMFNUM       goto :Error_MissingEnvVars
if not defined LOCAL_CURBLDNUM     goto :Error_MissingEnvVars
set LOCAL_BASEINSTALLDIR_32=%LOCAL_ROOTDIR%\%LOCAL_VRMFNUM%.%LOCAL_CURBLDNUM%
:CheckBaseInstDirFor32
if exist "%LOCAL_BASEINSTALLDIR_32%\Release\windows"  set LOCAL_BASEINSTALLDIR_32=%LOCAL_BASEINSTALLDIR_32%\Release\windows
if exist "%LOCAL_BASEINSTALLDIR_32%\32"               set LOCAL_BASEINSTALLDIR_32=%LOCAL_BASEINSTALLDIR_32%\32
:AfterCheckDefinedBaseInstallDir_32

if not defined INSTALLS_TOAPPLY_CORE_64   goto :AfterCheckDefinedBaseInstallDir_64
if not defined TXINSTALLS_BASEINSTALLDIR  goto :DetermineBaseInstallDir_64
set LOCAL_BASEINSTALLDIR_64=%TXINSTALLS_BASEINSTALLDIR:"=%
goto :CheckBaseInstDirFor64
:DetermineBaseInstallDir_64
if not defined LOCAL_ROOTDIR       goto :Error_MissingEnvVars
if not exist "%LOCAL_ROOTDIR%"     goto :Error_RootDirDoesNotExist
if not defined LOCAL_VRMFNUM       goto :Error_MissingEnvVars
if not defined LOCAL_CURBLDNUM     goto :Error_MissingEnvVars
set LOCAL_BASEINSTALLDIR_64=%LOCAL_ROOTDIR%\%LOCAL_VRMFNUM%.%LOCAL_CURBLDNUM%
:CheckBaseInstDirFor64
if exist "%LOCAL_BASEINSTALLDIR_64%\Release\windows"  set LOCAL_BASEINSTALLDIR_64=%LOCAL_BASEINSTALLDIR_64%\Release\windows
if exist "%LOCAL_BASEINSTALLDIR_64%\64"               set LOCAL_BASEINSTALLDIR_64=%LOCAL_BASEINSTALLDIR_64%\64
:AfterCheckDefinedBaseInstallDir_64

call :CheckIfVRMFUsesIF

if defined INSTALLS_TOAPPLY_CORE        goto :AfterCheckThatSomethingGetsInstalled
if defined INSTALLS_TOAPPLY_CORE_32     goto :AfterCheckThatSomethingGetsInstalled
if defined INSTALLS_TOAPPLY_CORE_64     goto :AfterCheckThatSomethingGetsInstalled
if defined INSTALLS_TOAPPLY_INTERIMFIX  goto :AfterCheckThatSomethingGetsInstalled
goto :Error_NoInstallsToApply
:AfterCheckThatSomethingGetsInstalled

call :SetDTXHome
call :SetSleepCmd


call :Log
call :Log ===
call :Log === %0 (v%FILE_REV%): Start: %date% %time%: MAJOR_VER=%MAJOR_VER% (!Done:)
if defined GENERATE_RESPONSEFILES  call :Log ===    *** Generating response files ***
if defined MACHINE_IS_64BIT        call :Log ===    64bit Windows detected
call :Log ===    Run on %COMPUTERNAME% as %USERDOMAIN%\%USERNAME%
call :Log ===    OS Version: %OSVERSION%
call :Log ===    Memory: Physical [Total=%WIN_MEM_PHYSICAL% Free=%WIN_MEM_PHYSICAL_FREE%]  Virtual [Total=%WIN_MEM_VIRTUAL% Free=%WIN_MEM_VIRTUAL_FREE%)]
call :Log ===    Current directory: %CD%
if     defined DTXHOME       call :Log ===    DTXHOME currently set to: "%DTXHOME%"
if not defined DTXHOME       call :Log ===    DTXHOME is undefined
if     defined DTXVER        call :Log ===    DTXVER currently installed:  "%DTXVER%"
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
if not defined MAKE_EXTRA_CLEAN_FILEEXT goto :AfterCautionMECFE
call :Log ===    CAUTION!  MAKE_EXTRA_CLEAN_FILEEXT defined - This will delete TX file extension registry entries
call :Log ===
:AfterCautionMECFE
if not defined MAKE_EXTRA_CLEAN_DIR goto :AfterCautionMECD
call :Log ===    CAUTION!  MAKE_EXTRA_CLEAN_DIR defined - This will delete the TX install directory if it exists!
call :Log ===
:AfterCautionMECD

call :Log === User-specified variables:
if     defined TXINSTALLS_ROOTDIR               call :Log ===    TXINSTALLS_ROOTDIR="%TXINSTALLS_ROOTDIR%"
if not defined TXINSTALLS_ROOTDIR               call :Log ===    TXINSTALLS_ROOTDIR not defined
if     defined TXINSTALLS_ROOTDIR_ALT           call :Log ===    TXINSTALLS_ROOTDIR_ALT="%TXINSTALLS_ROOTDIR_ALT%"
if not defined TXINSTALLS_ROOTDIR_ALT           call :Log ===    TXINSTALLS_ROOTDIR_ALT not defined
if     defined TXINSTALLS_VRMFNUM               call :Log ===    TXINSTALLS_VRMFNUM="%TXINSTALLS_VRMFNUM%"
if not defined TXINSTALLS_VRMFNUM               call :Log ===    TXINSTALLS_VRMFNUM not defined
if     defined TXINSTALLS_CURBLDNUM             call :Log ===    TXINSTALLS_CURBLDNUM="%TXINSTALLS_CURBLDNUM%"
if not defined TXINSTALLS_CURBLDNUM             call :Log ===    TXINSTALLS_CURBLDNUM not defined
if     defined TXINSTALLS_BASEINSTALLDIR        call :Log ===    TXINSTALLS_BASEINSTALLDIR="%TXINSTALLS_BASEINSTALLDIR%"
if not defined TXINSTALLS_BASEINSTALLDIR        call :Log ===    TXINSTALLS_BASEINSTALLDIR not defined
if     defined TXINSTALLS_CORE                  call :Log ===    TXINSTALLS_CORE="%TXINSTALLS_CORE%"
if not defined TXINSTALLS_CORE                  call :Log ===    TXINSTALLS_CORE not defined
if     defined TXINSTALLS_CORE_32               call :Log ===    TXINSTALLS_CORE_32="%TXINSTALLS_CORE_32%"
if not defined TXINSTALLS_CORE_32               call :Log ===    TXINSTALLS_CORE_32 not defined
if     defined TXINSTALLS_CORE_64               call :Log ===    TXINSTALLS_CORE_64="%TXINSTALLS_CORE_64%"
if not defined TXINSTALLS_CORE_64               call :Log ===    TXINSTALLS_CORE_64 not defined
if     defined TXINSTALLS_INTERIMFIX            call :Log ===    TXINSTALLS_INTERIMFIX="%TXINSTALLS_INTERIMFIX%"
if not defined TXINSTALLS_INTERIMFIX            call :Log ===    TXINSTALLS_INTERIMFIX not defined
if     defined TXINSTALLS_INTERIMFIX_CURBLDNUM  call :Log ===    TXINSTALLS_INTERIMFIX_CURBLDNUM="%TXINSTALLS_INTERIMFIX_CURBLDNUM%"
if not defined TXINSTALLS_INTERIMFIX_CURBLDNUM  call :Log ===    TXINSTALLS_INTERIMFIX_CURBLDNUM not defined
if     defined TXINSTALLS_IGNORE_FAILURES       call :Log ===    TXINSTALLS_IGNORE_FAILURES="%TXINSTALLS_IGNORE_FAILURES%"
if not defined TXINSTALLS_IGNORE_FAILURES       call :Log ===    TXINSTALLS_IGNORE_FAILURES not defined
if     defined TXINSTALLS_GENRESFILES           call :Log ===    TXINSTALLS_GENRESFILES="%TXINSTALLS_GENRESFILES%"
if not defined TXINSTALLS_GENRESFILES           call :Log ===    TXINSTALLS_GENRESFILES not defined
if     defined TXINSTALLS_RESPONSEDIR           call :Log ===    TXINSTALLS_RESPONSEDIR="%TXINSTALLS_RESPONSEDIR%"
if not defined TXINSTALLS_RESPONSEDIR           call :Log ===    TXINSTALLS_RESPONSEDIR not defined
if     defined TXINSTALLS_RESULTDIR             call :Log ===    TXINSTALLS_RESULTDIR="%TXINSTALLS_RESULTDIR%"
if not defined TXINSTALLS_RESULTDIR             call :Log ===    TXINSTALLS_RESULTDIR not defined
if     defined TXINSTALLS_GENFILELIST           call :Log ===    TXINSTALLS_GENFILELIST="%TXINSTALLS_GENFILELIST%"
if not defined TXINSTALLS_GENFILELIST           call :Log ===    TXINSTALLS_GENFILELIST not defined
if     defined TXINSTALLS_NOEXTRACLEAN          call :Log ===    TXINSTALLS_NOEXTRACLEAN="%TXINSTALLS_NOEXTRACLEAN%"
if not defined TXINSTALLS_NOEXTRACLEAN          call :Log ===    TXINSTALLS_NOEXTRACLEAN not defined
if     defined TXINSTALLS_CLEANFILEEXT          call :Log ===    TXINSTALLS_CLEANFILEEXT="%TXINSTALLS_CLEANFILEEXT%"
if not defined TXINSTALLS_CLEANFILEEXT          call :Log ===    TXINSTALLS_CLEANFILEEXT not defined
if     defined TXINSTALLS_NOEXTRACLEAN_DIR      call :Log ===    TXINSTALLS_NOEXTRACLEAN_DIR="%TXINSTALLS_NOEXTRACLEAN_DIR%"
if not defined TXINSTALLS_NOEXTRACLEAN_DIR      call :Log ===    TXINSTALLS_NOEXTRACLEAN_DIR not defined
if     defined TXINSTALLS_NOENABLEGPFS          call :Log ===    TXINSTALLS_NOENABLEGPFS="%TXINSTALLS_NOENABLEGPFS%"
if not defined TXINSTALLS_NOENABLEGPFS          call :Log ===    TXINSTALLS_NOENABLEGPFS not defined
if     defined TXINSTALLS_RUNFIRST              call :Log ===    TXINSTALLS_RUNFIRST="%TXINSTALLS_RUNFIRST%"
if not defined TXINSTALLS_RUNFIRST              call :Log ===    TXINSTALLS_RUNFIRST not defined
if     defined TXINSTALLS_USE_VR_FOR_MAJOR_VER  call :Log ===    TXINSTALLS_USE_VR_FOR_MAJOR_VER="%TXINSTALLS_USE_VR_FOR_MAJOR_VER%"
if not defined TXINSTALLS_USE_VR_FOR_MAJOR_VER  call :Log ===    TXINSTALLS_USE_VR_FOR_MAJOR_VER not defined
if     defined TXINSTALLS_NOPROMPT              call :Log ===    TXINSTALLS_NOPROMPT="%TXINSTALLS_NOPROMPT%"
if not defined TXINSTALLS_NOPROMPT              call :Log ===    TXINSTALLS_NOPROMPT not defined

call :Log === Values resulting from user-specified variables:
if     defined LOCAL_BASEINSTALLDIR             call :Log ===    LOCAL_BASEINSTALLDIR="%LOCAL_BASEINSTALLDIR%"
if not defined LOCAL_BASEINSTALLDIR             call :Log ===    LOCAL_BASEINSTALLDIR not defined
if     defined LOCAL_BASEINSTALLDIR_32          call :Log ===    LOCAL_BASEINSTALLDIR_32="%LOCAL_BASEINSTALLDIR_32%"
if not defined LOCAL_BASEINSTALLDIR_32          call :Log ===    LOCAL_BASEINSTALLDIR_32 not defined
if     defined LOCAL_BASEINSTALLDIR_64          call :Log ===    LOCAL_BASEINSTALLDIR_64="%LOCAL_BASEINSTALLDIR_64%"
if not defined LOCAL_BASEINSTALLDIR_64          call :Log ===    LOCAL_BASEINSTALLDIR_64 not defined
if     defined LOCAL_INTERIMFIX                 call :Log ===    LOCAL_INTERIMFIX="%LOCAL_INTERIMFIX%"
if not defined LOCAL_INTERIMFIX                 call :Log ===    LOCAL_INTERIMFIX not defined
if     defined INSTALLS_TOAPPLY_CORE            call :Log ===    INSTALLS_TOAPPLY_CORE="%INSTALLS_TOAPPLY_CORE%"
if not defined INSTALLS_TOAPPLY_CORE            call :Log ===    INSTALLS_TOAPPLY_CORE shows no core installs to apply
if     defined INSTALLS_TOAPPLY_INTERIMFIX      call :Log ===    INSTALLS_TOAPPLY_INTERIMFIX="%INSTALLS_TOAPPLY_INTERIMFIX%"
if not defined INSTALLS_TOAPPLY_INTERIMFIX      call :Log ===    INSTALLS_TOAPPLY_INTERIMFIX shows no InterimFix installs to apply

if not defined INSTALLS_TOAPPLY_INTERIMFIX goto :AfterDisplayIFLocations
for %%a in (%INSTALLS_TOAPPLY_INTERIMFIX%) do call :GetInterimFixInfo %%a
:AfterDisplayIFLocations
call :Log

rem ========================================
rem Make sure these directories exist and
rem are actually directories, not files.
rem ========================================

if not defined LOCAL_BASEINSTALLDIR   goto :AfterCheckLocalBaseDir
if not exist "%LOCAL_BASEINSTALLDIR%" goto :Error_MissingLocalBaseInstallDir
pushd "%LOCAL_BASEINSTALLDIR%" > nul 2>&1
if ERRORLEVEL 1                       goto :Error_MissingLocalBaseInstallDir
popd
:AfterCheckLocalBaseDir

if not defined LOCAL_BASEINSTALLDIR_32   goto :AfterCheckLocalBaseDir_32
if not exist "%LOCAL_BASEINSTALLDIR_32%" goto :Error_MissingLocalBaseInstallDir_32
pushd "%LOCAL_BASEINSTALLDIR_32%" > nul 2>&1
if ERRORLEVEL 1                       goto :Error_MissingLocalBaseInstallDir_32
popd
:AfterCheckLocalBaseDir_32

if not defined LOCAL_BASEINSTALLDIR_64   goto :AfterCheckLocalBaseDir_64
if not exist "%LOCAL_BASEINSTALLDIR_64%" goto :Error_MissingLocalBaseInstallDir_64
pushd "%LOCAL_BASEINSTALLDIR_64%" > nul 2>&1
if ERRORLEVEL 1                       goto :Error_MissingLocalBaseInstallDir_64
popd
:AfterCheckLocalBaseDir_64

if exist "%RESPONSEDIR%"            goto :AfterCheckResponseDirExists
if defined GENERATE_RESPONSEFILES   mkdir "%RESPONSEDIR%"
if not exist "%RESPONSEDIR%"        goto :Error_MissingResponseDir
:AfterCheckResponseDirExists
pushd "%RESPONSEDIR%" > nul 2>&1
if ERRORLEVEL 1                     goto :Error_MissingResponseDir
popd

set > %TEMP%\%~n0_env2.txt

if defined TXINSTALLS_NOPROMPT goto :AfterPause
pause
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
rem TODO:
rem - Add support for using WMB with WTX
rem   versions prior to WTX v8.2.
rem - Determine how we can tell if WMB is
rem   already stopped so that we don't try
rem   to start it if we didn't stop it.
rem - If "uninstall" stops WMB, does it make
rem   sense for it to start it again when it's
rem   done uninstalling so that we leave WMB
rem   in the same "running" state as when the
rem   uninstall started.  Or does it not make
rem   sense to run it without WTX installed?
rem - Should we get "uninstall" and "install"
rem   working together so that "uninstall" will
rem   do the stop, and leave a signal file
rem   telling "install" to start once it's
rem   done? (IFF it installs TX for IS???)
rem ========================================

call :IntServ_Initialize
call :IntServ_DisableIfRunning

rem ========================================
rem 07/13/2011: Check to see if we need to
rem put the user session into "install" mode.
rem ========================================

set TERMSERV_USERMODE=
change /? > NUL 2>&1
if ERRORLEVEL 9009  goto :TermServ_AfterInitialQuery
for /f "tokens=2" %%a in ('change user /query') do set TERMSERV_USERMODE=%%a
call :Log
call :Log === Current user session mode is "%TERMSERV_USERMODE%"
if /i ("%TERMSERV_USERMODE%") neq ("EXECUTE") set TERMSERV_USERMODE=
if not defined TERMSERV_USERMODE  goto :TermServ_AfterInitialQuery
call :Log === Putting user session into INSTALL mode...
set LOG_CMD=change user /install
call :Log
:TermServ_AfterInitialQuery

rem ========================================
rem Installs for Windows platform.
rem If requested, generate list of files
rem below DTXHOME.
rem
rem if MAKE_EXTRA_CLEAN is defined, call
rem :MakeExtraClean to put the machine
rem into a "known" state so we know what
rem prompts will be displayed during the
rem installs.  If it is not defined, check
rem if MAKE_EXTRA_CLEAN_FILEEXT is defined.
rem If so, call :DeleteTXFileExtensions to
rem clear out the WTX file extensions in
rem order to avoid needing multiple sets of
rem response files.  If neither variable is
rem defined, it facilitates adding new WTX
rem products (other than Design Studio due
rem to our predefined response files) to
rem existing WTX installs.
rem
rem Notes:
rem - Wait till after all the other core
rem   installs are done before installing the
rem   Online Library, due to the variable
rem   components that only get installed if
rem   certain prereq pieces are present.
rem   States for SHOULD_INSTALL_ONLINE_LIB:
rem   - <Undefined>: Do not install OL
rem   - ESDNAME INSTALL_TYPE: Env var holds the
rem     ESD image name of the library install to
rem     use as well as the INSTALL_TYPE that
rem     goes with it.
rem   - NOW: Install the OL now
rem - The TX for Integration Servers install
rem   should only be attempted if an appropriate
rem   integration server (such as WebSphere
rem   Message Broker) is present on the machine
rem   or a response file is used that expects
rem   that the install prereqs will not be met.
rem ========================================

@rem set TXINSTALLS_DEBUG=1

if defined LOCAL_BASEINSTALLDIR     goto :AfterCheckForBaseInstallsDefined
if defined LOCAL_BASEINSTALLDIR_32  goto :AfterCheckForBaseInstallsDefined
if defined LOCAL_BASEINSTALLDIR_64  goto :AfterCheckForBaseInstallsDefined
goto :AfterBaseInstalls
:AfterCheckForBaseInstallsDefined

if defined MAKE_EXTRA_CLEAN          call :MakeExtraClean
if defined MAKE_EXTRA_CLEAN          goto :AfterMakeExtraClean
if defined MAKE_EXTRA_CLEAN_FILEEXT  call :DeleteTXFileExtensions
:AfterMakeExtraClean

if defined MAKE_EXTRA_CLEAN_DIR  call :MakeExtraCleanDir

set SHOULD_INSTALL_ONLINE_LIB=

set INSTALL_TYPE_IS55=legacy
set INSTALL_TYPE_IS2011_32BIT=32
set INSTALL_TYPE_IS2011_64BIT=64

if ("%MAJOR_VER%") geq ("8.4.1")  goto :AfterCheckForIS55Installs
set INSTALL_TYPE=%INSTALL_TYPE_IS55%
call :SetCurInstallDir
call :GetCurResponseDirForThisInstall
for %%a in (%INSTALLS_TOAPPLY_CORE%)    do call :ProcessCoreInstallRequest %%a
:AfterCheckForIS55Installs

if ("%MAJOR_VER%") geq ("8.5.0")  goto :AfterCheckForIS2011_32BitInstalls
set INSTALL_TYPE=%INSTALL_TYPE_IS2011_32BIT%
call :SetInstallAndMenuNames
call :SetCurInstallDir
call :GetCurResponseDirForThisInstall
for %%a in (%INSTALLS_TOAPPLY_CORE_32%) do call :ProcessCoreInstallRequest %%a
:AfterCheckForIS2011_32BitInstalls

set INSTALL_TYPE=%INSTALL_TYPE_IS2011_64BIT%
call :SetInstallAndMenuNames
call :SetCurInstallDir
call :GetCurResponseDirForThisInstall
for %%a in (%INSTALLS_TOAPPLY_CORE_64%) do call :ProcessCoreInstallRequest %%a

if not defined SHOULD_INSTALL_ONLINE_LIB  goto :AfterInstallOnlineLibrary
call :Log === Processing SHOULD_INSTALL_ONLINE_LIB="%SHOULD_INSTALL_ONLINE_LIB%"
set INSTALL_TYPE=
for /f "tokens=1" %%a in ("%SHOULD_INSTALL_ONLINE_LIB%") do set ESD_INSTNAME_LIBRARY=%%a
for /f "tokens=2" %%a in ("%SHOULD_INSTALL_ONLINE_LIB%") do set INSTALL_TYPE=%%a
call :SetInstallAndMenuNames
call :SetCurInstallDir
call :GetCurResponseDirForThisInstall
set SHOULD_INSTALL_ONLINE_LIB=NOW
call :ProcessCoreInstallRequest %ESD_INSTNAME_LIBRARY%
:AfterInstallOnlineLibrary

if not defined TXINSTALLS_GENFILELIST  goto :AfterBaseInstalls
call :SetDTXHome
if defined DTXHOME  goto :GenListOfFiles_AfterCheckDTXHOME
call :Log ===
call :Log === %0: Warning: Cannot determine DTXHOME for generating list of files installed.
call :Log ===
goto :AfterBaseInstalls
:GenListOfFiles_AfterCheckDTXHOME
call :Log ===
call :Log === Generating list of files installed below DTXHOME="%DTXHOME%"
call :Log ===
set FILELIST_BRIEF=%FILELIST_PREFIX%.txt
set FILELIST_DETAILS=%FILELIST_PREFIX%_Detailed.txt
if exist "%DTXHOME%\%FILELIST_BRIEF%"    del /f /q "%DTXHOME%\%FILELIST_BRIEF%"
if exist "%DTXHOME%\%FILELIST_DETAILS%"  del /f /q "%DTXHOME%\%FILELIST_DETAILS%"
dir /s/on/b "%DTXHOME%" > "%TEMP%\%FILELIST_BRIEF%"   2>&1
dir /s/on   "%DTXHOME%" > "%TEMP%\%FILELIST_DETAILS%" 2>&1
copy /y "%TEMP%\%FILELIST_BRIEF%"   "%DTXHOME%\%FILELIST_BRIEF%"   > NUL 2>&1
copy /y "%TEMP%\%FILELIST_DETAILS%" "%DTXHOME%\%FILELIST_DETAILS%" > NUL 2>&1
set LOG_CMD=dir /od "%DTXHOME%\%FILELIST_PREFIX%*"
call :Log
call :Log
set FILELIST_BRIEF=
set FILELIST_DETAILS=

:AfterBaseInstalls

rem ========================================
rem If specified, apply any interim fix.
rem If requested, generate list of files
rem below DTXHOME.
rem ========================================

if not defined INSTALLS_TOAPPLY_INTERIMFIX goto :AfterInterimFix

for %%a in (%INSTALLS_TOAPPLY_INTERIMFIX%) do call :InstallInterimFixLevel %%a

if not defined TXINSTALLS_GENFILELIST  goto :AfterInterimFix
call :SetDTXHome
if defined DTXHOME  goto :GenListOfFilesAfterIF_AfterCheckDTXHOME
call :Log ===
call :Log === %0: Warning: Cannot determine DTXHOME for generating list of InterimFix files installed.
call :Log ===
goto :AfterInterimFix
:GenListOfFilesAfterIF_AfterCheckDTXHOME
call :Log ===
call :Log === Generating list of files installed below DTXHOME="%DTXHOME%" after InterimFix
call :Log ===
set FILELIST_BRIEF=%FILELIST_PREFIX%_InterimFix.txt
set FILELIST_DETAILS=%FILELIST_PREFIX%_Detailed_InterimFix.txt
if exist "%DTXHOME%\%FILELIST_BRIEF%"    del /f /q "%DTXHOME%\%FILELIST_BRIEF%"
if exist "%DTXHOME%\%FILELIST_DETAILS%"  del /f /q "%DTXHOME%\%FILELIST_DETAILS%"
dir /s/on/b "%DTXHOME%" > "%TEMP%\%FILELIST_BRIEF%"   2>&1
dir /s/on   "%DTXHOME%" > "%TEMP%\%FILELIST_DETAILS%" 2>&1
copy /y "%TEMP%\%FILELIST_BRIEF%"   "%DTXHOME%\%FILELIST_BRIEF%"   > NUL 2>&1
copy /y "%TEMP%\%FILELIST_DETAILS%" "%DTXHOME%\%FILELIST_DETAILS%" > NUL 2>&1
set LOG_CMD=dir /od "%DTXHOME%\%FILELIST_PREFIX%*"
call :Log
call :Log
set FILELIST_BRIEF=
set FILELIST_DETAILS=

:AfterInterimFix

if defined TXINSTALLS_NOENABLEGPFS goto :AfterEnableGPFs
call :DtxIni_EnableIgnoreGPFs
:AfterEnableGPFs

call :CleanUpAfterInstallShield

rem ========================================
rem 07/13/2011: Check to see if we need to
rem put the user session back into "execute"
rem mode.
rem ========================================

if not defined TERMSERV_USERMODE  goto :TermServ_AfterResetMode
call :Log === Putting user session back into EXECUTE mode...
set LOG_CMD=change user /execute
call :Log
:TermServ_AfterResetMode

rem =========================================
rem Reenable WMB if we stopped it.
rem =========================================

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

:Error_MajorVerNotSupported
call :Log ===
call :Log === %0: ERROR: MAJOR_VER=%MAJOR_VER% is not supported.
call :Log ===
goto :Usage

:Error_VRMFUndefined
call :Log ===
call :Log === %0: ERROR: TXINSTALLS_VRMFNUM not defined
call :Log ===
goto :Usage

:Error_RootDirDoesNotExist
call :Log ===
call :Log === %0: ERROR: "%LOCAL_ROOTDIR%" does not exist (drive mapping problem?)
call :Log ===
goto :Usage

:Error_MissingLocalBaseInstallDir
call :Log ===
call :Log === %0: ERROR: Missing install dir "%LOCAL_BASEINSTALLDIR%"
call :Log ===
goto :Usage

:Error_MissingLocalBaseInstallDir_32
call :Log ===
call :Log === %0: ERROR: Missing install dir "%LOCAL_BASEINSTALLDIR_32%"
call :Log ===
goto :Usage

:Error_MissingLocalBaseInstallDir_64
call :Log ===
call :Log === %0: ERROR: Missing install dir "%LOCAL_BASEINSTALLDIR_64%"
call :Log ===
goto :Usage

:Error_MissingResponseDir
call :Log ===
call :Log === %0: ERROR: Missing response dir "%RESPONSEDIR%"
call :Log ===
goto :Usage

:Error_MissingEnvVars
call :Log ===
call :Log === %0: ERROR: Missing required environment settings.
call :Log ===
goto :Usage

:Error_NoInstallsToApply
call :Log ===
call :Log === %0: ERROR: Missing list of installs to apply.
call :Log ===
goto :Usage

:Usage
call :Log
call :Log Variables used to control the installation:
call :Log
call :Log TXINSTALLS_ROOTDIR: Root directory to the installs.  Example: I: -OR- V:\Installs
call :Log TXINSTALLS_VRMFNUM: Version.Release.Maintenance.FixLevel number.  Example: 8.2.0.0
call :Log TXINSTALLS_CURBLDNUM: Current build number.  Example: 145
call :Log TXINSTALLS_CORE: IS55 core installs to run.  Uses prefix to ESD image names, "none" for none.  Example: design txlnch
call :Log TXINSTALLS_CORE_32: IS2011 32Bit core installs to run.  Uses prefix to ESD image names, "none" for none.  Example: wsdtxds wsdtxol
call :Log TXINSTALLS_CORE_64: IS2011 64Bit core installs to run.  Uses prefix to ESD image names, "none" for none.  Example: wsdtxcs wsdtxl
call :Log TXINSTALLS_INTERIMFIX: InterimFix installs to run, "none" for none.  Example: 01 02 03
call :Log TXINSTALLS_INTERIMFIX_CURBLDNUM: Current build number of InterimFix install.  Example: 184
call :Log
call :Log Optional: TXINSTALLS_BASEINSTALLDIR: Path to installs to use.  Example: I:\8.2.0.0.183
call :Log    Use TXINSTALLS_BASEINSTALLDIR to override default location of TXINSTALLS_ROOTDIR\TXINSTALLS_VRMFNUM.TXINSTALLS_CURBLDNUM
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

call :Log ===
call :Log === %0 (v%FILE_REV%): Done:  %date% %time%: FinalStatus - %FINAL_STATUS%
call :Log ===

if exist %TMPOUTFILE%         del /f /q %TMPOUTFILE%
if exist %TMPOUTFILE2%        del /f /q %TMPOUTFILE2%
if exist %REG_QUERY_OUTFILE%  del /f /q %REG_QUERY_OUTFILE%

goto :EOF



:SetTimeStamp


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
:SPN_v83
:SPN_v82
:SPN_v81
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
rem
rem InterimFix: Update Here!
rem ===============================================================================

:CheckIfVRMFUsesIF

if ("%LOCAL_VRMFNUM%") equ ("8.2.0.4") goto :CIVRMFUIF_UsesIFInstalls
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.2") goto :CIVRMFUIF_UsesIFInstalls
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.0") goto :CIVRMFUIF_UsesIFInstalls
if ("%LOCAL_VRMFNUM%") equ ("8.1.0.5") goto :CIVRMFUIF_UsesIFInstalls
set LOCAL_INTERIMFIX=
goto :CIVRMFUIF_Done
:CIVRMFUIF_UsesIFInstalls
if defined LOCAL_INTERIMFIX  goto :CIVRMFUIF_UsesIFInstalls_IFDefined
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.4") set INSTALLS_TOAPPLY_INTERIMFIX=03
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.2") set INSTALLS_TOAPPLY_INTERIMFIX=01
if ("%LOCAL_VRMFNUM%") equ ("8.2.0.0") set INSTALLS_TOAPPLY_INTERIMFIX=01 02
if ("%LOCAL_VRMFNUM%") equ ("8.1.0.5") set INSTALLS_TOAPPLY_INTERIMFIX=02
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

set LNCHRAGNT_SRVNAME=%DEFAULT_LNCHRAGNT_SRVNAME%

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
if not defined REG_QUERY_VALUE goto :SMH_AfterDTXHomeReg
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
rem - Set name of Launcher Agent service
rem   using the Launcher Agent response file
rem ========================================

if not defined RESPONSEDIR goto :SMH_AfterSetValuesFromResponseFiles

set SMH_TMP_INPUTFILE=%RESPONSEDIR%\%ESD_INSTNAME_DESSTUD%.iss
if not exist %SMH_TMP_INPUTFILE%  goto :SMH_AfterDTXHomeResp
type %SMH_TMP_INPUTFILE% | "%SystemRoot%\system32\find.exe" "szDir" > %SMH_TMP_OUTPUTFILE%
if ERRORLEVEL 1  goto :SMH_AfterDTXHomeResp
for /f "tokens=1* delims== " %%i in ('type %SMH_TMP_OUTPUTFILE%') do set DTXHOME_RESP=%%j
:SMH_AfterDTXHomeResp

if ("%MAJOR_VER%") lss ("8.4")   goto :SMH_AfterDTXHome64Resp
if not defined MACHINE_IS_64BIT  goto :SMH_AfterDTXHome64Resp
if defined DTXHOME_RESP  set DTXHOME64_RESP=%DTXHOME_RESP%
:SMH_AfterDTXHome64Resp

set SMH_TMP_INPUTFILE=%RESPONSEDIR%\%ESD_INSTNAME_LNCHRAGNT%.iss
if not exist %SMH_TMP_INPUTFILE%  goto :SMH_AfterLAServiceName
type %SMH_TMP_INPUTFILE% | "%SystemRoot%\system32\find.exe" "szEdit1" > %SMH_TMP_OUTPUTFILE%
if ERRORLEVEL 1  goto :SMH_AfterLAServiceName
for /f "tokens=1-2 delims== " %%i in ('type %SMH_TMP_OUTPUTFILE%') do set LNCHRAGNT_SRVNAME=%%j
:SMH_AfterLAServiceName

:SMH_AfterSetValuesFromResponseFiles

rem ========================================
rem If DTXHOME is defined, try to determine
rem what version it is.  Save the value in
rem DTXVER.
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



:Log

if defined TXINSTALLS_DEBUG @echo off

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
goto :EOF



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

if not defined LNCHRAGNT_SRVNAME  set LNCHRAGNT_SRVNAME=%DEFAULT_LNCHRAGNT_SRVNAME%

if ("%MAJOR_VER%") equ ("8.5.0") goto :MEC_v85
if ("%MAJOR_VER%") equ ("8.5")   goto :MEC_v85
if ("%MAJOR_VER%") equ ("8.4.1") goto :MEC_v84
if ("%MAJOR_VER%") equ ("8.4.0") goto :MEC_v84
if ("%MAJOR_VER%") equ ("8.4")   goto :MEC_v84
if ("%MAJOR_VER%") equ ("8.3")   goto :MEC_v83
if ("%MAJOR_VER%") equ ("8.2")   goto :MEC_v82
if ("%MAJOR_VER%") equ ("8.1")   goto :MEC_v81
if ("%MAJOR_VER%") equ ("8.0")   goto :MEC_v80

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
rem
rem NOTE: This should be used with care!  If the user created files below their
rem       installation directory, those files will be deleted!
rem
rem Other adverse behavior may occur.  For instance, if the files left in the
rem directory are MMS/MTT files that get accessed with a "newer" version of TX
rem (i.e., v8.2.0.3), then that version of TX is uninstalled and an "older" version
rem of TX is installed (i.e., v8.2.0.2), the files left intact may not be
rem accessible by the "older" version of TX if fix-levels were applied by the
rem "newer" version.
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


rem ===============================================================================
rem :DeleteTXFileExtensions: Delete the file extensions associated with WTX.
rem Parameters:
rem Arg1: If 0, handle normal (32bit) registry locations for file extensions.
rem       If !0, handle 64bit registry locations.
rem ===============================================================================

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

rem ========================================
rem Don't delete DataPower extensions for
rem older releases.
rem ========================================

if ("%MAJOR_VER%") equ ("8.1")  goto :DTXFEBB_AfterDPA
if ("%MAJOR_VER%") equ ("8.0")  goto :DTXFEBB_AfterDPA

set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\.dpa
call :RegDeleteKey
set REG_DEL_KEYNAME=%DTXFEBB_HKCRKEY%\%FULL_PRODNAME%.dpa
call :RegDeleteKey

:DTXFEBB_AfterDPA
if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :DeleteTXMenuEntries: Delete the menus items associated with WTX.  We need to
rem delete just the entries we know about so that any others will still be there.
rem This is the case when we're not "cleaning" the entire directory in order to
rem leave behind previously installed components, such as IP's or other packs.
rem
rem Notes:
rem - SNMP  dropped from v8.3.0.1
rem - TXSDK dropped from v8.3.0.0
rem - MB    dropped from v8.2.0.2
rem ===============================================================================

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

if ("%MAJOR_VER%") equ ("8.5.0") goto :DTXME_v85
if ("%MAJOR_VER%") equ ("8.5")   goto :DTXME_v85
if ("%MAJOR_VER%") equ ("8.4.1") goto :DTXME_v84
if ("%MAJOR_VER%") equ ("8.4.0") goto :DTXME_v84
if ("%MAJOR_VER%") equ ("8.4")   goto :DTXME_v84
if ("%MAJOR_VER%") equ ("8.3")   goto :DTXME_v83
if ("%MAJOR_VER%") equ ("8.2")   goto :DTXME_v82
if ("%MAJOR_VER%") equ ("8.1")   goto :DTXME_v81
if ("%MAJOR_VER%") equ ("8.0")   goto :DTXME_v80

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


rem ===============================================================================
rem :RegQueryKey: Query the specified registry value or key.  Call using the
rem following environment variables:
rem
rem REG_QUERY_KEYNAME:   Key being referenced.
rem REG_QUERY_VALUENAME: Value below REG_QUERY_KEYNAME to query.  Possible values:
rem - Not defined => Query all values under REG_QUERY_KEYNAME
rem - @ => Query the value of empty value name <no name>
rem - Any other value => The value name, under the selected Key, to query.
rem
rem Returns:
rem REG_QUERY_VALUE: If REG_QUERY_VALUENAME is specified, this is set to the first
rem                  line of data returned from the query.
rem REG_QUERY_OUTFILE: All output returned from the query.  If the query failed,
rem                    this file will be deleted before returning to the user.
rem REG_QUERY_RETCODE: Return code from "reg query", or 1 if an error ocurred.
rem ===============================================================================

:RegQueryKey

set REG_QUERY_VALUE=
set REG_QUERY_RETCODE=1
set RQK_FINDSTR=

if defined REG_QUERY_KEYNAME goto :RQK_AfterCheckKeyDefined
call :Log %0: REG_QUERY_KEYNAME not defined (REG_QUERY_VALUENAME=%REG_QUERY_VALUENAME%).  Nothing done.
goto :RQK_Done
:RQK_AfterCheckKeyDefined

rem ========================================
rem Define the query.  If REG_QUERY_VALUENAME
rem is "@", we need to find "<NO NAME>" in
rem the output.
rem ========================================

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

rem ========================================
rem Run the query.  If REG_QUERY_VALUENAME
rem was specified, set REG_QUERY_VALUE to
rem the first line of output from the query.
rem The idea is to provide the caller with
rem the value they're looking for without
rem them doing extra work.
rem
rem Note: 64Bit Windows has whitespace
rem differences in the output from the query
rem that needs to be dealt with.
rem ========================================

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
rem ========================================
rem There's extra parsing required if
rem REG_QUERY_VALUENAME contains whitespace.
rem ========================================
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


rem ===============================================================================
rem :RegDeleteKey: Delete the specified registry value or key.  Call using the
rem following environment variables:
rem
rem REG_DEL_KEYNAME:   Key being referenced.
rem REG_DEL_VALUENAME: Value below REG_DEL_KEYNAME to delete.  Possible values:
rem - Not defined => Delete all values under REG_DEL_KEYNAME
rem - @ => Delete the value of empty value name <no name>
rem - Any other value => The value name, under the selected Key, to delete.
rem
rem ===============================================================================

:RegDeleteKey

if defined REG_DEL_KEYNAME goto :RDK_AfterCheckKeyDefined
call :Log %0: REG_DEL_KEYNAME not defined.  Nothing done.
goto :RDK_Done
:RDK_AfterCheckKeyDefined

rem ========================================
rem For debugging purposes, check if the
rem key exists.  This way, we will only say
rem that we're delete it if we need to.
rem ========================================

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


rem ===============================================================================
rem :IntServ_Initialize: Initialize the list of integration servers that may use,
rem or may be using, this version of WTX.
rem ===============================================================================

:IntServ_Initialize

set STATUS_UNKNOWN=0
set STATUS_NOTPRESENT=1
set STATUS_PRESENT=2
set STATUS_STOPPED=3
set STATUS_RUNNING=4

set INTSERV_STATUS_WMB=%STATUS_UNKNOWN%
call :WMB_Initialize

goto :EOF


rem ===============================================================================
rem :IntServ_DisplayStatus: Display the status of the integration server.
rem Arg1: Server to display status of
rem ===============================================================================

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


rem ===============================================================================
rem :IntServ_DisableIfRunning: Disable any integration servers that may potentially
rem use, or may currently be using, this version of WTX.
rem ===============================================================================

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


rem ===============================================================================
rem :IntServ_ReenableIfStopped: Reenable any integration servers that were
rem previously stopped when this version of WTX was installed.
rem ===============================================================================

:IntServ_ReenableIfStopped

rem ========================================
rem If WMB is present, the profile will have
rem already been defined and run.
rem If WMB was previously stopped, setup the
rem command to start it.
rem
rem that we're interested in.  Per George Blue
rem of the WMB team, we should stop the DbInstMgr:
rem last.  Other than this, the order should not
rem matter.  Since we're stopping the DbInstMgr:
rem last, we'll go with starting it first.
rem ========================================

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



:WMB_Initialize

set WMB_PROFILE=
set INTSERV_STATUS_WMB=%STATUS_NOTPRESENT%

if ("%MAJOR_VER%") equ ("8.1") goto :WMB_Init_Exit
if ("%MAJOR_VER%") equ ("8.0") goto :WMB_Init_Exit


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

set INSTNAME_CMDSRVR=TX with Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=
set INSTNAME_LNCHR=TX with Launcher
set INSTNAME_LNCHRAGNT=
set INSTNAME_LNCHRSTUD=Launcher Studio
set INSTNAME_SECURE=
set INSTNAME_TXAPI=TX for Application Programming
set INSTNAME_TXIS=TX for Integration Servers

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

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR:TX with =%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR:TX with =%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_TXAPI=%INSTNAME_TXAPI:TX for =%
set MENUNAME_TXIS=%INSTNAME_TXIS:TX for =%

set INSTALLS_DEFAULT_CORE=
set INSTALLS_DEFAULT_CORE_32=
set INSTALLS_DEFAULT_CORE_64=%ESD_INSTNAME_DESSTUD% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_TXAPI% %ESD_INSTNAME_TXIS%

goto :SIAMN_AfterSetNames

:SIAMN_v84

set INSTNAME_CMDSRVR=TX with Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=Online Library
set INSTNAME_LNCHR=TX with Launcher
set INSTNAME_LNCHRAGNT=Launcher Agent
set INSTNAME_LNCHRSTUD=Launcher Studio
set INSTNAME_SECURE=Secure Adapter Collection
set INSTNAME_TXAPI=TX for Application Programming
set INSTNAME_TXIS=TX for Integration Servers

if not defined INSTALL_TYPE                           goto :SIAMN_v84_ESD_IS55
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS55%")  goto :SIAMN_v84_ESD_IS55

:SIAMN_v84_ESD_IS2011
set ESD_INSTNAME_CMDSRVR=wsdtxcs
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%") set ESD_INSTNAME_DESSTUD=wsdtxds
if /i ("%INSTALL_TYPE%") neq ("%INSTALL_TYPE_IS2011_32BIT%") set ESD_INSTNAME_DESSTUD=
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
@REM set ESD_INSTNAME_INTERIMFIX=intfix%INTERIMFIXNUM% - Set by :GetInterimFixInfo

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR:TX with =%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR:TX with =%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_TXAPI=%INSTNAME_TXAPI:TX for =%
set MENUNAME_TXIS=%INSTNAME_TXIS:TX for =%

set INSTALLS_DEFAULT_CORE=
set INSTALLS_DEFAULT_CORE_32=%ESD_INSTNAME_DESSTUD%

if not defined MACHINE_IS_64BIT  set INSTALLS_DEFAULT_CORE_32=%INSTALLS_DEFAULT_CORE_32% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_TXAPI% %ESD_INSTNAME_TXIS%
if     defined MACHINE_IS_64BIT  set INSTALLS_DEFAULT_CORE_64=%ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_TXAPI% %ESD_INSTNAME_TXIS%

goto :SIAMN_AfterSetNames

:SIAMN_v83
:SIAMN_v82

set INSTNAME_CMDSRVR=TX with Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=Online Library
set INSTNAME_LNCHR=TX with Launcher
set INSTNAME_LNCHRAGNT=Launcher Agent
set INSTNAME_LNCHRSTUD=Launcher Studio
set INSTNAME_MB=TX for Message Broker
set INSTNAME_SECURE=Secure Adapter Collection
set INSTNAME_SNMP=SNMP Collection
set INSTNAME_TXAPI=TX for Application Programming
set INSTNAME_TXIS=TX for Integration Servers
set INSTNAME_TXSDK=TX SDK
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
@REM set ESD_INSTNAME_INTERIMFIX=intfix%INTERIMFIXNUM% - Set by :GetInterimFixInfo

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR:TX with =%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR:TX with =%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_MB=%INSTNAME_MB%
set MENUNAME_TXSDK=Transformation Extender SDK
set MENUNAME_SNMP=%INSTNAME_SNMP%
set MENUNAME_TXAPI=%INSTNAME_TXAPI:TX for =%
set MENUNAME_TXIS=%INSTNAME_TXIS:TX for =%

@REM Handle changes to the installs that started with v8301.
@REM - SDK install dropped for the v8.3.0.0 release.  TX for API was around in the 8.2.0.0.145 release,
@REM   and was identical to the TX SDK install except that TX SDK included DK examples.  In v8.3.0.0,
@REM   DK examples were added to the Design Studio install.
@REM - SNMP install dropped. SNMP Agent service incorporated into the Launcher install.
@REM   SNMP adapter added to installs with default adapters.  SNMP examples added to Design Studio.

if ("%MAJOR_VER%")     equ ("8.2")      goto :SIAMN_PriorTo_v8300

:SIAMN_v8300_AndNewer
set INSTALLS_DEFAULT_CORE=%ESD_INSTNAME_DESSTUD% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_TXAPI% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_TXIS% %ESD_INSTNAME_LIBRARY%
goto :SIAMN_AfterSetNames

:SIAMN_PriorTo_v8300
set INSTALLS_DEFAULT_CORE=%ESD_INSTNAME_DESSTUD% %ESD_INSTNAME_LNCHR% %ESD_INSTNAME_CMDSRVR% %ESD_INSTNAME_TXSDK% %ESD_INSTNAME_LNCHRAGNT% %ESD_INSTNAME_LNCHRSTUD% %ESD_INSTNAME_SNMP% %ESD_INSTNAME_SECURE% %ESD_INSTNAME_TXIS%
goto :SIAMN_AfterSetNames

:SIAMN_v81

set INSTNAME_CMDSRVR=TX with Command Server
set INSTNAME_DESSTUD=Design Studio
set INSTNAME_LIBRARY=Online Library
set INSTNAME_LNCHR=TX with Launcher
set INSTNAME_LNCHRAGNT=Launcher Agent
set INSTNAME_LNCHRSTUD=Launcher Studio
set INSTNAME_MB=TX for Message Broker
set INSTNAME_SECURE=Secure Adapter Collection
set INSTNAME_SNMP=SNMP Collection
set INSTNAME_TX=TX
set INSTNAME_TXSDK=TX SDK
set INSTNAME_WEBSRV=Pack for Web Services
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

set MENUNAME_CMDSRVR=%INSTNAME_CMDSRVR:TX with =%
set MENUNAME_DESSTUD=%INSTNAME_DESSTUD%
set MENUNAME_LNCHR=%INSTNAME_LNCHR:TX with =%
set MENUNAME_LNCHRSTUD=%INSTNAME_LNCHRSTUD%
set MENUNAME_SNMP=%INSTNAME_SNMP%
set MENUNAME_TX=Transformation Extender
set MENUNAME_TXSDK=Transformation Extender SDK

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
rem :SetCurInstallDir: Set CURINSTALLDIR based on the MAJOR_VER being used.
rem ===============================================================================

:SetCurInstallDir

if ("%MAJOR_VER%") geq ("8.4")  goto :SCID_84
goto :SCID_Pre84

:SCID_84
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS55%")          set CURINSTALLDIR=%LOCAL_BASEINSTALLDIR%
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%")  set CURINSTALLDIR=%LOCAL_BASEINSTALLDIR_32%
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  set CURINSTALLDIR=%LOCAL_BASEINSTALLDIR_64%
goto :SCID_Done

:SCID_Pre84
set CURINSTALLDIR=%LOCAL_BASEINSTALLDIR%
goto :SCID_Done

:SCID_Done
goto :EOF


rem ===============================================================================
rem :DtxIni_EnableIgnoreGPFs: Parse dtx.ini (or dstx.ini for v8.0) to uncomment the
rem line that starts with ";IgnoreGPFs=0".  Need to call :SetDTXHome in order to
rem get the current install directory *after* the installs have been done.
rem ===============================================================================

:DtxIni_EnableIgnoreGPFs

call :SetDTXHome

set INIFILE=dtx.ini
if ("%DTXVER:~0,3%") equ ("8.0")  set INIFILE=dstx.ini

if defined DTXVER   goto :DIEIGPF_CheckDTXHome
if defined DTXVER64 goto :DIEIGPF_CheckDTXHome64
goto :DIEIGPF_Error_NotFound_INIFILE

:DIEIGPF_CheckDTXHome
set INIFILE="%DTXHOME%\%INIFILE%"
goto :DIEIGPF_AfterSetIniFile

:DIEIGPF_CheckDTXHome64
set INIFILE="%DTXHOME64%\%INIFILE%"
goto :DIEIGPF_AfterSetIniFile

:DIEIGPF_AfterSetIniFile
if not exist %INIFILE%  goto :DIEIGPF_Error_NotFound_INIFILE
set DIEIGPF_INIBACKUPFILE=%INIFILE:.ini=.org%

if exist %DIEIGPF_INIBACKUPFILE% goto :DIEIGPF_AfterBackupINIFile
call :Log %0: %date% %time%: Backing up INIFILE=%INIFILE%...
set LOG_CMD=copy /y %INIFILE% %DIEIGPF_INIBACKUPFILE%
call :Log
call :Log
:DIEIGPF_AfterBackupINIFile

if exist %INIFILE%  del /f /q %INIFILE%
call :Log %0: %date% %time%: Attempting to enable IgnoreGPFs in INIFILE=%INIFILE%...
for /f "eol=~ tokens=* usebackq" %%a in (`type %DIEIGPF_INIBACKUPFILE%`)  do call :ParseDtxIni_EnableIgnoreGPFs %%a
call :Log
set LOG_CMD=diff -w %DIEIGPF_INIBACKUPFILE% %INIFILE%
call :Log
call :Log
goto :DIEIGPF_Done

:DIEIGPF_Error_NotFound_INIFILE
call :Log %0: %date% %time%: Error: File not found: INIFILE=%INIFILE%
call :Log
goto :DIEIGPF_Done

:DIEIGPF_Done
goto :EOF


rem ===========================================================================
rem :ParseDtxIni_EnableIgnoreGPFs: Parse each line of the dtx.ini (or dstx.ini)
rem file in search of the line that is commented out that enables IgnoreGPFs=0.
rem When that line is found, uncomment it.  Output every other line as it is.
rem ===========================================================================

:ParseDtxIni_EnableIgnoreGPFs
set PDI_EIGPF_TMP=%*
if     defined PDI_EIGPF_TMP set PDI_EIGPF_LINE=%PDI_EIGPF_TMP:;IgnoreGPFs=IgnoreGPFs%
if not defined PDI_EIGPF_TMP set PDI_EIGPF_LINE=
if     defined PDI_EIGPF_LINE echo %PDI_EIGPF_LINE% >> %INIFILE%
if not defined PDI_EIGPF_LINE echo.>> %INIFILE%
goto :EOF


rem ===============================================================================
rem :CleanUpAfterInstallShield: Remove temporary directories left behind from the
rem installation process.
rem ===============================================================================

:CleanUpAfterInstallShield

for /d %%a in ("%TEMP%\_ISTMP*.DIR") do rmdir /q /s %%a

:CUAIS_Done
goto :EOF


rem ===============================================================================
rem :InstallInterimFixLevel: Try to install the InterimFix install specified
rem by the argument passed in.
rem
rem Arguments:
rem - Arg1: InterimFix Level to install (i.e., 01)
rem ===============================================================================

:InstallInterimFixLevel

call :GetInterimFixInfo %1
if defined INTERIMFIXDIR  goto :IIFL_InstallIF
set FINAL_STATUS=FAIL
goto :IIFL_Done

:IIFL_InstallIF
set CURINSTALLDIR=%INTERIMFIXDIR%\windows
call :InstallProduct "%INSTNAME_INTERIMFIX%"    %ESD_INSTNAME_INTERIMFIX%

:IIFL_Done
set CURINSTALLDIR=
goto :EOF


:GetInterimFixInfo

set INTERIMFIXNUM=
set INTERIMFIXDIR=
set ESD_INSTNAME_INTERIMFIX=
set GIFI_LOCAL_ROOTDIR=%LOCAL_ROOTDIR%

:GIFI_Loop

if ("%TXINSTALLS_VRMFNUM%") equ ("8.2.0.4") goto :GIFI_Check8204Installs
if ("%TXINSTALLS_VRMFNUM%") equ ("8.2.0.2") goto :GIFI_Check8202Installs
if ("%TXINSTALLS_VRMFNUM%") equ ("8.2.0.0") goto :GIFI_Check8200Installs
if ("%TXINSTALLS_VRMFNUM%") equ ("8.1.0.5") goto :GIFI_Check8105Installs
rem There is no IF for this IF or we don't know how to handle IF for this VRMF yet...
goto :GIFI_Done

rem ========================================
rem Handle 8.2.0.4 IFs
rem ========================================

:GIFI_Check8204Installs
set GIFI_VRMF=8.2.0.4
if (%1) equ ()    goto :GIFI_IF8204_DEFAULT
if (%1) equ (03)  goto :GIFI_IF8204_03
if (%1) equ (3)   goto :GIFI_IF8204_03
if (%1) equ (02)  goto :GIFI_IF8204_02
if (%1) equ (2)   goto :GIFI_IF8204_02
if (%1) equ (01)  goto :GIFI_IF8204_01
if (%1) equ (1)   goto :GIFI_IF8204_01
goto :GIFI_Done

:GIFI_IF8204_DEFAULT
:GIFI_IF8204_03
set INTERIMFIXNUM=03
if defined TXINSTALLS_INTERIMFIX_CURBLDNUM goto :GIFI_IF8204_03_CurBldNumDefined
call :Log %0: ERROR: TXINSTALLS_INTERIMFIX_CURBLDNUM required for determining path to InterimFix Level %INTERIMFIXNUM% installs
goto :GIFI_Exit
:GIFI_IF8204_03_CurBldNumDefined
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.%TXINSTALLS_INTERIMFIX_CURBLDNUM%\Release
goto :GIFI_CheckIFDirExists

:GIFI_IF8204_02
set INTERIMFIXNUM=02
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.116\Release
goto :GIFI_CheckIFDirExists

:GIFI_IF8204_01
set INTERIMFIXNUM=01
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.81\Release
goto :GIFI_CheckIFDirExists

rem ========================================
rem Handle 8.2.0.2 IFs
rem ========================================

:GIFI_Check8202Installs
set GIFI_VRMF=8.2.0.2
if (%1) equ ()    goto :GIFI_IF8202_DEFAULT
if (%1) equ (01)  goto :GIFI_IF8202_01
if (%1) equ (1)   goto :GIFI_IF8202_01
goto :GIFI_CheckIFDirExists

:GIFI_IF8202_DEFAULT
:GIFI_IF8202_01
set INTERIMFIXNUM=01
if defined TXINSTALLS_INTERIMFIX_CURBLDNUM goto :GIFI_IF8202_01_CurBldNumDefined
call :Log %0: ERROR: TXINSTALLS_INTERIMFIX_CURBLDNUM required for determining path to InterimFix Level %INTERIMFIXNUM% installs
goto :GIFI_Exit
:GIFI_IF8202_01_CurBldNumDefined
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.%TXINSTALLS_INTERIMFIX_CURBLDNUM%\Release
goto :GIFI_CheckIFDirExists

rem ========================================
rem Handle 8.2.0.0 IFs
rem ========================================

:GIFI_Check8200Installs
set GIFI_VRMF=8.2.0.0
if (%1) equ ()    goto :GIFI_IF8200_DEFAULT
if (%1) equ (03)  goto :GIFI_IF8200_03
if (%1) equ (3)   goto :GIFI_IF8200_03
if (%1) equ (02)  goto :GIFI_IF8200_02
if (%1) equ (2)   goto :GIFI_IF8200_02
if (%1) equ (01)  goto :GIFI_IF8200_01
if (%1) equ (1)   goto :GIFI_IF8200_01
goto :GIFI_Done

:GIFI_IF8200_03
set INTERIMFIXNUM=03
if defined TXINSTALLS_INTERIMFIX_CURBLDNUM goto :GIFI_IF8200_03_CurBldNumDefined
call :Log %0: ERROR: TXINSTALLS_INTERIMFIX_CURBLDNUM required for determining path to InterimFix Level %INTERIMFIXNUM% installs
goto :GIFI_Exit
:GIFI_IF8200_03_CurBldNumDefined
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.%TXINSTALLS_INTERIMFIX_CURBLDNUM%\Release
goto :GIFI_CheckIFDirExists

:GIFI_IF8200_DEFAULT
:GIFI_IF8200_02
set INTERIMFIXNUM=02
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.183\Release
goto :GIFI_CheckIFDirExists

:GIFI_IF8200_01
set INTERIMFIXNUM=01
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.167\Release
goto :GIFI_CheckIFDirExists

rem ========================================
rem Handle 8.1.0.5 IFs
rem
rem 08/24/2010: These were handled as ZIP
rem files, so we need a new mechanism to
rem unzip the files into MERCHOME.  Until
rem then, deal with these by ignoring they
rem exist.
rem ========================================

:GIFI_Check8105Installs
goto :GIFI_Exit
set GIFI_VRMF=8.1.0.5
if (%1) equ ()    goto :GIFI_IF8105_DEFAULT
if (%1) equ (02)  goto :GIFI_IF8105_02
if (%1) equ (2)   goto :GIFI_IF8105_02
if (%1) equ (01)  goto :GIFI_IF8105_01
if (%1) equ (1)   goto :GIFI_IF8105_01
goto :GIFI_CheckIFDirExists

:GIFI_IF8105_03
set INTERIMFIXNUM=03
if defined TXINSTALLS_INTERIMFIX_CURBLDNUM goto :GIFI_IF8105_03_CurBldNumDefined
call :Log %0: ERROR: TXINSTALLS_INTERIMFIX_CURBLDNUM required for determining path to InterimFix Level %INTERIMFIXNUM% installs
goto :GIFI_Exit
:GIFI_IF8105_03_CurBldNumDefined
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.%TXINSTALLS_INTERIMFIX_CURBLDNUM%\Release
goto :GIFI_CheckIFDirExists

:GIFI_IF8105_DEFAULT
:GIFI_IF8105_02
set INTERIMFIXNUM=02
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.89\Release
goto :GIFI_CheckIFDirExists

:GIFI_IF8105_01
set INTERIMFIXNUM=01
set INTERIMFIXDIR=%GIFI_LOCAL_ROOTDIR%\%GIFI_VRMF%.53\Release
goto :GIFI_CheckIFDirExists

rem ========================================
rem If IF installs are not found with the
rem base installs, check to see if there's
rem an alternate location we should use.
rem ========================================

:GIFI_CheckIFDirExists
if not defined INTERIMFIXDIR                                goto :GIFI_Done
if exist "%INTERIMFIXDIR%"                                  goto :GIFI_Done
if not defined LOCAL_ROOTDIR_ALT                            goto :GIFI_Done
if /i ("%GIFI_LOCAL_ROOTDIR%") equ ("%LOCAL_ROOTDIR_ALT%")  goto :GIFI_Done
set GIFI_LOCAL_ROOTDIR=%LOCAL_ROOTDIR_ALT%
@rem call :Log ===    Warning: INTERIMFIXDIR="%INTERIMFIXDIR%" does not exist.  Checking alternate location...
goto :GIFI_Loop

:GIFI_Done
if defined INTERIMFIXNUM set ESD_INSTNAME_INTERIMFIX=intfix%INTERIMFIXNUM%
if     defined INTERIMFIXDIR call :Log ===    InterimFix Level %INTERIMFIXNUM% using INTERIMFIXDIR=%INTERIMFIXDIR%
if not defined INTERIMFIXDIR call :Log ===    ERROR: %TXINSTALLS_VRMFNUM% InterimFix Level %1 not supported by this script (update %0)
:GIFI_Exit
goto :EOF


rem ===============================================================================
rem :ProcessCoreInstallRequest: Determine which of the core installs should be
rem launched based on the argument passed in.
rem
rem Arguments:
rem - Arg1: ESD name of the install to be launched.
rem ===============================================================================

:ProcessCoreInstallRequest

if (%*) equ () goto :PCIR_Done

rem ========================================
rem Handle installs common to all releases.
rem ========================================

:PCIR_Default

if /i (%*) neq (%ESD_INSTNAME_CMDSRVR%)  goto :PCIR_AfterCmdSrvr
call :InstallProduct "%INSTNAME_CMDSRVR%"    %ESD_INSTNAME_CMDSRVR%
goto :PCIR_Done
:PCIR_AfterCmdSrvr

if /i (%*) neq (%ESD_INSTNAME_DESSTUD%) goto :PCIR_AfterDesStud
call :InstallProduct "%INSTNAME_DESSTUD%"    %ESD_INSTNAME_DESSTUD%
goto :PCIR_Done
:PCIR_AfterDesStud

if /i (%*) neq (%ESD_INSTNAME_LIBRARY%)  goto :PCIR_AfterLibrary
if defined SHOULD_INSTALL_ONLINE_LIB     goto :PCIR_AfterSetShouldInstallLibFlag
set SHOULD_INSTALL_ONLINE_LIB=%ESD_INSTNAME_LIBRARY%
if defined INSTALL_TYPE  set SHOULD_INSTALL_ONLINE_LIB=%SHOULD_INSTALL_ONLINE_LIB% %INSTALL_TYPE%
call :Log === %0: Setting SHOULD_INSTALL_ONLINE_LIB="%SHOULD_INSTALL_ONLINE_LIB%"
:PCIR_AfterSetShouldInstallLibFlag
if /i ("%SHOULD_INSTALL_ONLINE_LIB%") neq ("NOW")  goto :PCIR_Done
call :InstallProduct "%INSTNAME_LIBRARY%"    %ESD_INSTNAME_LIBRARY%
goto :PCIR_Done
:PCIR_AfterLibrary

if /i (%*) neq (%ESD_INSTNAME_LNCHR%)  goto :PCIR_AfterLnchr
call :InstallProduct "%INSTNAME_LNCHR%"      %ESD_INSTNAME_LNCHR%
goto :PCIR_Done
:PCIR_AfterLnchr

if ("%MAJOR_VER%") geq ("8.5.0")  goto :PCIR_AfterLnchrAgnt
if /i (%*) neq (%ESD_INSTNAME_LNCHRAGNT%)  goto :PCIR_AfterLnchrAgnt
call :InstallProduct "%INSTNAME_LNCHRAGNT%"  %ESD_INSTNAME_LNCHRAGNT%
goto :PCIR_Done
:PCIR_AfterLnchrAgnt

if /i (%*) neq (%ESD_INSTNAME_LNCHRSTUD%)  goto :PCIR_AfterLnchrStud
call :InstallProduct "%INSTNAME_LNCHRSTUD%"  %ESD_INSTNAME_LNCHRSTUD%
goto :PCIR_Done
:PCIR_AfterLnchrStud

if ("%MAJOR_VER%") geq ("8.5.0")  goto :PCIR_AfterSecure
if /i (%*) neq (%ESD_INSTNAME_SECURE%)  goto :PCIR_AfterSecure
call :InstallProduct "%INSTNAME_SECURE%"     %ESD_INSTNAME_SECURE%
goto :PCIR_Done
:PCIR_AfterSecure

if ("%MAJOR_VER%") geq ("8.4")  goto :PCIR_AfterSNMP
if /i (%*) neq (%ESD_INSTNAME_SNMP%)  goto :PCIR_AfterSNMP
call :InstallProduct "%INSTNAME_SNMP%"       %ESD_INSTNAME_SNMP%
goto :PCIR_Done
:PCIR_AfterSNMP

if ("%MAJOR_VER%") geq ("8.3")  goto :PCIR_AfterTXSDK
if /i (%*) neq (%ESD_INSTNAME_TXSDK%)  goto :PCIR_AfterTXSDK
call :InstallProduct "%INSTNAME_TXSDK%"      %ESD_INSTNAME_TXSDK%
goto :PCIR_Done
:PCIR_AfterTXSDK

rem ========================================
rem Install was not in the "common" list, so
rem search for it based on MAJOR_VER.
rem ========================================

if ("%MAJOR_VER%") equ ("8.5.0") goto :PCIR_v85
if ("%MAJOR_VER%") equ ("8.5")   goto :PCIR_v85
if ("%MAJOR_VER%") equ ("8.4.1") goto :PCIR_v84
if ("%MAJOR_VER%") equ ("8.4.0") goto :PCIR_v84
if ("%MAJOR_VER%") equ ("8.4")   goto :PCIR_v84
if ("%MAJOR_VER%") equ ("8.3")   goto :PCIR_v83
if ("%MAJOR_VER%") equ ("8.2")   goto :PCIR_v82
if ("%MAJOR_VER%") equ ("8.1")   goto :PCIR_v81
if ("%MAJOR_VER%") equ ("8.0")   goto :PCIR_v80

rem ========================================
rem Handle v8.3 (and above) installs
rem ========================================

:PCIR_v85
:PCIR_v84
:PCIR_v83

if /i (%*) neq (%ESD_INSTNAME_TXAPI%)  goto :PCIR_v83_AfterTXAPI
call :InstallProduct "%INSTNAME_TXAPI%"      %ESD_INSTNAME_TXAPI%
goto :PCIR_Done
:PCIR_v83_AfterTXAPI

if /i (%*) neq (%ESD_INSTNAME_TXIS%)  goto :PCIR_v83_AfterTXIS
call :InstallProduct "%INSTNAME_TXIS%"       %ESD_INSTNAME_TXIS%
goto :PCIR_Done
:PCIR_v83_AfterTXIS

goto :PCIR_UnknownInstall

rem ========================================
rem Handle v8.2 (and above) installs
rem ========================================

:PCIR_v82

if /i (%*) neq (%ESD_INSTNAME_MB%)  goto :PCIR_v82_AfterMB
call :InstallProduct "%INSTNAME_MB%"      %ESD_INSTNAME_MB%
goto :PCIR_Done
:PCIR_v82_AfterMB

if /i (%*) neq (%ESD_INSTNAME_TXAPI%)  goto :PCIR_v82_AfterTXAPI
call :InstallProduct "%INSTNAME_TXAPI%"      %ESD_INSTNAME_TXAPI%
goto :PCIR_Done
:PCIR_v82_AfterTXAPI

if /i (%*) neq (%ESD_INSTNAME_TXIS%)  goto :PCIR_v82_AfterTXIS
call :InstallProduct "%INSTNAME_TXIS%"       %ESD_INSTNAME_TXIS%
goto :PCIR_Done
:PCIR_v82_AfterTXIS

goto :PCIR_UnknownInstall

rem ========================================
rem Handle v8.1 installs
rem ========================================

:PCIR_v81

if /i (%*) neq (%ESD_INSTNAME_MB%)  goto :PCIR_v81_AfterMB
call :InstallProduct "%INSTNAME_MB%"      %ESD_INSTNAME_MB%
goto :PCIR_Done
:PCIR_v81_AfterMB

if /i (%*) neq (%ESD_INSTNAME_TX%)  goto :PCIR_v81_AfterTX
call :InstallProduct "%INSTNAME_TX%"      %ESD_INSTNAME_TX%
goto :PCIR_Done
:PCIR_v81_AfterTX

if /i (%*) neq (%ESD_INSTNAME_WEBSRV%)  goto :PCIR_v81_AfterWebSrv
call :InstallProduct "%INSTNAME_WEBSRV%"  %ESD_INSTNAME_WEBSRV%
goto :PCIR_Done
:PCIR_v81_AfterWebSrv

goto :PCIR_UnknownInstall

rem ========================================
rem Handle v8.0 installs
rem ========================================

:PCIR_v80

if /i (%*) neq (%ESD_INSTNAME_CMDSRVR_INTL%)  goto :PCIR_v80_AfterCmdSrvrIntl
call :InstallProduct "%INSTNAME_CMDSRVR_INTL%"    %ESD_INSTNAME_CMDSRVR_INTL%
goto :PCIR_Done
:PCIR_v80_AfterCmdSrvrIntl

if /i (%*) neq (%ESD_INSTNAME_DESSTUD_INTL%) goto :PCIR_v80_AfterDesStudIntl
call :InstallProduct "%INSTNAME_DESSTUD_INTL%"    %ESD_INSTNAME_DESSTUD_INTL%
goto :PCIR_Done
:PCIR_v80_AfterDesStudIntl

if /i (%*) neq (%ESD_INSTNAME_LNCHR_INTL%)  goto :PCIR_v80_AfterLnchrIntl
call :InstallProduct "%INSTNAME_LNCHR_INTL%"      %ESD_INSTNAME_LNCHR_INTL%
goto :PCIR_Done
:PCIR_v80_AfterLnchrIntl

if /i (%*) neq (%ESD_INSTNAME_TXSDK_INTL%)  goto :PCIR_v80_AfterTXSDKIntl
call :InstallProduct "%INSTNAME_TXSDK_INTL%"      %ESD_INSTNAME_TXSDK_INTL%
goto :PCIR_Done
:PCIR_v80_AfterTXSDKIntl

if /i (%*) neq (%ESD_INSTNAME_JCAG%)  goto :PCIR_v80_AfterJCAG
call :InstallProduct "%INSTNAME_JCAG%"        %ESD_INSTNAME_JCAG%
goto :PCIR_Done
:PCIR_v80_AfterJCAG

if /i (%*) neq (%ESD_INSTNAME_MB%)  goto :PCIR_v80_AfterMB
call :InstallProduct "%INSTNAME_MB%"          %ESD_INSTNAME_MB%
goto :PCIR_Done
:PCIR_v80_AfterMB

if /i (%*) neq (%ESD_INSTNAME_WEBLOGIC%)  goto :PCIR_v80_AfterBEAWebLogic
call :InstallProduct "%INSTNAME_WEBLOGIC%"    %ESD_INSTNAME_WEBLOGIC%
goto :PCIR_Done
:PCIR_v80_AfterBEAWebLogic

if /i (%*) neq (%ESD_INSTNAME_WEBSRV%)  goto :PCIR_v80_AfterWebSrv
call :InstallProduct "%INSTNAME_WEBSRV%"      %ESD_INSTNAME_WEBSRV%
goto :PCIR_Done
:PCIR_v80_AfterWebSrv

goto :PCIR_UnknownInstall

rem ========================================
rem Handle unrecognized installs
rem ========================================

:PCIR_UnknownInstall
if not defined INSTALL_TYPE  call :Log === %0: Done:  %date% %time%: ERROR: Unknown v%MAJOR_VER% install name "%*".
if     defined INSTALL_TYPE  call :Log === %0: Done:  %date% %time%: ERROR: Unknown v%MAJOR_VER% install name "%*" (install type is %INSTALL_TYPE%).
set FINAL_STATUS=FAIL
goto :PCIR_Done

:PCIR_Done
if defined TXINSTALLS_DEBUG pause
goto :EOF


rem ===============================================================================
rem :InstallProduct: Install the specified product.
rem
rem Arguments:
rem Arg1: Name of the install
rem Arg2: Name of the response file for the install
rem
rem Assumptions:
rem - If response file is specified, we're using InstallShield.  If no response
rem   file, we're using InstallAnywhere.
rem - InstallShield installs:
rem   - Install executable is named setup.exe
rem   - INSTALLDIR\Disk1 is where the setup.exe is located.
rem - InstallAnywhere installs:
rem   - Install executable is named install.exe
rem   - INSTALLDIR is where the install.exe is located.
rem ===============================================================================

:InstallProduct

set INSTALL_RC=

if not defined CURINSTALLDIR goto :IP_CurInstallDirNotDefined

if "%2." equ "." goto :IP_SetForIA

if defined SKIP_REMAINING_INSTALLS  goto :IP_SkipInstallDueToPriorFailure

rem ========================================
rem Allow for use of UNC paths for INSTALLDIR.
rem For UNC's, Windows assigns a temp drive
rem letter for the pushd command, which goes
rem away after the popd is issued.  For
rem non-UNC paths, we still want to use the
rem drive letter in case "goofy" paths are
rem specified (such as ..\..\installdir).
rem ========================================

:IP_SetForIS
set IP_INSTALLNAME_DIR=%~1
if not defined INSTALL_TYPE                                   goto :IP_AfterSetInstallNameDir
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS55%")          goto :IP_AfterSetInstallNameDir
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_32BIT%")  set IP_INSTALLNAME_DIR=%IP_INSTALLNAME_DIR: =_%
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  set IP_INSTALLNAME_DIR=%IP_INSTALLNAME_DIR: =_%
:IP_AfterSetInstallNameDir
set INSTALLDIR=%CURINSTALLDIR%\%IP_INSTALLNAME_DIR%\Disk1

pushd "%INSTALLDIR%" > nul 2>&1
if ERRORLEVEL 1 goto :IP_InstallDirNotFound
if ("%INSTALLDIR:~0,2%") equ ("\\") set INSTALLEXEC="%INSTALLDIR%\setup.exe"
if ("%INSTALLDIR:~0,2%") neq ("\\") set INSTALLEXEC="%CD%\setup.exe"
popd

rem ========================================
rem CURRESPONSEDIR set in :GetCurResponseDirForThisInstall
rem ========================================

set RESPONSEFILE="%CURRESPONSEDIR%\%2.iss"
if ("%2") neq ("%ESD_INSTNAME_LNCHR%")  goto :IP_SetForIS_AfterResponseFile
if ("%MAJOR_VER%")     neq ("8.3")      goto :IP_SetForIS_AfterResponseFile
if ("%LOCAL_VRMFNUM%") neq ("8.3.0.0")  goto :IP_SetForIS_AfterResponseFile
set RESPONSEFILE="%CURRESPONSEDIR%\%2_8300.iss"
:IP_SetForIS_AfterResponseFile
set RESULTLOG="%RESULTDIR%\%2.log"
set GUILockFile="%RESULTDIR%\%2.lck"
goto :IP_AfterSetInstallType

:IP_SetForIA
set INSTALLDIR=%CURINSTALLDIR%\%~1
pushd "%INSTALLDIR%" > nul 2>&1
if ERRORLEVEL 1 goto :IP_InstallDirNotFound
if ("%INSTALLDIR:~0,2%") equ ("\\") set INSTALLEXEC="%INSTALLDIR%\install.exe"
if ("%INSTALLDIR:~0,2%") neq ("\\") set INSTALLEXEC="%CD%\install.exe"
popd
set RESPONSEFILE=
set RESULTLOG=
set GUILockFile=
goto :IP_AfterSetInstallType
:IP_AfterSetInstallType

call :Log
call :Log === %0: Start: %date% %time%: %*
call :Log ===    INSTALLDIR=%INSTALLDIR%
if defined RESPONSEFILE call :Log ===    RESPONSEFILE=%RESPONSEFILE%
if defined GUILockFile  call :Log ===    GUILockFile=%GUILockFile%
if defined RESULTLOG    call :Log ===    RESULTLOG=%RESULTLOG%
@REM pause

if exist %INSTALLEXEC%  goto :IP_AfterCheckForInstallExec
call :Log
call :Log === %0: ERROR: Missing INSTALLEXEC=%INSTALLEXEC%
set INSTALL_RC=1
goto :IP_DisplayInstallStatus
:IP_AfterCheckForInstallExec

if not defined RESPONSEFILE        goto :IP_AfterCheckForResponseFile
if defined GENERATE_RESPONSEFILES  goto :IP_DeleteResponseFile
if exist %RESPONSEFILE%            goto :IP_AfterCheckForResponseFile
call :Log
call :Log === %0: ERROR: Missing RESPONSEFILE=%RESPONSEFILE%
set INSTALL_RC=1
goto :IP_DisplayInstallStatus
:IP_DeleteResponseFile
if exist %RESPONSEFILE% del /f /q %RESPONSEFILE%
:IP_AfterCheckForResponseFile

if not defined RESULTLOG  goto :IP_AfterCheckForResultLog
if exist %RESULTLOG%  del /f /q %RESULTLOG%
:IP_AfterCheckForResultLog

if not defined GUILockFile  goto :IP_AfterCheckForLockFile
if not exist %GUILockFile%  goto :IP_AfterCheckForLockFile
call :Log
call :Log %0: GUILockFile=%GUILockFile% exists.
@REM 01/16/2008: gbc: Removing all interactive checks for automation purposes.
@REM set /p ASKYN=Delete lockfile (y/n)? 
set ASKYN=y
if /i "%ASKYN%" equ "yes"  set ASKYN=y
if /i "%ASKYN%" neq "y"    goto :IP_IS_WaitForInstall
call :Log %0: Deleting GUILockFile=%GUILockFile%...
del /f /q %GUILockFile%
:IP_AfterCheckForLockFile

if not defined RESPONSEFILE  goto :IP_LaunchIA

rem ========================================
rem Launch the InstallShield install
rem ========================================

:IP_LaunchIS
set MYCMD=%INSTALLEXEC%
if not defined GUILockFile goto :IP_LaunchIS_AfterCreateLockFile
echo %0: Start: %date% %time%: Silent install of %* > %GUILockFile%
set MYCMD=%MYCMD% -a %GUILockFile%
:IP_LaunchIS_AfterCreateLockFile
if     defined GENERATE_RESPONSEFILES  set MYCMD=%MYCMD% -r -f1%RESPONSEFILE%
if not defined GENERATE_RESPONSEFILES  set MYCMD=%MYCMD% -s -f1%RESPONSEFILE%
if defined RESULTLOG                   set MYCMD=%MYCMD% -f2%RESULTLOG%
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS55%")  goto :IP_LaunchIS_AfterTXLOG_Flag
if /i ("%INSTALL_TYPE%") equ ("%INSTALL_TYPE_IS2011_64BIT%")  set MYCMD=%MYCMD% -tx32bitdisc
if defined TXINSTALLS_DEBUG  set MYCMD=%MYCMD% -txlog "%RESULTDIR%\txlog_%2.log"
:IP_LaunchIS_AfterTXLOG_Flag
call :Log
call :Log %MYCMD%
@REM pause
%MYCMD%

rem ========================================
rem Wait for install to delete lockfile or
rem return a ResultCode.
rem ========================================

if not defined GUILockFile  goto :IP_IS_AfterWaitForInstall

:IP_IS_WaitForInstall
call :Log
@REM 03/12/2008: Update message to accomodate impatient people...
@REM call :Log %0: %date% %time%: Waiting for lockfile to be cleared...
call :Log %0: %date% %time%: Please wait while the install completes...

:IP_IS_WaitForInstall_Loop
if not exist %GUILockFile%    goto :IP_IS_AfterWaitForInstall
call :GetISRC
if not defined INSTALL_RC  goto :IP_ISWait_AfterCheckResult
del /f /q %GUILockFile%
goto :IP_IS_WaitForInstall_Loop
:IP_ISWait_AfterCheckResult

%SLEEP_CMD% > nul 2>&1
goto :IP_IS_WaitForInstall_Loop

:IP_IS_AfterWaitForInstall
if defined GENERATE_RESPONSEFILES goto :IP_IS_SetRCTo0
if not defined INSTALL_RC  call :GetISRC
call :DisplayISRC %INSTALL_RC%
goto :IP_DisplayInstallStatus

:IP_IS_SetRCTo0
set INSTALL_RC=0
goto :IP_DisplayInstallStatus

rem ========================================
rem Launch the InstallAnywhere install
rem ========================================

:IP_LaunchIA
if defined GENERATE_RESPONSEFILES  goto :IP_NoRespFileToGen
if not defined RESULTLOG_IA  goto :IP_LIA_AfterLogStart
if defined RESULTLOG_IA  call :Log ===    RESULTLOG_IA=%RESULTLOG_IA%
if exist %RESULTLOG_IA% del /f /q %RESULTLOG_IA%
:IP_LIA_AfterLogStart
set MYCMD=%INSTALLEXEC% -i silent
call :Log
call :Log %MYCMD%
%MYCMD%
if not defined RESULTLOG_IA  goto :IP_LIA_AfterLogDone
call :GetIARC
call :DisplayIARC %INSTALL_RC%
:IP_LIA_AfterLogDone
goto :IP_DisplayInstallStatus

rem ========================================
rem Current install directory not defined
rem ========================================

:IP_CurInstallDirNotDefined
call :Log
call :Log === %0: ERROR: CURINSTALLDIR not defined.
set INSTALL_RC=1
goto :IP_DisplayInstallStatus

rem ========================================
rem Install directory not present.
rem ========================================

:IP_InstallDirNotFound
call :Log
call :Log === %0: ERROR: Missing INSTALLDIR=%INSTALLDIR%
set INSTALL_RC=1
goto :IP_DisplayInstallStatus

rem ========================================
rem Generating response files, but this
rem install does not use one.
rem ========================================

:IP_NoRespFileToGen
call :Log ===     Response file not used.  Nothing done.
set INSTALL_RC=0
goto :IP_DisplayInstallStatus

rem ========================================
rem Install completed.
rem ========================================

:IP_DisplayInstallStatus
%SLEEP_CMD_AFTERISCOMPLETES% > nul 2>&1
if not defined INSTALL_RC goto :IP_ReturnFail
if /i (%INSTALL_RC%) neq (0) goto :IP_ReturnFail

:IP_ReturnPass
call :Log === %0: Done:  %date% %time%: %*  (install_type=%INSTALL_TYPE%) - PASS
goto :IP_Exit

:IP_ReturnFail
call :Log === %0: Done:  %date% %time%: %*  (install_type=%INSTALL_TYPE%) - FAIL
set FINAL_STATUS=FAIL
if not defined TXINSTALLS_IGNORE_FAILURES  set SKIP_REMAINING_INSTALLS=1
goto :IP_Exit

:IP_SkipInstallDueToPriorFailure
call :Log === %0: Done:  %date% %time%: %*  (install_type=%INSTALL_TYPE%) - WARNING: Skipped due to prior install failure
goto :IP_Exit

:IP_Exit
if exist %TMPOUTFILE%  del /f /q %TMPOUTFILE%
set INSTALLDIR=
set INSTALLEXEC=
set GUILockFile=
set RESPONSEFILE=
set RESULTLOG=
call :Log
goto :EOF


rem ===============================================================================
rem :GetCurResponseDirForThisInstall: Determine CURRESPONSEDIR to use based on
rem RESPONSEDIR and the install currently being installed.
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

set INSTALL_RC=

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
for /f "tokens=1,2 delims== " %%i in ('type %TMPOUTFILE%') do set INSTALL_RC=%%j

:GISRC_Done
goto :EOF


rem ===============================================================================
rem :DisplayISRC: Log the InstallShield return code passed in.
rem - Arg1: InstallShield return code to be logged
rem
rem The Setup.log file contains three sections. The first section, [InstallShield
rem Silent], identifies the version of InstallShield Silent used in the silent
rem installation. It also identifies the file as a log file.
rem
rem The second section, [Application], identifies the installed application's name and
rem version, and the company name.
rem
rem The third section, [ResponseResult], contains the result code indicating whether
rem or not the silent installation succeeded. An integer value is assigned to the
rem ResultCode key name in the [ResponseResult] section. InstallShield places one of
rem the following return values after the ResultCode key name:
rem
rem       0  Success.
rem      -1  General error.
rem      -2  Invalid mode.
rem      -3  Required data not found in the Setup.iss file.
rem      -4  Not enough memory available.
rem      -5  File does not exist.
rem      -6  Cannot write to the response file.
rem      -7  Unable to write to the log file.
rem      -8  Invalid path to the InstallShield Silent response file.
rem      -9  Not a valid list type (string or number).
rem     -10  Data type is invalid.
rem     -11  Unknown error during setup.
rem     -12  Dialogs are out of order.
rem     -51  Cannot create the specified folder.
rem     -52  Cannot access the specified file or folder.
rem     -53  Invalid option selected.
rem    -105  Component tree entry specified in response file not found.
rem
rem The Setup.log file for a successful silent installation of InstallShield is shown
rem below:
rem
rem     ...
rem     [ResponseResult]
rem     ResultCode=0
rem
rem ===============================================================================

:DisplayISRC

if /i ("%1") equ ("") set DISRC_PREFIX====    Install Return Code = UNDEFINED:
if /i ("%1") neq ("") set DISRC_PREFIX====    Install Return Code = %1:
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

set INSTALL_RC=

if not defined RESULTLOG_IA  goto :GIARC_AfterGetRC
if not exist %RESULTLOG_IA%  goto :GIARC_AfterGetRC

type %RESULTLOG_IA% | "%SystemRoot%\system32\find.exe" "Installation:" > %TMPOUTFILE%
if ERRORLEVEL 1  goto :GIARC_AfterGetRC
for /f "tokens=1,2 " %%i in ('type %TMPOUTFILE%') do set INSTALL_RC=%%j

:GIARC_AfterGetRC
if not defined INSTALL_RC               set INSTALL_RC=UNDEFINED
if ("%INSTALL_RC%") == ("Successful.")  set INSTALL_RC=0

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


rem ===============================================================================
rem :CheckIfMachineIs64Bit: Is this platform 64bit?
rem ===============================================================================

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

