org 0000h
	ljmp main

org 002bh
		main:
		clr p2.7
		mov p0,#0ffh ;set p0 as input port
		
		setb p2.3 ;set rest pin to 1 i.e. inactive mode
		
		mov sp,#60h ;move sp to ram loaction 60h
		
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
		
		/*mov a,#35h
				lcall choose_coord
				mov dptr,#cursor
				lcall display_char
				//lcall delay1s
				mov a,#36h
				lcall choose_coord
				mov dptr,#cursor
				lcall display_char
				lcall delay1s
				mov a,#35h
				lcall choose_coord
				mov dptr,#clear
				lcall display_char*/
		lcall screen1
		lcall screen2
	    lcall gui
		lcall game_start
		stay:sjmp stay


org 0003h
	setb p2.7
	ljmp main_isr

org 250h
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
		//clr p2.7
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



		

				
					 

org 0f00h
	screen1: push psw	
	setb psw.3
	     setb psw.4
		 mov a,#02h
		 lcall choose_coord
		mov dptr ,#wel
		mov b,a ; first char location in b
		mov a,#7 ;total characters in a
		lcall display_string ;location of string first element in dptr
        
		mov a,#00h
		add a,b
		inc a
		inc a
		lcall choose_coord

		mov dptr ,#to
		mov b,a ; first char location in b
		mov a,#2 ;total characters in a
		lcall display_string ;location of string first element in dptr
		
		mov a,#21h
		lcall choose_coord
	

		mov dptr ,#the
		mov b,a ; first char location in b
		mov a,#3 ;total characters in a
		lcall display_string ;location of string first element in dptr
		
		mov a,00h
		add a,b
		inc a
		inc a
		lcall choose_coord
		
		mov dptr ,#world
		mov b,a ; first char location in b
		mov a,#5 ;total characters in a
		lcall display_string ;location of string first element in dptr
		
		mov a,00h
		add a,b
		inc a
		inc a
		lcall choose_coord
		
		mov dptr ,#of
		mov b,a ; first char location in b
		mov a,#2 ;total characters in a
		lcall display_string ;location of string first element in dptr
		
		mov a,#42h
		lcall choose_coord
		mov dptr ,#gaming
		mov b,a ; first char location in b
		mov a,#6 ;total characters in a
		lcall display_string ;location of string first element in dptr
		
		mov a,#00h
		add a,b
		inc a
		inc a
		lcall choose_coord

		mov dptr ,#with
		mov b,a ; first char location in b
		mov a,#4 ;total characters in a
		lcall display_string ;location of string first element in dptr
		
		mov a,#74h
		lcall choose_coord
		mov dptr ,#g_yantra
		mov b,a ; first char location in b
		mov a,#8 ;total characters in a
		lcall display_string ;location of string first element in dptr
		
		 lcall delay1s
		 lcall delay1s
		 lcall delay1s
		lcall delay1s
		
		
		pop psw
		ret
		screen2:push psw
				lcall clrscreen
				mov a,#02h
				lcall choose_coord
				mov dptr ,#created
				mov b,a ; first char location in b
				mov a,#7 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#00h
				add a,b
				inc a
				inc a
				lcall choose_coord
				
				mov dptr ,#by
				mov b,a ; first char location in b
				mov a,#3 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#32h
				lcall choose_coord
				mov dptr ,#rudra
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				mov a,#00h
				add a,b
				inc a
				inc a
				lcall choose_coord
				
				mov dptr ,#joshi
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#57h
				lcall choose_coord
				mov dptr,#amp
				lcall display_char
				
				mov a,#72h
				lcall choose_coord
				mov dptr ,#tanvi
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				mov a,#00h
				add a,b
				inc a
				inc a
				lcall choose_coord

				mov dptr ,#shah
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				lcall delay1s
				lcall delay1s
				lcall delay1s
				lcall delay1s
				pop psw
				ret
	
		gui: ; r3 of rb3
		push psw
		 setb psw.3
		 setb psw.4
				lcall clrscreen
				mov a,#02h
				lcall choose_coord
				mov dptr ,#choose
				mov b,a ; first char location in b
				mov a,#6 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#00h
				add a,b
				inc a
				inc a
				lcall choose_coord

				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#30h
				lcall choose_coord
				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#50h
				lcall choose_coord
				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov ie,#81h
				mov r3,#35h
				clr c
				be:
				mov a,r3
				lcall choose_coord
				mov dptr,#cursor
				lcall display_char
				
				
				mov a,r3
				lcall choose_coord
				mov dptr,#clear
				lcall display_char
				jb 20h, end_gui
				sjmp be
				
				end_gui: 
				pop psw
				ret
		
		
		
		nxt_dptr: ;r4 of rb3
		mov r4,#8
		incr:inc dptr
		djnz r4,incr
		ret
		
		 
		 display_string: ;pass dptr value, total characters and first character location
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
		ret

game_start: push psw
			setb psw.3
		 setb psw.4
				lcall clrscreen
				mov a,1bh
				cjne a,#35h,nxt_game
				mov a,#26h
				lcall choose_coord
				mov dptr ,#the
				mov b,a ; first char location in b
				mov a,#3 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#45h
				lcall choose_coord

				mov dptr ,#snake
				mov b,a ; first char location in b
				mov a,#5 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
				mov a,#66h
				lcall choose_coord
				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string 
				sjmp end_game_gui
				nxt_game:
				mov a,#45h
				lcall choose_coord
				mov dptr ,#game
				mov b,a ; first char location in b
				mov a,#4 ;total characters in a
				lcall display_string 
				
				mov a,#4ah
				mov dptr,#C2
				lcall display_char
				
				end_game_gui:
				pop psw
				//ljmp stay
				ret
		
org 300h;lookup tables	for char ; black=1 ;upper nibble =lower 4 bits of 8 bits of col
	
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
			
		wel:DB 127,127,48,24,48,127,127,0
			DB 127,127,73,73,65,65,0,0
			DB 127,127,64,64,64,64,0,0
			DB 62,127,65,65,65,65,0,0
			DB 62,127,65,65,127,62,0,0
			DB 127,127,6,12,6,127,127,0
			DB 127,127,73,73,65,65,0,0
		to:	DB 1,1,127,127,1,1,0,0
			DB 62,127,65,65,127,62,0,0
		the:DB 1,1,127,127,1,1,0,0
			DB 127,127,8,8,127,127,0,0
			DB 127,127,73,73,65,65,0,0
		world:DB 127,127,48,24,48,127,127,0
			  DB 62,127,65,65,127,62,0,0
			  DB 127,127,9,25,127,102,0,0
			  DB 127,127,64,64,64,64,0,0
			  DB 127,127,65,65,127,62,0,0
		of: DB 62,127,65,65,127,62,0,0
			DB 127,127,9,9,1,1,0,0
		gaming: DB 62,127,65,81,81,113,0,0
				DB 124,126,19,19,126,124,0,0
				DB 127,127,6,12,6,127,127,0
				DB 65,65,127,127,65,65,0,0
				DB 127,127,6,12,24,127,127,0
				DB 62,127,65,81,81,113,0,0
		with:	DB 127,127,48,24,48,127,127,0
				DB 65,65,127,127,65,65,0,0
				DB 1,1,127,127,1,1,0,0
				DB 127,127,8,8,127,127,0,0
		g_yantra:DB 62,127,65,81,81,113,0,0
				 DB 00h,00h,18h,18h,18h,18h,00h,00h
				 DB 7,15,120,120,15,7,0,0
				 DB 124,126,19,19,126,124,0,0
				 DB 127,127,6,12,24,127,127,0
				 DB 1,1,127,127,1,1,0,0
				 DB 127,127,9,25,127,102,0,0
				 DB 124,126,19,19,126,124,0,0
		choose: DB 62,127,65,65,65,65,0,0
				DB 127,127,8,8,127,127,0,0
				DB 62,127,65,65,127,62,0,0
				DB 62,127,65,65,127,62,0,0
				DB 38,111,73,73,123,50,0,0
				DB 127,127,73,73,65,65,0,0
		game: DB 62,127,65,81,81,113,0,0
				DB 124,126,19,19,126,124,0,0
			  DB 127,127,6,12,6,127,127,0
				DB 127,127,73,73,65,65,0,0
					
		created:DB 62,127,65,65,65,65,0,0
			    DB 127,127,9,25,127,102,0,0
				DB 127,127,73,73,65,65,0,0
				DB 124,126,19,19,126,124,0,0
				DB 1,1,127,127,1,1,0,0
				DB 127,127,73,73,65,65,0,0
				DB 127,127,65,65,127,62,0,0
				
				
			by:DB 127,127,73,73,127,54,0,0
				DB 7,15,120,120,15,7,0,0
				DB 00h,00h,18h,18h,18h,18h,00h,00h
		rudra:DB 127,127,9,25,127,102,0,0
			  DB 63,127,64,64,127,63,0,0
			  DB 127,127,65,65,127,62,0,0
			  DB 127,127,9,25,127,102,0,0
			  DB 124,126,19,19,126,124,0,0
			  
		joshi:DB 48,112,64,64,127,63,0,0
			  DB 62,127,65,65,127,62,0,0
			  DB 38,111,73,73,123,50,0,0
			  DB 127,127,8,8,127,127,0,0
			  DB 65,65,127,127,65,65,0,0  
		tanvi:DB 1,1,127,127,1,1,0,0
			  DB 124,126,19,19,126,124,0,0
			  DB 127,127,6,12,24,127,127,0
			  DB 31,63,96,96,63,31,0,0
			  DB 65,65,127,127,65,65,0,0
				  
		shah: DB 38,111,73,73,123,50,0,0
			  DB 127,127,8,8,127,127,0,0
			  DB 124,126,19,19,126,124,0,0
			  DB 127,127,8,8,127,127,0,0
				  
		snake:DB 38,111,73,73,123,50,0,0
			  DB 127,127,6,12,24,127,127,0
			  DB 124,126,19,19,126,124,0,0
			  DB 127,127,8,28,119,99,0,0
			  DB 127,127,73,73,65,65,0,0
		
		