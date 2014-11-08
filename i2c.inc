;/*
; *	I2C functions for HI-TECH PIC C - master mode only
;   re-written in assembly by Chris Miller 11/4/14
;   edited and tweaked by Tom D'Agostino 11/7/14
; */
;


FUNCPARAMs udata_shr
I2C_STACK0    RES        1      ; Stack of 5 bytes for parameters
I2C_STACK1    RES        1
I2C_STACK2    RES        1
I2C_STACK3    RES        1
I2C_STACK4    RES        1

I2C CODE

; // approx 1ms per nrms at Fosc=8Mhz
;;********************************************
;;   nrms in LCD_STACK0 - 1 (2 bytes)
;;   uses LCD_STACK2 - 4 for local variables
;;********************************************
; void DelayMs(unsigned int nrms) {
;
;   unsigned int i, j;
;   for (j = 0; j < nrms; j++)
DELAYMSI2C
    CLRF LCD_STACK2
    CLRF LCD_STACK3
CHECKJc
    MOVF LCD_STACK1, W
    SUBWF LCD_STACK3, W
    BTFSS STATUS, Z
    GOTO JLESSc
    MOVF LCD_STACK0, W
    SUBWF LCD_STACK2, W
JLESSc
    BTFSC STATUS, C
    RETURN
;       for (i = 0; i < 248; i++);
    CLRF LCD_STACK4
INCIc
    MOVLW 0x1
    ADDWF LCD_STACK4, F
    NOP
    MOVLW 0xF8
    SUBWF LCD_STACK4, W
    BTFSS STATUS, C
    GOTO INCIc
    RETURN
;}


;/*
; * 	TIMING - see Philips document: THE I2C-BUS SPECIFICATION
; */
;// assuming Fosc = 8Mhz
;;********************************************
;;       I2C_STACK0-4 used by subfunction
;;********************************************
;void init_i2c(void)
;   {
INITI2C
;  	TRISC3=1;           // Set SCL and SDA pins as inputs, this initially relaxes SCL and SDA,
    BANKSEL TRISC
    BSF TRISC, 3
; 	TRISC4=1;           //	letting them be pulled high by the external pullup resistors.
    BSF TRISC, 4
;  	SSPCON = 0x38;      // Set the PIC Master Synchronous Serial Port (MSSP) Module for I2C master mode
    BANKSEL SSPCON
    MOVLW 0x38
    MOVWF SSPCON
; 	SSPCON2 = 0x00;		// See PIC16F887 Data Sheet REGISTER 13-2 (SSPCON register description)
;				// We are choosing <SSPM3:SSPM0> = <1000> = I2C Master mode, clock = FOSC / (4 * (SSPADD+1))
    BANKSEL SSPCON2
    CLRF SSPCON2
;	SSPADD = 19;        // Choose 100 kHZ I2C clock rate assuming an Fosc = 8 Mhz PIC clock
    MOVLW 0x13
    MOVWF SSPADD
; 	SSPIF=0;      		// Clear SSPIF interrupt flag (PIR1 bit 3)
    BANKSEL PIR1
    BCF PIR1,SSPIF

; 	BCLIF=0;      		// Clear bus collision flag (PIR2 bit 3)
    BCF PIR2,BCLIF

;	__delay_ms(500);
    MOVLW 0xF4
    MOVWF I2C_STACK0
    MOVLW 0x01
    MOVWF I2C_STACK1
    PAGESEL DELAYMSI2C
    CALL DELAYMSI2C
;   }
    RETURN

;/*
; * 	Send stop condition
; * 	  - data low-high while clock high
; */
;;********************************************
;;   uses I2C_STACK0 for local variable
;;********************************************
;void i2c_Stop(void)
;{
I2CSTOP
;	/* don't assume SCL is high on entry */
;	SDA_LOW();					/* ensure data is low first */
    BANKSEL TRISC
    BCF TRISC, 4
;	SCL_HIGH();
    BSF TRISC, 3
;	__delay_us(I2C_TM_DATA_SU);     1us
    NOP
    NOP
;	SCL_DIR = I2C_INPUT;		/* float clock high */
    BSF TRISC, 3
;	__delay_us(I2C_TM_STOP_SU);     4us
    MOVLW 0x4
    MOVWF I2C_STACK0
DELAYSTOP
    DECFSZ I2C_STACK0, f
    GOTO DELAYSTOP
;	SDA_HIGH();					/* the low->high data transistion */
    BSF TRISC, 4
;	__delay_us(I2C_TM_BUS_FREE);	/* bus free time before next start */   5us
    MOVLW 0x5
    MOVWF I2C_STACK0
DELAYBUS
    DECFSZ I2C_STACK0, f
    GOTO DELAYBUS
;	SDA_DIR = I2C_INPUT;		/* float data high */
    BSF TRISC, 4
;	return;
    RETURN
;}

;/*
; * 	Send (re)start condition
; * 	  - ensure data is high then issue a start condition
; * 	  - see also i2c_Start() macro
; */
;;********************************************
;;   uses I2C_STACK2 for local variable
;;********************************************
;void i2c_Restart(void)
;{
I2CSTART
;	SCL_LOW();      			/* ensure clock is low */
    BANKSEL TRISC
    BCF TRISC, 3
;	SDA_HIGH();					/* ensure data is high */
    BSF TRISC, 4
;	__delay_us(I2C_TM_DATA_SU);     1us
    NOP
    NOP
;	SCL_DIR = I2C_INPUT;		/* clock pulse high */
    BSF TRISC, 3
;	__delay_us(I2C_TM_SCL_HIGH);    4us
    MOVLW 0x4
    MOVWF I2C_STACK2
DELAYSTART
    DECFSZ I2C_STACK2, f
    GOTO DELAYSTART
;	SDA_LOW();					/* the high->low transition */
    BCF TRISC, 4
;	__delay_us(I2C_TM_START_HD);    4us
    MOVLW 0x4
    MOVWF I2C_STACK2
DELAYHD
    DECFSZ I2C_STACK2, f
    GOTO DELAYHD
;	return;
    RETURN
;}

;/*
; * 	Send a byte to the slave
; * 	  - returns true on error
; */
;;********************************************
;;       byte    - I2C_STACK0 (will be modified)
;;       uses I2C_STACK1-2 for local variables
;;       return value - W
;;********************************************
;unsigned char i2c_SendByte(unsigned char byte)
;{
I2CSENDBYTE
;	signed char i;
;	for(i=7; i>=0; i--)
;	{
    MOVLW 0x8
    MOVWF I2C_STACK1
LOOPBYTE
;		SCL_LOW();					/* drive clock low */
    BANKSEL TRISC
    BCF TRISC, 3
;		/* data hold time = 0, send data now */
;        SDA_DIR = ((byte>>i)&0x01);
    BTFSC I2C_STACK0, 7
SDAHIGH
    BSF TRISC, 4
    BTFSS I2C_STACK0, 7
SDALOW
     BCF TRISC, 4
;        if ((byte>>i)&0x01) {		/* bit to send */
;			SDA_HIGH();
;        }else {
;			SDA_LOW();
;        }
    RLF I2C_STACK0, f
    NOP
    NOP
;		__delay_us(I2C_TM_DATA_SU);     1us
    NOP
    NOP
;		SCL_DIR = I2C_INPUT;		/* float clock high */
    BSF TRISC, 3
;		if(i2c_WaitForSCL())		/* wait for clock release */
;			return TRUE;			/* bus error */
    PAGESEL I2CWAITSCL
    CALL I2CWAITSCL
    MOVWF I2C_STACK2
    BTFSC I2C_STACK2, 0
    RETLW   0x1
;SCLRELEASE
;		__delay_us(I2C_TM_SCL_HIGH);	/* clock high time */   4us
    MOVLW 0x4
    MOVWF I2C_STACK2
DELAYSCLHI
    DECFSZ I2C_STACK2, f
    GOTO DELAYSCLHI
;	}
    DECFSZ I2C_STACK1, f
    GOTO LOOPBYTE
;	return FALSE;
    RETLW 0x0
;}

;/*
; * 	send an address and data direction to the slave
; * 	  - 7-bit address (lsb ignored)
; * 	  - direction (FALSE = write )
; */
;;********************************************
;;       address    - I2C_STACK0 (will be modified)
;;       rw         - I2C_STACK1 (will be modified)
;;       I2C_STACK2 used by subfunctions
;;       return value - W
;;********************************************
;unsigned char i2c_SendAddress(unsigned char address, unsigned char rw)
;{
I2CSENDADDR
;	return i2c_SendByte(address | (rw?1:0));
    BTFSC I2C_STACK1, 0
    BSF I2C_STACK0, 0
    PAGESEL I2CSENDBYTE
    CALL I2CSENDBYTE
    RETURN
;}

;/*
; * 	Check for an acknowledge
; * 	  - returns ack or ~ack, or ERROR if a bus error
; */
;;********************************************
;;       uses I2C_STACK0-1 for local variables
;;       return value - W
;;********************************************
;signed char i2c_ReadAcknowledge(void)
;{
I2CREADACK
;	unsigned char ack;
;
;	SCL_LOW();						/* make clock is low */
    BANKSEL TRISC
    BCF TRISC, 3
;	SDA_DIR = I2C_INPUT;			/* disable data line - listen for ack */
    BSF TRISC, 4
;	__delay_us(I2C_TM_SCL_TO_DATA);	/* SCL low to data out valid */     4us
    MOVLW 0x4
    MOVWF I2C_STACK0
DELAYSCL2D
    DECFSZ I2C_STACK0, f
    GOTO DELAYSCL2D
;	SCL_DIR = I2C_INPUT;			/* float clock high */
    BSF TRISC, 3
;	__delay_us(I2C_TM_DATA_SU);     1us
    NOP
    NOP
;	ack = SDA;						/* read the acknowledge */
    BANKSEL PORTC
    MOVF PORTC, w       ; SDA in bit 4
    MOVWF I2C_STACK0
;	/* wait for slave to release clock line after processing byte */
;	if(i2c_WaitForSCL())
    PAGESEL I2CWAITSCL
    CALL I2CWAITSCL
    MOVWF I2C_STACK1
    BTFSC I2C_STACK1, 0
;		return I2C_ERROR;
    RETLW   0xff
;SCLRELEASE
;	return ack;
    BTFSS I2C_STACK0, 4
    RETLW 0x0
    RETLW 0x1
;}

;/*
; * 	Read a byte from the slave
; * 	  - returns the byte, or I2C_ERROR if a bus error
; */
;;********************************************
;;       uses I2C_STACK0-2 for local variables
;;       return value - W
;;********************************************
;int i2c_ReadByte(void)
;{
I2CREADBYTE
;	unsigned char i;
;	unsigned char byte = 0;
    CLRF I2C_STACK0
;
;	for(i=0; i<8; i++)
;	{
    MOVLW 0x8
    MOVWF I2C_STACK2
LOOPBYTER
;		SCL_LOW();					/* drive clock low */
    BANKSEL TRISC
    BCF TRISC, 3
;		__delay_us(I2C_TM_SCL_LOW);	/* min clock low  period */     5us
    MOVLW 0x5
    MOVWF I2C_STACK1
DELAYSCLLO
    DECFSZ I2C_STACK1, f
    GOTO DELAYSCLLO
;		SDA_DIR = I2C_INPUT;		/* release data line */
    BSF TRISC, 4
;		SCL_DIR = I2C_INPUT;		/* float clock high */
    BSF TRISC, 3
;		if(i2c_WaitForSCL())
    PAGESEL I2CWAITSCL
    CALL I2CWAITSCL
    MOVWF I2C_STACK1
    BTFSC I2C_STACK1, 0
;			return I2C_ERROR;
    RETLW   0xff
;SCLRELEASE
;		__delay_us(I2C_TM_SCL_HIGH);    4us
    MOVLW 0x4
    MOVWF I2C_STACK1
DELAYSCLHI2
    DECFSZ I2C_STACK1, f
    GOTO DELAYSCLHI2
;		byte = byte << 1;		/* read the next bit */
    BCF STATUS, C
    RLF I2C_STACK0, f
;		byte |= SDA;
    BANKSEL PORTC
    BTFSC PORTC, 4
    BSF I2C_STACK0, 0

;	}
    DECFSZ I2C_STACK2, f
    GOTO LOOPBYTER
;	return (int)byte;
    MOVF I2C_STACK0, w
    RETURN
;}

;/*
; * 	Send an (~)acknowledge to the slave
; * 	  - status of I2C_LAST implies this is the last byte to be sent
; */
;;********************************************
;;       status    - I2C_STACK0
;;       uses I2C_STACK1 for local variables
;;********************************************
;void i2c_SendAcknowledge(unsigned char status)
;{
I2CSENDACK
;	SCL_LOW();
    BANKSEL TRISC
    BCF TRISC, 3
;	if ( status & 0x01) {
    BTFSC I2C_STACK0, 0
;		SDA_LOW();				/* drive line low -> more to come */
    BCF TRISC, 4
;	}else {
    BTFSS I2C_STACK0, 0
;		SDA_HIGH();
    BSF TRISC, 4
;	}
;	__delay_us(I2C_TM_DATA_SU);     1us
    NOP
    NOP
;	SCL_DIR = I2C_INPUT;		/* float clock high */
    BSF TRISC, 3
;	__delay_us(I2C_TM_SCL_HIGH);    4us
    MOVLW 0x4
    MOVWF I2C_STACK1
DELAYSCLHI3
    DECFSZ I2C_STACK1, f
    GOTO DELAYSCLHI3
;	return;
    RETURN
;}

;/*
; * 	Send a byte to the slave and acknowledges the transfer
; * 	  - returns I2C_ERROR, ack or ~ack
; */
;;********************************************
;;       data    - I2C_STACK0 (will be modified)
;;       I2C_STACK1-2 used by subfunctions
;;       return value - W
;;********************************************
;signed char i2c_PutByte(unsigned char data)
;{
I2CPUTBYTE
;	if(i2c_SendByte(data))
    PAGESEL I2CSENDBYTE
    CALL I2CSENDBYTE
    MOVWF I2C_STACK1
    BTFSC I2C_STACK1, 0
;		return I2C_ERROR;
    RETLW   0xff
;	return i2c_ReadAcknowledge();	/* returns ack, ~ack */
    PAGESEL I2CREADACK
    CALL I2CREADACK
    RETURN
;}

;/*
; * 	Get a byte from the slave and acknowledges the transfer
; * 	  - returns true on I2C_ERROR or byte
; */
;;********************************************
;;       more    - I2C_STACK0 (will be modified)
;;       I2C_STACK1-2 used by subfunctions
;;       return value - W
;;********************************************
;int i2c_GetByte(unsigned char more)
;{
I2CGETBYTE
;	int byte;
    MOVF I2C_STACK0, w
    MOVWF I2C_STACK3
;	if((byte = i2c_ReadByte()) == I2C_ERROR)
    PAGESEL I2CREADBYTE
    CALL I2CREADBYTE
    MOVWF I2C_STACK2    ; save byte in stack2
    MOVLW 0xff
    SUBWF I2C_STACK2, w
    BTFSC STATUS, Z
;		return I2C_ERROR;
    RETLW 0xff
;	i2c_SendAcknowledge(more);
    MOVF I2C_STACK3, w
    MOVWF I2C_STACK0
    PAGESEL I2CSENDACK
    CALL I2CSENDACK
;	return byte;
    MOVF I2C_STACK2, w
    RETURN
;}

;/*
; * 	Send an array of bytes to the slave and acknowledges the transfer
; * 	  - returns number of bytes not successfully transmitted
; */
;int i2c_PutString(const unsigned char *str, unsigned char length)
;{
;	signed char error;
;
;	while(length)
;	{
;		if((error = i2c_PutByte(*str)) == I2C_ERROR)
;			return -(int)length;					/* bus error */
;		else
;			if(error)
;				return (int)length;					/* non acknowledge */
;		str++;
;		length--;
;	}
;
;	return FALSE;									/* everything OK */
;}

;/*
; * 	Reads number bytes from the slave, stores them at str and acknowledges the transfer
; * 	  - returns number of bytes not successfully read in
; */
;unsigned char i2c_GetString(unsigned char *str, unsigned char number)
;{
;	int byte;
;
;	while(number)
;	{
;		if((byte = i2c_GetByte(number-1)) == I2C_ERROR)
;			return number;								/* bus error */
;		else
;			*str = (unsigned char)byte;
;		str++;
;		number--;
;	}
;
;	return FALSE;										/* everything OK */
;}

;/*
; * 	Opens communication with a device at address. mode
; * 	indicates I2C_READ or I2C_WRITE.
; * 	  - returns TRUE if address is not acknowledged
; */
;;********************************************
;;       address    - I2C_STACK0 (will be modified)
;;       mode       - I2C_STACK1 (will be modified)
;;       I2C_STACK1-2 used by subfunctions
;;       return value - W
;;********************************************
;unsigned char i2c_Open(unsigned char address, unsigned char mode)
;{
I2COPEN
;	i2c_Start();
    PAGESEL I2CSTART
    CALL I2CSTART
;	i2c_SendAddress(address, mode);
    PAGESEL I2CSENDADDR
    CALL I2CSENDADDR
;	if(i2c_ReadAcknowledge())
    PAGESEL I2CREADACK
    CALL I2CREADACK
    ANDLW 0xff
    BTFSS STATUS, Z
;		return TRUE;
    RETLW 0x1
;	return FALSE;
    RETLW 0x0
;}

;/*
; * 	wait for the clock line to be released by slow slaves
; * 	  - returns TRUE if SCL was not released after the
; * 	    time out period.
; * 	  - returns FALSE if and when SCL released
; */
;;********************************************
;;       uses I2C_STACK4 for local variables
;;       return value - W
;;********************************************
;unsigned char i2c_WaitForSCL(void)
;{
I2CWAITSCL
;	/* SCL_DIR should be input here */
;	if(!SCL)
;	{
    BANKSEL PORTC
    BTFSC PORTC, 3
    GOTO SCLHIGH
;		__delay_us(I2C_TM_SCL_TMO);     10us
    MOVLW 0xA
    MOVWF I2C_STACK4
DELAYTMO
    DECFSZ I2C_STACK4, f
    GOTO DELAYTMO
;		/* if the clock is still low -> bus error */
;		if(!SCL)
    BTFSS PORTC, 3
;			return TRUE;
    RETLW 0x1
;	}
SCLHIGH
;	return FALSE;
    RETLW 0x0
;}

;void i2c_Free()
;{
;	unsigned char ucI;
;
;	SDA_DIR=I2C_INPUT;
;	for(ucI=0;ucI!=9;ucI++)
;	{
;		SCL_HIGH();
;		__delay_us(5);
;		SCL_LOW();
;		__delay_us(5);
;	}
;}

;unsigned char i2c_read(unsigned char ucAdr)
;{
;	unsigned char ucDat;
;
;	if (i2c_ReadFrom(ucAdr)==0)
;	{
;		ucDat=i2c_GetByte(I2C_MORE);
;		i2c_Stop();
;
;	}
;
;	return(ucDat);
;}


;
