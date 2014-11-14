; LCD driver file, re-written in assembly by Chris Miller 11/2/14
;   edited and tweaked by Tom D'Agostino 11/7/14
; *	This code will interface to a wide variety of B/W LCD Display Controllers
; *	like the Hitachi HD44780. It uses the 4-bit transfer mode, and it assumes that the
; * pins of PORT D (RD7:0) are connected to the LCD panel, with the 
; *	hardware connected as follows, assuming the standard 16 pin LCD pinout:
;
; *    GND to VSS Pin of LCD Pin 1
; *    +5V to VDD Pin of LCD Pin 2
; *     ~  to V0 Pin of LCD Pin 3
; *    GND to R/W* Pin of LCD Pin 5 (This means that the software can only write to the 
; *                                  LCD panel, and never read from it.)
; *	  RD4:7 are connected to the LCD data bits 4-7 LCD Pins 11-14
; *	  RD2 is connected to the LCD RS input (register select) LCD Pin 4
; *   RD3 is connected to the LCD EN bit (enable)  LCD Pin 6
; *


FUNCPARAM udata_shr
LCD_STACK0    RES        1      ; Stack of 5 bytes for parameters
LCD_STACK1    RES        1
LCD_STACK2    RES        1
LCD_STACK3    RES        1
LCD_STACK4    RES        1
CAP           RES        3
TEMP          RES        1

LCD4BITS    CODE

; // approx 1ms per nrms at Fosc=8Mhz
;;********************************************
;;   nrms in LCD_STACK0 - 1 (2 bytes)
;;   uses LCD_STACK2 - 4 for local variables
;;********************************************
; void DelayMs(unsigned int nrms) {
;
;   unsigned int i, j;
;   for (j = 0; j < nrms; j++)
DELAYMS
    banksel STATUS
    CLRF LCD_STACK2
    CLRF LCD_STACK3
CHECKJ      
    MOVF LCD_STACK1, W
    SUBWF LCD_STACK3, W
    BTFSS STATUS, Z
    GOTO JLESS
    MOVF LCD_STACK0, W
    SUBWF LCD_STACK2, W
JLESS
    BTFSC STATUS, C
    RETURN
;       for (i = 0; i < 248; i++);
    CLRF LCD_STACK4
INCI
    MOVLW 0x1
    ADDWF LCD_STACK4, F
    NOP
    MOVLW 0xF8
    SUBWF LCD_STACK4, W
    BTFSS STATUS, C
    GOTO INCI
;}
IEQUAL     
    MOVLW 0x1
    ADDWF LCD_STACK2, F
    BTFSC STATUS, C
    INCF LCD_STACK3, F
    NOP
    NOP
    GOTO CHECKJ


;   /*
;    * lcd_write function ---writes a byte to the LCD in 4-bit mode (as two back-to-back 4-bit transfers).
;    * Note that the "mode" argument is set to either CMD_MODE (=0) or DTA_MODE (=1), so that the
;    * LCD panel knows whether an instruction byte is being written to it or an ASCII code is being written to it
;    * that is to be displayed on the panel.
;    */
;;********************************************
;;       mode    - LCD_STACK0
;;       CmdChar - LCD_STACK1
;;       uses LCD_STACK2 for local variables
;;********************************************
;    void lcd_write(unsigned char mode, unsigned char CmdChar) {
;
;        unsigned char i;
;        for (i = 0; i < 10; i++);   // allow ~60us for each write (at Fosc=8MHz)
LCDWRITE  
    CLRF LCD_STACK2
LOOP10
    MOVLW 0xA
    SUBWF LCD_STACK2, W
    BTFSC STATUS, C
    GOTO DONE10
    INCF LCD_STACK2, F
    GOTO LOOP10
;        LCD_DATA = (CmdChar & 0xf0);
DONE10
    MOVF LCD_STACK1, W
    ANDLW 0xF0
    BANKSEL PORTD
    MOVWF PORTD
;        LCD_RS = mode;
    BTFSS LCD_STACK0, 0x0
    GOTO MODE0
    BSF PORTD, 0x2
    GOTO HINIBBLE
MODE0
    BCF PORTD, 0x2
HINIBBLE
    NOP
;        LCD_STROBE(); // Write 8 bits of data on D7-0
    BSF PORTD, 0x3
    BSF PORTD, 0x3
    BCF PORTD, 0x3
;        LCD_DATA = (CmdChar << 4);
    MOVLW 0x0F
    ANDWF LCD_STACK1, F
    BSF LCD_STACK1, 0x4
    BCF STATUS, C
SHIFTDATA
    RLF LCD_STACK1, F
    BTFSS STATUS, C
    GOTO SHIFTDATA
    MOVF LCD_STACK1, W
    MOVWF PORTD
;        LCD_RS = mode;
    BTFSS LCD_STACK0, 0x0
    GOTO MODE0LO
    BSF PORTD, 0x2
    GOTO LONIBBLE
MODE0LO
    BCF PORTD, 0x2
LONIBBLE
    NOP
;        LCD_STROBE(); // Write 8 bits of data on D7-0
    BSF PORTD, 0x3
    BSF PORTD, 0x3
    BCF PORTD, 0x3
    pagesel LCD_Init
;    }
    RETURN

;   /*
;    * 	Clear and home the LCD
;    */
;;********************************************
;;       uses LCD_STACK0-1 for local variables
;;********************************************
;   void lcd_clear(void) {
;
;       lcd_write(CMD_MODE, LCDCMD_ClearDisplay);
LCDCLEAR
    CLRF LCD_STACK1
    INCF LCD_STACK1, F  ; set CmdChar
    CLRF LCD_STACK0     ; set mode
    PAGESEL LCDWRITE    ; BCF PCLATH, 0x4, BCF PCLATH, 0x3
    CALL LCDWRITE
;       DelayMs(2);
    MOVLW 0x2
    MOVWF LCD_STACK0
    MOVLW 0x0
    MOVWF LCD_STACK1
    PAGESEL DELAYMS
    CALL DELAYMS
;     }
    RETURN

;     /* write a string of chars to the LCD */
;     void lcd_puts(const char *string) {
;       while (*string != 0) // Last character in a C-language string is alway "0" (ASCII NULL character)
;     lcd_write(DTA_MODE, *string++);
;     }

;     /* write one character to the LCD */
;     void lcd_putch(char character) {
;       lcd_write(DTA_MODE, character);
;     }

;     /*
;    * Moves cursor to desired position.
;    * For 16 x 2 LCD display panel,
;    *     the columns of Row 1 are 0x00....0x10
;    *     the columns of Row 2 are 0x40....0x50
;    */
;     void lcd_goto(unsigned char position) {
;       lcd_write(CMD_MODE, 0x80 + position); // The "cursor move" command is indicated by MSB=1 (0x80)
;       // followed by the panel position address (0x00- 0x7F)
;       DelayMs(2);
;     }

;   /*
;    * Initialize the LCD - put into 4 bit mode
;    * assume 4 MHz clock
;    */
;;********************************************
;;       uses LCD_STACK0-1 for local variables
;;********************************************
;   void lcd_init() //See Section 2.2.2.2 of the Optrex LCD DMCman User Manual
;   {
;       TRISD = 0b00000000; //Make PORTD (D7-0), RS, EN all output
LCDINIT
    BANKSEL TRISD
    CLRF TRISD
;       LCD_RS = CMD_MODE;
    BANKSEL PORTD
    BCF PORTD, 0x2
;       LCD_EN = 0;
    BCF PORTD, 0x3
;       DelayMs(30); // wait 30mSec after power applied,
    MOVLW 0x1E
    MOVWF LCD_STACK0
    MOVLW 0x0
    MOVWF LCD_STACK1
    PAGESEL DELAYMS
    CALL DELAYMS
;       lcd_write(CMD_MODE, LCDCMD_FunctionSet); // function set: 4-bit mode, 2 lines, 5x7 dots
    MOVLW 0x28
    MOVWF LCD_STACK1
    CLRF LCD_STACK0
    PAGESEL LCDWRITE
    CALL LCDWRITE
;       DelayMs(5); // wait 5mSec after mode set
    MOVLW 0x5
    MOVWF LCD_STACK0
    MOVLW 0x0
    MOVWF LCD_STACK1
    PAGESEL DELAYMS
    CALL DELAYMS
;       lcd_write(CMD_MODE, LCDCMD_FunctionSet); // function set: 4-bit mode, 2 lines, 5x7 dots
    MOVLW 0x28
    MOVWF LCD_STACK1
    CLRF LCD_STACK0
    PAGESEL LCDWRITE
    CALL LCDWRITE
;       lcd_write(CMD_MODE, LCDCMD_DisplaySettings); // display ON/OFF control: display on, cursor off, blink off
    MOVLW 0xC
    MOVWF LCD_STACK1
    CLRF LCD_STACK0
    PAGESEL LCDWRITE
    CALL LCDWRITE
;       lcd_clear(); // Clear screen
    PAGESEL LCDCLEAR
    CALL LCDCLEAR
;       lcd_write(CMD_MODE, LCDCMD_EMS); // Set entry Mode
    MOVLW 0x6
    MOVWF LCD_STACK1
    CLRF LCD_STACK0
    PAGESEL LCDWRITE
    CALL LCDWRITE
;     }
    RETURN

