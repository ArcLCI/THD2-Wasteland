@echo off
setlocal
for %%I in ("%~dp0..\..\..\..") do set "THD_OBSERVER_ROOT=%%~fI"
set "THD_OBSERVER_OUT=%THD_OBSERVER_ROOT%\artifacts\bot-native-dynamic-20261010-r2\build"
if not exist "%THD_OBSERVER_OUT%" mkdir "%THD_OBSERVER_OUT%"
"C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" -B "%~dp0prepare_signatures.py"
if errorlevel 1 exit /b 1
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b 1
cl /nologo /std:c++20 /EHsc /W4 /WX /O2 /MT /Z7 /utf-8 /LD /DMETA_NO_HL2SDK /I"%THD_OBSERVER_ROOT%\DOTA2_PERFORMANCE\native-bot-rewrite-r1\src" /I"%THD_OBSERVER_ROOT%\DOTA2_PERFORMANCE\native-pilot-r1\vendor\metamod-source\core" /I"%THD_OBSERVER_ROOT%\DOTA2_PERFORMANCE\native-pilot-r1\vendor\metamod-source\core\sourcehook" "%~dp0observer.cpp" /Fo"%THD_OBSERVER_OUT%\observer.obj" /Fe"%THD_OBSERVER_OUT%\thd_bot_native_observer.dll" /link /INCREMENTAL:NO /DEBUG:FULL /PDB:"%THD_OBSERVER_OUT%\thd_bot_native_observer.pdb" bcrypt.lib shell32.lib
exit /b %errorlevel%
