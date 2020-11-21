LN v0.2 - A fake symlink creator for DOS
========================================

Usage: LN <parameters> SOURCE [ .COM .EXE .BAT .TXT .DOC .HTM .MD \\ ] TARGET

       /? -h --help : Display this help text.
       /d -d : CD to TARGET's directory before executing.
       /e -e : Edit batch file after creation.
       /m -m : Save this help to a Markdown-formatted text file.
       /p -p : Enable TARGET to handle parameters 1 to 9.
       /r -r : Dry run. Display batch file but do not create it
       /s -s : Does nothing, just kept for compatibility.
       /v -v : View batch file after creation.

LN for DOS approximates the symlink command on UNIX-like operating systems
by creating batch files.
Extensions must be given in SOURCE, but may be omitted in TARGET.
Long filenames are not supported.

EXECUTABLES
-----------
If SOURCE is an executable (COM, EXE or BAT), then LN creates a 2-line batch
file called TARGET.BAT that runs the SOURCE directly. If the /d parameter is
used, TARGET.BAT will first CD to SOURCE's drive and directory before executing.

The /p parameter adds %1 to %9 in TARGET.BAT.

EXAMPLE: LN /d /p c:\fdos\progs\wp60\wp.com c:\fdos\links\wp6
Creates: c:\fdos\links\wp6.bat

~~~
   @echo off
   c:
   cd \fdos\progs\wp60
   \fdos\progs\wp60\wp.com %1 %2 %3 %4 %5 %6 %7 %8 %9
~~~

TEXT FILES
----------
If SOURCE is a text file (TXT, DOC, HTM, MD), then LN creates a 2-line batch
file that, when run, loads the file into the default text editor
(the EDIT command).  
The /d and /p parameters are not used.

EXAMPLE: LN c:\fdos\progs\wp60\wp.txt c:\fdos\links\wp6txt 
Creates: c:\fdos\links\wp6txt.bat

~~~
   @echo off
   edit \fdos\progs\wp60\wp.txt
~~~

DIRECTORIES
-----------
If SOURCE is a directory (trailing backslash required), then LN
creates a 2-line batch file that will cd to that directory.

EXAMPLE: LN c:\fdos\progs\wp60\ c:\fdos\links\cd2wp6 
Creates: c:\fdos\links\cd2wp6.bat

~~~
   @echo off
   c:
   cd \fdos\progs\wp60\
~~~

LN is written in QuickBASIC 4.5 for FreeDOS. It should also compile
under FreeBASIC for DOS using the -l qb switch.  
(c) Michel Clasquin-Johnson 2020  
Public domain routines used are marked as such in the code.  
Distributed under the MIT License.
