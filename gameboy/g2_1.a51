
org 0000h
	
	sjmp main
	
org 0003h
	
	ljmp key_board_isr
org 000bh
		
		main: ;main logic inception starts here 
		
		mov p0,#0ffh ;set p0 as input port
		
		setb p2.3 ;set rest pin to 1 i.e. inactive mode
		
		mov sp,#40h ;move sp to ram loaction 60h
		
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
		lcall _4_in_a_row
		clr p2.7
		stay: sjmp stay	

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
				
				cjne a,#00h,ch_01 ;if key 1 is pressed means move the coin
				;this logic is for game2
				;for same key game1 has different logic
				;1 bit adress can be used to determine which game is going on...will do it when I'll integrate both games
					
					mov a,10h ;clear old coin position;coin pos saved in reg r0 of rb2
					lcall choose_coord
					mov dptr,#clear
					lcall display_char
				
                ;below 4 lines are to make sure that the coin is still in range...our range is 17h to 1dh so if it is at 1dh so next position will be 17h				
					mov a,10h
					cjne a,#1dh,goto_nxt ;if it is at 1dh location i.e. last positoin then
					mov 10h,#16h ;set it to first position again but 1 less than it bcz in next instruction it will be incremented
					goto_nxt:inc 10h
					
					sjmp repeat
					
					
				ch_01:cjne a,#01h,sel_button_pressed ;if key 2 is pressed means move the coin
				;this logic is for game2
				;for same key game1 has different logic
				;1 bit adress can be used to determine which game is going on...will do it when I'll integrate both games
					
					mov a,10h ;clear old coin position;coin pos saved in reg r0 of rb2
					lcall choose_coord
					mov dptr,#clear
					lcall display_char
				
                ;below 4 lines are to make sure that the coin is still in range...our range is 17h to 1dh so if it is at 1dh so next position will be 17h				
					mov a,10h
					cjne a,#17h,goto_nxt1 ;if it is at 1dh location i.e. last positoin then
					mov 10h,#1eh ;set it to first position again but 1 less than it bcz in next instruction it will be incremented
					goto_nxt1:dec 10h
					
					
					repeat:
					mov a,10h
					lcall choose_coord
					jnb 01h,pl2 		;if 01h is set means pl1's turn is going on , else pl2 turn so display the cursor coin accordingly			
					mov dptr,#c_pl1
					lcall display_char
					sjmp returnback
					pl2:
					mov dptr,#c_pl2
					lcall display_char
					
					sjmp returnback
				
				
			
			sel_button_pressed: ;check if select button is pressed 
			    cjne a,#07h,returnback
							
				setb 00h; to mark that position is selected 00h bit is set
				cpl 01h ; to mark that now turn of next player so 01h is toggled
			
		returnback: 
				
				pop acc
				pop psw			
				
		reti	 ;for key-board isr
	



	
org 064h ;here lies the codes for GLCD Operations
	
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



		
org 400h;lookup tables for char ; black=1 ;upper nibble =lower 4 bits of 8 bits of col
	
		amp:  db 60h,0f4h,9eh,0bah,6eh,0f4h,90h,00h
		clear:  db 00h,00h,00h,00h,00h,00h,00h,00h
		
		grid: db 0ffh,0c3h,81h,81h,81h,81h,0c3h,0ffh;
		coin1: db 0ffh,0ffh,0e7h,0dbh,0dbh,0e7h,0ffh,0ffh;
		coin2: db 0ffh,0ffh,0e7h,0c3h,0c3h,0e7h,0ffh,0ffh;
		c_pl1: db 00h,3ch,42h,5ah,5ah,42h,3ch,00h; player 1 coin
		c_pl2: db 00h,3ch,42h,42h,42h,42h,3ch,00h; player 2 coin
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
		player: DB 127,127,9,9,15,6,0,0 ;P
				DB 127,127,64,64,64,64,0,0 ;L
				DB 124,126,19,19,126,124,0,0 ;A
				DB 7,15,120,120,15,7,0,0 ;Y
				DB 127,127,73,73,65,65,0,0 ;E
				DB 127,127,9,25,127,102,0,0 ;R
				
			
org 700h; _4_in_a_row game 
	 ;reg bank 2
	 ;r0 -> col position info stored in this reg
	_4_in_a_row:
	 setb psw.4
	 clr psw.3
	 ;starting functions called once to setup the starting of game screen
	 lcall display_grid
	 lcall display_other ;display score and player whose turn is there
	 setb 01h ;bit set to mark that starting turn will be of player 1
	 mov @r1,#30h ;r1 points to the location which cointain the no. of filled cell of chosen col(if 37h then it contains the no. of filled cells of 0th col; our 0th col is 7 so i used 37 )
	 main_game:
	 clr 00h;is low until select is pressed ; till that player is deciding position where he/she has to fill coin
	 wait:jnb 00h ,wait
	 lcall coin_drop;once position is selected by given player select is pressed then first coin has to get in chosen coloumn
	 
	 
	 
	 //lcall score_update;score calculation 
	 lcall update_screen ; based on changes like score and turn of other player display changes in screen
	 sjmp main_game
	 ret;return for game2
	
	display_grid:
			mov r7,#7
			mov r6,#6
			mov r5,#27h
			nxt:mov a,r5
				lcall choose_coord
				mov dptr,#grid
				lcall display_char
				inc r5	
				djnz r7,nxt
				mov a,r5
				clr c
				subb a,#1
				add a,#10h
				anl a,#0f0h
				add a,#07h
				mov r5,a
				mov r7,#7
				djnz r6,nxt				
				mov a,#17h
				mov r0,a
				lcall choose_coord
				mov dptr,#c_pl1
				lcall display_char					
			ret; return for display grid
	
			display_other:
			mov a,#00h ;set the coordinates from where 1st character of string is to be displayed
				lcall choose_coord
				mov dptr ,#player
				mov b,a ; first char location in b
				mov a,#6 ;total characters in a
				lcall display_string ;location of string first element in dptr
				
			mov a,#07h  //this position will change after each turn
				lcall choose_coord
				mov dptr ,#c_pl1				
				lcall display_char ;
			
			
				
			mov a,#30h ;
			lcall choose_coord
				mov dptr ,#c_pl1				
				lcall display_char ;
			mov a,#31h ;
			lcall choose_coord
				mov dptr ,#dash				
				lcall display_char ;
				mov a,#32h ;
			lcall choose_coord
				mov dptr ,#c0				
				lcall display_char ;
				mov a,#33h ;
			lcall choose_coord
				mov dptr ,#c0				
				lcall display_char ;
				
				mov a,#50h ;
			lcall choose_coord
				mov dptr ,#c_pl2				
				lcall display_char ;
				mov a,#51h ;
			lcall choose_coord
				mov dptr ,#dash				
				lcall display_char ;
				mov a,#52h ;
			lcall choose_coord
				mov dptr ,#c0				
				lcall display_char ;
				mov a,#53h ;
			lcall choose_coord
				mov dptr ,#c0				
				lcall display_char ;
				
			ret; return for display_other
	
			
			
			
	
			
	coin_drop: 		
					mov a,r0 
					lcall choose_coord
					mov dptr,#clear ;now pl2 turn has started thus his/her coin as cursor 
					lcall display_char
				
					//mov a,r0 
					//anl a,#0fh
					//add a,#70h ;logic left
					lcall fill_cell
					
					jb 01h,pl2_2 ; jump if 01h is set , if its set then pl1 has selected the position and coin has to go in that so grid coin of pl1 but cursor goin of pl2 as now pl2 turn is there				
					lcall choose_coord
					mov dptr,#coin1 ;grid coin of pl1...as bit is clr means its turn is just over
					lcall display_char
					
					mov a,r0 
					lcall choose_coord 
					mov dptr,#c_pl2 ;now pl2 turn has started thus his/her coin as cursor 
					lcall display_char
					sjmp exit_coin_drop
							
			
					pl2_2:
					lcall choose_coord
					mov dptr,#coin2
					lcall display_char
					
					mov a,r0
					lcall choose_coord
					mov dptr,#c_pl1 ;now pl1 turn has started thus his/her coin as cursor 
					lcall display_char
					
					
			exit_coin_drop:
	ret;return for coin_drop
	
	fill_cell:;r1 points to 30h, 30h to 37h contains the value till which given col is filled
    
	
	mov a,r0; lower nibble of r0 contains the col whuch is selected
	anl a,#0fh ; col which is selected is now in a
	add a,r1 ; a pionts to the location which contains the information that how much cells are filled in chosen col
	; say r0=18h => a=08h then a=>38h
	clr c
	subb a,#07h
	mov r1,a
	mov a,@r1 ;content of 38h in a ; say it is zero so last row will be filled
	mov r3,a ;temp reg to store the content of 38h
	
	;below 3 lines are logic to change the memory content 
	inc a ; inc the content in 38h
	mov @r1,a ; save it in 38h
	mov r1,#37h ; r1 again points to first location
	
	;below is to set the cell positon which is to be filled in a
	mov a,#07h
	clr c
	subb a,r3
	swap a ; now upper nibble is set 
	mov r3,a
	mov a,r0
	anl a,#0fh
	add a,r3 ; now a contains which cell has to be filled
ret; for fill_cell
			
	score_update:
	ret;return for score_update
			
	update_screen:
			mov a,#07h  //this position will change after each turn ; initially player one's turn is there
			lcall choose_coord
			jnb 01h ,pl2_sel
			mov dptr ,#c_pl1				
			lcall display_char ;
			sjmp exit_update_screen
			pl2_sel:
			mov dptr ,#c_pl2				
			lcall display_char ;
		exit_update_screen:
	ret;return for update_screen
end