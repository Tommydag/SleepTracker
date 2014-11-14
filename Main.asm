
;Author: Thomas D'Agostino

;Todo:
;By Importance:
;1 Push Button Working
;2 LCD Working
;3 Get loops to work
;4 Get constants to work
;Get ADC working
;10 Get capacitive sensor working
;11 Get wdt working
;12 Other possible functions(Power stuff)
;13 ????
;14 Profit

    list p=16F887
#include "p16F887.inc"
#include "lcd4bits.inc"

    ;errorlevel 1

; CONFIG1
; __config 0x20F2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3EFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

;errorlevel 1

    radix dec ; Make default numbers decimal values
    org 0 ; Reset vector is at prog loc 0x00.
    goto start ; Skip over INT vector at prog loc 0x04.

SENDPIN     EQU     2
RXPIN       EQU     5


    CBLOCK 0x20 ;Use CBLOCK and ENDC to reserve a block of registers
    ; starting at address 0x20 in register file space
    count1 ;count1 => 0x20
    count2 ;count2 => 0x21
    half_seconds
    secondsLSB
    seconds
    secondsMSB



    ENDC

    org 0x05 ;Start assembling program at location 5 in program space.
start
    

;Hardware initialization
;=========================================================
    
INIT
IO_INIT
    call CAPSENSE
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
    movlw 0x20
    movwf ANSELH
    clrf ANSEL
    banksel OPTION_REG
    bcf OPTION_REG,7;set bit 7 to 0
    banksel WPUB
    MOVLW 0x10
    MOVWF WPUB

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

CAPSENSE_Init

;C2 send pin, c5 recieve pin
    call ISP_DISABLE;Disable Interrups Temporarily
    pagesel CAPSENSE_Init
    banksel TRISC

    bcf TRISC,SENDPIN ;Set as output

    call ISP_ENABLE
    pagesel CAPSENSE_Init

  

INIT_FINISHED
    pagesel loop
    goto loop

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



Deficiency
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

ISP_DISABLE
    pagesel ISP_DISABLE
    banksel INTCON
    bcf TEMP,0  ;Clear Temp0
    btfsc INTCON,GIE ;Check if interrupts are enabled
    bsf TEMP,0  ;If enabled previously, set the temp0 bit high
    bcf INTCON,GIE
    return

ISP_ENABLE
    pagesel ISP_ENABLE
    banksel INTCON
    btfsc TEMP,0 ;Check if interrupts are enabled
    bsf INTCON,GIE  ;If enabled previously, turn them back on
    return

CAPSENSE
    call ISP_DISABLE
    pagesel CAPSENSE
    clrf CAP1
    clrf CAP2
    clrf CAP3

    banksel PORTC
    bcf PORTC,SENDPIN

    banksel TRISC
    bsf TRISC,RXPIN
    banksel PORTC
    bcf PORTC,RXPIN

    banksel TRISC
    bcf TRISC,RXPIN
    bsf TRISC,RXPIN

    banksel PORTC
    bsf PORTC,SENDPIN ;SEND it HIGH!

    bsf CAP1,0
CAPLOOP
    incfsz CAP1,F
    goto CAPCHECK

    clrf CAP1
    incf CAP2,F
    btfss STATUS,Z
    goto CAPCHECK

    clrf CAP2
    incf CAP3,F
    btfsc STATUS,Z
    bsf PORTC,1

CAPCHECK
    btfsc PORTC,RXPIN
    goto CAPSTEP

    goto CAPLOOP
CAPSTEP
    call ISP_ENABLE

    return

;-------------------------------------------------------
;End Function Section
    

    

;Main Program Loop
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++

loop
    pagesel loop
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

    incf PORTA, f ;Increment LED count
    
    btfss PORTB,4
    call Per_Week

    btfsc PORTB,4
    call Deficiency

    pagesel CAPSENSE
    call CAPSENSE

    pagesel loop
    goto loop
    end

;+++++++++++++++++++++++++++++++++++++++++++++++++++

