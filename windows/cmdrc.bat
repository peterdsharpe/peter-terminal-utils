@echo off

:: Commands

DOSKEY ls=dir /B $*
DOSKEY sublime=sublime_text $*  
    ::sublime_text.exe is name of the executable. By adding a temporary entry to system path, we don't have to write the whole directory anymore.
DOSKEY cmdrc=notepad %USERPROFILE%\GitHub\peter-ipython-terminal\cmdrc.bat