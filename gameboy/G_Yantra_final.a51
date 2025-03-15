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

;x-x-x-x-x-x-x-x-x-x-x-x-x-x-Key Changes Made in This Version Which I Would Like To Draw Your Attention To-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x
;1. Code In Code Memory has been segemnted as Follows:
;-> form 0010h to 0054h main labeled code is written
;-> from 0064h to 01A3h GLCD and Delay Related Routines are written
;-> from 00250h to 02C4h Keyboard ISR is Written for Snake Game and GUI
;-> from 002d0h to 0341h Keyboard ISR is Written for 4 in a Row
;-> from 0343h to 079bh Look-Up Table for Various Things Lies
;-> from 079dh to 0CFEh Main Gameboy Related Routines and Snake Games Are Written
;-> from 0d00h to 0FDAh 4 in a Row Game Related Routines Are Written
;2. for GUI Related Purposes bit-wise memory location 08h to 0bh have been used appropriately

;3. Keyboard ISR has been made more generalised as it should be !!!

;4. calc_pos subroutine has been modified at end

;5. some subroutines like that of snake game and game over haven been reduced to mere jump statements this can and probably will be fixed as and when 
; required

;6. I've changed some of your label names since they were conflicting with look-up table methods but don't worry I've renamed them more properly... 

;AND THAT'S IT ENJOY READING ALL THESE CODES TRYING TO UNDERSTAND WHAT THEY DO...! :)

org 0000h
	
	sjmp main
	
org 0003h
	
	jb 0ch,keyboard_normal
	jnb 09h,key_board_isr_4IR
	keyboard_normal:
	ajmp key_board_isr
	
	key_board_isr_4IR:
	ajmp keyboard_isr_4_in_a_row

org 0010h
		
		main: ;main logic inception starts here 
		
		mov p0,#0ffh ;set p0 as input port
		
		setb p2.3 ;set rest pin to 1 i.e. inactive mode
		
		mov sp,#5ch ;move sp to ram loaction 40h
		
		mov tmod,#02h
		mov th0,#00h
		setb tr0
		
		orl tcon,#01h
		
		mov ie,#00h
		
		
		lcall delay ;some delay is introduced purposefully
		lcall delay
		lcall delay
		lcall delay
		lcall delay
		lcall delay
		
		mov a,#3fh
		
		lcall cmdwrt
		
		lcall clrscreen
		lcall g_yantra_intro
		
		lcall clrscreen
		lcall developers_intro
		
		setb 08h ;set bit location 08h
	    setb 0ch
		
		lcall gui
		setb 09h
		ljmp game_select
		
		stay: sjmp stay

	
org 0064h ;here lies the codes for GLCD and GUI Related Operations
	
		cmdwrt: ;to give commands to GLCD
			
			push psw
			
			clr psw.3
			clr psw.4
			
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
		
		datawrt: ;to give data to GLCD
		
			push psw
			
			clr psw.3
			clr psw.4
		
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
				push acc
				
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
				
				pop acc
				pop psw
		
		ret ;for display_character
		
		display_string: ;used to display a string here we pass dptr value, total characters and first character location
		;r5 of rb3
			 
			 push psw
			 
			 setb psw.3
			 setb psw.4
			 
			 mov r5,a  ; total characters in string
			 
			 nxt_no: 
				lcall display_char
				lcall nxt_dptr
				inc b
				mov a,b
				lcall choose_coord
			 djnz r5 ,nxt_no
			
			pop psw
			
		ret ;for display_string
		
		nxt_dptr: ;used in subroutine of display_string only...! 
		;r4 of rb3
		;to transverse dptr through different characters of string
			
			mov r4,#8
			incr:inc dptr
			djnz r4,incr
			
		ret ;for nxt_dptr
		
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
		; r4,r5 of reg bank 1
			
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
		;r2 of reg b3
			
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
		
		clrscreen: ;r4,r3,r2,r1 of reg bank 0 used
				
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
				
				ag:	mov a,r4; initially at first page
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
		;r7 of rb3
					
					push psw
					push acc
					push 1fh
					
					setb psw.3
					setb psw.4
					
					mov r7,a ;a will contain coordinates which we would like to set as page and column
					
					anl a,#0fh
					lcall set_column
					
					mov a,r7 ;copy the coordinates saved temporarily back to reg-a
					anl a,#0f0h
					swap a
					lcall set_pg_cntrl
					
					pop 1fh
					pop acc
					pop psw
					
		ret ;for choose_coord

org 250h ;keyboard isr starts here
	
	key_board_isr: ;r0,r1 of reg bank 1
				
				push psw
				push acc
				setb psw.3 ;select reg-1 for Keyboard Opreations
				clr psw.4
				
				identify:lcall dboun ;now the program serves to check 
				mov a,p0 ;which key is pressed
				
				mov r0,#00h
				mov r1,#08h
				
				again: rrc  a ;key indentification logic starts here
				jc next_key
				sjmp found
				
				next_key: inc r0
				djnz r1,again
				sjmp returnback
				
				found: 
				mov a,r0; reg where key code is stored
				mov 13h,a; 13h (reg-3 of reg-bank-2) stores the direction coordinates
				
				jb 08h,gui_funcs ;check bitwise loaction if it is set
				
				jb 0ah,check_start ;check if start button is pressed
				
				sjmp returnback
				
				gui_funcs:
				
				cjne a,#02h,sel_down ;if a=up then clear down cursor and update cursor to new position
					
					setb 09h;set game select bit
					mov a,#50h
					lcall choose_coord
					mov dptr,#clear
					lcall display_char
					
					mov a,#30h
					lcall choose_coord
					mov dptr,#cursor
					lcall display_char
					
					sjmp returnback
				
				sel_down:
				
				cjne a,#03h,sel_button_pressed ;if a=down then clear up cursor and update cursor to new position
					
					clr 09h;clr game select bit
					mov a,#30h
					lcall choose_coord
					mov dptr,#clear
					lcall display_char
					
					mov a,#50h
					lcall choose_coord
					mov dptr,#cursor
					lcall display_char
					
					sjmp returnback
			
			sel_button_pressed: ;check if select button is pressed in while branching from GUI subroutine
				
				cjne a,#07h,returnback
			
					clr 08h ;clr selection bit
				
				sjmp returnback
				
			check_start: ;check if start button is pressed in while branching form game_select subroutine
			
				cjne a,#06h,returnback
				
				setb 0bh; set start bit 0bh
				clr 0ah ;for breaking out of start button pressed loop
				clr 0ch
			
		returnback: 
				
				pop acc
				pop psw			
				
		reti	 ;for key-board isr
		
org 2d0h ;KEYBOARD ISR FOR 4 IN A ROW GAME STRATS Here
	
	keyboard_isr_4_in_a_row:
	
				push psw
				push acc
				setb psw.3 ;select reg-1 for Keyboard Opreations
				clr psw.4
				
				identify_4IR:lcall dboun ;now the program serves to check 
				mov a,p0 ;which key is pressed
				
				mov r0,#00h
				mov r1,#08h
				
				again_4IR: rrc  a ;key indentification logic starts here
				jc next_key_4IR
				sjmp found_4IR
				
				next_key_4IR: inc r0
				djnz r1,again_4IR
				sjmp returnback_4IR
				
				found_4IR: 
				mov a,r0; reg where key code is stored
				
				cjne a,#00h,ch_01 ;if key 1 is pressed means move the coin right
				;this logic is for game2
				;for same key game1 has different logic
				;1 bit adress can be used to determine which game is going on...will do it when I'll integrate both games
					
					mov a,12h ;clear old coin position coin pos saved in reg r2(12h) of rb2
					lcall choose_coord
					mov dptr,#clear
					lcall display_char
				
                ;below 4 lines are to make sure that the coin is still in range...our range is 17h to 1dh so if it is at 1dh so next position will be 17h				
					mov a,12h
					cjne a,#1dh,goto_nxt_4IR ;if it is at 1dh location i.e. last positoin then
					mov 12h,#16h ;set it to first position again but 1 less than it bcz in next instruction it will be incremented
					goto_nxt_4IR:inc 12h
					
					sjmp repeat_4IR
					
					
				ch_01:cjne a,#01h,sel_button_pressed_4IR ;if key 2 is pressed means move the coin to left
				;this logic is for game2
				;for same key game1 has different logic
				;1 bit adress can be used to determine which game is going on...will do it when I'll integrate both games
					
					mov a,12h ;clear old coin position;coin pos saved in reg r2 of rb2
					lcall choose_coord
					mov dptr,#clear
					lcall display_char
				
                ;below 4 lines are to make sure that the coin is still in range...our range is 17h to 1dh so if it is at 1dh so next position will be 17h				
					mov a,12h
					cjne a,#17h,goto_nxt1_4IR ;if it is at 1dh location i.e. last positoin then
					mov 12h,#1eh ;set it to first position again but 1 less than it bcz in next instruction it will be incremented
					goto_nxt1_4IR:dec 12h
					
					
					repeat_4IR:
					mov a,12h
					lcall choose_coord
					
					jnb 01h,player2 		;if 01h is set means p1's turn is going on , else p2 turn so display the cursor coin accordingly			
					
					mov dptr,#c_p1
					lcall display_char
					
					sjmp returnback_4IR
					
					player2:
					mov dptr,#c_p2
					lcall display_char
					
					sjmp returnback_4IR
				
				
			
			sel_button_pressed_4IR: ;check if select button is pressed 
			    
				cjne a,#07h,returnback_4IR
				
				setb 00h; to mark that position is selected 00h bit is set
				cpl 01h ; to mark that now turn of next player so 01h is toggled
			
		returnback_4IR: 
				
				pop acc
				pop psw			
				
		reti	 ;for key-board isr_4IR
		
org 343h ;lookup tables	for char ; black=1 ;upper nibble =lower 4 bits of 8 bits of col
		
		clear:  db 00h,00h,00h,00h,00h,00h,00h,00h
		
		cursor: db 0x00, 0xFF, 0xFF, 0x7E, 0x7E, 0x3C, 0x18, 0x00  ;Code for Cursor (>)

		grid: db 0ffh,0c3h,81h,81h,81h,81h,0c3h,0ffh;
		
		coin1: db 0ffh,0ffh,0e7h,0dbh,0dbh,0e7h,0ffh,0ffh;
		coin2: db 0ffh,0ffh,0e7h,0c3h,0c3h,0e7h,0ffh,0ffh;
		
		c_p1: db 00h,3ch,42h,5ah,5ah,42h,3ch,00h; player 1 coin
		c_p2: db 00h,3ch,42h,42h,42h,42h,3ch,00h; player 2 coin
		
		dash:DB 00h,00h,18h,18h,18h,18h,00h,00h ; -
		
		food: db 0ch, 12h, 22h, 44h, 44h, 22h, 12h, 0ch

		body_horizontal:db 18h,3ch,3ch,3ch,3ch,3ch,3ch,3ch,18h
		head_horizontal: db 18h,3ch,7eh,7eh,7eh,7eh,3ch,18h
		
		body_vertical:db 00h, 00h, 7eh, 0ffh, 0ffh, 7eh, 00h,00h
		head_vertical:db  00h, 3ch, 7eh, 0ffh, 0ffh, 7eh, 3ch, 00h
			
		bented_char_1: db 18h,3ch,7ch,7ch,0fch,7ch,00h,00h ;-|		
		bented_char_2:db 18h,3ch,3eh,3fh,3fh,3eh,00h,00h ;_|
		
		bented_char_3: db 00h,00h,3eh,3fh,3fh,3eh,3ch,18h;|_
		bented_char_4:db 00h,00h,7ch,0fch,0fch,7ch,3ch,1ch;|-
		
		boundary_collision_values:db 00h,0fh,7fh,70h ;4 
								  db 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0ah, 0bh, 0ch, 0dh, 0eh ;14
								  db 1fh, 2fh, 3fh, 4fh, 5fh, 6fh ;6
		                          db 7eh, 7dh, 7ch, 7bh, 7ah, 79h, 78h, 77h, 76h, 75h, 74h, 73h, 72h, 71h ;14
		                          db 60h, 50h, 40h, 30h, 20h, 10h ;6
		
		start_food_pos:db 11h,6eh,17h,61h,22h,5dh,28h,55h,33h,49h,16h,64h,15h,51h,25h,63h,37h,59h,44h,1eh
		
		chA: DB 124,126,19,19,126,124,0,0    ; A
		chB: DB 127,127,73,73,127,54,0,0 ; B
			
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
			
		;characters of string gaming
		gaming: DB 62,127,65,81,81,113,0,0 ;G
				DB 124,126,19,19,126,124,0,0 ;A
				DB 127,127,6,12,6,127,127,0 ;M
				DB 65,65,127,127,65,65,0,0 ;I
				DB 127,127,6,12,24,127,127,0 ;N
				DB 62,127,65,81,81,113,0,0 ;G
					
		;characters of string YANTRA
		yantra:DB 7,15,120,120,15,7,0,0 ;Y
			   DB 124,126,19,19,126,124,0,0 ;A
			   DB 127,127,6,12,24,127,127,0 ;N
			   DB 1,1,127,127,1,1,0,0 ;T
			   DB 127,127,9,25,127,102,0,0 ;R
			   DB 124,126,19,19,126,124,0,0 ;A
		
		;characters of string G-YANTRA
		g_yantra:DB 62,127,65,81,81,113,0,0 ;G
				 DB 00h,00h,18h,18h,18h,18h,00h,00h ;-
				 DB 7,15,120,120,15,7,0,0 ;Y
				 DB 124,126,19,19,126,124,0,0 ;A
				 DB 127,127,6,12,24,127,127,0 ;N
				 DB 1,1,127,127,1,1,0,0 ;T
				 DB 127,127,9,25,127,102,0,0 ;R
				 DB 124,126,19,19,126,124,0,0 ;A
		
		;characters of string SELECT
		select: DB 38,111,73,73,123,50,0,0 ;S
				DB 127,127,73,73,65,65,0,0 ;E
				DB 127,127,64,64,64,64,0,0 ;L
				DB 127,127,73,73,65,65,0,0 ;E
				DB 62,127,65,65,65,65,0,0 ;C
				DB 1,1,127,127,1,1,0,0 ;T
					
		;characters of string SCORE
		score: DB 38,111,73,73,123,50,0,0 ;S
			   DB 62,127,65,65,65,65,0,0 ;C
			   DB 62,127,65,65,127,62,0,0 ;O
			   DB 127,127,9,25,127,102,0,0 ;R
			   DB 127,127,73,73,65,65,0,0 ;E
		
		;characters of string GAME			
		game: DB 62,127,65,81,81,113,0,0 ;G
			  DB 124,126,19,19,126,124,0,0 ;A
			  DB 127,127,6,12,6,127,127,0 ;M
			  DB 127,127,73,73,65,65,0,0 ;E
		
		;characters of string over		  
		over: DB 62,127,65,65,127,62,0,0 ;O
			  DB 31,63,96,96,63,31,0,0 ; V
		      DB 127,127,73,73,65,65,0,0 ;E
		      DB 127,127,9,25,127,102,0,0 ;R
		
		;characters of string DEVELOPED
		developed:DB 127,127,65,65,127,62,0,0 ;D
			      DB 127,127,73,73,65,65,0,0 ;E
				  DB 31,63,96,96,63,31,0,0 ;V
				  DB 127,127,73,73,65,65,0,0 ;E
				  DB 127,127,64,64,64,64,0,0 ;L
				  DB 62,127,65,65,127,62,0,0 ;O
				  DB 127,127,9,9,15,6,0,0 ;P
				  DB 127,127,73,73,65,65,0,0 ;E	
				  DB 127,127,65,65,127,62,0,0 ;D
		
		;characters of string BY
		by:DB 127,127,73,73,127,54,0,0 ;B
		   DB 7,15,120,120,15,7,0,0 ;Y
			   
		;characters of string IN
		in:DB 65,65,127,127,65,65,0,0 ;I
		   DB 127,127,6,12,24,127,127,0 ;N
		   
			   
		;characters of string TO
		to:DB 1,1,127,127,1,1,0,0 ;T 
		   DB 62,127,65,65,127,62,0,0 ;O
		
		;characters of string PRESS
		press: DB 127,127,9,9,15,6,0,0 ; P
			   DB 127,127,9,25,127,102,0,0 ;R
			   DB 127,127,73,73,65,65,0,0 ;E	
			   DB 38,111,73,73,123,50,0,0 ;S
			   DB 38,111,73,73,123,50,0,0 ;S

		;characters of string PLAY
		play: DB 127,127,9,9,15,6,0,0 ; P
			  DB 127,127,64,64,64,64,0,0 ;L
			  DB 124,126,19,19,126,124,0,0 ;A	
			  DB 7,15,120,120,15,7,0,0 ;Y
				  
		;characters of string PLAYER
		player: DB 127,127,9,9,15,6,0,0 ;P
				DB 127,127,64,64,64,64,0,0 ;L
				DB 124,126,19,19,126,124,0,0 ;A
				DB 7,15,120,120,15,7,0,0 ;Y
				DB 127,127,73,73,65,65,0,0 ;E
				DB 127,127,9,25,127,102,0,0 ;R
				  
		;characters of string START
		start: DB 38,111,73,73,123,50,0,0 ;S
			   DB 1,1,127,127,1,1,0,0 ;T 
			   DB 124,126,19,19,126,124,0,0 ;A	
			   DB 127,127,9,25,127,102,0,0 ;R
			   DB 1,1,127,127,1,1,0,0 ;T
				
		;characters of string ROW
		row:DB 127,127,9,25,127,102,0,0 ;R
		    DB 62,127,65,65,127,62,0,0 ;O
			DB 127,127,48,24,48,127,127,0 ; W
				
		;characters of string RUDRA
		rudra:DB 127,127,9,25,127,102,0,0 ;R
			  DB 63,127,64,64,127,63,0,0 ;U
			  DB 127,127,65,65,127,62,0,0 ;D
			  DB 127,127,9,25,127,102,0,0 ;R
			  DB 124,126,19,19,126,124,0,0 ;A
		
		;characters of string JOSHI
		joshi:DB 48,112,64,64,127,63,0,0 ;J
			  DB 62,127,65,65,127,62,0,0 ;O
			  DB 38,111,73,73,123,50,0,0 ;S
			  DB 127,127,8,8,127,127,0,0 ;H
			  DB 65,65,127,127,65,65,0,0 ;I
				  
		;characters of string &
		amp:db 60h,0f4h,9eh,0bah,6eh,0f4h,90h,00h ;&
				  
		;characters of string TANVI
		tanvi:DB 1,1,127,127,1,1,0,0 ;T
			  DB 124,126,19,19,126,124,0,0 ;A
			  DB 127,127,6,12,24,127,127,0 ;N
			  DB 31,63,96,96,63,31,0,0 ;V
			  DB 65,65,127,127,65,65,0,0 ;I
		
		;characters of string SHAH
		shah: DB 38,111,73,73,123,50,0,0 ;S
			  DB 127,127,8,8,127,127,0,0 ;H
			  DB 124,126,19,19,126,124,0,0 ;A
			  DB 127,127,8,8,127,127,0,0 ;A
		
		;characters of string SNAKE	
		snake:DB 38,111,73,73,123,50,0,0 ;S
			  DB 127,127,6,12,24,127,127,0 ;N
			  DB 124,126,19,19,126,124,0,0 ;A
			  DB 127,127,8,28,119,99,0,0 ;K
			  DB 127,127,73,73,65,65,0,0 ;E
		
org 079dh
	
		g_yantra_intro: ;for project intro
		
				push psw
				
				mov a,#31h ;set the coordinates from where 1st character of string is to be displayed
				lcall choose_coord
				mov dptr ,#gaming
				mov b,a ; first char location in b
				mov a,#6 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#38h ;set the coordinates from where 1st character of string is to be displayed
				lcall choose_coord
				mov dptr ,#yantra
				mov b,a ; first char location in b
				mov a,#6 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				;to give user some time to read the tex
				lcall delay1s
				lcall delay1s
				
				mov a,#54h ;set the coordinates from where 1st character of string is to be displayed
				lcall choose_coord
				mov dptr ,#g_yantra
				mov b,a ; first char location in b
				mov a,#8 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				;to give user some time to read the tex
				lcall delay1s
				lcall delay1s
				
				pop psw
		
		ret ;for g_yantra_intro
	
				developers_intro:;to display developers intro 
		
				push psw
				
				mov a,#32h ;set the coordinates from where 1st character of string is to be displayed
				lcall choose_coord
				mov dptr ,#developed
				mov b,a ; first char location in b
				mov a,#9 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#3ch
				lcall choose_coord
				mov dptr ,#by
				mov b,a ; first char location in b
				mov a,#2 ;total characters in a
				lcall display_string ;location of string first element in dptr


				;delay is added to give user time to read the string
				lcall delay1s
				
				
				lcall clrscreen
				
				mov a,#13h
				lcall choose_coord
				mov dptr ,#tanvi
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#19h
				lcall choose_coord
				mov dptr ,#shah
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				
				
				mov a,#37h
				lcall choose_coord
				mov dptr,#amp
				lcall display_char
				
				
				mov a,#53h
				lcall choose_coord
				mov dptr ,#rudra
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#59h
				lcall choose_coord
				mov dptr ,#joshi
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				lcall delay1s
				lcall delay1s
				lcall delay1s
				
				pop psw
				
		ret ;for develeopers_intro
		
		
	
		gui: ; functions to provide a basic subroutine
				
				push psw
				
				setb psw.3
				setb psw.4
				
				lcall clrscreen
				
				clr 0ah ;clr bit 0ah for safety purposes
				
				mov a,#11h
				lcall choose_coord
				mov dptr ,#select
				mov b,a ; first char location in b
				mov a,#6 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#18h
				lcall choose_coord
				mov dptr ,#chA
				lcall display_char ;location of string first element in dptr
				
				mov a,#1Ah
				lcall choose_coord
				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#32h
				lcall choose_coord
				mov dptr ,#C1
				lcall display_char ;location of string first element in dptr
				
				display_snake_game:
				jb 0ah,choose_diff_coord_1
				mov a,#34h
				sjmp done1
				choose_diff_coord_1:
				mov a,#53h
				done1:
				lcall choose_coord
				mov dptr ,#snake
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				jb 0ah,choose_diff_coord_2
				mov a,#3ah
				sjmp done2
				choose_diff_coord_2:
				mov a,#59h
				done2:
				lcall choose_coord
				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				jb 0ah,in_range
				sjmp continue
				
				in_range:
				ajmp back2game_select
				
				continue:
				mov a,#52h
				lcall choose_coord
				mov dptr ,#C2
				lcall display_char ;location of string first element in dptr
				
				display_4_in_a_row:
				
				mov a,#54h
				lcall choose_coord
				mov dptr ,#C4
				lcall display_char ;location of string first element in dptr
				
				mov a,#56h
				lcall choose_coord
				mov dptr ,#in
				mov b,a ; first char location in b
				mov a,#2 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#59h
				lcall choose_coord
				mov dptr ,#chA
				lcall display_char ;location of string first element in dptr
				
				mov a,#5bh
				lcall choose_coord
				mov dptr ,#row
				mov b,a ; first char location in b
				mov a,#3 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				jb 0ah,back2game_select
				
				mov ie,#81h ;enable external interupt at this point to start accepting keyboard inputs
				
				mov r3,#30h
				clr c
				
				mov a,r3
				lcall choose_coord
				mov dptr,#cursor
				lcall display_char
				
				setb 09h ;set game selection bit
				
				wait_for_input: jb 08h,wait_for_input ;loop till a game is selected and selection but 08h is cleared
				 
				pop psw
		
		ret ;for gui

		game_select: ;to start a given game 
		
					push psw
					
					setb psw.3
					setb psw.4
						
					lcall clrscreen
					
					mov a,#12h
					lcall choose_coord
					mov dptr ,#press
					mov b,a ; first char location in b
					mov a,#5 ;total characters in a
					lcall display_string ;location of string first element in dptr
					
					mov a,#18h
					lcall choose_coord
					mov dptr ,#start
					mov b,a ; first char location in b
					mov a,#5 ;total characters in a
					lcall display_string ;location of string first element in dptr
						
					mov a,#34h
					lcall choose_coord
					mov dptr ,#to
					mov b,a ; first char location in b
					mov a,#2 ;total characters in a
					lcall display_string ;location of string first element in dptr
					
					mov a,#37h
					lcall choose_coord
					mov dptr ,#play
					mov b,a ; first char location in b
					mov a,#4 ;total characters in a
					lcall display_string ;location of string first element in dptr
					
					setb 0ah ;set bit loaction ah for string display
					
					jb 09h,snake_selected ;if bit 09h is set the snake game was selected else other game was selected
					
					ajmp display_4_in_a_row ;display 4 in a row from previously written commands and hence save space
					
					back2game_select:
					
					sjmp wait_for_start
					
					snake_selected:
					
					ljmp display_snake_game
					
					wait_for_start: jnb 0bh,wait_for_start ;keep on looping here till start button is pressed
					
					clr 0bh ;clear start button once its use case is over
					
					lcall clrscreen
					
					jnb 09h,four_in_a_row_selected ;if 09h bit location is zero then
					
					ljmp snake_game
					
					
					four_in_a_row_selected:
					
					ljmp four_4_in_a_row;other game calling statements lies here
				
		
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
					
					mov r1,#14h ;set initial head coordinates
					mov @r0,#13h ;set initial body coordinates
					mov r2,#13h	;set initial tail coordinates 
					
					mov r3,#00h ;initially start moving towards left
					mov r4,#02h ;length at start contains only one middle section this is required to match with the later subroutines for increasing length
					mov r5,#35h ; set the initial food position  
					
					mov 19h,@r0 ;19h (r1 of reg-bank-3) for old body coord
					mov b,r2 ;b for old tail 
					
					mov a,r1
					mov r6,a ; r6 for old head
					mov 18h,r1 ;18h (r0 of reg-bank-3) for head
					
					mov 1dh,#00 ;seting the score register to zero immdiate value at start of game
					
					mov a,r5 ; load a with initial food coordinates
					lcall choose_coord ;these instructions are concerned with displaying food at location present in r5
					mov dptr,#food
					lcall display_char
					
					sg_loop:
					
					mov ie,#00h
					lcall calc_pos
					lcall update_pos
					lcall update_lcd
					mov ie,#81h
					lcall delay1s
					
					sjmp sg_loop	
		
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
				subb a,#10h ;dec upper niblle i.e. y--
				mov r1,a
				sjmp ext
					
				nxt_03:
				
				cjne a,#03h,ext
				mov a,r1
				add a,#10h ;inc upper nibble i.e. y++
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
			
		ret ;for update_body_position

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
			
		ret ;for update_tail_position
		
		food_pos:;r5 of reg bank 2 and r6 of reg bank 2 , need to chage r6
	
	
				setb psw.4
				clr psw.3
				push 16h
				
				mov dptr,#start_food_pos ;in dptr the starting value where all random food coordinates are stored...for now total 20 coordinates are there
				mov r5,tl0 ;random value in r5
				mov a,r5 ;random value in a
				anl a,#19 ;limit the random value in  0 to 19(total 20 coordinates saved) bcz it is basically the count which we will add to dptr to point to some random coordinate
				mov r6,a ;r6 will remember the count i.e form '#start' which position in lookup we are pointing that count

				movc a,@a+dptr ;mov the coord corresponding to pointed vaule in a...so now a has random food position but randomness is controlled
				mov r5,a ;mov the food coordinate into r5
				
				check_overlap: 
				
					mov 20h,r1 ;due to syntax limitaion of cjne we are using 20h to store specific value (head,tail or other body element) at a time so that it can be compared with the newly generated conrolled random food coordinate which is till now stored in r5 and a
					
					cjne a,20h,ch_ot ;compare food coord with head coord
					
					sjmp nxt_coord ;if equal we have to change coord so jmp to nxt_coord
								
				ch_ot:mov 20h,b ;mov old tail coord in 20h
					  cjne a,20h,ch_t ;if not equal we will compare tail and food coordinate
					  sjmp nxt_coord
								
								
				ch_t:mov 20h,r2 ;mov tail coord in 20h
					 cjne a,20h,ch_b ;if not equal we will compare tail and food coordinate
					 sjmp nxt_coord ;if equal jmp to nxt coord else go for body comparision
								
				ch_b: mov 20h,@r0 ;first mov 1st body elemnt coord that is stored in 30h (r0 points 30h) in 20h
					  cjne r4,#01h,ch_b_len_nt1 ;if length is one then we only have to check whether food overlaps with one body element but if it is > 1 the we'll have to check for (r4) body elemnts...(r4)=length of body elements
					  cjne a,20h,finally_done ;check for 1 elemnt as r4=1 and if no overlapping then done otherwise nxt_coord
					  sjmp nxt_coord				
							
				ch_b_len_nt1: push 10h ;first push r0=10h bcz due to limitaion of reg we will use r0 to point diff elements
							  push 14h ;r4=14h ,reg bank 2
							
				do_again: cjne a,20h,nxt_element ;a=food coord and 20h = coord in 30h for first iteration...compare and decide accordingly
						  sjmp nxt_coord
									
				nxt_element: inc r0	; element in 30h is compared the in r0 so now it point to 31h
							 mov 20h,@r0 ;mov value stored in 31h in 20h
							 djnz r4,do_again ;repeat for r4 times i.e if body length is 2 then r4=2 and this will repeat for 30h and 31h 
								
							 pop 14h ;pop r4
							 pop 10h ; pop r0
								
							 sjmp finally_done ;if till here it has not jumped to nxt_coord this means there is no overlapping so we are good to go
				
	
				nxt_coord: cjne r6,#19,barabar ;r6 has count of which random position out stored 10 we are using...if count is 10 then it means that it will be pointion to last element of pur lookup array so we will re initialize ut by making r6 0
					       mov r6,#00h ;re initialize r6
					       sjmp check_again		
						
				barabar: inc r6	; if r6<19 then no issue we can simply in it and then get respective value
					     mov a,r6 ;mov count in a...so say if r6 was 3h so after incr it is 4h and so now a has 4 stored
						
				check_again: movc a,@a+dptr	;thus from the stored values choose 4th one
							 sjmp check_overlap ;as it entered nxt_coord it meant there was overlaping somewhere so after giving new coordinates again check if still overlapping exists 
			 
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
				mov dptr,#boundary_collision_values
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
					
					game_over_call:ljmp game_over ;however if a=0 then up key pressed for a head moving down and hence we call game-over
				
			exit_self_collision:
			
		ret ;for self_collision

				calc_score: ;this subroutine calculates the score and diplays the 2-digit code form 0-99 in decimal number system
					;so yes this code can show you correct scores only for values form 0-99 in decimal
					;also the logic used to display a given binary number/stored as hex number to its equivalent BCD is shown in Book By MKP Sir Ch-9 Ex-9.1 
					;One Can Refer that for that logic understanting
			
				mov a, 18h;move cuurent score value in reg-a
				
				mov b,#10 ;move 10d in reg-b
				
				div ab ;quotient is stored in a (10's place digit) & remainder is stored in b (1's Digit Number)
				
				clr 00h ;clr bit location for iterating for both the digits
				
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
					
					;push acc ;push the digit value of 10's or 1's place on stack
					
					jb 00h,almost_there ;check if carry is set or not if not then load 10's digit number on GLCD else jmp to label
					
					
					mov a,#3ah
					lcall choose_coord
					;pop acc
					lcall display_char
					sjmp next_digit ;after displaying 10's digit at appropraite place in glcd make decsions for 1's digit
					
					almost_there:
					
					mov a,#3bh ;since carry was set now display 1's digit number on glcd and then return from subroutine
					lcall choose_coord
					;pop acc
					;mov a,1dh
					;mov b,#10 ;move 10d in reg-b
					;div ab ;quotient is stored in a (10's place digit) & remainder is stored in b (1's Digit Number)
					;mov a,b ;put the 1's digit in a
					lcall display_char
					sjmp exit_calc_score
					
				next_digit:
				
				
				setb 00h
				mov a,b 
				sjmp now_1s_place ;iterate the procedure again for 1's digit number
			
			exit_calc_score:
			
		ret ;for calc score
		
		disp_score: ;this subroutine displays the score of user after a game-over
			
				mov a,#34h
				lcall choose_coord
				mov dptr ,#score
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				lcall calc_score ;calculate score as per value in score register and display the digits
				
		ret ;for display_score
				
		game_over: ;this subroutine is used to display gameover string along with score display at end
			
				lcall clrscreen
				mov a,1dh
				mov 18h,a
				mov a,#36h
				lcall choose_coord
				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#46h
				lcall choose_coord
				mov dptr ,#over
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				lcall delay1s
				lcall delay1s
				lcall delay1s
				lcall delay1s
				
				lcall clrscreen
				jnb 09h,ends
				lcall disp_score
				
				ends: sjmp ends
				
org 0d00h
	
	;_4_in_a_row game starts here
	
		;reg bank 2 used for game operations
		;r0 (10h)-> used as pointer to memory mapped loactions corresponding to GLCD Coordinates which is from 30h to 59h in RAM
		;r1 (11h)-> used as pointers to memory loaction of which column is filled by what amount which is from 21h to 27h
		;r2 (12h)-> col position info stored in this reg
		;r3 -> temporarily store the the value upto which a given selected column is filled
		;r4 -> contains the glcd coordinates where the coin is suppose to fell once the user presses select
		;r5 -> stores the memory mapped address value of any given GLCD coordinates
		;r6 -> stores the memory mapped address the currently filled element
		;r7 -> stores the count value for score related subroutines
		;bit 00h -> column where coin is to be placed is seletcted this bit is used to indicate that
		;bit 01h -> to determine a given players turn
		;bit 03h -> to determine if get_memory_mapped subroutines is in use
		
		;also for ram location 30h to 59h the data in these memory locations are mapped to corresponding grid element coordinates of glcd 
		;data present in them means the follwing thing
		;00h means the given grid element is void of any coin
		;01h means the given grid element is filled with coin of player-1
		;02h means the given grid element is filled with coin of player-2
		
		four_4_in_a_row:
		
		setb psw.4
		clr psw.3
		;starting functions called once to setup the starting of game screen
		lcall display_grid_4IR
		lcall display_other_4IR ;display score and player whose turn is there
		lcall clr_ram_4IR
		
		setb 01h ;bit set to mark that starting turn will be of player 1
		mov r0,#30h ;r0 points to the memory mapped locations for the GLCD Screen Which contains information about type of data in a given grid cell
		mov r1,#22h ;r1 points to the location which cointain the no. of filled cell of chosen col
		
		main_game_4IR:
		
		clr 00h ;is low until select is pressed till that player is deciding position where he/she has to fill coin
		
		wait_4IR:jnb 00h ,wait_4IR
		
		lcall coin_drop_4IR;once position is selected by given player select is pressed then first coin has to get in chosen coloumn
	  
		lcall update_cursor_4IR ; based on change that turn of next player display changes in screen
		
		lcall score_check_4IR
		
		sjmp main_game_4IR
		
		clr_ram_4IR: ;used to clear 42(D) ram loactions with 00h starting from 30h
		
		mov r7,#42 ;no. of ram locations to be cleared
		
		repeate_till_done_4IR:
		
		mov @r0,#00h ;initialize all the ram locations with 00h which means all grid elements are empty
		inc r0
		djnz r7,repeate_till_done_4IR
		
		mov r0,#30h ;make sure to re-initialize r0 to correct default value
		
		ret ;for clr_ram
	
		display_grid_4IR:
				
				mov r7,#7 ;no. of columns
				mov r6,#6 ;no. of rows
				
				mov r5,#27h ;coordinate location from where 1st element of grid starts
				
				nxt_4IR:
					
					mov a,r5 ;display grind character at location value present in r5
					lcall choose_coord
					mov dptr,#grid
					lcall display_char
					
					inc r5	
					
					djnz r7,nxt_4IR ;this is repeated  7-times i.e. till a row is completed 
					
					mov a,r5 ;the following subtraction is done because while the loop rotates 7-times an extra increment takes
					clr c	;place when the condition turns out to be false and hence to match things properly we subtract 1 from value of r5 reg
					subb a,#1
					
					add a,#10h ;this is done to transverse to next row 
					anl a,#0f0h
					add a,#07h
					mov r5,a
					
					mov r7,#7 ;reinitialize r7 to cover for the new row
					
					djnz r6,nxt_4IR ;repeat the process till entire grid is drawn on screen
					
					mov a,#17h ;this is to place the coin of initial player as cursor
					mov r2,a
					lcall choose_coord
					mov dptr,#c_p1
					lcall display_char
					
		ret; return for display grid
	
		display_other_4IR: ;used to display other useful info at start of the game
			
			mov a,#10h ;set the coordinates from where 1st character of string is to be displayed
			lcall choose_coord
			mov dptr ,#player
			mov b,a ; first char location in b
			mov a,#6 ;total characters in a
			lcall display_string ;location of string first element in dptr
			
			mov a,#30h  ;this cursor position will change after each turn
			lcall choose_coord
			mov dptr ,#cursor				
			lcall display_char ;
		
			mov a,#32h ;
			lcall choose_coord
			mov dptr ,#c_p1				
			lcall display_char ;
			
			mov a,#52h ;
			lcall choose_coord
			mov dptr ,#c_p2				
			lcall display_char ;
			
		ret; return for display_other
	
		coin_drop_4IR: ;deals with where to place the coin after select button is pressed  		
						
				mov a,r2 ;used to clear coin from current cursor location 
				lcall choose_coord
				mov dptr,#clear ;now p2 turn has started thus his/her coin as cursor 
				lcall display_char
			
				lcall fill_cell_4IR
				
				jb 01h,pl2_2 ; jump if 01h is set , if its set then p1 has selected the position and coin has to go in that so grid coin of p1 but cursor coin of p2 as now p2 turn is there				
				;seeing the logic it may be hard to digest it is because the 01h bit is complemented in keyboard isr as soon as select is pressed and because of that we follow an invereted logic here
				
				lcall choose_coord
				mov dptr,#coin1 ;grid coin of p1...as bit is clr means its turn is just over
				lcall display_char
				lcall update_ram_4IR
				
				mov a,r2 
				lcall choose_coord 
				mov dptr,#c_p2 ;now p2 turn has started thus his/her coin as cursor 
				lcall display_char
				sjmp exit_coin_drop_4IR
						
		
				pl2_2:
				lcall choose_coord
				mov dptr,#coin2
				lcall display_char
				lcall update_ram_4IR
				
				mov a,r2
				lcall choose_coord
				mov dptr,#c_p1 ;now p1 turn has started thus his/her coin as cursor 
				lcall display_char
				
				
		exit_coin_drop_4IR:
		ret;return for coin_drop
	
		fill_cell_4IR:;r1 points to 21h, 21h to 27h contains the value till which given column is filled
		
			mov a,r2; lower nibble of r2 contains the col which is selected , 
			anl a,#0fh ; col which is selected is now in a
			add a,r1 ; reg-a points to the location which contains the information that how much cells are filled in chosen col
			; say r2=18h => a=08h then a=>29h
			
			clr c ;now this is done because the grid starts from 7th column till dth column for each row
			subb a,#07h ;while r1 is to point form 21 to 28h only so to avoid the indexing issue
			mov r1,a ;we subtract 7 from the masked column value so that correct ram loaction corresponding to selected column can be choosen
			mov a,@r1 ;content of 38h in a ; say it is zero so last row will be filled
			mov r3,a ;temp reg to store the content of 38h
			
			;below 3 lines are logic to change the memory content 
			inc a ; inc the content in 38h
			mov @r1,a ; save it in 38h
			mov r1,#22h ; r1 again points to first location
			
			;below is to set the cell positon which is to be filled in reg-a
			mov a,#07h ; last row i.e row sixth is in page 7 so set that in accumulator
			clr c
			subb a,r3 ;r3 has content of how much the chosen col is filled upto , subtracting that from the last row so say two coins were filled in given col then the nxt coin has to be in 6-2=4th row that is 7-2=5th page  
			swap a ; as our upper nibble is for page(row) and lower for col so swapping is done , this which cell has to be filled its page or row location is set 
			mov r3,a ; again temporarily store that in r3
			mov a,r2 ; lower nibble of r2 contains selected col
			anl a,#0fh ; so now col information is in accumulator's lower nibble and upper is masked off 
			add a,r3 ; now accumulator contains which cell has to be filled i.e exact coordinates of the location to be filled
			
			mov r4,a ;to be used later in ram updating subroutines
			
	ret; for fill_cell
	
	update_ram_4IR: ;used to update ram memory locations correspoding to the grid filled by a given player
	
			mov a,r4 ;restore the currently filled cell location in reg-a
			
			get_mm:
			
			anl a,#0f0h ;mask the upper nibble to get row of the filled coin
			swap a
			
			cjne a,#2,check_for_row3 ;since row is 2 no need to update r0 to desired value
			
			mov r0,#30h ;this done to properly map given ram memory locations to grid coordinates
			
			sjmp done_selecting
			
			check_for_row3:
			
			cjne a,#3,check_for_row4 
			mov r0,#37h
			
			sjmp done_selecting
			
			check_for_row4:
			
			cjne a,#4,check_for_row5
			mov r0,#3eh
			mov a,r4
			
			sjmp done_selecting
			
			check_for_row5:
			
			cjne a,#5,check_for_row6 
			mov r0,#45h
			
			sjmp done_selecting
			
			check_for_row6:
			
			cjne a,#6,check_for_row7 
			mov r0,#4ch
			
			sjmp done_selecting
			
			check_for_row7:
			
			cjne a,#7,exit_update_ram 
			mov r0,#53h
			
			done_selecting:
			
			mov a,r4
			anl a,#0fh ;now we extract the column information
			clr c
			subb a,#07h ;since each element of a given row starts from 7th column of glcd
			add a,r0
			mov r0,a
			mov r6,a ;stores the memory mapped address the currently filled element
			
			jb 03h,exit_getmm
			
			jb 01h,updt_p2 ;to take apt decision as to what value is to be filled
			
			mov @r0,#01h ;player-1's coin is filled at corresponding memory location
			
			sjmp exit_update_ram
			
			updt_p2:
			
			mov @r0,#02h
			
		exit_update_ram:
		
		mov r0,#30h
	
	ret ;for update_ram
	
	get_memory_mapped:
		
		setb 03h ;set 03h bit high until this fuction is being executed
		
		sjmp get_mm
		
		exit_getmm:
		
		clr 03h ;clr the bit value once the job is over 
		
		mov r5,a ;store the memory mapped address value of any given GLCD coordinates 
	
	ret ;get memory mapped
			
	score_check_4IR:
	
		lcall check_vertical ;check for vertical game over possiblity with currently filled element
		lcall check_horizontal ;check for horizontal game over possiblity with currently filled element 
	
	ret ;for score_check
	
	check_vertical: ;check the winning possiblity vertically
	
		mov a,r4; lower nibble of r2 contains the col which is selected , 
		anl a,#0f0h ; col which is selected is now in a
		swap a
		mov r7,a ;store the number temporarily in r7
		
		clr c
		subb a,#04h ;subtract from 4 because a minimum of four values are required to be filled to start vertical checking
		
		jc continue_vertical ; if after subtracttion carry is not set means the total rows filled are either greater than or equal to 4
		mov a,r7 ;if the above condition is false then we are still required to check fill the newly added element belongs to 4th row or not
		cjne a,#04h,exit_vertical_algorithm ;if reg-a is 4 then we continue to implement our algorithm else we'll exit saving processing time
		
		continue_vertical:
		
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1bh,a ;move the type of data corresponding to coordinates in 1bh (i.e. R3 of RB-3)
		
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		add a,#10h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a
		mov a,@r0
		mov 1ch,a ;move the type of data corresponding to coordinates in 1ch (i.e. R4 of RB-3)
		
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		add a,#20h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a
		mov a,@r0
		mov 1dh,a ;move the type of data corresponding to coordinates in 1ch (i.e. R5 of RB-3)
		
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		add a,#30h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a
		mov a,@r0
		mov 1eh,a ;move the type of data corresponding to coordinates in 1ch (i.e. R5 of RB-3)
		
		mov a,1bh ;now copy the contents of 1bh in reg-a for comparision purposes
		
		cjne a,1ch,exit_vertical_algorithm ;compare reg-a with elements below it if their data type are same
		cjne a,1dh,exit_vertical_algorithm ;coninue to check for 3-values 
		cjne a,1eh,exit_vertical_algorithm ;else exit at first different value
		ljmp game_over
		exit_vertical_algorithm:
		
		mov r0,#30h ;reinitialize r0 with default value for which it was to be used as pointer for other routines 
		
	ret ;for check_vertical
	
	cmp:
	mov a,1bh ;now copy the contents of 1bh in reg-a for comparision purposes
		
		cjne a,1ch,exit_cmp ;compare reg-a with elements below it if their data type are same
		cjne a,1dh,exit_cmp ;coninue to check for 3-values 
		cjne a,1eh,exit_cmp ;else exit at first different value
		ljmp game_over
		here:sjmp here
		exit_cmp:
	ret; cmp
	
	check_horizontal: ;check the winning possiblity horizontally
		mov a,r4; lower nibble of r4 contains the col which is selected , 
		anl a,#0fh ; col which is selected is now in acc
		
		;check which col is selected and accordingly take decision 
		;c1 => check for 3 right col
		;c2 => check for 3 left col
		;c3 => check for 2 right cols and 1 Left
		;c4 => check for 1 right col and 2 left
		
		cjne a,#07h,ch8_4IR ;07 means 1st col is selected so only 3 right check possibility is there
		lcall c1_4IR
		sjmp exit_horizontal_algorithm		
		ch8_4IR:cjne a,#08h,ch9_4IR
		lcall c1_4IR
		lcall c3_4IR
		sjmp exit_horizontal_algorithm
		ch9_4IR:cjne a,#09h,cha_4IR
		lcall c1_4IR
		lcall c3_4IR
		lcall c4_4IR
		sjmp exit_horizontal_algorithm
		cha_4IR:cjne a,#0ah,chb_4IR
		lcall c1_4IR
		lcall c2_4IR
		lcall c3_4IR
		lcall c4_4IR
		sjmp exit_horizontal_algorithm
		chb_4IR:cjne a,#0bh,chc_4IR
		lcall c2_4IR
		lcall c3_4IR
		lcall c4_4IR
		sjmp exit_horizontal_algorithm
		chc_4IR:cjne a,#0ch,chd_4IR
		lcall c2_4IR
		lcall c4_4IR
		sjmp exit_horizontal_algorithm
		chd_4IR:cjne a,#07h,ch8_4IR
		lcall c2_4IR
	
		exit_horizontal_algorithm:
		
		
		mov r0,#30h ;reinitialize r0 with default value for which it was to be used as pointer for other routines 
		
	ret ;for check_vertical
	
	
	c1_4IR: ;3 Right
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1bh,a ; just filled cell's content (01/02) stored in 1bh
		
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		add a,#01h ;mem add of nxt col of same row
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1ch,a ; nxt col filled cell's content (01/02/00) stored in 1ch
		
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		add a,#02h ; inc to two cols
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1dh,a ; nxt to nxt col filled cell's content (01/02/00) stored in 1dh
		
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		add a,#03h
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1eh,a ; nxt to nxt to next col filled cell's content (01/02/00) stored in 1eh
		
		lcall cmp
		
	ret; c1
	
	
	c2_4IR: ;3 Left
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1bh,a ;recently filled cell's content (01/02) stored in 1bh
		
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		clr c
		subb a,#01h ; prev col meme mapped location in acc
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1ch,a; prev col filled cell's content (01/02/00) stored in 1ch
		
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		clr c
		subb a,#02h
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1dh,a ;prev to prev col filled cell's content (01/02/00) stored in 1dh
		
		mov a,r4
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		clr c
		subb a,#03h
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1eh,a ; prev to prev to prev col filled cell's content (01/02/00) stored in 1dh
		
		lcall cmp
		
	ret;c2
	
	c3_4IR: ;2Right 1Left
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1bh,a ;move the type of data corresponding to coordinates in 1bh (i.e. R3 of RB-3)
		
		;1L
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		clr c
		subb a,#01h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		mov r0,a
		mov a,@r0
		mov 1ch,a ;move the type of data corresponding to coordinates in 1ch (i.e. R4 of RB-3)
		
		;2R
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		add a,#01h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		mov r0,a
		mov a,@r0
		mov 1dh,a ;move the type of data corresponding to coordinates in 1ch (i.e. R5 of RB-3)
		
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		add a,#02h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		mov r0,a
		mov a,@r0
		mov 1eh,a ;move the type of data corresponding to coordinates in 1ch (i.e. R5 of RB-3)
		lcall cmp
	ret;c2
	
	c4_4IR: ;2Left 1Right
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		mov r0,a ;copy the correpsonding memory mapped value in ro
		mov a,@r0 ;now using r0 as pointer fetch the data stored in mapped memory adderss
		mov 1bh,a ;move the type of data corresponding to coordinates in 1bh (i.e. R3 of RB-3)
		
		;2L
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		clr c
		subb a,#01h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		
		mov r0,a
		mov a,@r0
		mov 1ch,a ;move the type of data corresponding to coordinates in 1ch (i.e. R4 of RB-3)
		
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		clr c
		subb a,#02h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		
		mov r0,a
		mov a,@r0
		mov 1dh,a ;move the type of data corresponding to coordinates in 1ch (i.e. R5 of RB-3)
		
		;1R
		mov a,r4 ;move the coordinates of recently filled GLCD Coordinates in reg-a
		lcall get_memory_mapped
		
		mov a,r5 ;move the type of data corresponding to coordinates in reg-a
		add a,#01h ;since for every vertical check we have to go down a element to check and to go down by 1-Row We Increase by 10h;  
		
		mov r0,a
		mov a,@r0
		mov 1eh,a ;move the type of data corresponding to coordinates in 1ch (i.e. R5 of RB-3)
		lcall cmp
	ret;c4
	

			
	update_cursor_4IR:


			jnb 01h ,pl2_sel
			
			;if 01h bit is high the new turn is of player-1 and we set the curosor accordingly and if not the new turn will be player-2
			;and again curosor there will be set accordingly
			mov a,#50h
			lcall choose_coord
			mov dptr ,#clear			
			lcall display_char

			mov a,#30h
			lcall choose_coord
			mov dptr ,#cursor			
			lcall display_char
			
			sjmp exit_update_screen
			
			pl2_sel:
			mov a,#30h
			lcall choose_coord
			mov dptr ,#clear			
			lcall display_char

			mov a,#50h
			lcall choose_coord
			mov dptr ,#cursor			
			lcall display_char
		
		exit_update_screen:
	ret;return for update_cursor
	
	
end
