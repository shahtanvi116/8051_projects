org 0000h  
sjmp main
org 002bh 	
	main:
		mov p0,#0ffh
		mov sp,#20h
		mov ie,#81h ; active external interrupt-0 pin
		mov ip,#01h ; give external interrupt-0 highest priority
		setb tcon.0 ; set the external interrupt pin as edge triggered
		
		acall lcd_init       ; initialize lcd
		mov a, #80h          ; set ddram address to display location
        mov b,a              ; mov cursor starting position in b
		acall lcd_command
		mov dptr, #string1    ; point to the string
		acall display_string
		mov a, #0cah          ; set ddram address to display location
        mov b,a
		acall lcd_command
		mov dptr, #string2    ; point to the string
		acall display_string
        here:sjmp here           

lcd_init:
        mov a, #38h          ; function set: 8-bit, 2-line display
        acall lcd_command
        mov a, #0fh          ; display on, cursor on, blink on
        acall lcd_command
        mov a, #80h          ; set cursor position (line 1, position 2)
        acall lcd_command
        ret

display_string:		
		mov r0, #00h          ; initialize index for looping through the string
		mov a,#00h
		movc a, @a+dptr         ; load the character from the string
		back:
		acall lcd_data       ; call lcd_data to display the character
		inc r0 				 ; length of string in r0
		inc dptr             ; move to the next character in the string		; increment the index
		mov a,#00h
		movc a, @a+dptr
		cjne a, #00h, back  ; if not end of string (null terminator), loop
		mov a,r0
		add a,b
		mov b,a				; final cursor position in b
		ret

	   
; --- lcd command function ---
lcd_command:
    mov p2, a              ; place command on p2
    clr p1.0               ; rs = 0 for command
    clr p1.1               ; r/w = 0 for write operation
    setb p1.2              ; e = 1 for high pulse
    lcall wait             ; wait for some time
    clr p1.2               ; e = 0 for h-to-l pulse
    lcall wait             ; wait for lcd to complete the given command
    ret

; --- lcd data function ---
lcd_data:
    mov p2, a              ; send data to p2
    setb p1.0              ; rs = 1 for data
    clr p1.1               ; r/w = 0 for write operation
    setb p1.2              ; e = 1 for high pulse
    lcall wait             ; wait for some time
    clr p1.2               ; e = 0 for h-to-l pulse
    lcall wait             ; wait for lcd to write the given data
    ret

; --- wait subroutine ---
wait:
    push 05h
    push 06h
    mov r6, #30h           ; delay subroutine
there:
    mov r5, #0ffh
here1:
    djnz r5, here1
    djnz r6, there
    pop 06h
    pop 05h
    ret

dboun: mov r6,#10d ;delay subroutine for keypad
	dloop2:mov r7,#250d
	dloop1:nop
	nop
	djnz r7,dloop1
	djnz r6,dloop2
	ret
	
down:mov a, #0cch       ; set cursor position after no  
		mov b,a
        acall lcd_command
        ret
up:mov a, #8dh          ; set cursor position after yes 
		mov b,a
        acall lcd_command
        ret
enter:mov a, #01h          
        acall lcd_command
		mov a,b
		cjne a,#0cch,disp_no
		mov dptr, #string4    ; point to the string
		acall display_string
		ret
		disp_no: mov dptr, #string3    ; point to the string
		acall display_string		
        ret
ret

org 0400h
string1:     db "GO AHEAD: YES",00h
string2:     db "NO",00h
string3:     db "YES: CONT GAME",00h
string4:     db "NO: THANK YOU",00h

	

org 0003h		
		ljmp main_isr ;isr for external interrupt-0 starts here
		return: reti
org 0700h		
		main_isr:
		lcall dboun
		mov a,p0
		anl a,#07h
		cjne a,#07h,identify
		ljmp return
		identify:lcall dboun ;now the program serves to check 
		mov a,p0 ;which key is pressed
		
		setb psw.3 ; set register bank-1 for keyboard operations
		clr psw.4
		mov r0,#00h
		mov r1,#03h
		
		again: rrc  a ;key identification logic starts here
		jc next_key
		sjmp found
		
		next_key: inc r0
		djnz r1,again
		//mov r1,#03h
		
		found:cjne r0,#00h,n1
			lcall up
			sjmp no
			n1:cjne r0,#01h,n2
			lcall down
			sjmp no
			n2:cjne r0,#02h,no
			lcall enter
			no:
			clr psw.3; reset the register bank for lcd display purposes
			clr psw.4
			ljmp return
