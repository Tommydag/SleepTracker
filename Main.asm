;Author: Thomas D'Agostino
;Student: Rose-Hulman Institute of Technology
;Electrical Engineering 2017
;Class: ECE250
;Purpose: A sleep tracker that utilizes a capacitive touch sensor to
;keep track of the amount of time slept.
;Credit to Dr. Christopher Miller for the LCD display include file and the
;arduino community for inspiration and guidance on designing the capacitive
;touch sensor. 

    list p=16F887
#include "p16F887.inc"
#include "lcd4bits.inc"

; CONFIG1
; __config 0x20F2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3EFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

    radix dec ; Make default numbers decimal values
    org 0 ; Reset vector is at prog loc 0x00.
    goto start ; Skip over INT vector at prog loc 0x04.

    SENDPIN     EQU     2 ;Definition for the output part of the capacitive touch sensor.
    RXPIN       EQU     5 ;Definition for the input part of the capacitive touch sensor


    CBLOCK 0x20 ;Use CBLOCK and ENDC to reserve a block of registers
    ; starting at address 0x20 in register file space
    count1 ;count1 => 0x20
    count2 ;count2 => 0x21
    CAP_ARRAY:4 ;Array of 4 capsense readings 0x22:0x25
    SLP_HRS ;The number of hours slept
    SLP_MINS ;The number of minutes slept
    SLP_SECS ;The number of seconds slept
    CAP_AVG ;Used when computing the average of the array
    CAP_LOC ;Current location in array
    HDLR ;A temporary holding variable
    ENDC

    ;Added to the ushared data in LCD.inc
    ;CAP           RES        3
    ;TEMP          RES        1
    ;TIMEQTR       RES        1
    ;TEMPCHAR      RES        1

    ;ISP BELOW
    ;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    org 0x04 ;When Interrupt triggers
    goto ISPHANDLER ;goes to the interrupt handler
    ;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    org 0x05 ;Start assembling program at location 5 in program space.
start
    
;Hardware initialization
;=========================================================
    
INIT
IO_INIT
    pagesel INIT
    ;Port A
    banksel TRISA
    clrf TRISA
    banksel PORTA
    clrf PORTA ;

    ;Port B
    banksel TRISC
    bcf TRISC,1
    banksel PORTC
    bcf PORTC,1
    banksel TRISB
    MOVLW 0xFF
    MOVWF TRISB
    banksel ANSEL
    clrf ANSEL ;Digital Mode
    banksel ANSELH
    clrf ANSELH ;Digital mode
    banksel OPTION_REG
    bcf OPTION_REG,7;set bit 7 to 0 to turn on internal pull-ups
    banksel WPUB
    MOVLW 0x10
    MOVWF WPUB

;Initializes the LCD and displays the main message on the screen
LCD_Init
    pagesel LCDINIT
    call LCDINIT

    call LCDCLEAR
    movlw 0x01
    movwf LCD_STACK0

    PAGESEL LCDWRITE
    movlw 'S'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'l'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'e'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'e'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'p'
    movwf LCD_STACK1
    call LCDWRITE
    movlw ':'
    movwf LCD_STACK1
    call LCDWRITE

;Initializes the IO for the capacitive sensing
CAPSENSE_Init
    ;C2 send pin, c5 recieve pin
    call ISP_DISABLE;Disable Interrups Temporarily
    pagesel CAPSENSE_Init

    banksel TRISC
    bcf TRISC,SENDPIN ;Set as output

    banksel CAP_LOC
    clrf CAP_LOC

    call ISP_ENABLE ;Re-enable interrupts
    pagesel TIMER_ISP_Init
TIMER_ISP_Init
    banksel SLP_HRS
    clrf SLP_HRS
    clrf SLP_MINS
    clrf SLP_SECS
    clrf TIMEQTR
    banksel TMR1L
    clrf TMR1L
    banksel TMR1H
    clrf TMR1H
    banksel T1CON
    movlw 0xB0 ;timer setup but off
    movwf T1CON
    banksel INTCON
    bsf INTCON,PEIE
    bsf INTCON,GIE
    banksel PIE1
    bsf PIE1,TMR1IE
    banksel TMR1H
    movlw 0x0B
    movwf TMR1H
    banksel TMR1L
    movlw 0xDC
    movwf TMR1L
  
INIT_FINISHED
    pagesel loop
    goto loop

;Quickly handle ISP and get back normal operation
ISPHANDLER
    banksel PIR1
    btfss PIR1,TMR1IF
    goto LEAVEISP
    
    ;ALL in the same bank(How Efficient!), don't rearrange!

    btfss TIMEQTR,2
    goto NORMAL
   

    clrf TIMEQTR
    banksel SLP_SECS
    incf SLP_SECS

    movlw 60
    subwf SLP_SECS,W

    btfss STATUS,Z
    goto NORMAL2

    CLRF SLP_SECS
    incf SLP_MINS

    movlw 60
    subwf SLP_MINS,W

    btfss STATUS,Z
    goto NORMAL2

    CLRF SLP_MINS
    incf SLP_HRS

    goto NORMAL2
    
NORMAL ;Check to increment sleep time
    btfsc TEMP,7
    incf TIMEQTR
NORMAL2
    banksel T1CON
    bcf T1CON,TMR1ON ;Pause timer while reseting stuff
    movlw 0x3C
    movwf TMR1H
    movlw 0xFF
    movwf TMR1L
    banksel PIR1
    bcf PIR1, TMR1IF
    bsf T1CON,TMR1ON ;restart timer
LEAVEISP ;'nuff said
    retfie

;=======================================================================
; End Startup


;Functions Section
;-----------------------------------------------------------------------
Per_Week
    pagesel LCDWRITE
    movlw 0x00
    movwf LCD_STACK0
    movlw 0x86
    movwf LCD_STACK1
    call LCDWRITE
    movlw 0x01
    movwf LCD_STACK0

    movlw ' '
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'T'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'h'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'i'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 's'
    movwf LCD_STACK1
    call LCDWRITE
    movlw ' '
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'w'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'e'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'e'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'k'
    movwf LCD_STACK1
    call LCDWRITE
    pagesel loop
    return

Deficiency ;Not currently implemented, shows up on screen but nothing is different
    pagesel LCDWRITE
    movlw 0x00
    movwf LCD_STACK0
    movlw 0x86
    movwf LCD_STACK1

    call LCDWRITE
    movlw 0x01
    movwf LCD_STACK0

    movlw 'D'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'e'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'f'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'i'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'c'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'i'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'e'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'n'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'c'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'y'
    movwf LCD_STACK1
    call LCDWRITE
    pagesel loop
    return

ISP_DISABLE;Temporarily disable ISP
    pagesel ISP_DISABLE
    banksel INTCON
    bcf TEMP,0  ;Clear Temp0
    btfsc INTCON,GIE ;Check if interrupts are enabled
    bsf TEMP,0  ;If enabled previously, set the temp0 bit high
    bcf INTCON,GIE
    return

ISP_ENABLE;reenable ISP
    pagesel ISP_ENABLE
    banksel INTCON
    btfsc TEMP,0 ;Check if interrupts are enabled
    bsf INTCON,GIE  ;If enabled previously, turn them back on
    return

;A heavily modified version of the arduino capsense library to work with pic and
;assembly.
;Based on arduino capsense library, which can be found using the link below:
;http://playground.arduino.cc/Main/CapacitiveSensor?from=Main.CapSense
CAPSENSE
    call ISP_DISABLE
    pagesel CAPSENSE
    clrf CAP
    clrf CAP+1
    clrf CAP+2

    banksel PORTC
    bcf PORTC,SENDPIN

    banksel TRISC
    bsf TRISC,RXPIN
    banksel PORTC
    bcf PORTC,RXPIN

    banksel TRISC
    bcf TRISC,RXPIN
    bsf TRISC,RXPIN

    movlw 0x01
    movwf CAP

    banksel PORTC
    bsf PORTC,SENDPIN ;SEND it HIGH!

CAPLOOP ;Loop until the input pin goes high
    incfsz CAP,F
    goto CAPCHECK

    incfsz CAP+1,F
    goto CAPCHECK

    incf CAP+2,F
    btfsc CAP+2,3
    goto CAPSTEP

CAPCHECK
    btfsc PORTC,RXPIN
    goto CAPSTEP

    goto CAPLOOP

CAPSTEP
    btfsc CAP+2,3
    bsf PORTC,1 ;ERROR:TIMEOUT, needs to be handled better in the future
    call ISP_ENABLE

SAMPLEDECIDE
    bcf STATUS,C
    rrf CAP,F
    bcf STATUS,C
    rrf CAP,F
    bcf STATUS,C
    rrf CAP,F
    bcf STATUS,C
    rrf CAP,F
    bcf STATUS,C
    rrf CAP,F

    banksel CAP_LOC

    btfsc CAP_LOC,1
    goto THIRDSAMPLE

    btfsc CAP_LOC,0
    goto SECONDSAMPLE

FIRSTSAMPLE
    banksel CAP_ARRAY
    movf CAP,W
    movwf CAP_ARRAY

    banksel CAP_LOC
    incf CAP_LOC,F
    goto AVGCALC

SECONDSAMPLE
    banksel CAP_ARRAY
    movf CAP,W
    movwf CAP_ARRAY+1

    banksel CAP_LOC
    incf CAP_LOC,F
    goto AVGCALC
THIRDSAMPLE
    btfsc CAP_LOC,0
    goto FOURTHSAMPLE

    banksel CAP_ARRAY
    movf CAP,W
    movwf CAP_ARRAY+2

    banksel CAP_LOC
    incf CAP_LOC,F
    goto AVGCALC

FOURTHSAMPLE
    banksel CAP_ARRAY
    movf CAP,W
    movwf CAP_ARRAY+3

    banksel CAP_LOC
    clrf CAP_LOC
    goto AVGCALC

AVGCALC ;Calculate a running average of the past four capsense samples
    movf CAP_ARRAY,W
    addwf CAP_ARRAY+1,W
    addwf CAP_ARRAY+2,W
    addwf CAP_ARRAY+3,W
    movwf CAP_AVG

    rrf CAP_AVG,F ;divide by 2(I found it better to divide by 2 instead of 4,
    ; so I guess it isn't technically an average)

    btfsc CAP_AVG,3
    goto SLEEPING
    btfsc CAP_AVG,2
    goto SLEEPING
    btfsc CAP_AVG,1
    goto SLEEPING
    goto nSLEEPING
SLEEPING ;Indicate sleeping
    bsf TEMP,7
    return
nSLEEPING ;Indicate not sleeping
    bcf TEMP,7
    return

;DISPLAYSTUFF: Controls the hex display for the lcd
CHARDISP
    btfsc TEMPCHAR,3
    goto  CHARSPECIAL

CHARNORM
    movlw 0x30
    addwf TEMPCHAR,W
    movwf LCD_STACK1
    call LCDWRITE

    goto EXITCHAR

CHARSPECIAL
    movlw 0x08
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHAREIGHT

    movlw 0x09
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHARNINE

    movlw 0x0A
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHARA

    movlw 0x0B
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHARB

    movlw 0x0C
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHARC

    movlw 0x0D
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHARD

    movlw 0x0E
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHARE

    movlw 0x0F
    subwf TEMPCHAR,W
    btfsc STATUS,Z
    goto CHARF
    goto EXITCHAR

CHAREIGHT
    movlw '8'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
CHARNINE
    movlw '9'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
CHARA
    movlw 'A'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
CHARB
    movlw 'B'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
CHARC
    movlw 'C'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
CHARD
    movlw 'D'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
CHARE
    movlw 'E'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
CHARF
    movlw 'F'
    movwf LCD_STACK1
    call LCDWRITE
    goto EXITCHAR
EXITCHAR
    return

;-------------------------------------------------------
;End Function Section
    

    

;Main Program Loop
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++

loop
    pagesel loop
    banksel T1CON
    bsf T1CON,TMR1ON ;Start timer

    ;Delay Block
    ;-----------------
    banksel count1
    clrf count1
small_loop
    clrf count2
smallest_loop
    decfsz count2, f
    goto smallest_loop
    decfsz count1, f
    goto small_loop
    ;----------------

    banksel PORTA
    incf PORTA, f ;Increment LED count,
    ;just a flashing LED display for effect!

    ;Select what mode to display(deficiency not implemented)
    btfsc PORTB,4
    call Per_Week
    btfss PORTB,4
    call Deficiency

    pagesel CAPSENSE
    call CAPSENSE ;Test if someone is sleeping

    ;Display how much time has been slept
    clrf LCD_STACK0
    movlw 0xC0
    movwf LCD_STACK1
    call LCDWRITE
    bsf LCD_STACK0,0

HOURS;Display
    banksel SLP_HRS
    movlw 0xF0
    andwf SLP_HRS,W
    movwf HDLR

    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,W


    movwf TEMPCHAR
    pagesel CHARDISP
    call CHARDISP
    pagesel HOURS

    banksel SLP_HRS
    movlw 0x0F
    andwf SLP_HRS,W
    movwf TEMPCHAR
    pagesel CHARDISP
    call CHARDISP
    pagesel HOURS

    movlw ':'
    movwf LCD_STACK1
    call LCDWRITE

MINUTES;Display
    banksel SLP_MINS
    movlw 0xF0
    andwf SLP_MINS,W
    movwf HDLR

    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,W


    movwf TEMPCHAR
    pagesel CHARDISP
    call CHARDISP
    pagesel MINUTES

    banksel SLP_MINS
    movlw 0x0F
    andwf SLP_MINS,W
    movwf TEMPCHAR
    pagesel CHARDISP
    call CHARDISP
    pagesel MINUTES

    movlw ':'
    movwf LCD_STACK1
    call LCDWRITE

SECONDS;Display
    banksel SLP_SECS
    movlw 0xF0
    andwf SLP_SECS,W
    movwf HDLR

    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,F
    bcf STATUS,C
    rrf HDLR,W

    movwf TEMPCHAR
    pagesel CHARDISP
    call CHARDISP
    pagesel SECONDS

    banksel SLP_SECS
    movlw 0x0F
    andwf SLP_SECS,W
    movwf TEMPCHAR
    pagesel CHARDISP
    call CHARDISP
    pagesel SECONDS

    btfsc TEMP,7
    bsf PORTC,1

    btfss TEMP,7
    bcf PORTC,1

    pagesel loop
    goto loop;Restart loop
    end

;+++++++++++++++++++++++++++++++++++++++++++++++++++

