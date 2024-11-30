org 0000h
sjmp main	
org 002bh
	main:
	mov ie,#81h ; active external interrupt-0 and external interrupt-1 pin
	mov ip,#01h ; give external interrupt-0 higghest priority
	setb tcon.0 ;set the external interrupt pin as edge triggred

	mov sp,#20h ; initialze stack pointer to place other than register bank addresses
	
	lcall lcd_initialization
	//lcall create_custom_char1 ;load custom character into CGRAM of LCD
	//lcall display_title ;display title of project
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
	
delay:;2ms delay assuming clk freq 12MHz
	
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
	
display_title:	
		mov a,#0fh ; dispaly on cursor blinking
		lcall cmdwrt

		mov a,#01h ;clr display
		lcall cmdwrt

		mov a,#84h; shift cursor to 5th Position of 1st line
		lcall cmdwrt

		mov dptr,#string1 ;"G-Yantra"

		lcall display_string

		mov a,#0c1h ;shift curosr to 2nd positon of 2nd line
		lcall cmdwrt

		mov dptr,#string2 ;"Gaming Yantra"

		lcall display_string

		mov a,#0ch ;set lcd to display on cursor off mode
		lcall cmdwrt

		lcall delay1s ; give user time to read the contents of screen
		
		mov a,#0fh ; dispaly on cursor blinking
		lcall cmdwrt
		
		mov a,#84h; shift cursor to 5th Position of 1st line now to display G in Hindi Script
		lcall cmdwrt
		
		mov a,#00h ;display 1st cc "g" in Hindi
		lcall datawrt
		
		mov a,#0ch ;set lcd to display on cursor off mode
		lcall cmdwrt
		
		lcall delay1s
	
ret ;for display_title 
	
create_custom_char1:
		
		mov a,#40h ; Set CGRAM address for Custom Char 1
		lcall cmdwrt
		
		mov dptr,#cch1  ; Point to the start of the custom character table (cc=custom charcter)
		mov r0,#00h     ; Row counter (0-7)
		
		cc1:
		mov a,r0 ;load the index into reg-a       
		movc a,@a+dptr ; Get the row data for Custom Char 1
		lcall datawrt
		inc r0  ; Increment row counter to access the data for next row of c.c.
		mov a,r0
		cjne a,#08h,cc1 ; Repeat until 8 rows are stored
		
ret ;for create_custom_char1
	


org 0003h ;keyboard logic is written here
	ljmp main_isr ;isr for external interrupt-0 starts here
	return:	
		reti
org 0400h		
		main_isr:
			lcall dboun
			mov a,p0
			cjne a,#0ffh,identify
			ljmp return
			
			identify:
			lcall dboun ;now the program serves to check 
			mov a,p0 ;which key is pressed
			
			setb psw.3 ; set register bank-1 for keyboard operations
			clr psw.4
			mov r0,#00h
			mov r1,#04h
			
			again: 
			rrc  a ;key indentification logic starts here
			jc next_key
			sjmp found
			
			next_key: inc r0
			djnz r1,again
			mov r0,#00h
			
			found: mov a,r0; reg where key code is stored
			//mov b,a; *****Reg-B stores the value of direction control*****
			clr psw.3; reset the register bank to 2 for snake_game 
			setb psw.4
			mov r3,a
			ljmp return



org 0500h ;Look-Up to store Strings
		
			;00h is used here to represent a null character indicating the termination of a string
			
			string1:db "G-Yantra",00h ; length of string-8 (Total Length=9 Including Null Character) 
			string2:db "Gaming-Yantra",00h ; length of string-13 (Total Length=14 Including Null Character)
				
			org 0600h ;Look-Up Table to Store Custom Characters Which Will be Loaded in CGRAM when needed
		
				cch1:db  1fh,05h,05h,05h,1dh,15h,19h,01h ;this is hindi character  "g"
					
org 0650h ;Look-Up Table To Map Out LCD Cursor Positions Based on Coordinate Values
			
				y0:db 80h,81h,82h,83h,84h,85h,86h,87h,88h,89h,8ah,8bh,8ch,8dh,8eh,8fh ;values if y=0
				y1:db 0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch,0cdh,0ceh,0cfh ;values if y=1
					
			org 0675h ;Look-Up Table to Store Snake Characters
				
				head:db "x"
				body:db "o"
				tail:db "*"

org 0700h ; Logic for Snake Game Starts Here
snake_game:
			mov a,#01h
			lcall cmdwrt
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
			mov r1,#12h
			mov @r0,#11h
			mov r2,#10h
			
			mov r3,#00h;initially start moving towards right
			mov r4,#01h;length at start contains only one middle section
			mov r5,#00d; set the initial score to 00
			
			mov b,r2
			mov a,r1
			mov r6,a
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
				mov r6,a
				
				mov a,r3 ;mov direction info to reg-a
				
				cjne a,#00h,nxt_01
				inc r1 ;mov snake's head in +-ve x direction
				sjmp ext
				
				nxt_01:
				
				cjne a,#01h,nxt_02
				dec r1 ;mov snake's head in -ve x direction
				sjmp ext
				
				nxt_02:
				
				cjne a,#02h,nxt_03
				mov a,r1
				anl a,#0fh ;set upper nibble to zero i.e. y=0
				mov r1,a
				sjmp ext
				
				nxt_03:
				
				mov a,r1
				orl a,#10h; set the upper nibble to 1 i.e. y=1
				mov r1,a
			
			ext:
			ret ;for calc_pos subroutine

update_pos: ;this subroutine updates the coordinates of snakes body exluding head
				setb psw.4 ;reg-bank-2
				clr psw.3
				
				mov b,r2 ;store the previous tail location in b to later clear it
				
				mov a,r4 ;store length of middle body in reg-a
				
				//cjne a,#01h,len_nt_1 ;check for default movment till the length is not increased to more than 1				
				mov a,@r0 ;mov the coordinates of middle position to tail 
				mov r2,a
				
				mov a,r6; store the old snake heads position to middle segment
				mov @r0,a
				
				sjmp ext_1
				
				len_nt_1:
				
				mov a,r4 ;store the actual length temporary in r7 
				mov r7,a
	
				dec r4 ;length decremented here to make array processing easy
				
				mov a,r0 ;store the last element address by adding the index value to r0
				add a,r4
				mov r0,a
				
				dec r0
				
				mov a,r0; store the address of higher in reg-1 of reg-bank-3 
				
				setb psw.3 ;change to Reg-Bank-3 For Accessing other arrays
				setb psw.4
				
				mov r1,a ;use r1 of reg-bank-3 as pointer in this case I know its Awfull But Theres Nothing I can Do Every other Register Is Occupied At This Pt
				
				clr psw.3 ;change to reg-bank-2 for other operations
				setb psw.4
				
				inc r0 ;set r0 to original indexed value
				
				mov a,@r0 ;store the position of segment after tail to tail
				mov r2,a
				
				iterate:setb psw.3 ;change to Reg-Bank-3 For Accessing other arrays
				setb psw.4
				
				mov a,@r1 ;bring the upper body seg coordinated to reg-a
				dec r1 ;to point to coordinates of next segment
				
				clr psw.3
				setb psw.4
				
				mov @r0,a ;shifting of upper coordinates to lower ones
				
				dec r0
				
				cjne r0,#30h,iterate ;shift all upper elements to lower ones till r0 becomes 30h
				
				mov a,r6 ;load old coordinates of snakes head to last segment closest to head
				mov @r0,a
				
				mov a,r7 ;fill r4 with body's original length
				mov r4,a
				
			ext_1:
			ret ;for update_pos

update_lcd: ;this function converts the coordinates to lcd values and displays the same
				;lcd clr and cursor off yet to be given
				setb psw.4 ;reg-bank-2
				clr psw.3
				mov a,b				
				anl a,#0f0h
				//swap a
				
				jnz y_1
				
				mov a,b
				mov dptr,#y0
				
				
				movc a,@a+dptr; set the curosr at tails old coordinates
				lcall cmdwrt
				
				mov a,#' ' ;clr the previous tail position with empty space
				lcall datawrt
				
				sjmp go1
				
				y_1: ;if tail is at y=1 and x=something then
				
				mov a,b
				mov dptr,#y1
				anl a,#0fh
				movc a,@a+dptr; set the curosr at tails old coordinates
				lcall cmdwrt
				
				mov a,#' ' ;clr the previous tail position with empty space
				lcall datawrt
				
				go1:
				
				;update new coordinates of snake
				
				;update tail
				clr a ;store the tails character in reg-6
				mov dptr,#tail
				movc a,@a+dptr
				mov r6,a
				 
				
				mov a,r2 ;store the new coordinates of tail in a
				anl a,#0f0h
				//swap a
				
				jnz tail_updt_y1
				
				mov dptr,#y0 ;point to values of y0
				mov a,r2
				movc a,@a+dptr ;load lcd postion from L.U.T.
				
				lcall cmdwrt ;set cursor to this position
				
				mov a,r6
				lcall datawrt ; display the new position
				
				sjmp body_updt
				
				tail_updt_y1:
				
				mov dptr,#y1; point to values of y1
				mov a,r2
				anl a,#0fh
				
				movc a,@a+dptr
				
				lcall cmdwrt
				
				mov a,r6
				lcall datawrt
				
				;update body
		body_updt:
				mov a,r4;copy body length in r7 for looping purposes
				mov r7,a
				
				clr a ;store the value of body character in reg-6
				mov dptr,#body
				movc a,@a+dptr
				mov r6,a
				
		bd_updt_loop:
				
				mov a,@r0
				anl a,#0f0h
				//swap a
				
				jnz bd_updt_y1
				
				mov dptr,#y0
				mov a,@r0 ;fetch the coordinates form value pointed by r0
				movc a,@a+dptr
				lcall cmdwrt ;set cursor to new position
				
				mov a,r6
				lcall datawrt ;update lcd with body char
				//cjne r7,#00,bd_loop
				sjmp head_updt_y0
				
		bd_updt_y1:
				
				mov dptr,#y1
				mov a,@r0 ;fetch the coordinates form value pointed by r0
				anl a,#0fh
				movc a,@a+dptr
				lcall cmdwrt ;set cursor to new position
				
				mov a,r6
				lcall datawrt ;update lcd with body char
				
				/*bd_loop:inc r0
				
				djnz r7,bd_updt_loop
				
				mov r0,#30h; load r0 original value back to r0*/
				
				;update head
		head_updt_y0:
				clr a ;store the head character in r6
				mov dptr,#head
				movc a,@a+dptr
				mov r6,a
				
				mov a,r1 ;load the coordinates of head in reg-a
				anl a,#0f0h
				//swap a
				
				jnz head_updt_y1 
				
				mov dptr,#y0
				mov a,r1 ;set cursor to new head location
				movc a,@a+dptr
				lcall cmdwrt
				
				mov a,r6 ;update head on new location 
				lcall datawrt
				
				sjmp ext_2
				
		head_updt_y1:		
				mov dptr,#y1
				
				mov a,r1 ;set cursor to new head location
				anl a,#0fh
				movc a,@a+dptr
				lcall cmdwrt
				
				mov a,r6 ;update head on new location 
				lcall datawrt
				
			ext_2:	
			ret ;for update_lcd
			
end

