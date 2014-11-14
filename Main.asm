
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


; CONFIG1
; __config 0x20F2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3EFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF


    radix dec ; Make default numbers decimal values
    org 0 ; Reset vector is at prog loc 0x00.
    goto start ; Skip over INT vector at prog loc 0x04.

SENDPIN     EQU     2
RXPIN       EQU     5


    CBLOCK 0x20 ;Use CBLOCK and ENDC to reserve a block of registers
    ; starting at address 0x20 in register file space
    count1 ;count1 => 0x20
    count2 ;count2 => 0x21
    CAP_AVG:12
    CAP_LOC
    ENDC

    org 0x04
    goto ISPHANDLER



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
    clrf ANSEL
    banksel ANSELH
    clrf ANSELH
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

    banksel CAP_LOC
    clrf CAP_LOC


    call ISP_ENABLE
    pagesel CAPSENSE_Init
TIMER_ISP_Init

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

ISPHANDLER

    ;ALL in the same bank(How Efficient!), don't rearrange!
    banksel T1CON
    bcf T1CON,TMR1ON
    movlw 0x0B
    movwf TMR1H
    movlw 0xDC
    movwf TMR1L
    banksel PIR1
    bcf PIR1, TMR1IF
    banksel T1CON
    bsf T1CON,TMR1ON

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

    
CAPLOOP
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
    bsf PORTC,1
    call ISP_ENABLE

SAMPLEDECIDE
    banksel CAP_LOC

    btfsc CAP_LOC,1
    goto THIRDSAMPLE

    btfsc CAP_LOC,0
    goto SECONDSAMPLE

FIRSTSAMPLE
    banksel CAP_AVG
    movf CAP+2,W
    movwf CAP_AVG
    movf CAP+1,W
    movwf CAP_AVG+1
    movf CAP+0,W
    movwf CAP_AVG+2

    banksel CAP_LOC
    incf CAP_LOC,F
    goto AVGCALC

SECONDSAMPLE
    banksel CAP_AVG
    movf CAP+2,W
    movwf CAP_AVG+3
    movf CAP+1,W
    movwf CAP_AVG+4
    movf CAP+0,W
    movwf CAP_AVG+5

    banksel CAP_LOC
    incf CAP_LOC,F
    goto AVGCALC
THIRDSAMPLE
    btfsc CAP_LOC,0
    goto FOURTHSAMPLE

    banksel CAP_AVG
    movf CAP+2,W
    movwf CAP_AVG+6
    movf CAP+1,W
    movwf CAP_AVG+7
    movf CAP+0,W
    movwf CAP_AVG+8

    banksel CAP_LOC
    incf CAP_LOC,F
    goto AVGCALC

FOURTHSAMPLE
    banksel CAP_AVG
    movf CAP+2,W
    movwf CAP_AVG+9
    movf CAP+1,W
    movwf CAP_AVG+10
    movf CAP+0,W
    movwf CAP_AVG+11

    banksel CAP_LOC
    clrf CAP_LOC
    goto AVGCALC

AVGCALC
    ;TODO





    
    clrf LCD_STACK0
    movlw 0xC0
    movwf LCD_STACK1
    call LCDWRITE
    bsf LCD_STACK0,0

    

    movlw 0x31
    btfss CAP+1,7
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP+1,6
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP+1,5
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP+1,4
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE
    movlw 0x31
    btfss CAP+1,3
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE
    movlw 0x31
    btfss CAP+1,2
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE
    movlw 0x31
    btfss CAP+1,1
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE
    movlw 0x31
    btfss CAP+1,0
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP,7
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP,6
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP,5
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP,4
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE
    movlw 0x31
    btfss CAP,3
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP,2
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP,1
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE

    movlw 0x31
    btfss CAP,0
    movlw 0x30
    movwf LCD_STACK1
    call LCDWRITE






    return

;-------------------------------------------------------
;End Function Section
    

    

;Main Program Loop
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++

loop
    pagesel loop
    banksel T1CON
    bsf T1CON,TMR1ON
    



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

