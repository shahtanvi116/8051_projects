
org 0000h
sjmp main	
org 002bh
	main:
	mov sp,#20h ; initialze stack pointer to place other than register bank addresses
	lcall lcd_initialization
	lcall snake_game
	here: sjmp here
	

org 100h ;space to write LCD Subroutines + Animation Subroutines		

cmdwrt:	
		acall check_busy_flag; wait till lcd is ready to accept new instruction
		mov p1,a
		clr p3.3 ; select rs to write command
		clr p3.4 ; select r/w to write mode
		setb p3.5 ; set enable signal
		acall delay
		clr p3.5 ; give a high to low pulse		
	ret ;for cmdwrt
	
datawrt:
	
		acall check_busy_flag; wait till lcd is ready to accept new instruction
		mov p1,a
		setb p3.3 ; select rs to write data
		clr p3.4 ;select r/w to write mode
		setb p3.5 ; set enable signal
		acall delay
		clr p3.5 ; give a high to low pulse
	ret ;for datawrt
	
check_busy_flag: ;subroutine that checks the status of busy flag based on above mentioned conditions
	
		clr p3.3 ; clr rs
		setb p3.4 ;set r/w to 1 for reading from LCD
		back:clr p3.5 ;clr enable for low to high pulse to be given
		acall delay ; delay to generate a low pulse
		setb p3.5 ; set enable so that busy flag is now made availabe for reading at D7 of lcd
		jb p1.7,back ; check
	ret ;for check_busy_flag
	
dboun: ;delay subroutine for keypad
		mov r6,#10d 
		dloop2:mov r7,#250d
		dloop1:nop
		nop
		djnz r7,dloop1
		djnz r6,dloop2
	ret
	
delay:;25ms delay assuming clk freq 12MHz
	
		mov r3,#50
		here2:mov r4,#255
		here1:djnz r4,here1
		djnz r3,here2
	ret ;for delay
	
delay1s: ;1sec delay generation assuming 12Mhz Clk
		clr psw.3
		clr psw.4
		mov r3,#04
		here0:mov r4,#250
		here10:mov r2,#250
		here20:
		nop
		nop
		djnz r2,here20
		djnz r4,here10
		djnz r3,here0

	ret 

display_string: ;subroutine to display a string form lookup table
	
		mov r0,#00h	; Initialize index for looping through the string
		
		back2nxt:mov a,r0 ;mov cuurent index into a
		movc a, @a+dptr ; Load the character from the string
		
		lcall datawrt ; Call datawrt to display the character           
		
		inc r0 ;increment index to access next character
		mov a,r0 ;mov new index back into reg-a
		movc a, @a+dptr ;access then new character
		
		cjne a,#00h,back2nxt  ; If not end of string (null terminator), loop
	ret

lcd_initialization:
	
		lcall delay ;give lcd some time to Initialize
		lcall delay
		
		mov a,#38h
		lcall cmdwrt
		lcall delay
		
		mov a,#38h
		lcall cmdwrt
		lcall delay
		
		mov a,#38h ;repeat the same command a several times so that Power Supply Reset Timings are met
		lcall cmdwrt
		lcall delay
		
		mov a,#0fh ; dispaly on cursor blinking
		lcall cmdwrt

		mov a,#01h ;clr display
		lcall cmdwrt
					
			mov a,#80h
			lcall cmdwrt	
	ret

org 0650h ;Look-Up Table To Map Out LCD Cursor Positions Based on Coordinate Values
			
				y0:db 80h,81h,82h,83h,84h,85h,86h,87h,88h,89h,8ah,8bh,8ch,8dh,8eh,8fh ;values if y=0
				y1:db 0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch,0cdh,0ceh,0cfh ;values if y=1
					
			org 0675h ;Look-Up Table to Store Snake Characters
				
				head:db "x"
				body:db "o"
				tail:db "*"

org 0700h ; Logic for Snake Game Starts Here
snake_game:
			clr psw.3 ;set Reg-Bank-2 For Game Operations
			setb psw.4
		
		;lets clear what each register of this register bank represents:
		;r0->stores the value of ram location 30h from where the coordinates of snakes body position can be accessed
		;r1->stores the coordinates of head of snake
		;r2->stores the coordinates of tail of snake
		;r3->stores the direction in which the snake is supposed to move currently acts as direction register
		;r4->stores the length of the midlle body section of snake
		;r5->stores the score of snake
		;r6,r7->these are kept free for any copying use in any game related operation
			mov r0,#30h ;store the value of ram locations that will be used to store body coordinates
			;set the intial coordinates of snake: head->(y,x)=>0,2, body->0,1, tail->0,0
			mov r1,#02h
			mov @r0,#01h
			mov r2,#00h
			
			mov r3,#00h;initially start moving towards right
			mov r4,#01h;length at start contains only one middle section
			mov r5,#00d; set the initial score to 00
	
			test:
			lcall update_lcd
			lcall calc_pos
			lcall update_pos
			lcall delay1s
			sjmp test

ret

calc_pos: ;subroutine to calculate position of head
				setb psw.4 ;reg-bank-2
				clr psw.3
;		*****For Our Case p0.0->Right, p0.1->Left, p0.2->Up, p0.3->Down*****
				mov a,r1 ;store the old snake heads coordinates temporary in r6
				mov r6,a ;old head in r6
                inc r1
				
ret

update_pos: ;this subroutine updates the coordinates of snakes body exluding head
				setb psw.4 ;reg-bank-2
				clr psw.3
				mov b,r2 ;old tail in b
				mov a,@r0
				mov r2,a
				mov a,r6
				mov @r0,a
ret

update_lcd:
;this function converts the coordinates to lcd values and displays the same
				;lcd clr and cursor off yet to be given
				setb psw.4 ;reg-bank-2
				clr psw.3

			tail_up:
				mov a,b
				mov dptr,#y0				
				movc a,@a+dptr; set the curosr at tails old coordinates
				lcall cmdwrt				
				mov a,#' ' ;clr the previous tail position with empty space
				lcall datawrt
				
				clr a ;store the tails character in reg-6
				mov dptr,#tail
				movc a,@a+dptr
				mov r6,a
				
				mov dptr,#y0 ;point to values of y0
				mov a,r2
				movc a,@a+dptr ;load lcd postion from L.U.T.
				lcall cmdwrt ;set cursor to this position
				
				mov a,r6
				lcall datawrt ; display the new position
			
			body_up:
				
				clr a ;store the value of body character in reg-6
				mov dptr,#body
				movc a,@a+dptr
				mov r6,a
				
				mov dptr,#y0
				mov a,@r0 ;fetch the coordinates form value pointed by r0
				movc a,@a+dptr
				lcall cmdwrt ;set cursor to new position
				
				mov a,r6
				lcall datawrt ;update lcd with body char
			head_up:
				
				clr a ;store the head character in r6
				mov dptr,#head
				movc a,@a+dptr
				mov r6,a
				
				mov dptr,#y0
				mov a,r1 ;set cursor to new head location
				movc a,@a+dptr
				lcall cmdwrt
				
				mov a,r6 ;update head on new location 
				lcall datawrt
ret

