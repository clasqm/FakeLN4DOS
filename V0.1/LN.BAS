REM if compiled under FreeBASIC, force qb mode
REM this works with the REM in place!
REM $lang: "qb"

DECLARE SUB MakeBatchExec (TargetDrive$, Target$, SourceDrive$, Source$)
DECLARE SUB MakeBatchText (TargetDrive$, Target$, SourceDrive$, Source$)
DECLARE SUB MakeBatchDirectory (TargetDrive$, Target$, SourceDrive$, Source$)
DECLARE FUNCTION GetExtension% (filename$)
DECLARE FUNCTION Exists% (filename$)
DECLARE SUB SpaceCheck ()
DECLARE SUB ErrorWarning (error$)
DECLARE FUNCTION GetFile$ (file$)
DECLARE SUB ShowHelp (destination%)
COMMON SHARED param$, version$
COMMON SHARED addparams, cdbefore, editafter, exportafter, viewafter
version$ = "0.1"

REM get parameters - already in uppercase
param$ = COMMAND$
param$ = LTRIM$(RTRIM$(param$))
IF INSTR(param$, "  ") THEN SpaceCheck

REM check if help is required
IF param$ = "" OR LEFT$(param$, 2) = "/?" OR LEFT$(param$, 2) = "-H" OR LEFT$(param$, 3) = "--H" OR LEFT$(param$, 6) = "--HELP" THEN
    CALL ShowHelp(0)
    SYSTEM
END IF

REM Export help to Markdown file
IF INSTR(param$, "/M") OR INSTR(param$, "-M") THEN
    CALL ShowHelp(1)
    PRINT "LN Help exported to LN.MD"
    SYSTEM
END IF

REM check for other parameters
IF INSTR(param$, "/D ") OR INSTR(param$, "-D ") THEN cdbefore = 1
IF INSTR(param$, "/E ") OR INSTR(param$, "-E ") THEN editafter = 1
IF INSTR(param$, "/P ") OR INSTR(param$, "-P ") THEN addparams = 1
IF INSTR(param$, "/V ") OR INSTR(param$, "-V ") THEN viewafter = 1

REM get filenames
Source$ = GetFile$("src")
IF INSTR(Source$, "/") THEN
   IF LEN(Source$) = 2 THEN
        ErrorWarning ("missingfilename")
   ELSE
        ErrorWarning ("slashes")
   END IF
END IF
IF MID$(Source$, 2, 1) = ":" THEN
    SourceDrive$ = LEFT$(Source$, 2)
    Source$ = MID$(Source$, 3)
END IF

Target$ = GetFile$("trgt")
IF INSTR(Target$, "/") THEN
    IF LEN(Target$) = 2 THEN
        ErrorWarning ("missingfilename")
    ELSE
        ErrorWarning ("slashes")
    END IF
END IF
IF MID$(Target$, 2, 1) = ":" THEN
    TargetDrive$ = LEFT$(Target$, 2)
    Target$ = MID$(Target$, 3)
END IF

REM housekeeping
param$ = ""

ActionType% = GetExtension%(Source$)
SELECT CASE ActionType%
    CASE 1 'Executable
        CALL MakeBatchExec(TargetDrive$, Target$, SourceDrive$, Source$)
    CASE 2 'Text file
        CALL MakeBatchText(TargetDrive$, Target$, SourceDrive$, Source$)
    CASE 3 'Directory
        CALL MakeBatchDirectory(TargetDrive$, Target$, SourceDrive$, Source$)
    CASE ELSE
       ErrorWarning ("filetype")
END SELECT

SYSTEM

SUB ErrorWarning (errors$)
    PRINT "ERROR: ";
    SELECT CASE errors$
        CASE "missingfilename"
            PRINT "SOURCE and/or TARGET appears to be missing."
        CASE "slashes"
            PRINT "Forward slash(es) detected (/). Please use DOS-style backslashes (\)."
        CASE "filetype"
            PRINT "SOURCE does not appear to be a valid filetype."
            PRINT "(.COM .EXE .BAT .TXT .DOC or \)"
            PRINT "Please use LN with no parameters (or with /?) for Help."
    END SELECT
    SYSTEM
END SUB

FUNCTION Exists% (filename$)
REM *******************************************************************************
REM Routine to see if a file exists
REM This uses the fact that if you open a file for BINARY and the file
REM didn't exist, then QB will create a file of length 0.  Of course, this
REM won't work if you're trying to test for file of length 0 which already
REM exists.
REM adopted/adapted from a routine by Steve Haiko
REM *******************************************************************************
    FileNr = FREEFILE
    OPEN filename$ FOR BINARY AS FileNr
    IF LOF(FileNr) THEN
        Exist1% = 1
        CLOSE FileNr
    ELSE
        Exist1% = 0
        CLOSE FileNr
        KILL filename$
    END IF
    Exists% = Exist1%
END FUNCTION

FUNCTION GetExtension% (filename$)
    IF RIGHT$(filename$, 1) = "\" THEN
        Extension% = 3
    ELSE
        Extension$ = RIGHT$(filename$, 4)
        SELECT CASE Extension$
            CASE ".COM", ".EXE", ".BAT"
                Extension% = 1
            CASE ".DOC", ".TXT"
                Extension% = 2
        END SELECT
    END IF
    GetExtension% = Extension%
END FUNCTION

FUNCTION GetFile$ (file$)
    localparam$ = param$
    flen = LEN(localparam$)
    spaces = 1
    FOR f = 1 TO flen
        IF MID$(localparam$, f, 1) = " " THEN spaces = spaces + 1
    NEXT f
    DIM a$(spaces)
    FOR f = 1 TO spaces
        FOR n = 1 TO flen
            IF LEFT$(localparam$, 1) <> " " THEN
                a$(f) = a$(f) + LEFT$(localparam$, 1)
                localparam$ = RIGHT$(localparam$, flen - 1)
                flen = flen - 1
            ELSE
                localparam$ = RIGHT$(localparam$, flen - 1)
                flen = flen - 1
                EXIT FOR
            END IF
        NEXT n
    NEXT f

    IF file$ = "src" THEN
        GetFile1$ = a$(spaces - 1)
    ELSEIF file$ = "trgt" THEN
       GetFile1$ = a$(spaces)
       IF RIGHT$(GetFile1$, 4) <> ".BAT" THEN GetFile1$ = GetFile1$ + ".BAT"
    END IF
    GetFile$ = GetFile1$
END FUNCTION

SUB MakeBatchDirectory (TargetDrive$, Target$, SourceDrive$, Source$)
    FileNr% = FREEFILE
    TheFile$ = TargetDrive$ + Target$
    OPEN TheFile$ FOR OUTPUT AS #FileNr%
    PRINT #FileNr%, "@echo off"
    PRINT #FileNr%, SourceDrive$
    PRINT #FileNr%, "cd " + Source$
    CLOSE
    IF editafter THEN SHELL "edit " + TargetDrive$ + Target$
    IF viewafter THEN SHELL "type " + TargetDrive$ + Target$
END SUB

SUB MakeBatchExec (TargetDrive$, Target$, SourceDrive$, Source$)
    FileNr% = FREEFILE
    TheFile$ = TargetDrive$ + Target$
    OPEN TheFile$ FOR OUTPUT AS #FileNr%
    PRINT #FileNr%, "@echo off"
    IF cdbefore THEN
        PRINT #FileNr%, SourceDrive$
        FOR f = 1 TO LEN(Source$)
            IF MID$(Source$, f, 1) = "\" THEN position% = f
        NEXT f
        PRINT #FileNr%, "cd " + LEFT$(Source$, position%)
    END IF
    PRINT #FileNr%, SourceDrive$ + Source$;
    IF addparams THEN PRINT #FileNr%, " %1 %2 %3 %4 %5 %6 %7 %8 %9"
    CLOSE
    IF editafter THEN SHELL "edit " + TargetDrive$ + Target$
    IF viewafter THEN SHELL "type " + TargetDrive$ + Target$

END SUB

SUB MakeBatchText (TargetDrive$, Target$, SourceDrive$, Source$)
    FileNr% = FREEFILE
    TheFile$ = TargetDrive$ + Target$
    OPEN TheFile$ FOR OUTPUT AS #FileNr%
    PRINT #FileNr%, "@echo off"
    PRINT #FileNr%, "EDIT " + SourceDrive$ + Source$
    CLOSE
    IF editafter THEN SHELL "edit " + TargetDrive$ + Target$
    IF viewafter THEN SHELL "type " + TargetDrive$ + Target$
END SUB

SUB ShowHelp (dest%)
    IF dest% THEN
        b$ = CHR$(13) + CHR$(10)
    ELSE
        b$ = CHR$(13)
    END IF
    a$ = "LN v" + version$ + " - A fake symlink creator for DOS"
    a$ = a$ + b$ + "========================================"
    a$ = a$ + b$
    IF dest% THEN
        a$ = a$ + b$ + "Usage: LN <parameters> SOURCE [ .COM .EXE .BAT .TXT .DOC \\ ] TARGET"
    ELSE
        a$ = a$ + b$ + "Usage: LN <parameters> SOURCE [ .COM .EXE .BAT .TXT .DOC \ ] TARGET"
    END IF
    a$ = a$ + b$
    a$ = a$ + b$ + "       /? -h --help : Display this help text."
    a$ = a$ + b$ + "       /d -d : CD to TARGET's directory before executing."
    a$ = a$ + b$ + "       /e -e : Edit batch file after creation."
    a$ = a$ + b$ + "       /m -m : Save this help to a Markdown-formatted text file."
    a$ = a$ + b$ + "       /p -p : Enable TARGET to handle parameters 1 to 9."
    a$ = a$ + b$ + "       /s -s : Does nothing, just kept for compatibility."
    a$ = a$ + b$ + "       /v -v : View batch file after creation."
    a$ = a$ + b$
    a$ = a$ + b$ + "LN for DOS approximates the symlink command on UNIX-like operating systems"
    a$ = a$ + b$ + "by creating batch files."
    a$ = a$ + b$ + "Extensions must be given in SOURCE, but may be omitted in TARGET."
    a$ = a$ + b$ + "Long filenames are not supported."
    a$ = a$ + b$
    a$ = a$ + b$ + "EXECUTABLES"
    a$ = a$ + b$ + "-----------"
    a$ = a$ + b$ + "If SOURCE is an executable (COM, EXE or BAT), then LN creates a 2-line batch"
    a$ = a$ + b$ + "file called TARGET.BAT that runs the SOURCE directly. If the /d parameter is"
    a$ = a$ + b$ + "used, TARGET.BAT will first CD to SOURCE's drive and directory before executing."
    a$ = a$ + b$
    a$ = a$ + b$ + "The /p parameter adds %1 to %9 in TARGET.BAT."
    a$ = a$ + b$
    a$ = a$ + b$ + "EXAMPLE: LN /d /p c:\fdos\progs\wp60\wp.com c:\fdos\links\wp6"
    a$ = a$ + b$ + "Creates: c:\fdos\links\wp6.bat"
    a$ = a$ + b$
    a$ = a$ + b$ + "~~~"
    a$ = a$ + b$ + "   @echo off"
    a$ = a$ + b$ + "   c:"
    a$ = a$ + b$ + "   cd \fdos\progs\wp60"
    a$ = a$ + b$ + "   \fdos\progs\wp60\wp.com %1 %2 %3 %4 %5 %6 %7 %8 %9"
    a$ = a$ + b$ + "~~~"
    a$ = a$ + b$
    a$ = a$ + b$ + "TEXT FILES"
    a$ = a$ + b$ + "----------"
    a$ = a$ + b$ + "If SOURCE is a text file (TXT, DOC), then LN creates a 2-line batch"
    a$ = a$ + b$ + "file that, when run, loads the file into the default text editor"
    a$ = a$ + b$ + "(the EDIT command).  "
    a$ = a$ + b$ + "The /d and /p parameters are not used."
    a$ = a$ + b$
    a$ = a$ + b$ + "EXAMPLE: LN c:\fdos\progs\wp60\wp.txt c:\fdos\links\wp6txt "
    a$ = a$ + b$ + "Creates: c:\fdos\links\wp6txt.bat"
    a$ = a$ + b$
    a$ = a$ + b$ + "~~~"
    a$ = a$ + b$ + "   @echo off"
    a$ = a$ + b$ + "   edit \fdos\progs\wp60\wp.txt"
    a$ = a$ + b$ + "~~~"
    a$ = a$ + b$
    a$ = a$ + b$ + "DIRECTORIES"
    a$ = a$ + b$ + "-----------"
    a$ = a$ + b$ + "If SOURCE is a directory (trailing backslash required), then LN"
    a$ = a$ + b$ + "creates a 2-line batch file that will cd to that directory."
    a$ = a$ + b$
    a$ = a$ + b$ + "EXAMPLE: LN c:\fdos\progs\wp60\ c:\fdos\links\cd2wp6 "
    a$ = a$ + b$ + "Creates: c:\fdos\links\cd2wp6.bat"
    a$ = a$ + b$
    a$ = a$ + b$ + "~~~"
    a$ = a$ + b$ + "   @echo off"
    a$ = a$ + b$ + "   c:"
    a$ = a$ + b$ + "   cd \fdos\progs\wp60\"
    a$ = a$ + b$ + "~~~"
    a$ = a$ + b$
    a$ = a$ + b$ + "LN is written in QuickBASIC 4.5 for FreeDOS. It should also compile"
    a$ = a$ + b$ + "under FreeBASIC for DOS using the -l qb switch.  "
    a$ = a$ + b$ + "(c) Michel Clasquin-Johnson 2020  "
    a$ = a$ + b$ + "Public domain routines used are marked as such in the code.  "
    a$ = a$ + b$ + "Distributed under the MIT License."
    IF dest% THEN
        FileNr% = FREEFILE
        OPEN "LN.MD" FOR OUTPUT AS FileNr%
        PRINT #FileNr%, a$
        CLOSE
     ELSE
        PRINT a$
    END IF
END SUB

SUB SpaceCheck
    REM remove double spaces
    flen = LEN(param$)
    FOR f = 1 TO flen
        IF MID$(param$, f, 1) <> " " THEN
           a$ = a$ + CHR$(13) + CHR$(10) + MID$(param$, f, 1)
        ELSE
            IF f < flen AND MID$(param$, f + 1, 1) <> " " THEN
                a$ = a$ + CHR$(13) + CHR$(10) + MID$(param$, f, 1)
            END IF
        END IF
    NEXT f
    param$ = a$
END SUB

