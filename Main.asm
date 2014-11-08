
;Author: Thomas D'Agostino

;Todo:
;By Importance:
;1 Push Button Working
;2 LCD Working
;3 Get loops to work
;4 Get constants to work
;5 get I2C to work
;6 Set up RTC
;7 Communicate with RTC
;8 Get basic clock working
;9 Get relay working
;10 Get capacitive sensor working
;11 Get wdt working
;12 Other possible functions(Power stuff)
;13 ????
;14 Profit

    list p=16F887
#include "p16F887.inc"
#include "lcd4bits.inc"
#include "i2c.inc"
; CONFIG1
; __config 0x20F2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3EFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF


    radix dec ; Make default numbers decimal values
    org 0 ; Reset vector is at prog loc 0x00.
    goto start ; Skip over INT vector at prog loc 0x04.
    CBLOCK 0x20 ;Use CBLOCK and ENDC to reserve a block of registers
    ; starting at address 0x20 in register file space
    count1 ;count1 => 0x20
    count2 ;count2 => 0x21
    ENDC




    org 0x05 ;Start assembling program at location 5 in program space.
start

    banksel TRISA ;This directive switches to data bank that TRISA is found
    ; in (Bank 1). It results in the assembly of the
    ; following instruction: "bsf STATUS,5" (Set RP0 = 1)
    clrf TRISA ;Configure PORTA for output - set to all zero
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
    MOVLW 0xFF
    MOVWF WPUB
    banksel ANSEL
    clrf ANSEL ;Configure PORTA as digital I/O - set to all zero
    banksel PORTA
    clrf PORTA ;Initialize port A by zeroing output data latches
    banksel PORTB
    clrf PORTB
    movlw 0xFF
    movwf PORTB

LCDPLACE
    PAGESEL LCDINIT
    call LCDINIT
    PAGESEL INITI2C
    call INITI2C

COMMSTART
    call I2CSTART
    movlw 0x68
    movwf I2C_STACK0
    bsf I2C_STACK1,0
    call I2CSENDADDR
    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto COMMSTART

BYTE1
    clrw
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE1

BYTE2
    clrw
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE2

BYTE3
    movlw B'00001101'
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE3

BYTE4
    movlw B'00000101'
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE4

BYTE5
    movlw B'00000111'
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE5

BYTE6
    movlw B'00010000'
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE6

BYTE7
    movlw B'00010100'
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE7

BYTE8
    movlw B'00010000'
    movwf I2C_STACK0
    call I2CSENDBYTE

    movwf I2C_STACK4
    btfsc I2C_STACK4,0
    goto BYTE8

    call I2CSTOP




    banksel PORTA
    movwf PORTA




    call LCDCLEAR
    movlw 0x01
    movwf LCD_STACK0
    movlw 'T'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'O'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'M'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'D'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'A'
    movwf LCD_STACK1
    call LCDWRITE
    movlw 'G'
    movwf LCD_STACK1
    call LCDWRITE



    banksel PORTA
    movlw 0x88
    movwf PORTA


loop
    clrf count1
small_loop
    clrf count2
smallest_loop
    decfsz count2, f
    goto smallest_loop
    decfsz count1, f
    goto small_loop
    movlw 0x10
    btfsc PORTA,0
    addwf PORTA
    btfsc PORTB,4
    rrf PORTA, f ;Increment LED count
    goto loop
    end
