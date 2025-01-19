;P1->D0-D7
;P2.0->RS (Reg. Select)
;P2.1->R/W'
;P2.2->E
;P2.3->RST (RESET)
;P2.4->CS1
;P2.5->CS2

;the following are steps that we'll follow:
;1. Initialize GLCD
;2. Select GLCD Half
;3. Select Page
;4. Display Text

;time to give it next set of instructions this helps as we now no longer has to use fixed delay method

;the following is the change in procedure for checking the busy flag which is slightly different compared to standard
;charcter LCD's which is:
;here a high to low pulse is given to enable
;instead of a low to high pulse for conventional displays rest of the code remains the same
;also standard delay subroutine is reduced to 1ms to be more faster
;and pulse duration for high to low transition is also reduced to 1 microsecond instead of 20ms that was used earlier

;For Keyboard :
;p0 is used to Interface Buttons for 8x1 Board

;---The Purpose of this experiment is as follows---
;to divide the screen into grid of 128 pixel grid which contains 8x8 pixel array which can be controlled individually
;also on this display move a snake as per the user inputs

;---also the follwing register banks have been used for varoius operations---
; reg-0->LCD Operations
; reg-1->Keyboard Operations
; reg-2->Snake Game Operations
; reg-3->Random Use

org 0000h
	ljmp main

org 002bh
		main:
		clr p2.7
		mov p0,#0ffh ;set p0 as input port
		
		setb p2.3 ;set rest pin to 1 i.e. inactive mode
		
		mov sp,#40h ;move sp to ram loaction 20h
		
		mov tmod,#02h
		mov th0,#00h
		setb tr0
		
		orl tcon,#01h
		
		mov ie,#81h
		
		
		lcall delay ;some delay is introduced purposefully
		lcall delay
		lcall delay
		lcall delay
		lcall delay
		lcall delay
		
		mov a,#3fh
		
		lcall cmdwrt
		
		lcall clrscreen
		
		lcall snake_game
		stay:sjmp stay


org 0003h
	
	setb p2.7
	ljmp main_isr
	

org 0cffh
	main_isr: ;r0,r1 of reg bank 1
				push psw
				push acc
				setb psw.3 ;select reg-1 for Keyboard Opreations
				clr psw.4
				
				identify:lcall dboun ;now the program serves to check 
				mov a,p0 ;which key is pressed
				
				mov r0,#00h
				mov r1,#04h
				
				again: rrc  a ;key indentification logic starts here
				jc next_key
				sjmp found
				
				next_key: inc r0
				djnz r1,again
				not_found_dir:mov r1,#04h
								again1: rrc  a ;key indentification logic starts here
								jc next_key1
								sjmp found1
								
								next_key1: inc r0
								djnz r1,again1
							  
				sjmp returnback
				
				found: 
				mov a,r0; reg where key code is stored
				mov 13h,a; 13h (reg-3 of reg-bank-2) stores the direction coordinates
				sjmp returnback
				
				found1:
				mov a,r0				
				cjne a,#04h,k5
				mov a,1bh
				cjne a,#35h,not_opt1
			
				mov 1bh,#55h
				lcall choose_coord
				mov dptr,#clear
				
	
				mov r5,#00h	; Initialize index for looping through the string
				mov r0,#08
				back2:
				mov a,r5 ;mov cuurent index into a
				movc a, @a+dptr ; Load the character from the string
				lcall datawrt ; Call datawrt to display the character           
				lcall delay ;call delay 
				inc r5 ;increment index to access next character
				djnz r0,back2
				clr 20h
				sjmp returnback
				
				not_opt1:
				mov 1bh,#35h
				lcall choose_coord
				mov dptr,#clear
				mov r5,#00h	; Initialize index for looping through the string
				mov r0,#08
				back22:
				mov a,r5 ;mov cuurent index into a
				movc a, @a+dptr ; Load the character from the string
				lcall datawrt ; Call datawrt to display the character           
				lcall delay ;call delay 
				inc r5 ;increment index to access next character
				djnz r0,back22
				
				clr 20h
				sjmp returnback
				
				k5:cjne a,#05h,returnback
				setb 20h
				sjmp returnback
				/*k6:cjne a,#06h,k7
				sjmp returnback
				k7:*/
				
		returnback: 
				clr p2.7
				pop acc
				pop psw			
				reti	 ;for key-board isr
			


	
org 0100h ;here lies the codes for GLCD Operations
	
		cmdwrt:
			
			push psw
			clr psw.3
			clr psw.4
			
			;acall check_busy_flag; wait till lcd is ready to accept new instruction
			acall delay
			mov p1,a ;move command in accumulator to p1
			
			clr p2.0 ;select command register (rs-pin)
			
			clr p2.1 ;set lcd to write mode (r/w'-pin)
			setb p2.2 ;set enable signal (e-pin)
			acall delay ;call delay subroutine
			clr p2.2 ;give a high to low pulse
			acall delay
			
			pop psw
			
		ret ;for cmdwrt
		
		datawrt:
		
			push psw
			clr psw.3
			clr psw.4
		
			;acall check_busy_flag; wait till lcd is ready to accept new instruction
			acall delay
			mov p1,a ;move data in accumulator to p1
			
			setb p2.0 ;select data register (rs-pin)
			
			clr p2.1 ;set lcd to write mode (r/w'-pin)
			setb p2.2 ;set enable signal (e-pin)
			acall delay ;call delay subroutine
			clr p2.2 ;give a high to low pulse
			acall delay
			
			pop psw
			
		ret ;for datawrt
		
		display_char: ;subroutine to display a charcter form lookup table
			  ;r5,r0 of reg bak 0 used
				push psw
				clr psw.3
				clr psw.4
				mov r5,#00h	; Initialize index for looping through the string
				mov r0,#08
				back2nxt:
				mov a,r5 ;mov cuurent index into a
				movc a, @a+dptr ; Load the character from the string
				lcall datawrt ; Call datawrt to display the character           
				lcall delay ;call delay 
				inc r5 ;increment index to access next character
				djnz r0,back2nxt
				
				pop psw
		
		ret ;for display_character
		
		delay:;1ms delay assuming clk freq 12MHz
			  ;r7 and r6 of reg bank 0 used
				push psw
				
				clr psw.3
				clr psw.4
				mov r7,#2
				here2:mov r6,#255
				here1:djnz r6,here1
				djnz r7,here2
				
				pop psw
				
			ret ;for delay

		
		delay1s:;1sec delay generation assuming 12Mhz Clk
				;r7,r5 and r6 of reg bank 0 used
		
			push psw
			clr psw.3
			clr psw.4
			mov r7,#02
			here0:mov r6,#250
			here10:mov r5,#250
			here20:
			nop
			nop
			djnz r5,here20
			djnz r6,here10
			djnz r7,here0
			
			pop psw
		
		ret ;for delay1s		
		
		dboun: ;delay subroutine for keypad
			
			push psw
			setb psw.3 ;select reg-1 for Keyboard Opreations
			clr psw.4
			
			mov r4,#10d 
			dloop2:mov r5,#250d
			dloop1:nop
			nop
			djnz r5,dloop1
			djnz r4,dloop2
			
			pop psw
			
		ret ;for dboun
		
		set_column: ;selects a particular column form where to write data for a given selected page
			
			push b
			
			mov b,#08d ;to set the starting column address to the one meant by pixel grid value 
			mul ab
			mov b,a ;copy a in b for book-keeping
			
			subb a,#40h ;check if the number in accumulator is greater than 64 in decimal to take decision
			jnc right_half ;jump to right half if number is >=64 in decimal
			
			;logic for selecting on left half of screen
			
			mov 1ah,#00h ; r2 of reg-bank-3
			
			clr p2.4 ;set cs1 to select first half of glcd (actullay inverted logic is used for proteus simulation hence a bit change in these and rst instructions is seen)
			setb p2.5
			
			
			mov a,b ;reload a with original number
			add a,#40h ;add the number plus the 40h which is command for slecting 0th column in glcd
			
			acall cmdwrt ;call command function to select a particular column
			
			sjmp column_set
			
			right_half: ;logic for right of screen
			
			mov 1ah,#01h ; r2 of reg-bank-3
			
			setb p2.4 ;selecting right half of screen
			clr p2.5
			
			add a,#40h ;since for right half values we'll add to 40h
			acall cmdwrt ;call command function to select a particular column
				
		column_set: 
		
			pop b
			clr c
		ret ;for set_column
		
		set_pg_cntrl: ;Selects one of 8 vertical pages, each representing 8 rows of pixels.
			
			push b
			
			mov b,a ;copy a in reg-b temporarily
			
			mov a,1ah 
			
			jnz rhalf
			
			clr p2.4 ;select left half
			setb p2.5
			
			sjmp done
			
			rhalf: ;if carry isn't 1 set screen to left half
			
			setb p2.4
			clr p2.5
			
			done:mov a,b
			add a,#0b8h ;add numbers form 0 to 7 to b8h to select any pg out of the available 8 pgs
			acall cmdwrt
			
			pop b
			
		ret ;for set_pg_cntrl
		
		clrscreen:
				  ;r4,r3,r2,r1 of reg bank 0 used
				push psw
				clr psw.3
				clr psw.4
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
				
				ag: mov a,r4; initially at first page
					   lcall cmdwrt
					   lcall delay
					   mov r2,#8
					   back1:lcall display_char
					   djnz r2,back1		
					   inc r4
				 djnz r3,ag
				 
				pop psw
			
		ret ;for clear screen
		
		choose_coord: ;this subroutine sets the cursor value to the coordinates contained in reg-a
			
					push acc
					
					mov r7,a ;a will contain coordinates which we would like to set as page and column
					
					anl a,#0fh
					lcall set_column
					
					mov a,r7 ;copy the coordinates saved temporarily back to reg-a
					anl a,#0f0h
					swap a
					lcall set_pg_cntrl
					
					pop acc
					
			ret ;for choose_coord



		
org 250h;lookup tables	for char ; black=1 ;upper nibble =lower 4 bits of 8 bits of col
	
		amp:  db 60h,0f4h,9eh,0bah,6eh,0f4h,90h,00h
		clear:  db 00h,00h,00h,00h,00h,00h,00h,00h
		cursor: db 00h,00h,00h,0ffh,0ffh,00h,00h,00h
		dash:DB 00h,00h,18h,18h,18h,18h,00h,00h
		food: db 0ch, 12h, 22h, 44h, 44h, 22h, 12h, 0ch

		body_horizontal:db 18h,3ch,3ch,3ch,3ch,3ch,3ch,3ch,18h
		head_horizontal: db 18h,3ch,7eh,7eh,7eh,7eh,3ch,18h
		
		body_vertical:db 00h, 00h, 7eh, 0ffh, 0ffh, 7eh, 00h,00h
		head_vertical:db  00h, 3ch, 7eh, 0ffh, 0ffh, 7eh, 3ch, 00h
			
		bented_char_1: db 18h,3ch,7ch,7ch,0fch,7ch,00h,00h ;-|		
		bented_char_2:db 18h,3ch,3eh,3fh,3fh,3eh,00h,00h ;_|
		
		bented_char_3: db 00h,00h,3eh,3fh,3fh,3eh,3ch,18h;|_
		bented_char_4:db 00h,00h,7ch,0fch,0fch,7ch,3ch,1ch;|-
			
		over: db 00h,0fh,7fh,70h //4 
			  db 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0ah, 0bh, 0ch, 0dh, 0eh //14
		      db 1fh, 2fh, 3fh, 4fh, 5fh, 6fh //6
		      db 7eh, 7dh, 7ch, 7bh, 7ah, 79h, 78h, 77h, 76h, 75h, 74h, 73h, 72h, 71h //14
		      db 60h, 50h, 40h, 30h, 20h, 10h //6
			
		N: DB 127,127,6,12,24,127,127,0   ; N
		chA: DB 124,126,19,19,126,124,0,0    ; A
		E: DB 127,127,73,73,65,65,0,0      ; E
		G: DB 62,127,65,81,81,113,0,0      ; G
		M: DB 127,127,6,12,6,127,127,0     ; M
		D: DB 127,127,65,65,127,62,0,0
		S: DB 38,111,73,73,123,50,0,0
		O: DB 62,127,65,65,127,62,0,0
		V: DB 31,63,96,96,63,31,0,0
		R: DB 127,127,9,25,127,102,0,0
		chC: DB 62,127,65,65,65,65,0,0       ; C
			
		; Characters 0-9
		C0: DB 00h,3eh,7fh,51h,49h,7fh,3eh,00h     ; 0
		C1: DB 00h,80h,88h,0feh,0feh,80h,80h,00h        ; 1
		C2: DB 00h,0c4h,0e6h,0a2h,92h,9eh,8ch,00h    ; 2
		C3: DB 00h,44h,0c6h,92h,92h,0feh,6ch,00h      ; 3
		C4: DB 00h,30h,28h,24h,0feh,0feh,20h,00h     ; 4
		C5: DB 00h,4eh,0ceh,8ah,8ah,0fah,72h,00h     ; 5
		C6: DB 00h,7ch,0feh,92h,92h,0f6h,64h,00h     ; 6
		C7: DB 00h,06h,06h,0e2h,0fah,1eh,06h,00h         ; 7
		C8: DB 00h,6ch,0feh,92h,92h,0feh,6ch,00h     ; 8
		C9: DB 00h,4ch,0deh,92h,92h,0feh,7ch,00h    ; 9
			
		start:db 11h,6eh,17h,61h,22h,5dh,28h,55h,33h,49h,16h,64h,15h,51h,25h,63h,37h,59h,44h,1eh
			
org 700h; snake game 
	
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
			
			;*-*-*-*-*Here Coordinates follow (y,x) System where y=rows= page number of glcd (0-7) and x=columns= 8x8 grid columns of glcd (0-fh)*-*-*-*-*
			
			mov r0,#30h ;store the value of ram locations that will be used to store body coordinates
			;set the intial coordinates of snake: head->(y,x)=>0,3, body->0,1, tail->0,1
			
			mov r1,#13h ;set initial head coordinates
			mov @r0,#12h ;set initial body coordinates
			mov r2,#11h	;set initial tail coordinates 
			
			mov r3,#00h ;initially start moving towards left
			mov r4,#02h ;length at start contains only one middle section this is required to match with the later subroutines for increasing length
			mov r5,#34h ; set the initial food position 
			
			mov 19h,@r0 ;19h (r1 of reg-bank-3) for old body coord
			mov b,r2 ;b for old tail 
			
			mov a,r1
			mov r6,a ; r6 for old head
			mov 18h,r1 ;18h (r0 of reg-bank-3) for head
			
			mov 1dh,#00h ;seting the score register to zero immdiate value at start of game
			
			mov a,r5 ; load a with initial food coordinates
			lcall choose_coord ;these instructions are concerned with displaying food at location present in r5
			mov dptr,#food
			lcall display_char
			
			test:
			mov ie,#00h
			lcall calc_pos
			lcall update_pos
			lcall update_lcd
			mov ie,#81h
			lcall delay1s
			sjmp test
		ret	
			
			
			
			
			calc_pos: ;subroutine to calculate position of head
				
				setb psw.4 ;reg-bank-2
				clr psw.3
				
				clr c
	;		*****For Our Case p0.0->Right, p0.1->Left, p0.2->Up, p0.3->Down*****
				mov a,r1 ;store the old snake heads coordinates temporary in r6
				mov r6,a
				
				;the follwoing three lines of codes will assist later in assigning proper charcters as per various situations...
				mov 18h,a ;store old head coordinate in 18h i.e. r0 of reg bank-3
				mov 1bh,r2; store old tail coordinates in 1ch i.e. r3 of reg bank-3	
				mov 19h,@r0 ; store old body coordinates in 19h i.e. r1 of reg bank-3
				
				mov a,r3 ;mov direction info to reg-a
				mov 1ch,a ;store the current direction in 1ch i.e. r4 of reg-bank-3	
				
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
					
				mov a,r0 ;mov the coordinates of middle position to tail
				add a,r4 ;to give access of memory location body element immediately ahead of tail
				dec a ;for indexing as r4=01h by default
				mov r0,a
				
				mov a,@r0 ;access the coordinates of the body element exactly ahead of tail
				
				mov r2,a ;append those coordinates to current tail
				
				mov a,r6; store the old snake heads position to 1st element immediately behind head of middle segment
				mov r0,#30h ;reloading r0 to original value as this body element is the one that is exactly behind head
				mov @r0,a ; copying old head coordinates in middle segment exactly behind the head
				
				cjne r4,#01h,len_nt_1
				
				sjmp ext_1
				
				len_nt_1:
				
				push 14h ;temporarily (reg-R4 of Reg-Bank-2)
				
				dec r4 ;again for indexing purposes
				
				mov a,r0 ;access the last element of array
				add a,r4 ;place its memory location in r0
				mov r0,a ;
				
				continue_len_logic:
				
				push b ;temproarily
				
				mov b,r0 ;store the memory location of currently accessed element
				
				dec r0
				
				mov a,@r0 ;access the coordinates stored at the place
				
				push 10h ;temporarily (reg-R0 of Reg-Bank-2)
				
				mov r0,b ;access the element behind the cuurent using this
				
				mov @r0,a ;load the coordinate values of element ahead in element behind

				pop 10h ;(reg-R0 of Reg-Bank-2)
				
				pop b
				
				djnz r4,continue_len_logic ;at the end of loop r0 will again be 30h Atleast that's what I hope
				
				pop 14h ;(reg-R4 of Reg-Bank-2)
				
				mov r0,#30h ;to be on safer side
				
			ext_1:
			ret ;for update_pos

			update_lcd: ;this function converts the coordinates to lcd values and displays the same
				;lcd clr and cursor off yet to be given
			
				setb psw.4 ;reg-bank-2
				clr psw.3
				
				lcall clear_tail
				
				;remember that old tail coordinate after executing above subroutine still remains in reg-b
				
				lcall update_head_position
				
				push 14h ;temporarily
				
				loop_body_elements:
				
				cjne r0,#30h,skip_itr ;if the current r0=30h then and only then body update is allowed otherwise updation is skipped
				lcall update_body_position ;this is because this subroutine is specially designed for body element just behind head
				
				skip_itr: ;now we may wonder then how is the game working if there is no provision to update rest of array elements based on formulas derived...?
				;this because update_pos subroutine effectively shifts the coordinates that rest of the body elements follow what the 1st body element followed when it was there
				;and their animation/charcter is then cleared when a tail element arrives at same position so in this way we optimized for memory and computations for each element
				;instead we focus on only 3-elements and the rest of the thing follows...
				inc r0
				
				djnz r4,loop_body_elements
				
				pop 14h
				
				mov r0,#30h ;to be on safe side
				
				lcall update_tail_position
				
				mov a,r1 ; store new head position in r1
				cjne a,15h,exit_update_lcd ; compare head position with current food position
				
				inc 1dh ;i.e. R5 of reg-bank-3 used for score tracking
				
				inc r4 ;of reg-bank-2 which contains the length of middle body seection
				
				lcall food_pos ; update food_pos if it merge with head 
				
				
				exit_update_lcd:
				
				lcall check_coll
			ret ;for update_lcd
				
			clear_tail: ;this subroutine clears the tail on glcd at old coordinates
				
				mov a,b	; old tail in b
				lcall choose_coord 
				mov dptr,#clear
				lcall display_char
			
			ret;for clear tail
			
			update_head_position:
			
				mov a,r1 ;load the current head coordinates in reg-a
				lcall choose_coord ;set the coordinates on GLCD
				
				clr c
				subb a,18h ; find h(result)=(h[new]-h[old])
				
				;what follows now is a switch case type instructions based on the patterns I have observed and tabulated in my diary 
				
				cjne a,#10h,next_head_coord1
				
				mov dptr,#head_vertical
				sjmp exit_head
				
				next_head_coord1:
				
				cjne a,#0f0h,next_head_coord2
				
				mov dptr,#head_vertical
				sjmp exit_head
				
				next_head_coord2:
				
				
				cjne a,#01h,next_head_coord3
				
				mov dptr,#head_horizontal
				sjmp exit_head
				
				next_head_coord3:
				
				mov dptr,#head_horizontal
			
				exit_head:
				
				lcall display_char
				
			ret ;for update_head_position
			
			update_body_position:
			
			mov a,@r0 ;load the current body coordinates in a
			lcall choose_coord ;set the coordinates on GLCD
			
			clr c
			subb a,19h ;find b(ro)=(b[new]-b[old])
			
			cjne a,#01h,next_body_coord_1 ;checks if bro=01h
			
				mov a,r1 ;if a=01h check for br status value
				clr c
				subb a,@r0 ;b(r)=(h[new]-b[new])
				
				cjne a,#01h,skip_bro01_01
				
					mov dptr,#body_horizontal
					sjmp exit_body
					
				skip_bro01_01:
				
				cjne a,#10h,skip_bro01_02
				
					mov dptr,#bented_char_1
					sjmp exit_body
				
				skip_bro01_02:
				
					mov dptr,#bented_char_2
					sjmp exit_body
					
			next_body_coord_1:
			
			cjne a,#10h,next_body_coord_2 ;checks if bro=10h
				
				mov a,r1 ;if a=10h check for br status value
				clr c
				subb a,@r0 ;b(r)=(h[new]-b[new])
				
				cjne a,#01h,skip_bro10_01
				
					mov dptr,#bented_char_3
					sjmp exit_body
					
				skip_bro10_01:
				
				cjne a,#10h,skip_bro10_02
				
					mov dptr,#body_vertical
					sjmp exit_body
					
				skip_bro10_02:
				
					mov dptr,#bented_char_2
					sjmp exit_body
					
			next_body_coord_2:
			
			cjne a,#0f0h,next_body_coord_3 ;checks if bro=0f0h
				
				mov a,r1 ;if a=0f0h check for br status value
				clr c
				subb a,@r0 ;b(r)=(h[new]-b[new])
			
				cjne a,#01h,skip_bro0f0_01
				
					mov dptr,#bented_char_4
					sjmp exit_body
					
				skip_bro0f0_01:
				
				cjne a,#0f0h,skip_bro0f0_02
				
					mov dptr,#body_vertical
					sjmp exit_body
					
				skip_bro0f0_02:
				
					mov dptr,#bented_char_1
					sjmp exit_body
					
			next_body_coord_3: ;if nothing matches then bro=0ffh
				
				mov a,r1 ;if a=0ffh check for br status value
				clr c
				subb a,@r0 ;b(r)=(h[new]-b[new])
			
				cjne a,#10h,skip_bro0ff_01
				
					mov dptr,#bented_char_4
					sjmp exit_body
					
				skip_bro0ff_01:
				
				cjne a,#0f0h,skip_bro0ff_02
				
					mov dptr,#bented_char_3
					sjmp exit_body
					
				skip_bro0ff_02:
				
					mov dptr,#body_horizontal
					
			exit_body:
			
			lcall display_char
			
			ret ;for update_head_position
			
			update_tail_position:
			
			mov a,r2 ;load the current tail coordinates in a
			lcall choose_coord ;set the coordinates on GLCD
			
			clr c
			subb a,1bh ;find t(ro)=(t[new]-t[old])
			
			cjne a,#01h,next_tail_coord_1 ;checks if tro=01h
				
				mov a,r0 ;access the last element of array
				add a,r4 ;place its memory location in r0
				mov r0,a
				dec r0 ;for indexing purposes
				mov a,@r0 ;if a=01h check for tr status value
				clr c
				subb a,r2 ;t(r)=(b[new]-t[new])
				
				cjne a,#01h,skip_tro01_01
				
					mov dptr,#body_horizontal
					sjmp exit_tail
					
				skip_tro01_01:
				
				cjne a,#10h,skip_tro01_02
				
					mov dptr,#bented_char_1
					sjmp exit_tail
				
				skip_tro01_02:
				
					mov dptr,#bented_char_2
					sjmp exit_tail
					
			next_tail_coord_1:
			
			cjne a,#10h,next_tail_coord_2 ;checks if tro=10h
				
				mov a,r0 ;access the last element of array
				add a,r4 ;place its memory location in r0
				mov r0,a
				dec r0 ;for indexing purposes
				mov a,@r0 ;if a=10h check for tr status value
				clr c
				subb a,r2 ;t(r)=(b[new]-t[new])
			
				cjne a,#01h,skip_tro10_01
				
					mov dptr,#bented_char_3
					sjmp exit_tail
					
				skip_tro10_01:
				
				cjne a,#10h,skip_tro10_02
				
					mov dptr,#body_vertical
					sjmp exit_tail
					
				skip_tro10_02:
				
					mov dptr,#bented_char_2
					sjmp exit_tail
					
			next_tail_coord_2:
			
			cjne a,#0f0h,next_tail_coord_3 ;checks if tro=0f0h
				
				mov a,r0 ;access the last element of array
				add a,r4 ;place its memory location in r0
				mov r0,a
				dec r0 ;for indexing purposes
				mov a,@r0 ;if a=0f0h check for tr status value
				clr c
				subb a,r2 ;t(r)=(b[new]-t[new])
			
				cjne a,#01h,skip_tro0f0_01
				
					mov dptr,#bented_char_4
					sjmp exit_tail
					
				skip_tro0f0_01:
				
				cjne a,#0f0h,skip_tro0f0_02
				
					mov dptr,#body_vertical
					sjmp exit_tail
					
				skip_tro0f0_02:
				
					mov dptr,#bented_char_1
					sjmp exit_tail
					
			next_tail_coord_3: ;if nothing matches then tro=0ffh
				
				mov a,r0 ;access the last element of array
				add a,r4 ;place its memory location in r0
				mov r0,a
				dec r0 ;for indexing purposes
				mov a,@r0 ;if a=0ffh check for tr status value
				clr c
				subb a,r2 ;t(r)=(b[new]-t[new])
			
				cjne a,#10h,skip_tro0ff_01
				
					mov dptr,#bented_char_4
					sjmp exit_tail
					
				skip_tro0ff_01:
				
				cjne a,#0f0h,skip_tro0ff_02
				
					mov dptr,#bented_char_3
					sjmp exit_tail
					
				skip_tro0ff_02:
				
					mov dptr,#body_horizontal
					
			exit_tail:
			
			lcall display_char
			
			mov r0,#30h
			
			ret ;for update_body_position
			
food_pos:;r5 of reg bank 2 and r6 of reg bank 2 and 20h memory location
	
	
	setb psw.4
	clr psw.3
	push 16h
	
	mov dptr,#start  ;in dptr the starting value where all random food coordinates are stored...for now total 10 coordinates are there
	mov r5,tl0       ;random value in r5
	mov a,r5     	;random value in a
	anl a,#19		;limit the random value in  0 to 20 bcz it is basically the count which we will add to dptr to point to some random coordinate
	mov r6,a		;r6 will remember the count i.e form '#start' which position in lookup we are pointing that count

	movc a,@a+dptr	;mov the coord corresponding to pointed vaule in a...so now a has random food position but randomness is controlled
	mov r5,a		;mov the food coordinate into r5
	
    check_overlap: mov 20h,r1		;due to syntax limitaion of cjne we are using 20h to store specific value (head,tail or other body element) at a time so that it can be compared with the newly generated conrolled random food coordinate which is till now stored in r5 and a
					cjne a,20h,ch_t ;compare food coord with head coord
					sjmp nxt_coord ;if equal we have to change coord so jmp to nxt_coord
					
				ch_t:mov 20h,r2			;mov tail coord in 20h
				     cjne a,20h,ch_b	;if not equal we will compare tail and food coordinate
					sjmp nxt_coord		;if equal jmp to nxt coord else go for body comparision
					
				ch_b: mov 20h,@r0					;first mov 1st body elemnt coord that is stored in 30h (r0 points 30h) in 20h
					  cjne r4,#01h,ch_b_len_nt1		;if length is one then we only have to check whether food overlaps with one body element but if it is > 1 the we'll have to check for (r4) body elemnts...(r4)=length of body elements
					  cjne a,20h,finally_done		;check for 1 elemnt as r4=1 and if no overlapping then done otherwise nxt_coord
					  sjmp nxt_coord				
				ch_b_len_nt1: push 10h				;first push r0=10h bcz due to limitaion of reg we will use r0 to point diff elements
							push 14h				;r4=14h ,reg bank 2
				do_again: cjne a,20h,nxt_element	;a=food coord and 20h = coord in 30h for first iteration...compare and decide accordingly
						  sjmp nxt_coord
						nxt_element: inc r0			; element in 30h is compared the in r0 so now it point to 31h
							mov 20h,@r0				;mov value stored in 31h in 20h
						djnz r4,do_again			;repeat for r4 times i.e if body length is 2 then r4=2 and this will repeat for 30h and 31h 
						pop 14h						;pop r4
						pop 10h						; pop r0
						sjmp finally_done			;if till here it has not jumped to nxt_coord this means there is no overlapping so we are good to go
				
	
	nxt_coord: cjne r6,#19,barabar 				;r6 has count of which random position out stored 10 we are using...if count is 10 then it means that it will be pointion to last element of pur lookup array so we will re initialize ut by making r6 0
				mov r6,#00h							;re initialize r6
				sjmp check_again		
				
				barabar: inc r6						; if r6<10 then no issue we can simply in it and then get respective value
						 mov a,r6					;mov count in a...so say if r6 was 3h so after incr it is 4h and so now a has 4 stored
				check_again: movc a,@a+dptr			;thus from the stored values choose 4th one
							sjmp check_overlap		;as it entered nxt_coord it meant there was overlaping somewhere so after giving new coordinates again check if still overlapping exists 
			 
			 finally_done:
			 mov r5,a 
			 
				lcall choose_coord
				mov dptr,#food
				lcall display_char
				pop 16h
				
				mov a,r4 ;cuurent body element length
				
				cjne a,#01h,len_incremented
				
				sjmp exit_food_pos
				
				len_incremented:
				
				dec a ;for indexing puropses
				add a,r0 ;find the element location (memory) associated with increased length
				mov r0,a ;and copy its location in r0
				
				mov a,r2 ;copy cuurent tail location in element location pointed by r2
				mov @r0,a

				mov r0,#30h ;after this restore r0 to original value since this is required to be done only for tail and the new body element add ahead of it
				
				mov r2,b ;store the current tails coordinates to the one from where it was cleared earlier because food element is eaten and condition requires to do so
			
			exit_food_pos:
			ret ;ret from food_pos 
			
			
			check_coll: ;this subroutine checks for collision with GLCD boundary coordinates
			
				mov a,r1
				push psw
				setb psw.4
				setb psw.3
				mov r7,a
				mov dptr,#over
				mov r0,#44
				chk_nxt:clr a
						movc a,@a+dptr
						cjne a,1fh,cont
						ljmp game_over
						cont:inc dptr
				djnz r0,chk_nxt				
				pop psw
				
			ret;for check_coll
				
			
			self_collision: ;this subroutine checks for self-collision of snake with itself
			
				;this is called at Keyboards ISR only and checks if the latest key press is for or against a given 1-d Direction
				
				cjne a,#00h,check_left ;if not right then check left
					
					clr c
					subb a,1ch ;subtract the old direction info
					
					clr c;
					
					subb a,#0ffh ;00h-01h =0ffh thus after this if a=0 then left is detected i.e. initial movement was left but new movment is towards right
					
					jnz exit_self_collision 
					
					sjmp game_over_call ;however if a=0 then right key pressed for a head moving left and hence we jump to game-over
				
				check_left:
				
				cjne a,#01h,check_up ;if not left then check up
					
					clr c
					subb a,1ch ;subtract the old direction info
					
					clr c;
					
					subb a,#01h ;01h-00h =01h thus after this if a=0 then right is detected i.e. initial movement was right but new movment is towards left 
					
					jnz exit_self_collision 
					
					sjmp game_over_call ;however if a=0 then right key pressed for a head moving left and hence we jump to game-over
					
				check_up:
				
				cjne a,#02h,check_down ;if not right then ckeck left
					
					clr c
					subb a,1ch ;subtract the old direction info
					
					clr c;
					
					subb a,#0ffh ;02h-03h =0ffh thus after this if a=0 then down is detected i.e. initial movement was down but new movment is towards up 
					
					jnz exit_self_collision 
					
					sjmp game_over_call ;however if a=0 then up key pressed for a head moving down and hence we jump to game-over
					
				check_down:
					
					clr c
					subb a,1ch ;subtract the old direction info
					
					clr c;
					
					subb a,#01h ;03h-02h =01h thus after this if a=0 then up is detected i.e. initial movement was up but new movment is towards down 
					
					jnz exit_self_collision 
					
					game_over_call:lcall game_over ;however if a=0 then up key pressed for a head moving down and hence we call game-over
				
			exit_self_collision:
			
			ret ;for self_collision
			
			calc_score: ;this subroutine calculates the score and diplays the 2-digit code form 0-99 in decimal number system
			;so yes this code can show you correct scores only for values form 0-99 in decimal
			;also the logic used to display a given binary number/stored as hex number to its equivalent BCD is shown in Book By MKP Sir Ch-9 Ex-9.1 
			;One Can Refer that for that logic understanting
			
				mov a,1dh ;move cuurent score value in reg-a
				
				mov b,#10d ;move 10d in reg-b
				
				div ab ;quotient is stored in a (10's place digit) & remainder is stored in b (1's Digit Number)
				
				clr c ;clr carry for iterating for both the digits
				
				now_1s_place:
				
				cjne a,#00h,check_1 ;checkes if content of a is 00h takes appropriate action similar thing is done for other instructions below
				
					mov dptr,#C0
					sjmp go_to_display
					
				check_1:
				
				cjne a,#01h,check_2
				
					mov dptr,#C1
					sjmp go_to_display
					
				check_2:
				
				cjne a,#02h,check_3
				
					mov dptr,#C2
					sjmp go_to_display
					
				check_3:
				
				cjne a,#03h,check_4
				
					mov dptr,#C3
					sjmp go_to_display
					
				check_4:
				
				cjne a,#04h,check_5
				
					mov dptr,#C4
					sjmp go_to_display
					
				check_5:
				
				cjne a,#05h,check_6
				
					mov dptr,#C5
					sjmp go_to_display
					
				check_6:
				
				cjne a,#06h,check_7
				
					mov dptr,#C6
					sjmp go_to_display
				
				check_7:
				
				cjne a,#07h,check_8
				
					mov dptr,#C7
					sjmp go_to_display	
					
				check_8:
				
				cjne a,#08h,check_9
				
					mov dptr,#C8
					sjmp go_to_display
					
				check_9:
				
					mov dptr,#C9
					
				go_to_display:
					
					jc almost_there ;check if carry is set or not if not then load 10's digit number on GLCD else jmp to label
					
					mov a,#3ah
					lcall choose_coord
					lcall display_char
					sjmp next_digit ;after displaying 10's digit at appropraite place in glcd make decsions for 1's digit
					
					almost_there:
					
					mov a,#3bh ;since carry was set now display 1's digit number on glcd and then return from subroutine
					lcall choose_coord
					lcall display_char
					sjmp exit_calc_score
					
				next_digit:
				
				mov a,b ;put the 1's digit in a
				setb c
				sjmp now_1s_place ;iterate the procedure again for 1's digit number
			
			exit_calc_score:
			
			ret ;for calc score
			
			disp_score: ;this subroutine displays the score of user after a game-over
			
				mov a ,#34h
				lcall choose_coord
				mov dptr,#S
				lcall display_char
				
				mov a ,#35h
				lcall choose_coord
				mov dptr,#chC
				lcall display_char
				
				mov a ,#36h
				lcall choose_coord
				mov dptr,#O
				lcall display_char
				
				mov a ,#37h
				lcall choose_coord
				mov dptr,#R
				lcall display_char
				
				mov a ,#38h
				lcall choose_coord
				mov dptr,#E
				lcall display_char
				
				lcall calc_score ;calculate score as per value in score register and display the digits
				
			ret ;for display_score
				
			game_over: ;this subroutine is used to display gameover string along with score display at end
			
				lcall clrscreen
				
				mov a ,#36h
				lcall choose_coord
				mov dptr,#G
				lcall display_char
				
				mov dptr,#chA
				lcall display_char
				mov a,#38h
				
				lcall choose_coord
				mov dptr,#M
				lcall display_char
				
				mov dptr,#E
				lcall display_char
				mov a ,#46h
				lcall choose_coord
				
				mov dptr,#O
				lcall display_char
				
				mov dptr,#V
				lcall display_char
				mov a,#48h
				lcall choose_coord
				
				mov dptr,#E
				lcall display_char
				
				mov dptr,#R
				lcall display_char
				
				lcall delay1s
				lcall delay1s
				lcall delay1s
				lcall delay1s
				
				lcall clrscreen
				
				lcall disp_score
				
			ends:sjmp ends

end
