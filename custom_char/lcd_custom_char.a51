        ACALL LCD_INIT       ; Initialize LCD
        ACALL CREATE_CHARACTERS  ; Load custom characters into CGRAM
		MOV A, #81H          ; Set DDRAM address to display location
        ACALL LCD_COMMAND
		MOV DPTR, #STRING1    ; Point to the string
		ACALL DISPLAY_STRING
        ACALL DISPLAY_CUSTOM_CHARACTERS  ; Display custom characters
		CHECK: ACALL KEY
		JNB 00H,CHECK
		ACALL DISPLAY_GREETING
        HERE:SJMP HERE           

LCD_INIT:
        MOV A, #38H          ; Function set: 8-bit, 2-line display
        ACALL LCD_COMMAND
        MOV A, #0FH          ; Display ON, cursor ON, blink ON
        ACALL LCD_COMMAND
        MOV A, #80H          ; Set cursor position (line 1, position 2)
        ACALL LCD_COMMAND
        RET
CREATE_CHARACTERS:
        MOV A, #40H           ; Set CGRAM address for Custom Char 1
		ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH1  ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_1:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_1 ; Repeat until 8 rows are stored
		
		MOV A, #48H          ; Next CGRAM address for custom char
       ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH2  ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_2:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_2 ; Repeat until 8 rows are stored
		
		MOV A,#50H
		ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH3  ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_3:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_3 ; Repeat until 8 rows are stored
		
		MOV A,#58H
		ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH4  ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_4:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_4 ; Repeat until 8 rows are stored


		MOV A, #60H           ; Set CGRAM address for Custom Char 1
		ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH5  ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_5:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_5 ; Repeat until 8 rows are stored
		
		MOV A, #68H           ; Set CGRAM address for Custom Char 1
		ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH6  ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_6:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_6 ; Repeat until 8 rows are stored

		MOV A, #70H           ; Set CGRAM address for Custom Char 1
		ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH7 ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_7:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_7 ; Repeat until 8 rows are stored
		
		MOV A, #78H           ; Set CGRAM address for Custom Char 1
		ACALL LCD_COMMAND
		MOV DPTR, #CUS_CH8  ; Point to the start of the custom character table
		MOV R0, #0            ; Row counter (0-7)
		CHAR_8:
			MOV A,#00H
			MOVC A,@A+DPTR       ; Get the row data for Custom Char 1
			ACALL LCD_DATA
			INC DPTR           ; Move to the next row of the character
			INC R0             ; Increment row counter
			MOV A, R0
			CJNE A, #8,CHAR_8 ; Repeat until 8 rows are stored
		RET

DISPLAY_CUSTOM_CHARACTERS:
		MOV A, #0C5H          ; Set DDRAM address to display location
        ACALL LCD_COMMAND
        MOV A, #00H          ; Display first custom character
        ACALL LCD_DATA
        MOV A, #01H          ; Display second custom character
        ACALL LCD_DATA
        MOV A, #02H          ; Display third custom character
        ACALL LCD_DATA
        MOV A, #03H          ; Display fourth custom character
        ACALL LCD_DATA
        MOV A, #04H          ; Display fifth custom character
        ACALL LCD_DATA
        MOV A, #05H          ; Display sixth custom character
        ACALL LCD_DATA
        MOV A, #06H          ; Display seventh custom character
        ACALL LCD_DATA
        MOV A, #07H          ; Display eighth custom character
        ACALL LCD_DATA
        RET

DISPLAY_STRING:		
		MOV R0, #00H          ; Initialize index for looping through the string
		BACK:MOV A,#00H
		MOVC A, @A+DPTR         ; Load the character from the string
		MOV R1, A            ; Store the character in R1
		ACALL LCD_DATA       ; Call LCD_DATA to display the character
		MOV A, R1            ; Load the character back into A
		INC R0 
		INC DPTR             ; Move to the next character in the string		; Increment the index
		MOV A,#00H
		MOVC A, @A+DPTR
		CJNE A, #00H, BACK  ; If not end of string (null terminator), loop
RET

DISPLAY_GREETING:
		
		MOV A,#01H
		LCALL LCD_COMMAND
		MOV A,#80H
		LCALL LCD_COMMAND
		MOV DPTR, #STRING2    ; Point to the string
	    ACALL DISPLAY_STRING
		MOV A,#0C6H
		LCALL LCD_COMMAND	
		MOV A, #06H          ; Display eighth custom character
        ACALL LCD_DATA
		MOV A, #04H          ; Display sixth custom character
        ACALL LCD_DATA
		MOV A, #07H          ; Display sixth custom character
        ACALL LCD_DATA
		MOV A, #03H          ; Display sixth custom character
        ACALL LCD_DATA
RET

KEY:
AGAIN:MOV C, P0.0
JC AGAIN
ACALL WAIT
MOV C, P0.0
SETB 00H

RET
	   
	   
; --- LCD Command Function ---
LCD_COMMAND:
    MOV P2, A              ; Place command on P2
    CLR P1.0               ; RS = 0 for command
    CLR P1.1               ; R/W = 0 for write operation
    SETB P1.2              ; E = 1 for high pulse
    LCALL WAIT             ; Wait for some time
    CLR P1.2               ; E = 0 for H-to-L pulse
    LCALL WAIT             ; Wait for LCD to complete the given command
    RET

; --- LCD Data Function ---
LCD_DATA:
    MOV P2, A              ; Send data to P2
    SETB P1.0              ; RS = 1 for data
    CLR P1.1               ; R/W = 0 for write operation
    SETB P1.2              ; E = 1 for high pulse
    LCALL WAIT             ; Wait for some time
    CLR P1.2               ; E = 0 for H-to-L pulse
    LCALL WAIT             ; Wait for LCD to write the given data
    RET

; --- Wait Subroutine ---
WAIT:
    PUSH 05H
    PUSH 06H
    MOV R6, #30H           ; Delay subroutine
THERE:
    MOV R5, #0FFH
HERE1:
    DJNZ R5, HERE1
    DJNZ R6, THERE
    POP 06H
    POP 05H
    RET


ORG 0300H
; Define the lookup table for custom characters
CUS_CH1:    DB 00000B, 01010B, 01010B, 01010B, 00000B, 10001B, 01110B, 00000B  ; Custom Char 1 (0x40)
CUS_CH2:    DB 00000B, 01010B, 10101B, 10001B, 01010B, 00100B, 00000B, 00000B  ; Custom Char 2 (0x48)
CUS_CH3:    DB 01110B, 01110B, 00100B, 01110B, 10101B, 00100B, 01010B, 01010B  ; Custom Char 3 (0x50)
CUS_CH4:    DB 00100B, 00010B, 11111B, 00010B, 11110B, 10010B, 10010B, 00000B  ; Custom Char 4 (0x58)
CUS_CH5:    DB 00000B, 00000B, 11111B, 01010B, 11110B, 11010B, 11010B, 00000B  ; Custom Char 5 (0x60)
CUS_CH6:    DB 00000B, 00100B, 01100B, 11100B, 11100B, 01100B, 00100B, 00000B  ; Custom Char 6 (0x68)
CUS_CH7:    DB 00000B, 00000B, 11111B, 00010B, 11110B, 11010B, 11010B, 00000B  ; Custom Char 7 (0x70)
CUS_CH8:    DB 00000B, 00000B, 11100B, 00100B, 11111B, 01000B, 01100B, 00000B  ; Custom Char 8 (0x78)
	
ORG 0400H
STRING1:     DB "ALL CHARACTERS",00H
STRING2:     DB "HELLO & WELCOME",00H