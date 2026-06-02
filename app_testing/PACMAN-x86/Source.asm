
; M. Zubair Adnan
; 22i-0789-B
; Semester Project

INCLUDE Irvine32.inc
BUFFER_SIZE = 5000
includelib Winmm.lib
PlaySound PROTO,
        pszSound:PTR BYTE, 
        hmod:DWORD, 
        fdwSound:DWORD
.data

beginSound db ".\startSound.wav",0
pacmandeath db ".\DeathSound.wav",0
foodsound db ".\FoodSound.wav",0
wakasound db ".\WakaSound.wav",0
gameOverSound db ".\GameOverSound.wav",0

errorMessage1 BYTE "Cannnot Open File", 0
errorMessage2 BYTE "Error Reading File", 0
errorMessage3 BYTE "Buffer too small for the file", 0

ground BYTE "------------------------------------------------------------------------------------------------------------------------",0
ground1 BYTE "|",0ah,0
ground2 BYTE "|",0
level1 BYTE "_", 0
level1Coordinates Word 250 dup (?)
levelCoordinatesOffset DD ?
numberOfCoordinates Word ?
levelTemp BYTE 2 dup(?)
temp byte ?

intro1 BYTE "                ________   ___        ___  ___   _______             ________   ________   ___  __       ", 0ah   
       BYTE "               |\   __  \ |\  \      |\  \|\  \ |\  ___ \           |\   __  \ |\   __  \ |\  \|\  \     ", 0ah   
       BYTE "               \ \  \|\ /_\ \  \     \ \  \\\  \\ \   __/|          \ \  \|\  \\ \  \|\  \\ \  \/  /|_   ", 0ah   
       BYTE "                \ \   __  \\ \  \     \ \  \\\  \\ \  \_|/__         \ \  \\\  \\ \   _  _\\ \   ___  \  ", 0ah   
       BYTE "                 \ \  \|\  \\ \  \____ \ \  \\\  \\ \  \_|\ \         \ \  \\\  \\ \  \\  \|\ \  \\ \  \ ", 0ah   
       BYTE "                  \ \_______\\ \_______\\ \_______\\ \_______\         \ \_______\\ \__\\ _\ \ \__\\ \__\", 0ah   
       BYTE "                   \|_______| \|_______| \|_______| \|_______|          \|_______| \|__|\|__| \|__| \|__|", 0ah   
       BYTE "                                                                                                         ", 0ah 
       BYTE "                ________   ________   _______    ________   _______    ________    _________   ________       ", 0ah      
       BYTE "               |\   __  \ |\   __  \ |\  ___ \  |\   ____\ |\  ___ \  |\   ___  \ |\___   ___\|\   ____\      ", 0ah     
       BYTE "               \ \  \|\  \\ \  \|\  \\ \   __/| \ \  \___|_\ \   __/| \ \  \\ \  \\|___ \  \_|\ \  \___|_     ", 0ah     
       BYTE "                \ \   ____\\ \   _  _\\ \  \_|/__\ \_____  \\ \  \_|/__\ \  \\ \  \    \ \  \  \ \_____  \    ", 0ah     
       BYTE "                 \ \  \___| \ \  \\  \|\ \  \_|\ \\|____|\  \\ \  \_|\ \\ \  \\ \  \    \ \  \  \|____|\  \   ", 0ah    
       BYTE "                  \ \__\     \ \__\\ _\ \ \_______\ ____\_\  \\ \_______\\ \__\\ \__\    \ \__\   ____\_\  \  ", 0ah    
       BYTE "                   \|__|      \|__|\|__| \|_______||\_________\\|_______| \|__| \|__|     \|__|  |\_________\ ", 0ah  
       BYTE "                                                    \|_________|                                  \|_________|", 0
                                                                                                    
 intro2 BYTE "                         ________   ________   ________   _____ ______    ________   ________      ", 0ah
        BYTE "                        |\   __  \ |\   __  \ |\   ____\ |\   _ \  _   \ |\   __  \ |\   ___  \    ", 0ah
        BYTE "                        \ \  \|\  \\ \  \|\  \\ \  \___| \ \  \\\__\ \  \\ \  \|\  \\ \  \\ \  \   ", 0ah
        BYTE "                         \ \   ____\\ \   __  \\ \  \     \ \  \\|__| \  \\ \   __  \\ \  \\ \  \  ", 0ah
        BYTE "                          \ \  \___| \ \  \ \  \\ \  \____ \ \  \    \ \  \\ \  \ \  \\ \  \\ \  \ ", 0ah   
        BYTE "                           \ \__\     \ \__\ \__\\ \_______\\ \__\    \ \__\\ \__\ \__\\ \__\\ \__\", 0ah
        BYTE "                            \|__|      \|__|\|__| \|_______| \|__|     \|__| \|__|\|__| \|__| \|__|", 0
                                                                             
intro3 BYTE "                                                Press Any Key To Continue", 0                                                                             
intro4 BYTE "                                                                         ", 0                                                                            

mainMenu1 BYTE "Welcome, ", 0
mainMenu2 BYTE "                                       Press 1 to Start the Game      ", 0ah
          BYTE "                                       Press 2 to see the instructions", 0ah
          BYTE "                                       Press 3 to see the Hall of Fame", 0

infoMenu1 BYTE "Player: ", 0

pauseMenu1 BYTE "Game Paused. Press P to Resume", 0
pauseMenu2 BYTE "                              ", 0
   
instructionMenu1 BYTE "      ___  ________   ________  _________  ________  ___  ___  ________ _________  ___  ________  ________      ", 0ah
                 BYTE "     |\  \|\   ___  \|\   ____\|\___   ___|\   __  \|\  \|\  \|\   ____|\___   ___|\  \|\   __  \|\   ___  \    ", 0ah
                 BYTE "     \ \  \ \  \\ \  \ \  \___|\|___ \  \_\ \  \|\  \ \  \\\  \ \  \___\|___ \  \_\ \  \ \  \|\  \ \  \\ \  \   ", 0ah
                 BYTE "      \ \  \ \  \\ \  \ \_____  \   \ \  \ \ \   _  _\ \  \\\  \ \  \       \ \  \ \ \  \ \  \\\  \ \  \\ \  \  ", 0ah
                 BYTE "       \ \  \ \  \\ \  \|____|\  \   \ \  \ \ \  \\  \\ \  \\\  \ \  \____   \ \  \ \ \  \ \  \\\  \ \  \\ \  \ ", 0ah
                 BYTE "        \ \__\ \__\\ \__\____\_\  \   \ \__\ \ \__\\ _\\ \_______\ \_______\  \ \__\ \ \__\ \_______\ \__\\ \__\", 0ah
                 BYTE "         \|__|\|__| \|__|\_________\   \|__|  \|__|\|__|\|_______|\|_______|   \|__|  \|__|\|_______|\|__| \|__|", 0ah
                 BYTE "                     \|_________|                                                                           ", 0                                                                                      

instructionMenu2 BYTE "                                             Press w to go up", 0ah
                 BYTE "                                             Press s to do down", 0ah
                 BYTE "                                             Press d to go right", 0ah
                 BYTE "                                             Press a to go left", 0ah
                 BYTE "                                             Press x to quit", 0ah
                 BYTE "                                             Press p to pause game", 0ah
                 BYTE "                                             Press i to see instructions menu during game", 0ah
                 BYTE "                                             Press b to go back to", 0

hallOfFameMenu1 BYTE " ___  ___  ________  ___       ___             ________  ________     ________ ________  _____ ______   _______       ", 0ah
                BYTE "|\  \|\  \|\   __  \|\  \     |\  \           |\   __  \|\  _____\   |\  _____|\   __  \|\   _ \  _   \|\  ___ \      ", 0ah
                BYTE " \ \  \\\  \ \  \|\  \ \  \    \ \  \          \ \  \|\  \ \  \__/    \ \  \__/\ \  \|\  \ \  \\\__\ \  \ \   __/|    ", 0ah
                BYTE "  \ \   __  \ \   __  \ \  \    \ \  \          \ \  \\\  \ \   __\    \ \   __\\ \   __  \ \  \\|__| \  \ \  \_|/__  ", 0ah
                BYTE "   \ \  \ \  \ \  \ \  \ \  \____\ \  \____      \ \  \\\  \ \  \_|     \ \  \_| \ \  \ \  \ \  \    \ \  \ \  \_|\ \ ", 0ah
                BYTE "    \ \__\ \__\ \__\ \__\ \_______\ \_______\     \ \_______\ \__\       \ \__\   \ \__\ \__\ \__\    \ \__\ \_______\", 0ah
                BYTE "     \|__|\|__|\|__|\|__|\|_______|\|_______|      \|_______|\|__|        \|__|    \|__|\|__|\|__|     \|__|\|_______|", 0 
                                                                                                                       
hallOfFameMenu2 BYTE "                                              Press m to go back to main menu", 0

getSetGo BYTE "      ________   _______   _________            ________   _______   _________            ________   ________     ", 0ah
         BYTE "     |\   ____\ |\  ___ \ |\___   ___\         |\   ____\ |\  ___ \ |\___   ___\         |\   ____\ |\   __  \    ", 0ah
         BYTE "     \ \  \___| \ \   __/|\|___ \  \_|         \ \  \___|_\ \   __/|\|___ \  \_|         \ \  \___| \ \  \|\  \   ", 0ah
         BYTE "      \ \  \  ___\ \  \_|/__   \ \  \           \ \_____  \\ \  \_|/__   \ \  \           \ \  \  ___\ \  \\\  \  ", 0ah
         BYTE "       \ \  \|\  \\ \  \_|\ \   \ \  \           \|____|\  \\ \  \_|\ \   \ \  \           \ \  \|\  \\ \  \\\  \ ", 0ah
         BYTE "        \ \_______\\ \_______\   \ \__\            ____\_\  \\ \_______\   \ \__\           \ \_______\\ \_______\", 0ah
         BYTE "         \|_______| \|_______|    \|__|           |\_________\\|_______|    \|__|            \|_______| \|_______|", 0ah
         BYTE "                                                  \|_________|                                                    ", 0

level1StartMsg BYTE "                    ___        _______    ___      ___  _______    ___                _____     ", 0ah
               BYTE "                   |\  \      |\  ___ \  |\  \    /  /||\  ___ \  |\  \              / __  \    ", 0ah
               BYTE "                   \ \  \     \ \   __/| \ \  \  /  / /\ \   __/| \ \  \            |\/_|\  \   ", 0ah
               BYTE "                    \ \  \     \ \  \_|/__\ \  \/  / /  \ \  \_|/__\ \  \           \|/ \ \  \  ", 0ah
               BYTE "                     \ \  \____ \ \  \_|\ \\ \    / /    \ \  \_|\ \\ \  \____           \ \  \ ", 0ah
               BYTE "                      \ \_______\\ \_______\\ \__/ /      \ \_______\\ \_______\          \ \__\", 0ah
               BYTE "                       \|_______| \|_______| \|__|/        \|_______| \|_______|           \|__|", 0
                                                                             
level2StartMsg BYTE "                    ___        _______    ___      ___  _______    ___                _______     ", 0ah
               BYTE "                   |\  \      |\  ___ \  |\  \    /  /||\  ___ \  |\  \              /  ___  \    ", 0ah
               BYTE "                   \ \  \     \ \   __/| \ \  \  /  / /\ \   __/| \ \  \            /__/|_/  /|   ", 0ah
               BYTE "                    \ \  \     \ \  \_|/__\ \  \/  / /  \ \  \_|/__\ \  \           |__|//  / /   ", 0ah
               BYTE "                     \ \  \____ \ \  \_|\ \\ \    / /    \ \  \_|\ \\ \  \____          /  /_/__  ", 0ah
               BYTE "                      \ \_______\\ \_______\\ \__/ /      \ \_______\\ \_______\       |\________\", 0ah
               BYTE "                       \|_______| \|_______| \|__|/        \|_______| \|_______|        \|_______|", 0
                                                                               
level3StartMsg BYTE "                    ___        _______    ___      ___  _______    ___               ________     ", 0ah
               BYTE "                   |\  \      |\  ___ \  |\  \    /  /||\  ___ \  |\  \             |\_____  \    ", 0ah
               BYTE "                   \ \  \     \ \   __/| \ \  \  /  / /\ \   __/| \ \  \            \|____|\ /_   ", 0ah
               BYTE "                    \ \  \     \ \  \_|/__\ \  \/  / /  \ \  \_|/__\ \  \                 \|\  \  ", 0ah
               BYTE "                     \ \  \____ \ \  \_|\ \\ \    / /    \ \  \_|\ \\ \  \____           __\_\  \ ", 0ah
               BYTE "                      \ \_______\\ \_______\\ \__/ /      \ \_______\\ \_______\        |\_______\", 0ah
               BYTE "                       \|_______| \|_______| \|__|/        \|_______| \|_______|        \|_______|", 0
                             
gameOver BYTE "          ________   ________   _____ ______    _______           ________   ___      ___  _______    ________     ", 0ah
         BYTE "         |\   ____\ |\   __  \ |\   _ \  _   \ |\  ___ \         |\   __  \ |\  \    /  /||\  ___ \  |\   __  \    ", 0ah
         BYTE "         \ \  \___| \ \  \|\  \\ \  \\\__\ \  \\ \   __/|        \ \  \|\  \\ \  \  /  / /\ \   __/| \ \  \|\  \   ", 0ah
         BYTE "          \ \  \  ___\ \   __  \\ \  \\|__| \  \\ \  \_|/__       \ \  \\\  \\ \  \/  / /  \ \  \_|/__\ \   _  _\  ", 0ah
         BYTE "           \ \  \|\  \\ \  \ \  \\ \  \    \ \  \\ \  \_|\ \       \ \  \\\  \\ \    / /    \ \  \_|\ \\ \  \\  \| ", 0ah
         BYTE "            \ \_______\\ \__\ \__\\ \__\    \ \__\\ \_______\       \ \_______\\ \__/ /      \ \_______\\ \__\\ _\ ", 0ah
         BYTE "             \|_______| \|__|\|__| \|__|     \|__| \|_______|        \|_______| \|__|/        \|_______| \|__|\|__|", 0
                                                                                                         
gameWon BYTE "               ___    ___  ________   ___  ___          ___       __    ________   ________           ___         ", 0ah  
        BYTE "              |\  \  /  /||\   __  \ |\  \|\  \        |\  \     |\  \ |\   __  \ |\   ___  \        |\  \        ", 0ah  
        BYTE "              \ \  \/  / /\ \  \|\  \\ \  \\\  \       \ \  \    \ \  \\ \  \|\  \\ \  \\ \  \       \ \  \       ", 0ah  
        BYTE "               \ \    / /  \ \  \\\  \\ \  \\\  \       \ \  \  __\ \  \\ \  \\\  \\ \  \\ \  \       \ \  \      ", 0ah  
        BYTE "                \/  /  /    \ \  \\\  \\ \  \\\  \       \ \  \|\__\_\  \\ \  \\\  \\ \  \\ \  \       \ \__\     ", 0ah  
        BYTE "              __/  / /       \ \_______\\ \_______\       \ \____________\\ \_______\\ \__\\ \__\       \|__|     ", 0ah  
        BYTE "             |\___/ /         \|_______| \|_______|        \|____________| \|_______| \|__| \|__|           ___   ", 0ah  
        BYTE "             \|___|/                                                                                       |\__\ ", 0ah   
        BYTE "                                                                                                           \|__| ", 0   
        
Level1Row1 BYTE "########################################################################################", 0ah
           BYTE "# ................                                                                     #", 0ah
           BYTE "#                                                                      ............... #", 0ah
           BYTE "############################                                 ###########################", 0ah
           BYTE "############################      ......................     ###########################", 0ah
           BYTE "#                                 ######################                               #", 0ah
           BYTE "#      ..............            ########################          .............       #", 0ah
           BYTE "#      ##############           ##########################         #############       #", 0ah
           BYTE "#      ## ........ ##            ########################          ## ..........       #", 0ah
           BYTE "#                                 ######################           ##                  #", 0ah
           BYTE "#############..#############      ......................     #############..############", 0ah
           BYTE "#############..#############                                 #############..############", 0ah
           BYTE "#          ......                       #########                       ......         #", 0ah
           BYTE "#############..#############                                 #############..############", 0ah
           BYTE "#############..#############     ......................      #############..############", 0ah
           BYTE "#                                ######################                                #", 0ah
           BYTE "#           ..........          ########################            ..........         #", 0ah
           BYTE "#           ##########         ##########################           ##########         #", 0ah
           BYTE "#           .. ## ....          ########################            ..........         #", 0ah
           BYTE "#                                ######################                                #", 0ah
           BYTE "####  ######################     ......................      #################### ######", 0ah
           BYTE "####  ######################                                 #################### ######", 0ah
           BYTE "#                        ###                                 .................         #", 0ah
           BYTE "# ...............                                                                      #", 0ah
           BYTE "########################################################################################", 0

Level2Row1 BYTE "########################################################################################", 0ah
           BYTE "# ...................................................................................  #", 0ah
           BYTE "# .. ########################## ........########################################## ..  #", 0ah
           BYTE "# .. ##                                                                         ## ..  #", 0ah
           BYTE "# .. ##     ############################################         ############ .......  #", 0ah
           BYTE "# .. ##                                                             ....   ####### ..  #", 0ah
           BYTE "# .. ##                 ......   #################    .....                     ## ..  #", 0ah
           BYTE "# .. ## ..  ##       ##############   .......   ##############                  ## ..  #", 0ah
           BYTE "# .. ## ..  ##                                                                  ## ..  #", 0ah
           BYTE "# .. ## ..  ##    ###########..#########..##################..###############   ## ..  #", 0ah
           BYTE "# .. ## ..  ##                                                                  ## ..  #", 0ah
           BYTE "# .. ## ..  ##                                                                  ## ..  #", 0ah
           BYTE "# ........  ##    ###########         #################      ## .      ##       .. ..  #", 0ah
           BYTE "# .. ## ..  ##                                               ## .      ##       ## ..  #", 0ah
           BYTE "# .. ## ..  ##       ........                             .. ## .      ##       ## ..  #", 0ah
           BYTE "# .. ## ..  ##       ########          ## . ##     ## .. ########      ##       ## ..  #", 0ah
           BYTE "# .. ## ..  ##       ## .. ##          ## . ##     ## .. ## .          ##       ## ..  #", 0ah
           BYTE "# .. ## ..  ##       ## .. ##    ######## . ##     ## .. ## .          ##       ## ..  #", 0ah
           BYTE "# .. ## ..  ##       ## .. ##     .... ## . ##     ######## .          ##       ## ..  #", 0ah
           BYTE "# .. ## ..  ##                         ## . ##                         ##       ## ..  #", 0ah
           BYTE "# ........  ##  ######################### . #############################       ## ..  #", 0ah
           BYTE "# .. ## ..  ##                                                                  ## ..  #", 0ah
           BYTE "# .. ############################################# ....... ####################### ..  #", 0ah           
           BYTE "# ...................................................................................  #", 0ah
           BYTE "########################################################################################", 0

Level3Row1 BYTE "########################################################################################", 0ah
           BYTE "#                                                       ...                            #", 0ah
           BYTE "#                                                 ...  ######     ##        ######     #", 0ah
           BYTE "#      #############       ##               ...  ######           ##        ## ..      #", 0ah
           BYTE "#      ####### .....       ## ...     ...  ######            ...  ##        ## ..      #", 0ah
           BYTE "#                 ##       ######## .######                 ########        ## ..      #", 0ah
           BYTE "#######           ##       ##               ...                   ##    ##########     #", 0ah
           BYTE "# ....            ##       ##   ....       ###### ...             ##                   #", 0ah
           BYTE "#                 ##       ##    ....       ...  ###### ...                     ### .. #", 0ah
           BYTE "########## . #########     ##     ....            ...  ######   ########### . ##########", 0ah
           BYTE "########## . #########                                  ...     ########### . ##########", 0ah
           BYTE "########## . #########                                          ########### . ##########", 0ah
           BYTE " .........                      ########################        ...........             ", 0ah
           BYTE "########## . #########                                          ########### . ##########", 0ah
           BYTE "########## . #########                                ####      ########### . ##########", 0ah
           BYTE "########## . #########      ############              .. #      ########### . ##########", 0ah
           BYTE "#   ..  ##                  ## .................                                       #", 0ah
           BYTE "#   ..  ##                  ## .### .#############. ####          ##                   #", 0ah
           BYTE "#   ..  ##  .....           ## .### .#############. ####          ## .#####            #", 0ah
           BYTE "#   ..  ##########          ## .######## ...... ##. ####          ## .#####            #", 0ah
           BYTE "#   ####  ...... #####      ## .###### .. ####  ... ####          ## ...........       #", 0ah
           BYTE "#         ###   ......      ## .###### .################          ##############       #", 0ah
           BYTE "#           ####                                                    ........  ##       #", 0ah
           BYTE "#                                                                                      #", 0ah
           BYTE "########################################################################################", 0                                                                                                 

levelCoins Word 260, 376, 185  ; 260, 376, 185

currentLevelNumber BYTE 0
maxLevel BYTE 2
levelOffsets DD offset Level1Row1, offset Level2Row1, offset Level3Row1
currentLevelOffset DD ?
currentLevelCoins Word 0
coinsCollected Word ?

enemy1 BYTE "#", 0
enemyCoordinates Word 3 dup(?)
enemyMVMT WORD 0, 0, 0

tempHold DD 0

strScore BYTE "Your score is: ",0
score WORD 0

strLife BYTE "Lives Left: ", 0
lives BYTE 3

initialXPos BYTE 44 ; 44
initialYPos BYTE 12 ; 12

xPos BYTE 44
yPos BYTE 12

xCoinPos BYTE ?
yCoinPos BYTE ?

inputChar BYTE ?

userNamePrompt BYTE "Enter Your Name: ", 0
userName BYTE 255 dup(?), 0
userNameSize BYTE ?

buffer BYTE BUFFER_SIZE DUP(?)
filename    BYTE "output.txt"
fileHandle  HANDLE ?

.code
main PROC

    ; call PROC to display the intro at the start of the game
    call displayIntro

    ; make space for return value
    sub esp, 4
    push offset userNamePrompt
    push offset userName
    ; call PROC to prompt the user to get their Name
    call getUserName
    pop eax
    mov userNameSize, al

mainMenu:

    push offset hallOfFameMenu1
    push offset hallOfFameMenu2
    push offset instructionMenu1
    push offset instructionMenu2
    push offset intro2
    push offset userName
    push offset mainMenu1
    push offset mainMenu2
    ; call PROC to display the main menu to the player
    call displayMainMenu

newLevel:
   
    ; load the offset of the current level into the currentLevelOffset variable
    sub esp, 4
    movzx edx, currentLevelNumber
    push edx
    push offset levelOffsets
    call selectCurrentLevelOffset
    pop currentLevelOffset
    pop eax
    
    sub esp, 4
    push offset levelCoins
    movzx edx, currentLevelNumber
    push edx
    call selectCurrentLevelCoins
    pop eax
    add currentLevelCoins, ax
    
    movzx edx, currentLevelNumber
    push edx
    ; call PROC to prompt the start of the level
    call displayLevelStart
    
    ; draw the current level by the offset currently present in the currentLevelOffset
    mov edx, currentLevelOffset
    push edx
    call displayLevel
     
    ;call DrawPlayer
    call Randomize
   
    cmp currentLevelNumber, 0
    JE lowerLevel1
    call CreateRandomCoin
    call DrawCoin   
lowerLevel1: 

resetAfterCollision:
    ; generate the initial spawn point for the player
    mov edx, 0
    push edx
    call setInitialPlayerSpawn
    pop edx
    mov xPos, dl
    mov yPos, dh
    ; display the player
    call DrawPlayer

    ; generate the initial spawn points for the ghosts associated with the current level
    movzx edx, currentLevelNumber
    push edx
    push offset enemyCoordinates
    call setInitialEnemySpawn               ; set enemyMVMT to zero 
    ; display the ghosts
    movzx edx, currentLevelNumber
    push edx
    push offset enemyCoordinates
    call drawEnemy
    
    ; draw score:
    push offset strScore
    call drawScore
    mov eax, 300
    call delay

    gameLoop:
        
        push offset infoMenu1
        push offset userName
        call drawName


        movzx eax, currentLevelCoins
        cmp coinsCollected, ax
        JL continue
        inc currentLevelNumber
        movzx eax, maxLevel
        cmp currentLevelNumber, al
        JG gameFinished
        jmp newLevel
continue:


        mov edx, currentLevelOffset
        push edx
        call displayLevel
        
        ; PROC to display the bonus coin 
        cmp currentLevelNumber, 0
        JE lowerLevel2
        call DrawCoin
lowerLevel2:
        call DrawPlayer

        ; clears the current position of the ghost
        movzx edx, currentLevelNumber
        push edx
        push offset enemyCoordinates
        call updateEnemy
        
        ; generate the moves for the ghost
        movzx edx, currentLevelNumber
        push edx 
        push offset enemyMVMT
        call randEnemyMVMT

        ; moves enemy in the relevant direction
        movzx ecx, currentLevelNumber
        inc ecx
        mov edx, offset enemyMVMT
        mov esi, offset enemyCoordinates
        movEnemyLoop:
        push ecx
        push edx
        push esi

        mov eax, [edx]
        push eax
        mov eax, [esi]
        push eax
        push currentLevelOffset
        call movEnemy
        pop eax

        pop ebx
        pop esi
        pop edx
        pop ecx
        mov [esi], ax
        mov [edx], bx
        add edx, 2
        add esi, 2
        loop movEnemyLoop

        ; draws enemy at the relevant position
        movzx edx, currentLevelNumber
        push edx
        push offset enemyCoordinates
        call drawEnemy
        mov eax, 100
        call delay

        ; checking for ghost collision
        movzx ecx, currentLevelNumber
        inc ecx                         ; current number of ghosts
        mov esi, offset enemyCoordinates
        ghostCollisionLoop:
        push ecx
        push esi
        sub esp, 4
        mov edx, 0
        mov dl, xPos
        mov dh, yPos
        push edx
        mov edx, 0
        mov edx, [esi]
        push edx
        call checkGhostCollision
        pop eax
        cmp eax, 0
        JE noLivesLost1
        ;INVOKE PlaySound, OFFSET pacmandeath, NULL,11h
        mov eax, 200
        call delay
        cmp lives, 0
        JE livesFinished
        dec lives
        movzx edx, currentLevelNumber
        push edx
        push offset enemyCoordinates
        call updateEnemy
        call UpdatePlayer
        mov eax, 200
        call delay
        jmp resetAfterCollision
noLivesLost1:
        pop esi
        add esi, 2
        pop ecx
        loop ghostCollisionLoop

        ; displaying the current number of lives
        mov esi, offset strLife
        movzx edx, lives        ; lives left
        push esi
        push edx
        call drawLives
      
        ; getting points:
        mov bl,xPos
        cmp bl,xCoinPos
        jne notCollecting
        mov bl,yPos
        cmp bl,yCoinPos
        jne notCollecting
        ; player is intersecting coin:
        add score, 10
        INVOKE PlaySound, OFFSET foodsound, NULL,11h
        mov eax, 200
        call delay

        ; draw score:
        push offset strScore
        call drawScore
        
        call CreateRandomCoin
        call DrawCoin
notCollecting:

        mov eax,white (black * 16)
        call SetTextColor

        ; get user key input:
        call ReadKey
        jz gameLoop         ; if no input has been given 
        mov inputChar,al

        ; exit game if user types 'x':
        cmp inputChar,"x"
        je exitGame

        cmp inputChar,"w"
        je moveUp

        cmp inputChar,"s"
        je moveDown

        cmp inputChar,"a"
        je moveLeft

        cmp inputChar,"d"
        je moveRight

        cmp inputChar, "p"
        je showPauseMenu

        cmp inputChar, "i"
        je showInstructionsMenu

        jmp gameLoop

showPauseMenu:
        push offset pauseMenu1
        push offset pauseMenu2
        call displayPauseMenu
        jmp gameLoop

showInstructionsMenu:
        push offset instructionMenu1
        push offset instructionMenu2
        call displayInstructionsMenu
        jmp gameLoop

        moveUp:
        ; allow player to jump:
        call UpdatePlayer
        dec yPos
        cmp yPos, 2     ; min possible y coordinate
        JGE noUpperBoundaryCollision
        inc yPos
noUpperBoundaryCollision:
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkUpCollision       ; check for collision with a wall
            add esp, 8
            pop eax
            cmp eax, 0
            JE withinBound1
            inc yPos
withinBound1:
            INVOKE PlaySound, OFFSET wakasound, NULL,11h
            call DrawPlayer
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkUpCoinCollision
            add esp, 8
            pop eax
            cmp eax, 0
            JE noCoinCollision1
            inc score
            inc coinsCollected
noCoinCollision1:
            push offset strScore
            call drawScore
        jmp gameLoop

        moveDown:
        call UpdatePlayer
        inc yPos
        ; check for boundary collision
        cmp yPos, 28    ; max possible y coordinate
        JBE noBottomBoundaryCollision
        dec ypos
noBottomBoundaryCollision:
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkDownCollision     ; check for collision with a wall
            add esp, 8
            ;add esp, 12
            pop eax
            cmp al, 0
            JE withinBound2
            dec yPos
withinBound2:
            call DrawPlayer
            INVOKE PlaySound, OFFSET wakasound, NULL,11h
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkDownCoinCollision
            add esp, 8
            pop eax
            cmp eax, 0
            JE noCoinCollision2
            inc score
            inc coinsCollected
noCoinCollision2:
            push offset strScore
            call drawScore
        jmp gameLoop

        moveLeft:
        call UpdatePlayer
        cmp yPos, 13
        JNE noTeleportation3
        cmp xPos, 1
        JNE noTeleportation3
        mov yPos, 13
        mov xPos, 87
        jmp withinBound3
noTeleportation3:
        dec xPos
        ; check for boundary collision
        cmp xPos, 1     ; min possible x coordinate
        JGE noLeftBoundaryCollision
        inc xPos
noLeftBoundaryCollision:
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkLeftCollision     ; check for collision with a wall
            add esp, 8
            pop eax
            cmp al, 0
            JE withinBound3
            inc xPos
withinBound3:
            call DrawPlayer
            INVOKE PlaySound, OFFSET wakasound, NULL,11h
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkLeftCoinCollision
            add esp, 8
            pop eax
            cmp eax, 0
            JE noCoinCollision3
            inc score
            inc coinsCollected
noCoinCollision3:
            push offset strScore
            call drawScore
        jmp gameLoop

        moveRight:
        call UpdatePlayer
        cmp yPos, 13
        JNE noTeleportation4
        cmp xPos, 87
        JNE noTeleportation4
        mov yPos, 13
        mov xPos, 1
        jmp withinBound4
noTeleportation4: 
        inc xPos
        ; check for boundary collision
        cmp xPos, 118   ; max possible x coordinate
        JBE noRightBoundaryCollision
        dec xPos
noRightBoundaryCollision:
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkRightCollision    ; check for collision with a wall
            add esp, 8
            pop eax
            cmp al, 0
            JE withinBound4
            dec xPos
withinBound4:            
            call DrawPlayer
            INVOKE PlaySound, OFFSET wakasound, NULL,11h
            sub esp, 4
            mov edx, 0
            mov dl, xPos
            mov dh, yPos
            push edx
            push currentLevelOffset
            call checkRightCoinCollision
            add esp, 8
            pop eax
            cmp eax, 0
            JE noCoinCollision4
            inc score
            inc coinsCollected
noCoinCollision4:
            push offset strScore
            call drawScore
        jmp gameLoop

    jmp gameLoop

    
gameFinished:
    push offset gameWon
    push offset infoMenu1
    push offset userName
    push offset strScore
    movzx eax, score
    push eax
    push offset strLife
    movzx eax, lives
    push eax
    call displayGameWon
    jmp exitGame

livesFinished:
    push offset gameOver
    push offset infoMenu1
    push offset userName
    push offset strScore
    movzx eax, score
    push eax
    push offset strLife
    movzx eax, lives
    push eax
    call displayGameOver
    
exitGame:

    exit
main ENDP

drawScore PROC
    push ebp
    mov ebp, esp
    
    mov eax, white
    call setTextColor
    mov dl,0
    mov dh,0
    call Gotoxy
    mov edx, [ebp + 8]
    call WriteString
    mov eax, 0
    mov ax,score
    call WriteDec

    pop ebp
    ret 4
drawScore ENDP

DrawPlayer PROC
    ; draw player at (xPos,yPos):
    mov eax,yellow ;(blue*16)
    call SetTextColor
    mov dl,xPos
    mov dh,yPos
    call Gotoxy
    mov al,"X"
    call WriteChar
    ret
DrawPlayer ENDP

UpdatePlayer PROC
    mov dl,xPos
    mov dh,yPos
    call Gotoxy
    mov al," "
    call WriteChar
    ret
UpdatePlayer ENDP

DrawCoin PROC
    mov eax,yellow ;(red * 16)
    call SetTextColor
    mov dl,xCoinPos
    mov dh,yCoinPos
    call Gotoxy
    mov al,"$"
    call WriteChar
    ret
DrawCoin ENDP

CreateRandomCoin PROC
    ; setting the x coord of the coin
    ;mov eax, 118     ; max x coord
    mov eax, 88
    call RandomRange
    cmp al, 0
    JG skipXCordInc1
    add al, 1
skipXCordInc1:
    mov xCoinPos, al
    
    ; setting the y coord of the coin
    ;mov eax, 28      ; max y coord 
    mov eax, 24
    call RandomRange
    cmp al, 1
    JG skipYCordInc1
    add al, 2
skipYCordInc1:
    mov yCoinPos, al

    ; ensuring that the coin does not spawn on the wall of a given level
checkAgain:    
    sub esp, 4
    mov edx, 0
    mov dl, xCoinPos
    mov dh, yCoinPos
    push edx
    push currentLevelOffset
    call checkUpCollision
    add esp, 8
    pop eax
    cmp al, 0
    JE noChange
        dec yCoinPos
    jmp checkAgain

noChange:
    ret
CreateRandomCoin ENDP

selectCurrentLevelOffset PROC
    push ebp
    mov ebp, esp
    
    mov eax, [ebp + 12]
    mov esi, [ebp + 8]
    CDQ
    mov bx, 4
    imul bx
    mov edx, [esi + eax]
    mov [ebp + 16], edx

    pop ebp
    ret 8
selectCurrentLevelOffset ENDP

displayLevel PROC
    push ebp
    mov ebp, esp

    mov dl, 0
    mov dh, 1
    call gotoxy
    mov eax, blue
    call setTextColor
    mov edx, [ebp + 8]
    ;mov edx, offset Level1Row2
    call writeString

    pop ebp
    ret 4
displayLevel ENDP

checkUpCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0              ; 0 for no collision and 1 for collision detected
    mov [ebp + 16], eax     ; space to hold true or false
    mov ecx, [ebp + 12]     ; current coordinates 
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch              ; ch has the y coord
    imul edx, 89
    mov ebx, 0
    mov bl, cl              ; cl has the x cord
    add edx, ebx
    sub edx, 89             ; since each line has at max 89 characters, adjusting the coordinates accordingly
    mov al, [esi + edx]     ; comparing the current coordinate with the equivalent coordinate in the map
    cmp al, '#'     
    jne noCollision1
    mov eax, 1              ; collision detected
    mov [ebp + 16], eax
noCollision1:

    pop ebp
    ret 
checkUpCollision ENDP

checkUpCoinCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0
    mov [ebp + 16], eax     ; space to hold true or false
    mov ecx, [ebp + 12]     ; current coordinates 
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch              ; ch has the y coord
    imul edx, 89
    mov ebx, 0
    mov bl, cl              ; cl has the x cord
    add edx, ebx
    sub edx, 89
    ;sub edx, 120
    mov al, [esi + edx]
    cmp al, '.'
    jne noCoinCollision1
    mov al, ' '
    mov [esi + edx], al
    mov eax, 1
    mov [ebp + 16], eax
noCoinCollision1:

    pop ebp
    ret 
checkUpCoinCollision ENDP


checkDownCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0
    mov [ebp + 16], eax
    mov ecx, [ebp + 12]
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch
    imul edx, 89
    mov ebx, 0
    mov bl, cl
    add edx, ebx
    sub edx, 89
    mov al, [esi + edx]
    cmp al, '#'
    jne noCollision2
    mov eax, 1
    mov [ebp + 16], eax
noCollision2:
    
    pop ebp
    ret 
checkDownCollision ENDP

checkDownCoinCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0
    mov [ebp + 16], eax
    mov ecx, [ebp + 12]
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch
    imul edx, 89
    mov ebx, 0
    mov bl, cl
    add edx, ebx
    sub edx, 89
    mov al, [esi + edx]
    cmp al, '.'
    jne noCoinCollision2
    mov al, ' '
    mov [esi + edx], al
    mov eax, 1
    mov [ebp + 16], eax
noCoinCollision2:
    
    pop ebp
    ret 
checkDownCoinCollision ENDP


checkLeftCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0
    mov [ebp + 16], eax
    mov ecx, [ebp + 12]
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch
    imul edx, 89
    mov ebx, 0
    mov bl, cl
    add edx, ebx
    dec edx
    sub edx, 89
    mov al, [esi + edx]
    cmp al, '#'
    jne noCollision3
    mov eax, 1
    mov [ebp + 16], eax
noCollision3:

    pop ebp
    ret 
checkLeftCollision ENDP

checkLeftCoinCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0
    mov [ebp + 16], eax
    mov ecx, [ebp + 12]
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch
    imul edx, 89
    mov ebx, 0
    mov bl, cl
    add edx, ebx
    dec edx
    sub edx, 89
    mov al, [esi + edx]
    cmp al, '.'
    jne noCoinCollision3
    mov al, ' '
    mov [esi + edx], al
    mov eax, 1
    mov [ebp + 16], eax
noCoinCollision3:

    pop ebp
    ret 
checkLeftCoinCollision ENDP

checkRightCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0
    mov [ebp + 16], eax
    mov ecx, [ebp + 12]
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch
    imul edx, 89
    mov ebx, 0
    mov bl, cl
    add edx, ebx
    inc edx
    sub edx, 89
    mov al, [esi + edx]
    cmp al, '#'
    jne noCollision4
    mov eax, 1
    mov [ebp + 16], eax
noCollision4:

    pop ebp
    ret 
checkRightCollision ENDP

checkRightCoinCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0
    mov [ebp + 16], eax
    mov ecx, [ebp + 12]
    mov esi, [ebp + 8]

    mov edx, 0
    mov dl, ch
    imul edx, 89
    mov ebx, 0
    mov bl, cl
    add edx, ebx
    inc edx
    sub edx, 89
    mov al, [esi + edx]
    cmp al, '.'
    jne noCoinCollision4
    mov al, ' '
    mov [esi + edx], al
    mov eax, 1
    mov [ebp + 16], eax
noCoinCollision4:

    pop ebp
    ret 
checkRightCoinCollision ENDP

; PROC to set the initial coordinates of the player
setInitialPlayerSpawn PROC
    push ebp
    mov ebp, esp

    mov edx, 0
    mov dl, initialXPos
    mov dh, initialYPos
    mov [ebp + 8], edx

    pop ebp
    ret
setInitialPlayerSpawn ENDP

; PROC to set the initial coordinates of the ghosts 
setInitialEnemySpawn PROC
    push ebp 
    mov ebp, esp
    
    mov ecx, [ebp + 12]
    inc ecx             ; number of ghosts in the current level
    mov esi, [ebp + 8]
    mov edx, 0
    mov dl, 44
    mov dh, 14
    setSpawnPoints:
        mov [esi], edx
        add esi, 2
        add dl, 2
    loop setSpawnPoints

    pop ebp
    ret 8
setInitialEnemySpawn ENDP

; draw enemies at the given coordinates
drawEnemy PROC
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 12]
    inc ecx                 ; number of ghosts in the current level
    mov esi, [ebp + 8]
    drawEnemyLoop:
        mov edx, [esi]
        call gotoxy
        mov eax, green
        call setTextColor
        mov edx, offset enemy1
        call writechar
        add esi, 2
    loop drawEnemyLoop

    pop ebp
    ret 8
drawEnemy ENDP

; replaces the current coordianate of the enemy with the empty space
updateEnemy PROC
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 12]
    inc ecx             ; current number of ghosts in the current level
    mov esi, [ebp + 8]  ; current coordinates of the ghosts
    updateEnemyLoop:
        mov edx, [esi]
        call Gotoxy
        mov eax, 0
        mov al," "
        call WriteChar
        add esi, 2
    loop updateEnemyLoop

    pop ebp
    ret 8
updateEnemy ENDP

; PROC to generate a random number of moves and a random direction for the ghost to travel in
randEnemyMVMT PROC
    push ebp
    mov ebp, esp
    
    mov ecx, [ebp + 12]
    inc ecx                 ; number of ghosts in the current level
    mov esi, [ebp + 8]      
    
    randEnemyMVMTLoop:
        mov edx, [esi]
        cmp dh, 0
        JG movesLeft1    ; the ghost still has some movements left
        mov eax, 18       ; generates a random number of moves if all moves have been consumed
        call randomRange
        cmp al, 0
        JG noChangeRequired1
        inc al
    noChangeRequired1:
        mov dh, al
        mov eax, 20          
        call randomRange    ; setting a random direction for the ghost to travel in for
        mov dl, al          ; the set amount of moves
        mov [esi], edx
    movesLeft1:
        add esi, 2
    loop randEnemyMVMTLoop
    
    pop ebp
    ret 8
randEnemyMVMT endp

; moves enemy in the direction provided
movEnemy PROC
    push ebp
    mov ebp, esp
    
    mov eax, [ebp + 16] ; eax holds the direction to travel in
    mov ebx, [ebp + 12] ; ebx holds the current coordinates of the ghost
    mov esi, [ebp + 8] ; esi points to the coordinates of the walls in the current level
    ;mov ecx, [ebp + 8]  ; ecx holds the number of walls in the current level
    
    
    cmp ah, 0
    JLE noMovesLeft1    ; if the ghost still has some moves left
    dec ah              ; decrement the number of moves left
    mov tempHold, eax
    cmp al, 5           ; checks the direction in which to move the ghost towards
    JLE movRight1

    cmp al, 10
    JLE movUp1

    cmp al, 15
    JLE movLeft1

    cmp al, 20
    JLE movBelow1
    jmp noMovesLeft1

movRight1:
    inc bl
    cmp bl, 118
    JG movUp1
    sub esp, 4
    push ebx
    push esi
    ;push ecx
    call checkRightCollision
    ;pop ecx
    pop esi
    pop ebx
    pop eax
    cmp eax, 0      ; no collision detected
    JE noMovesLeft1  

movUp1:
    mov ebx, [ebp + 12]
    dec bh
    cmp bh, 2
    JL movLeft1
    sub esp, 4
    push ebx
    push esi
    ;push ecx
    call checkUpCollision
    ;pop ecx
    pop esi
    pop ebx
    pop eax
    cmp eax, 0      ; no collision detected
    JE noMovesLeft1 

movLeft1:
    mov ebx, [ebp + 12]
    dec bl
    cmp bl, 1
    JL movBelow1
    sub esp, 4
    push ebx
    push esi
    ;push ecx
    call checkLeftCollision
    ;pop ecx
    pop esi
    pop ebx
    pop eax
    cmp eax, 0      ; no collision detected
    JE noMovesLeft1

movBelow1:
    mov ebx, [ebp + 12]
    inc bh
    cmp bh, 28
    JG fixCord
    sub esp, 4
    push ebx
    push esi
    ;push ecx
    call checkDownCollision
    ;pop ecx
    pop esi
    pop ebx
    pop eax
    cmp eax, 0      ; no collision detected
    JE noMovesLeft1

fixCord:
    dec bh

noMovesLeft1:
    mov [ebp + 12], ebx
    mov eax, tempHold
    mov [ebp + 16], eax
    pop ebp
    ret 4
movEnemy ENDP

; PROC to display the number of lives left
drawLives PROC
    push ebp
    mov ebp, esp
    mov dl, 40
    mov dh, 0
    call gotoxy
    mov eax, red
    call setTextColor
    mov edx, [ebp + 12]
    call writeString
    mov eax, [ebp + 8]
    call writeDec
    mov eax, white
    call setTextColor
    pop ebp
    ret 8
drawLives ENDP

drawName PROC
    push ebp
    mov ebp, esp

    mov dl, 70
    mov dh, 0
    call gotoxy
    mov eax, green
    call setTextColor
    mov edx, [ebp + 12]
    call writeString
    mov edx, [ebp + 8]
    call writeString
    mov eax, white
    call setTextColor

    pop ebp
    ret 8
drawName ENDP


; PROC to check collision between a ghost and the player
checkGhostCollision PROC
    push ebp
    mov ebp, esp

    mov eax, 0          ; 0 for no collision and 1 for collision 
    mov ebx, [ebp + 12] ; load the current coordinates of the player
    mov edx, [ebp + 8]  ; load the current coordinates of a ghots

    cmp bh, dh              ; checking y coordinates
    JNE noGhostCollision
        cmp bl, dl          ; checking x coordinates
        JNE noGhostCollision    
            mov eax, 1      ; collision detected
noGhostCollision:
    mov [ebp + 16], eax

    pop ebp
    ret 8
checkGhostCollision ENDP

; PROC to display the intro at the game start
displayIntro PROC
    push ebp
    mov ebp, esp

    INVOKE PlaySound, OFFSET beginsound, NULL,11h

    ; display Blue Ork Presents
    mov eax, red
    call setTextColor
    mov dh, 5
    mov dl, 0
    call gotoxy
    mov edx, offset intro1
    call writeString
    mov eax, 1000
    call delay
    call clrscr

    ; display PACMAN
    mov dh, 5
    mov dl, 0
    call gotoxy
    mov edx, offset intro2
    call writeString
     
    mov dh, 14
    mov dl, 0
    call gotoxy
    mov eax, white
    call setTextColor

    ; display Press Any Key To Continue
blinkingGraphic:
    mov dh, 14
    mov dl, 0
    call gotoxy
    mov edx, offset intro3
    call writeString
    mov eax, 400
    call delay
    mov dh, 14
    mov dl, 0
    call gotoxy
    mov edx, offset intro4
    call writeString
    mov eax, 400
    call delay
    call readKey
    jz blinkingGraphic

    call clrscr
    pop ebp
    ret 
displayIntro ENDP

; PROC to prompt user to get their name
getUserName PROC
    push ebp
    mov ebp, esp

    mov dh, 14
    mov dl, 50
    call gotoxy
    mov eax, white 
    call setTextColor
    mov edx, [ebp + 12]
    call writeString
    mov edx, [ebp + 8]
    mov ecx, 255
    call readString
    mov [ebp + 16], eax

    call clrscr

    pop ebp
    ret 8
getUserName ENDP

displayMainMenu PROC
    push ebp
    mov ebp, esp

continueMainMenu:
    mov eax, red
    call setTextColor
    mov dl, 0
    mov dh, 5
    call gotoxy
    mov edx, [ebp + 20]
    call writeString

    mov eax, magenta
    call setTextColor
    mov dl, 50
    mov dh, 14
    call gotoxy
    mov edx, [ebp + 12]
    call writeString
    mov edx, [ebp + 16]
    call writeString

    mov dl, 0
    mov dh, 16
    call gotoxy 
    mov edx, [ebp + 8]
    call writeString


    call readChar
    cmp al, '1'
    JE exitMainMenu
    
    cmp al, '2'
    JE displayInstructionsMenu1

    cmp al, '3'
    JE displayHallOfFameMenu1

    jmp continueMainMenu

displayInstructionsMenu1:
    push [ebp + 28]
    push [ebp + 24]

    call displayInstructionsMenu
    jmp continueMainMenu

displayHallOfFameMenu1:
    push [ebp + 36]
    push [ebp + 32]

    call displayHallOfFame
    jmp continueMainMenu

exitMainMenu:
    call clrscr
    pop ebp
    ret 32
displayMainMenu ENDP

displayInstructionsMenu PROC
    push ebp
    mov ebp, esp
    
    call clrscr
    mov dl, 0
    mov dh, 2
    call gotoxy
    mov eax, red
    call setTextColor
    mov edx, [ebp + 12]
    call writeString
    
    mov dl, 0
    mov dh, 15
    call gotoxy
    mov eax, cyan
    call setTextColor
    mov edx, [ebp + 8]
    call writeString

continueInstructionsMenu:
    call readChar
    cmp al, "b"
    jne continueInstructionsMenu

    call clrscr
    pop ebp
    ret 8
displayInstructionsMenu ENDP

displayHallOfFame PROC
    push ebp
    mov ebp, esp

    call clrscr 

    mov dl, 0
    mov dh, 4
    call gotoxy
    mov eax, cyan
    call setTextColor
    
    mov edx, [ebp + 12]
    call writeString
    mov eax, magenta
    call setTextColor

    mov edx, offset filename
    call openInputFile
    mov fileHandle, eax
    cmp eax, INVALID_HANDLE_Value
    jne file_ok
    mov dl, 50
    mov dh, 15
    call gotoxy
    mov edx, offset errorMessage1
    call writeString    
    jmp quit
    file_ok:
    mov edx, offset buffer
    mov ecx,BUFFER_SIZE
	call ReadFromFile
	jnc check_buffer_size
	; error reading?
    mov dl, 50
    mov dh, 15
    call gotoxy
    mov edx, offset errorMessage2
    call writeString	
	jmp close_file
	check_buffer_size:
	cmp eax,BUFFER_SIZE
	; buffer large enough?
	jb buf_size_ok
	; yes
    mov dl, 50
    mov dh, 15
    call gotoxy
    mov edx, offset errorMessage3
    call writeString
	jmp quit
	; and quit
	buf_size_ok:
	mov buffer[eax],0
	; insert null terminator
	; Display the buffer.
	mov dl, 0
    mov dh, 15
    call gotoxy
    mov edx,OFFSET buffer
	; display the buffer
	call WriteString
	call Crlf
	close_file:
	mov eax,fileHandle
	call CloseFile
	quit:

    mov dl, 0
    mov dh, 20
    call gotoxy
    mov edx, [ebp + 8]
    call writeString

remainInHallOfFameMenu:
    call readChar
    cmp al, 'm'
    JE exitHallOfFameMenu 
    jmp remainInHallOfFameMenu

exitHallOfFameMenu:
    call clrscr

    pop ebp
    ret 8
displayHallOfFame ENDP


displayLevelStart PROC
    push ebp
    mov ebp, esp

    call clrscr
    INVOKE PlaySound, OFFSET beginsound, NULL,11h
    mov ecx, [ebp + 8]
    cmp ecx, 0
    mov dl, 0
    mov dh, 4
    call gotoxy
    cmp ecx, 0
    JNE notLevel1
    mov eax, green
    call setTextColor
    mov edx, offset level1StartMsg
    call writeString
    jmp dispMsg
notLevel1:
    cmp ecx, 1
    JNE notLevel2
    mov eax, yellow
    call setTextColor
    mov edx, offset level2StartMsg
    call writeString
    jmp dispMsg
notLevel2:
    mov eax, cyan
    call setTextColor
    mov edx, offset level3StartMsg
    call writeString

dispMsg:
    
    mov eax, 1000
    call delay
    mov dh, 15
    mov dl, 0
    call gotoxy
    mov edx, offset getSetGo
    call writeString
    mov eax, 500
    call delay

    call clrscr

    pop ebp
    ret 4
displayLevelStart ENDP

selectCurrentLevelCoins PROC
    push ebp
    mov ebp, esp

    mov esi, [ebp + 12]     ; points to the number of coins present in each level
    mov eax, [ebp + 8]      ; current level number
    CDQ
    mov bx, 2
    imul bx
    mov edx, [esi + eax]
    mov [ebp + 16], edx

    pop ebp
    ret 8
selectCurrentLevelCoins ENDP

; PROC to display text when game finishes
displayGameWon PROC
    push ebp
    mov ebp, esp

    call clrscr
    mov dl, 0
    mov dh, 4
    call gotoxy
    mov eax, green
    call setTextColor
    mov edx, [ebp + 32]
    call writeString

    mov dl, 50
    mov dh, 14
    call gotoxy
    mov edx, [ebp + 28]
    call writeString
    mov edx, [ebp + 24]
    call writeString
    mov dh, 18
    mov dl, 50
    call gotoxy
    mov edx, [ebp + 20]
    call writeString
    mov eax, [ebp + 16]
    call writeDec
    mov dh, 22
    mov dl, 50
    call gotoxy
    mov edx, [ebp + 12]
    call writeString
    mov eax, [ebp + 8]
     
    call writeDec

    call readChar

    pop ebp
    ret 28
displayGameWon ENDP

; PROC to display text when game finishes
displayGameOver PROC
    push ebp
    mov ebp, esp

    call clrscr
    mov dl, 0
    mov dh, 4
    call gotoxy
    mov eax, cyan
    call setTextColor
    mov edx, [ebp + 32]
    call writeString

    mov dl, 50
    mov dh, 14
    call gotoxy
    mov edx, [ebp + 28]
    call writeString
    mov edx, [ebp + 24]
    call writeString
    mov dh, 18
    mov dl, 50
    call gotoxy
    mov edx, [ebp + 20]
    call writeString
    mov eax, [ebp + 16]
    call writeDec
    mov dh, 22
    mov dl, 50
    call gotoxy
    mov edx, [ebp + 12]
    call writeString
    mov eax, [ebp + 8]
    call writeDec

    call readChar

    pop ebp
    ret 28
displayGameOver ENDP


; PROC to display menu during game pause
displayPauseMenu PROC
    push ebp
    mov ebp, esp

    mov eax, white
    call setTextColor
blinkingGraphics2:
    mov dl, 88
    mov dh, 10
    call gotoxy
    mov edx, [ebp + 12]
    call writeString
    mov eax, 400
    call delay
    mov dl, 88
    mov dh, 10
    call gotoxy
    mov edx, [ebp + 8]
    call writeString
    mov eax, 400
    call delay
    call readKey
    jz blinkingGraphics2

    cmp al, "p"
    JE resumeGame
    jmp blinkingGraphics2

resumeGame:
    mov dl, 88
    mov dh, 10
    call gotoxy
    mov edx, [ebp + 8]
    call writeString

    pop ebp
    ret 8
displayPauseMenu ENDP


END main