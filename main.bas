$RESIZE:STRETCH
REM $DYNAMIC
'$EXEICON:'vacuuflower_icon.ico'
_TITLE "Work on your ADHD"

DECLARE CUSTOMTYPE LIBRARY "code\direntry"
    FUNCTION load_dir& (s AS STRING)
    FUNCTION has_next_entry& ()
    SUB close_dir ()
    SUB get_next_entry (s AS STRING, flags AS LONG, file_size AS LONG)
END DECLARE

TYPE rectangle
    AS _FLOAT x, y, w, h
END TYPE

TYPE molecule
    name AS STRING
    AS rectangle coord
    AS _FLOAT vx, vy
    AS _FLOAT rotation
    AS _BYTE display
END TYPE

TYPE sprite
    handle AS LONG
    coord AS rectangle
    AS DOUBLE x, y
END TYPE
REDIM SHARED sprites(0) AS sprite

TYPE mouse
    AS rectangle coord
    AS _BYTE left, right, leftrelease, rightrelease
    AS INTEGER scroll
    AS _FLOAT offsetx, offsety
END TYPE

SCREEN _NEWIMAGE(720, 405, 32)

REDIM SHARED mouse AS mouse
REDIM SHARED AS _FLOAT centerx, centery, starttime, levelprogress, prevlp
REDIM SHARED AS INTEGER lockmouse, gamestate, leveltreshhold
REDIM SHARED AS _UNSIGNED _INTEGER64 level, score, finalscore
leveltreshhold = 20

loadSprites

REDIM SHARED AS LONG font_normal, font_big
loadFonts

REDIM SHARED AS STRING spriteFiles(0), nothing(0)
GetFileList "data/sprites", nothing(), spriteFiles()

RANDOMIZE TIMER

setGlobals -1
DO
    checkKeys
    COLOR col&("ui"), col&("black")
    CLS
    setScore
    checkMouse
    displaySprites
    displayui
    _DISPLAY
    _LIMIT 60
LOOP

SUB loadFonts
    fontpath$ = "data\fonts\"
    fontr$ = fontpath$ + "PTMono-Regular.ttf"
    fonteb$ = fontpath$ + "OpenSans-ExtraBold.ttf"
    font_normal = _LOADFONT(fontr$, 16, "MONOSPACE")
    font_big = _LOADFONT(fonteb$, 48)
    _FONT font_normal
END SUB

SUB checkKeys
    keyhit = _KEYHIT
    SELECT CASE keyhit
        CASE 82
            setGlobals -1
        CASE 16128
            setGlobals -1
        CASE 27
            SYSTEM
    END SELECT
END SUB

SUB setGlobals (resetstate AS _BYTE)
    centerx = _WIDTH(0) / 2
    centery = _HEIGHT(0) / 2
    IF resetstate THEN
        gamestate = 1
        finalscore = 0
        score = 0
        level = 0
        prevlp = 0
        starttime = TIMER
    END IF
END SUB

SUB setScore
    score = (TIMER - starttime)
END SUB

SUB checkMouse
    mouse.scroll = 0
    startx = mouse.coord.x
    starty = mouse.coord.y
    DO
        mouse.coord.x = _MOUSEX
        mouse.coord.y = _MOUSEY
        mouse.scroll = mouse.scroll + _MOUSEWHEEL
        mouse.left = _MOUSEBUTTON(1)
        IF NOT mouse.left THEN
            lockmouse = 0
        END IF
        mouse.offsetx = mouse.coord.x - startx
        mouse.offsety = mouse.coord.y - starty
        mouse.right = _MOUSEBUTTON(2)
    LOOP WHILE _MOUSEINPUT
END SUB

SUB checkResize
    IF _RESIZE THEN
        DO
            winresx = _RESIZEWIDTH
            winresy = _RESIZEHEIGHT
        LOOP WHILE _RESIZE
        IF (winresx <> _WIDTH(0) OR winresy <> _HEIGHT(0)) THEN
            SCREEN _NEWIMAGE(winresx, winresy, 32)
            DO: LOOP UNTIL _SCREENEXISTS
            setGlobals 0
        END IF
    END IF
END SUB

SUB displayProgress (x AS _FLOAT, y AS _FLOAT, w AS _FLOAT, h AS _FLOAT, progress AS _FLOAT, orientation AS STRING)
    IF orientation = "v" THEN
        LINE (x, y)-(x + w, y + (h * progress)), col&("ui"), BF
    ELSE
        LINE (x, y)-(x + (w * progress), y + h), col&("ui"), BF
    END IF
END SUB

SUB loadSprites
    spritepath$ = "data\sprites\"
    DO: i = i + 1
        bsprite(i) = _LOADIMAGE(spritepath$ + "barrier_" + lst$(i) + ".png")
    LOOP UNTIL i = 6
END SUB

SUB displaySpriteImage (this AS sprite, scale, adjust AS _BYTE)
    IF this.handle < -1 THEN
        IF adjust THEN
            _PUTIMAGE (this.coord.x - ((_WIDTH(this.handle) / 2) * scale), this.coord.y - ((_HEIGHT(this.handle) / 2) * scale))-(this.coord.x + ((_WIDTH(this.handle) / 2) * scale), this.coord.y + ((_HEIGHT(this.handle) / 2) * scale)), this.handle
        ELSE
            _PUTIMAGE (this.coord.x, this.coord.y)-(this.coord.x + (_WIDTH(this.handle) * scale), this.coord.y + (_HEIGHT(this.handle) * scale)), this.handle
        END IF
    END IF
END SUB

SUB displayui
    COLOR col&("ui"), col&("t")
    _PRINTSTRING (10, 10 + (0 * _FONTHEIGHT(font_normal))), "Score: " + lst$(score) + " / Level: " + lst$(level)
    speed$ = lst$(1.1 ^ level)
    IF INSTR(speed$, ".") THEN length = INSTR(speed$, ".") + 1 ELSE length = LEN(speed$)

    IF gamestate = 2 THEN
        _FONT font_big
        IF finalscore = 0 THEN finalscore = score + calcium + (10 * gold)
        LINE (vacuum.x, vacuum.y)-(vacuum.x + vacuum.w, vacuum.y + vacuum.h), col&("black"), BF
        COLOR col&("red"), col&("black")
        text$ = "GAMEOVER"
        _PRINTSTRING (vacuum.x + 10, vacuum.y + 10), text$
        text$ = "Score: " + lst$(finalscore)
        _PRINTSTRING (vacuum.x + 10, vacuum.y + 10 + _FONTHEIGHT(font_big)), text$
        _FONT font_normal
    END IF

    progressheight = 4
    levelprogress = (score MOD leveltreshhold) / leveltreshhold
    displayProgress 0, _HEIGHT(0) - progressheight, _WIDTH(0), progressheight, levelprogress, "h"
    IF levelprogress < prevlp THEN level = level + 1
    prevlp = levelprogress
END SUB

SUB drawCircle (x AS _FLOAT, y AS _FLOAT, size AS _FLOAT, colour&)
    CIRCLE (x, y), size, colour&
    PAINT (x, y), colour&, colour&
END SUB

SUB displaySprites
    DO: s = s + 1
        IF sprites(s).coord.x > 0 AND sprites(s).coord.y > 0 THEN
            displaySprite s
        END IF
    LOOP UNTIL s = UBOUND(barrier)
END SUB

SUB displaySprite (s)
    displaySpriteImage sprites(s), 1, -1
END SUB

FUNCTION alphaMod& (colour&, alpha AS _FLOAT)
    alphaMod& = _RGBA(_RED(colour&), _GREEN(colour&), _BLUE(colour&), alpha)
END FUNCTION

FUNCTION lst$ (number)
    lst$ = LTRIM$(STR$(number))
END FUNCTION

FUNCTION min (a, b)
    IF a < b THEN min = a ELSE min = b
END FUNCTION

FUNCTION max (a, b)
    IF a > b THEN max = a ELSE max = b
END FUNCTION

FUNCTION inBounds (inner AS rectangle, outer AS rectangle, margin AS _FLOAT)
    IF inner.x > outer.x - margin AND inner.x + inner.w < outer.x + outer.w + margin AND inner.y > outer.y - margin AND inner.y + inner.h < outer.y + outer.h + margin THEN inBounds = -1 ELSE inBounds = 0
END FUNCTION

FUNCTION col& (colour$)
    SELECT CASE colour$
        CASE "t"
            col& = _RGBA(0, 0, 0, 0)
        CASE "ui"
            col& = _RGBA(255, 255, 255, 255)
        CASE "highlight"
            col& = _RGBA(78, 255, 0, 255)
        CASE "barrier"
            col& = _RGBA(127, 200, 127, 255)
        CASE "red"
            col& = _RGBA(255, 0, 33, 255)
        CASE "black"
            col& = _RGBA(15, 15, 20, 255)
    END SELECT
END FUNCTION

SUB GetFileList (SearchDirectory AS STRING, DirList() AS STRING, FileList() AS STRING)
    CONST IS_DIR = 1
    CONST IS_FILE = 2
    DIM flags AS LONG, file_size AS LONG

    REDIM _PRESERVE DirList(100), FileList(100)
    DirCount = 0: FileCount = 0

    IF load_dir(SearchDirectory) THEN
        DO
            length = has_next_entry
            IF length > -1 THEN
                nam$ = SPACE$(length)
                get_next_entry nam$, flags, file_size
                IF flags AND IS_DIR THEN
                    DirCount = DirCount + 1
                    IF DirCount > UBOUND(DirList) THEN REDIM _PRESERVE DirList(UBOUND(DirList) + 100)
                    DirList(DirCount) = nam$
                ELSEIF flags AND IS_FILE THEN
                    FileCount = FileCount + 1
                    IF FileCount > UBOUND(filelist) THEN REDIM _PRESERVE FileList(UBOUND(filelist) + 100)
                    FileList(FileCount) = nam$
                END IF
            END IF
        LOOP UNTIL length = -1
        close_dir
    ELSE
    END IF
    REDIM _PRESERVE DirList(DirCount)
    REDIM _PRESERVE FileList(FileCount)
END SUB
