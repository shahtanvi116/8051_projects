org 0000h
	ljmp main

org 0023h
main:
	mov sp,#20h
	mov psw,#00h ;reg bank 0	
	lcall clrscreen
	clr p2.4
	clr p2.5
	mov a,#0b8h
	lcall cmdwrt
	mov a,#40h
	lcall cmdwrt
	mov a,0c0h
	lcall cmdwrt	
	lcall snake_game
	here:sjmp here


org 100h ; basic subroutines
cmdwrt:
		acall check_busy_flag; wait till lcd is ready to accept new instruction
		mov p1,a ;move command in accumulator to p1
		
		clr p2.0 ;select command register (rs-pin)
		
		clr p2.1 ;set lcd to write mode (r/w'-pin)
		setb p2.2 ;set enable signal (e-pin)
		acall delay ;call delay subroutine
		clr p2.2 ;give a high to low pulse
		
		ret ;for cmdwrt
		
datawrt:
		//acall check_busy_flag; wait till lcd is ready to accept new instruction
		mov p1,a ;move data in accumulator to p1
		
		setb p2.0 ;select data register (rs-pin)
		
		clr p2.1 ;set lcd to write mode (r/w'-pin)
		setb p2.2 ;set enable signal (e-pin)
		acall delay ;call delay subroutine
		clr p2.2 ;give a high to low pulse
		
		ret ;for datawrt

delay:;1ms delay assuming clk freq 12MHz
	  ;r7 and r6 of reg bank 0 used
		push psw
		mov psw ,#08h //reg bank 1
		mov r7,#2
		here2:mov r6,#255
		here1:djnz r6,here1
		djnz r7,here2
		pop psw
		ret ;for delay
		
delay1s:;1sec delay generation assuming 12Mhz Clk
		;r7 and r6 of reg bank 0 used
		push psw
		mov psw ,#08h //reg bank 1
		mov r7,#04
		here0:mov r6,#250
		here10:mov r5,#250
		here20:
		nop
		nop
		djnz r5,here20
		djnz r6,here10
		djnz r7,here0
		
		pop psw
		ret 
		
display_char: ;subroutine to display a charcter form lookup table
			  ;r5 of reg bak 1 used
		push psw
		mov psw ,#08h //reg bank 1
		mov r5,#00h	; Initialize index for looping through the string		
		mov a,r5 ;mov cuurent index into a
		movc a, @a+dptr ; Load the character from the string
		back2nxt:
		lcall datawrt ; Call datawrt to display the character           
		lcall delay ;call delay 
		inc r5 ;increment index to access next character
		mov a,r5 ;mov new index back into reg-a
		movc a, @a+dptr ;access then new character
		cjne a,#'/',back2nxt  ; If not end of string (null terminator), loop
		pop psw
		ret ;for display_character
		
check_busy_flag: ;subroutine that checks the status of busy flag based on above mentioned conditions
		
		clr p2.0 ; clr rs
		setb p2.1 ;set r/w to 1 for reading from LCD
		back:setb p2.2 ;set enable for high to low pulse to be given
		nop	; delay to generate a low pulse
		clr p2.2 ; clr enable so that busy flag is now made availabe for reading at D7 of lcd
		jb p1.7,back ; check
		ret ;for check busy flag
		
clrscreen:
		  ;r4,r3,r2,r1 of reg bank 1 used
		push psw
		mov psw ,#08h //reg bank 1
		clr p2.4 ;cs1=0
		clr p2.5;cs2=0 
		mov r4,#0b8h
		mov r3,#8
		
		mov a,#40h ;first col
		lcall cmdwrt
		lcall delay
		mov a,#0c0h ;z
		lcall cmdwrt
		lcall delay
		mov dptr,#clear
		
		again: mov a,r4; initially at first page
			   lcall cmdwrt
			   lcall delay
			   mov r2,#8
			   back1:lcall display_char
			   djnz r2,back1		
			   inc r4
		 djnz r3,again
		 
		pop psw
		ret ;for clear screen


		
		


		

org 500h;lookup tables	for char ; black=1 ;upper nibble =lower 4 bits of 8 bits of col
		clear:  db 00h,00h,00h,00h,00h,00h,00h,00h,'/'
		food: db 0ch, 12h, 22h, 44h, 44h, 22h, 12h, 0ch,'/'
		black: db 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,'/'
		 
		tail: db 18h,3ch,3ch,3ch,3ch,3ch,3ch,3ch,18h,'/'
		body:db 18h,3ch,3ch,3ch,3ch,3ch,3ch,3ch,18h,'/'
		head: db 18h,3ch,7eh,7eh,7eh,7eh,3ch,18h,'/'
		
		tail_:db 00h, 00h, 7eh, 0ffh, 0ffh, 7eh, 00h,00h,'/'
		body_:db 00h, 00h, 7eh, 0ffh, 0ffh, 7eh, 00h,00h,'/'
		head_:db  00h, 3ch, 7eh, 0ffh, 0ffh, 7eh, 3ch, 00h,'/'
			
		down: db 18h,3ch,7ch,7ch,0fch,7ch,00h,00h,'/'		
		up:db 18h,3ch,3eh,3fh,3fh,3eh,'/'
			
		S: DB 38,111,73,73,123,50,0,0,'/'      ; S
		N: DB 127,127,6,12,24,127,127,0,'/'    ; N
		chA: DB 124,126,19,19,126,124,0,0,'/'    ; A
		K: DB 127,127,8,28,119,99,0,0,'/'      ; K
		E: DB 127,127,73,73,65,65,0,0,'/'      ; E
		G: DB 62,127,65,81,81,113,0,0,'/'      ; G
		M: DB 127,127,6,12,6,127,127,0,'/'     ; M
		chE: DB 127,127,73,73,65,65,0,0,'/'      ; E

org 600h; snake game 
snake_game:
		setb psw.4
		clr psw.3 ;set Reg-Bank-2 For Game Operations	
		;lets clear what each register of this register bank represents:
		;r0->stores the value of ram location 30h from where the coordinates of snakes body position can be accessed
		;r1->stores the coordinates of head of snake
		;r2->stores the coordinates of tail of snake
		;r3->stores the direction in which the snake is supposed to move currently acts as direction register
		;r4->stores the length of the midlle body section of snake
		;not yet decided->stores the score of snake
		;r6,r7->these are kept free for any copying use in any game related operation
		;r5->food position
			mov r0,#30h ;store the value of ram locations that will be used to store body coordinates
			;set the intial coordinates of snake: head->(y,x)=>0,2, body->0,1, tail->0,0
			mov r1,#03h
			mov @r0,#02h
			mov r2,#01h
			
			mov r3,#00h;initially start moving towards left
			mov r4,#00h;length at start contains only one middle section
			mov r5,#54h; set the initial food position 
			
			mov 19h,@r0 ;19h for old body coord
			mov b,r2 ;b for old tail 
			
			mov a,r1
			mov r6,a ; r6 for old head
			mov a,r5
			mov 18h,r1;18h for head
			lcall choose_coord
			mov dptr,#food
			lcall display_char
	
			test:
			lcall update_lcd
			lcall calc_pos
			lcall update_pos
			lcall delay1s
			mov r3,#03h
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
			subb a,#10h ;set upper nibble to zero i.e. y=0
			mov r1,a
			sjmp ext
				
			nxt_03:
				
			mov a,r1
			add a,#10h ;set upper nibble to zero i.e. y=0
			mov r1,a
			
			ext:
			ret ;for calc_pos subroutine

update_pos: ;this subroutine updates the coordinates of snakes body exluding head
				setb psw.4 ;reg-bank-2
				clr psw.3
				
				mov b,r2 ;store the previous tail location in b to later clear it
					
				mov a,@r0 ;mov the coordinates of middle position to tail 
				mov r2,a
				
				mov 19h,@r0
				
				mov a,r6; store the old snake heads position to middle segment
				mov @r0,a
				
				mov 18h,r6
				
				sjmp ext_1
				
			ext_1:
			ret ;for update_pos

update_lcd: ;this function converts the coordinates to lcd values and displays the same
				;lcd clr and cursor off yet to be given
				setb psw.4 ;reg-bank-2
				clr psw.3
				
				mov a,b	; old tail in b
				lcall choose_coord
				mov dptr,#clear
				lcall display_char
				
				mov a,r2			;tail pos in a
				lcall choose_coord	;set coordinates
				mov a,@r0			;head pos in a
				subb a,19h			;compare with old body pos
				anl a,#0f0h			; if both same then horizontal movement is there
				jz s_t				; if not same body moving up r3=02 or down r3=03
				mov a,r2			; if body moving up or down then check tail  
				subb a,b			;if tail new and old pos same then tail is still horizontal
				anl a,#0f0h			;else tail vertical
				jz st_				
				mov dptr,#body_		;if both tail and body moving vertically
				sjmp e_t
				st_:mov a,r3
					subb a,#02h
					jz up_
					mov dptr,#down	;if only body vertical
					sjmp e_t
					up_:mov dptr,#up
						sjmp e_t
				s_t:mov dptr,#body	;none in vertical
				e_t:lcall display_char
				
				
				mov a,@r0			;body pos in a
				lcall choose_coord	;set coordinates
				mov a,r1			;head pos in a
				subb a,18h			;compare with old head pos
				anl a,#0f0h			; if both same then horizontal movement is there
				jz s_b				; if not same head moving up r3=02 or down r3=03
				mov a,@r0			; if head moving up or down then check body  
				subb a,19h			;if body new and old pos same then body is still horizontal
				anl a,#0f0h			;else head vertical
				jz sb_				
				mov dptr,#body_		;if both body and head moving vertically
				sjmp e_b
				sb_:mov a,r3
					subb a,#02h
					jz up_again
					mov dptr,#down	;if only body vertical
					sjmp e_b
					up_again:mov dptr,#up
						sjmp e_b
				s_b:mov dptr,#body	;none in vertical
				e_b:lcall display_char
				
				
				mov a,r1
				lcall choose_coord
				subb a,18h
				anl a,#0f0h
				jnz s_h
				mov dptr,#head
				sjmp e_h
				s_h:mov dptr,#head_
				e_h:lcall display_char
				
				
			ext_2:	
				mov a,r1 ; store new head position in r1
				cjne a,15h,ext_ ; compare head position 
				lcall food_pos ; update food_pos if it merge with head 
				ext_:ret ;for update_lcd


food_pos:
				clr psw.3 ;reg bank 2 selected
				setb psw.4
				
				mov 1fh,r5 ; r7 of reg bank 3
				mov r5,tl0 ;timer instantaneous value in r5
				mov a,r5
				cjne a,11h,ch_b ; compare new position with head location
				inc a
				ch_b:cjne a,30h,ch_t;compare new position with body location
				inc a
				ch_t:cjne a,12h,skip;compare new position with tail location
				inc a
				skip:inc r4 ; inc length
				mov r5,a ; final food position
			
				mov a,1fh ;old food position in 1fh, replace with space
				lcall choose_coord
				mov dptr,#clear
				lcall display_char
	
				mov a,r5			; mov food to location stored in r5
				lcall choose_coord
				mov dptr,#food
				lcall display_char
				ret ; ret from food_pos
		
choose_coord:
				push acc
				mov r6,a 			;a will have coord of say tail say 33 (row,col)
				anl a,#0f0h 		; a=30
				swap a  			; a=03
				add a,#0b8h 		; a=0bbh ;page selected
				lcall cmdwrt
				mov a,r6			;a=33
				anl a,#0fh 			;a=03 so 3rd block of 0bbh is to be chosen ; col=40h+3h*8h=58h 
				cjne a,#07,nxt		;if less than or equal
				setb p2.5
				clr p2.4
				sjmp nxt_e
				nxt:jnc nxt1
					setb p2.5
					clr p2.4
					sjmp nxt_e
				nxt1: clr p2.5
						setb p2.4
						subb a,#08h
				nxt_e:push b
				mov b,#08h
				mul ab
				pop b
				add a,#40h
				lcall cmdwrt
				pop acc
				ret
end
		
