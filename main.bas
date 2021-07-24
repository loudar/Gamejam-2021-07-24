$RESIZE:STRETCH
REM $DYNAMIC
'$EXEICON:'vacuuflower_icon.ico'
_TITLE "Work on your ADHD"

DECLARE CUSTOMTYPE LIBRARY "F:\new shit\data\coding\QB\TargonIndustries\Gamejam-2021-07-24\code\direntry"
    FUNCTION get_last_error& ()
    FUNCTION get_path& ()
    FUNCTION load_dir& (s AS STRING)
    FUNCTION has_next_entry& ()
    SUB close_dir ()
    SUB get_next_entry (s AS STRING, flags AS LONG, file_size AS LONG)
END DECLARE

TYPE rectangle
    AS DOUBLE x, y, w, h
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
    AS STRING name, file
    AS _BYTE visible
END TYPE
REDIM SHARED sprites(0) AS sprite

TYPE mapInfo
    AS STRING spriteName, x, y, state
    AS DOUBLE scale
    AS _BYTE visible
END TYPE
REDIM SHARED mapInfo(0) AS mapInfo

TYPE mouse
    AS rectangle coord
    AS _BYTE left, right, leftrelease, rightrelease
    AS INTEGER scroll
    AS _FLOAT offsetx, offsety
END TYPE

SCREEN _NEWIMAGE(720, 405, 32)

REDIM SHARED mouse AS mouse
REDIM SHARED AS _FLOAT centerx, centery, levelprogress, prevlp
REDIM SHARED AS INTEGER lockmouse, gamestate, leveltreshhold, eventState
REDIM SHARED AS _UNSIGNED _INTEGER64 level, score, happiness, finalscore, maxHappiness, counter, smoke
REDIM SHARED AS STRING spriteFiles(0), mapFiles(0), nothing(0), activeSprites(0), activeTask
REDIM SHARED AS _BYTE eventRunning
REDIM SHARED AS DOUBLE startTime, currentTime
leveltreshhold = 20
maxHappiness = 30

REDIM SHARED AS LONG font_normal, font_big, font_small
loadFonts
loadMaps
loadSprites
changeTask

RANDOMIZE TIMER

setGlobals -1
startTime = TIMER
DO
    ' controls + vars
    checkKeys
    checkMouse
    checkTimedEvents
    decreaseHappiness

    ' drawing
    COLOR col&("ui"), col&("black")
    CLS
    displaySprites
    displayUI
    _DISPLAY
    _LIMIT 60
LOOP

SUB checkTimedEvents
    eventChance = 0.009
    roll = RND
    IF roll < eventChance AND eventRunning = 0 THEN
        startRandomEvent
    ELSEIF eventRunning > 0 THEN
        updateRandomEvent
    END IF
    IF roll < 0.0005 THEN
        DO: i = i + 1
            IF sprites(i).name = "2zbackground2" THEN
                sprites(i).handle = _LOADIMAGE("data\sprites\2zbackground1.png", 32)
                sprites(i).name = "2zbackground1"
            ELSEIF sprites(i).name = "2zbackground1" THEN
                sprites(i).handle = _LOADIMAGE("data\sprites\2zbackground2.png", 32)
                sprites(i).name = "2zbackground2"
            END IF
        LOOP UNTIL i = UBOUND(sprites)
    END IF
    IF smoke >= 100 THEN
        smoke = 0
        DO: i = i + 1
            IF sprites(i).name = "2cigarette1" THEN
                sprites(i).handle = _LOADIMAGE("data\sprites\2cigarette2.png", 32)
                sprites(i).name = "2cigarette2"
            ELSEIF sprites(i).name = "2cigarette2" THEN
                sprites(i).handle = _LOADIMAGE("data\sprites\2cigarette1.png", 32)
                sprites(i).name = "2cigarette1"
            END IF
        LOOP UNTIL i = UBOUND(sprites)
    ELSE
        smoke = smoke + 1
    END IF
END SUB

SUB decreaseHappiness
    counter = counter + 1
    IF counter >= 50 AND happiness > 0 THEN
        counter = 0
        happiness = happiness - 1
    END IF
END SUB

SUB updateRandomEvent
    i = VAL(activeSprites(1))
    IF mouse.left AND inBounds(mouse.coord, sprites(i).coord, -5) THEN clickCondition = -1
    IF clickCondition OR eventState > 0 THEN
        'IF clickCondition then changeSprite
        eventState = eventState + 1
        SELECT CASE eventRunning
            CASE 1
                IF eventState = 50 THEN
                    increaseScore 5
                    changeTask
                    resetRandomEvent
                END IF
            CASE 2
                IF eventState = 20 THEN
                    increaseHappiness 10
                    resetRandomEvent
                END IF
            CASE 3
                IF eventState = 20 THEN
                    increaseHappiness 5
                    resetRandomEvent
                END IF
        END SELECT
    END IF
END SUB

SUB changeTask
    taskRND = INT(RND * 18) + 1
    SELECT CASE taskRND
        CASE 1: activeTask = "Satisfy the sales department"
        CASE 2: activeTask = "Empty your recycle bin"
        CASE 3: activeTask = "Delete your browser history"
        CASE 4: activeTask = "Do the job someone else forgot to do"
        CASE 5: activeTask = "Create more problems"
        CASE 6: activeTask = "Git merge - wait, something seems off..."
        CASE 7: activeTask = "Fix the printer"
        CASE 8: activeTask = "Restart the router"
        CASE 9: activeTask = "Choose a color theme for your editor"
        CASE 10: activeTask = "Browse hilarious memes on reddit"
        CASE 11: activeTask = "Get some coffee. It will help."
        CASE 12: activeTask = "Find out what's the best coffee brand"
        CASE 13: activeTask = "Watch a documentary about penguins"
        CASE 14: activeTask = "Check out the new Kanye West album"
        CASE 15: activeTask = "Play Minesweeper...or Solitaire."
        CASE 16: activeTask = "Automate your job."
        CASE 17: activeTask = "Spend 3 hours automating a 5 minute task."
        CASE 18: activeTask = "Take a big dump."
        CASE 19: activeTask = "Start an unnecessary argument"
    END SELECT
END SUB

SUB resetRandomEvent
    eventRunning = 0
    eventState = 0
    REDIM _PRESERVE activeSprites(0) AS STRING
    setSpriteStates "always"
END SUB

SUB startRandomEvent
    eventRunning = INT(RND * 3) + 1
    IF eventRunning = 0 OR eventRunning > 3 THEN resetRandomEvent: EXIT SUB
    setSpriteStates "random" + lst$(eventRunning)
END SUB

SUB loadFonts
    fontpath$ = "data\fonts\"
    fontr$ = fontpath$ + "PTMono-Regular.ttf"
    fonteb$ = fontpath$ + "OpenSans-ExtraBold.ttf"
    font_normal = _LOADFONT(fontr$, 16, "MONOSPACE")
    font_small = _LOADFONT(fontr$, 10, "MONOSPACE")
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
        CASE 114
            loadMaps
            loadSprites
            eventRunning = 0
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
        startTime = TIMER
    END IF
END SUB

SUB increaseScore (value AS INTEGER)
    score = score + value
END SUB

SUB increaseHappiness (value AS INTEGER)
    happiness = happiness + value
    IF happiness > maxHappiness THEN happiness = maxHappiness
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
    REDIM _PRESERVE AS STRING nothing(0), spriteFiles(0), activeSprites(0)
    spritePath$ = _CWD$ + "\data\sprites\"
    GetFileList spritePath$, nothing(), spriteFiles()
    IF UBOUND(spriteFiles) < 1 THEN: PRINT "fuck?": _DISPLAY: SLEEP: EXIT SUB
    DO: i = i + 1
        IF isImage(fileFormat$(spriteFiles(i))) THEN
            addSprite spritePath$ + spriteFiles(i)
            PRINT "loaded sprite " + sprites(UBOUND(sprites)).name + "!"
            _DISPLAY
        END IF
    LOOP UNTIL i = UBOUND(spriteFiles)
    setSpriteStates "start"
END SUB

SUB loadMaps
    REDIM _PRESERVE AS STRING nothing(0), mapFiles(0)
    mapPath$ = _CWD$ + "\data\maps\"
    GetFileList mapPath$, nothing(), mapFiles()
    IF UBOUND(mapFiles) < 1 THEN EXIT SUB
    DO: i = i + 1
        IF isMap(fileFormat$(mapFiles(i))) THEN
            addMap mapPath$ + mapFiles(i)
            PRINT "loaded map " + mapFiles(i) + "!"
            _DISPLAY
        END IF
    LOOP UNTIL i = UBOUND(mapFiles)
END SUB

FUNCTION isMap (sourceFileFormat AS STRING)
    SELECT CASE sourceFileFormat
        CASE ".tmf"
            isMap = -1
        CASE ELSE
            isMap = 0
    END SELECT
END FUNCTION

FUNCTION isImage (sourceFileFormat AS STRING)
    SELECT CASE sourceFileFormat
        CASE ".png"
            isImage = -1
        CASE ".jpeg"
            isImage = -1
        CASE ".jpg"
            isImage = -1
        CASE ELSE
            isImage = 0
    END SELECT
END FUNCTION

FUNCTION fileFormat$ (sourceFile AS STRING)
    fileFormat$ = MID$(sourceFile, _INSTRREV(sourceFile, "."), LEN(sourceFile))
END FUNCTION

SUB addMap (sourceFile AS STRING)
    REDIM AS STRING mapFileContent(0), fileName
    getFileArray mapFileContent(), sourceFile
    IF UBOUND(mapFileContent) < 1 THEN EXIT SUB
    nameStart = _INSTRREV(sourceFile, "\")
    nameEnd = _INSTRREV(sourceFile, ".")
    fileName = MID$(sourceFile, nameStart + 1, nameEnd - nameStart - 1)
    DO: i = i + 1
        addMapInfo mapFileContent(i), fileName
    LOOP UNTIL i = UBOUND(mapFileContent)
END SUB

SUB addMapInfo (source AS STRING, stateName AS STRING)
    REDIM _PRESERVE mapInfo(UBOUND(mapInfo) + 1) AS mapInfo
    m = UBOUND(mapInfo)
    mapInfo(m).spriteName = getArgument$(source, "spriteName")
    mapInfo(m).x = getArgument$(source, "x")
    mapInfo(m).y = getArgument$(source, "y")
    mapInfo(m).scale = getArgumentV(source, "scale")
    mapInfo(m).visible = getArgumentV(source, "visible")
    mapInfo(m).state = stateName
END SUB

SUB addToStringArray (array() AS STRING, toadd AS STRING)
    REDIM _PRESERVE array(UBOUND(array) + 1) AS STRING
    array(UBOUND(array)) = toadd
END SUB

SUB getFileArray (array() AS STRING, file AS STRING)
    IF _FILEEXISTS(file) = 0 THEN EXIT SUB
    freen = FREEFILE
    OPEN file FOR INPUT AS #freen
    IF EOF(freen) THEN CLOSE #freen: EXIT SUB
    DO
        INPUT #freen, filedata$
        addToStringArray array(), filedata$
    LOOP UNTIL EOF(freen)
    CLOSE #freen
END SUB

SUB writeFileArray (array() AS STRING, file AS STRING, exclude AS STRING)
    freen = FREEFILE
    OPEN file FOR OUTPUT AS #freen
    DO: index = index + 1
        IF array(index) <> exclude THEN PRINT #freen, array(index)
    LOOP UNTIL index = UBOUND(array)
    CLOSE #freen
END SUB

SUB addSprite (sourceFile AS STRING)
    REDIM _PRESERVE sprites(UBOUND(sprites) + 1) AS sprite
    s = UBOUND(sprites)
    sprites(s).file = sourceFile
    sprites(s).handle = _LOADIMAGE(sourceFile, 32)
    sprites(s).coord.w = _WIDTH(sprites(s).handle)
    sprites(s).coord.h = _HEIGHT(sprites(s).handle)
    nameStart = _INSTRREV(sourceFile, "\")
    nameEnd = _INSTRREV(sourceFile, ".")
    sprites(s).name = MID$(sourceFile, nameStart + 1, nameEnd - nameStart - 1)
    sprites(s).visible = 0
END SUB

SUB setSpriteStates (state AS STRING)
    IF UBOUND(sprites) = 0 THEN EXIT SUB
    DO: i = i + 1
        setSpriteState i, state
    LOOP UNTIL i = UBOUND(sprites)
END SUB

SUB setSpriteState (i AS INTEGER, state AS STRING)
    IF UBOUND(mapInfo) = 0 THEN: EXIT SUB
    noInfo = -1
    DO: m = m + 1
        IF mapInfo(m).spriteName = sprites(i).name AND (mapInfo(m).state = state OR mapInfo(m).state = "always") THEN
            IF mapInfo(m).state = state THEN
                addToStringArray activeSprites(), lst$(i)
            END IF
            modifySprite sprites(i).name, getSpriteX(mapInfo(m), sprites(i)), getSpriteY(mapInfo(m), sprites(i)), getSpriteW(mapInfo(m), sprites(i)), getSpriteH(mapInfo(m), sprites(i)), mapInfo(m).visible
            noInfo = 0
        END IF
    LOOP UNTIL m = UBOUND(mapInfo)
    IF noInfo THEN
        sprites(i).visible = 0
    END IF
END SUB

FUNCTION getSpriteX (mapInfo AS mapInfo, sprite AS sprite)
    SELECT CASE mapInfo.x
        CASE "left": getSpriteX = 0
        CASE "right": getSpriteX = _WIDTH(0) - getSpriteW(mapInfo, sprite)
        CASE "center": getSpriteX = (_WIDTH(0) / 2) - (getSpriteW(mapInfo, sprite) / 2)
        CASE ELSE: getSpriteX = VAL(mapInfo.x)
    END SELECT
END FUNCTION

FUNCTION getSpriteY (mapInfo AS mapInfo, sprite AS sprite)
    SELECT CASE mapInfo.y
        CASE "top": getSpriteY = 0
        CASE "bottom": getSpriteY = _HEIGHT(0) - (getSpriteH(mapInfo, sprite))
        CASE "center": getSpriteY = (_HEIGHT(0) / 2) - (getSpriteH(mapInfo, sprite) / 2)
        CASE ELSE: getSpriteY = VAL(mapInfo.y)
    END SELECT
END FUNCTION

FUNCTION getSpriteW (mapInfo AS mapInfo, sprite AS sprite)
    getSpriteW = _WIDTH(sprite.handle) * mapInfo.scale
END FUNCTION

FUNCTION getSpriteH (mapInfo AS mapInfo, sprite AS sprite)
    getSpriteH = _HEIGHT(sprite.handle) * mapInfo.scale
END FUNCTION

SUB modifySprite (spriteName AS STRING, x, y, w, h, visible AS _BYTE)
    IF UBOUND(sprites) < 1 THEN EXIT SUB
    DO: i = i + 1
        IF sprites(i).name = spriteName THEN
            IF x > -999 THEN sprites(i).coord.x = x
            IF y > -999 THEN sprites(i).coord.y = y
            IF w > -999 THEN sprites(i).coord.w = w
            IF h > -999 THEN sprites(i).coord.h = h
            IF visible < 1 THEN sprites(i).visible = visible
        END IF
    LOOP UNTIL i = UBOUND(sprites)
END SUB

SUB displaySpriteImage (this AS sprite, scale)
    IF this.handle < -1 THEN
        _PUTIMAGE (this.coord.x, this.coord.y)-(this.coord.x + (this.coord.w * scale), this.coord.y + (this.coord.h * scale)), this.handle

        IF MID$(this.name, 1, 12) = "2zbackground" THEN
            progressheight = 10
            levelprogress = (score MOD leveltreshhold) / leveltreshhold
            displayProgress this.coord.x + 10, (this.coord.y + (this.coord.h * 0.28)) - progressheight, this.coord.w * 0.33, progressheight, levelprogress, "h"
            _FONT font_small
            _PRINTSTRING (this.coord.x + 10, (this.coord.y + (this.coord.h * 0.28)) + 5), "Your task:"
            _PRINTSTRING (this.coord.x + 10, (this.coord.y + (this.coord.h * 0.28)) + 8 + _FONTHEIGHT), activeTask
        END IF
    END IF
END SUB

SUB displayUI
    REDIM AS STRING workingHours
    COLOR col&("ui"), col&("t")
    workingHours = lst$(INT(TIMER - startTime))
    IF workingHours = "69" OR workingHours = "420" OR workingHours = "1337" THEN workingHours = ";)"
    _PRINTSTRING (getRow(1), getColumn(1)), "You have been working for " + workingHours + " hours."
    _PRINTSTRING (getRow(1), getColumn(3)), "We are proud of you!"
    IF eventState > 0 THEN
        loadSize = 30
        loadState = eventState MOD loadSize
        IF loadState <= 4 THEN
            _PRINTSTRING (getRow(1), getColumn(5)), "Completing task."
        ELSEIF loadState > 4 AND loadState < 9 THEN
            _PRINTSTRING (getRow(1), getColumn(5)), "Completing task.."
        ELSE
            _PRINTSTRING (getRow(1), getColumn(5)), "Completing task..."
        END IF
    END IF
    happinessFactor = (happiness / maxHappiness)
    IF happinessFactor > 1 THEN happinessFactor = 1
    IF happinessFactor < 0 THEN happinessFactor = 0
    LINE (_WIDTH - 10, _HEIGHT - 5 - ((_HEIGHT - 10) * happinessFactor))-(_WIDTH - 5, _HEIGHT - 5), _RGBA(161, 255, 11, 255), BF
    SELECT CASE happinessFactor
        CASE IS < 0.3
            emojiFile = 3
        CASE IS > 0.7
            emojiFile = 1
        CASE ELSE
            emojiFile = 2
    END SELECT
    REDIM AS LONG emoji
    emoji = _LOADIMAGE("data\sprites\emoji" + lst$(emojiFile) + ".png", 32)
    emojiScale = 0.5
    _PUTIMAGE (_WIDTH - 20 - (_WIDTH(emoji) * emojiScale), 10)-(_WIDTH - 20, 10 + (_HEIGHT(emoji) * emojiScale)), emoji
END SUB

FUNCTION getRow (row AS _INTEGER64)
    getRow = 10 + (_FONTHEIGHT * row)
END FUNCTION

FUNCTION getColumn (column AS _INTEGER64)
    getColumn = 10 + (_FONTWIDTH * column)
END FUNCTION

SUB drawCircle (x AS _FLOAT, y AS _FLOAT, size AS _FLOAT, colour&)
    CIRCLE (x, y), size, colour&
    PAINT (x, y), colour&, colour&
END SUB

SUB displaySprites
    IF UBOUND(sprites) < 1 THEN EXIT SUB
    DO: s = s + 1
        IF sprites(s).visible = -1 THEN displaySprite s
    LOOP UNTIL s = UBOUND(sprites)
END SUB

SUB displaySprite (s)
    displaySpriteImage sprites(s), 1
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
    REDIM SearchDirectory2 AS STRING
    CONST IS_DIR = 1
    CONST IS_FILE = 2
    DIM flags AS LONG, file_size AS LONG
    SearchDirectory2 = SearchDirectory + CHR$(0)

    REDIM _PRESERVE DirList(100), FileList(100)
    DirCount = 0: FileCount = 0

    IF load_dir(SearchDirectory2) THEN
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
                    FileList(FileCount) = _TRIM$(nam$)
                END IF
            END IF
        LOOP UNTIL length = -1
        close_dir
    ELSE
        PRINT "Failed to load directory " + SearchDirectory2 + " with error: " + lst$(get_last_error)
        _DISPLAY
        SLEEP
    END IF
    REDIM _PRESERVE DirList(DirCount)
    REDIM _PRESERVE FileList(FileCount)
END SUB

FUNCTION getArgument$ (basestring AS STRING, argument AS STRING)
    getArgument$ = stringValue$(basestring, argument)
END FUNCTION

FUNCTION getArgumentV (basestring AS STRING, argument AS STRING)
    getArgumentV = VAL(stringValue$(basestring, argument))
END FUNCTION

FUNCTION stringValue$ (basestring AS STRING, argument AS STRING)
    IF LEN(basestring) > 0 THEN
        p = 1: DO
            IF MID$(basestring, p, LEN(argument)) = argument THEN
                endpos = INSTR(p + LEN(argument), basestring, ";")
                IF endpos = 0 THEN endpos = LEN(basestring) ELSE endpos = endpos - 1 'means that no comma has been found. taking the entire rest of the string as argument value.

                startpos = INSTR(p + LEN(argument), basestring, "=")
                IF startpos > endpos THEN
                    startpos = p + LEN(argument)
                ELSE
                    IF startpos = 0 THEN startpos = p + LEN(argument) ELSE startpos = startpos + 1 'means that no equal sign has been found. taking value right from the end of the argument name.
                END IF

                stringValue$ = LTRIM$(RTRIM$(MID$(basestring, startpos, endpos - startpos + 1)))
                EXIT FUNCTION
            END IF
            finder = INSTR(p + 1, basestring, ";") + 1
            IF finder > 1 THEN p = finder ELSE stringValue$ = "": EXIT FUNCTION
        LOOP UNTIL p >= LEN(basestring)
    END IF
END FUNCTION
