:: This file sets up custom commands for the Windows command line. I "grew up" on Linux, so I like to have some of the same commands available.
@echo off

:: Linux-like commands
DOSKEY ls=dir /B $*
DOSKEY clear=cls
DOSKEY cp=copy $*
DOSKEY mv=move $*
DOSKEY rm=del $*
DOSKEY grep=findstr $*
DOSKEY cat=type $*
DOSKEY touch=echo.>$*
DOSKEY pwd=cd
DOSKEY ll=dir /A $*
DOSKEY ps=tasklist $*
DOSKEY kill=taskkill /PID $*
DOSKEY chmod=echo Windows does not support chmod, use icacls instead
DOSKEY man=help $*

:: Edit this file
DOSKEY cmdrc=notepad %USERPROFILE%\GitHub\peter-terminal-utils\windows\cmdrc.bat