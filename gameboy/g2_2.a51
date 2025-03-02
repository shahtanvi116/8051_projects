
org 0000h
	
	sjmp main
	
org 0003h
	
	ljmp key_board_isr
org 000bh
		
		main: ;main logic inception starts here 
		
		mov p0,#0ffh ;set p0 as input port
		
		setb p2.3 ;set rest pin to 1 i.e. inactive mode
		
		mov sp,#5ch ;move sp to ram loaction 5ch
		
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
					cjne a,#1dh,goto_nxt ;if it is at 1dh location i.e. last positoin then
					mov 12h,#16h ;set it to first position again but 1 less than it bcz in next instruction it will be incremented
					goto_nxt:inc 12h
					
					sjmp repeat
					
					
				ch_01:cjne a,#01h,sel_button_pressed ;if key 2 is pressed means move the coin to left
				;this logic is for game2
				;for same key game1 has different logic
				;1 bit adress can be used to determine which game is going on...will do it when I'll integrate both games
					
					mov a,12h ;clear old coin position;coin pos saved in reg r2 of rb2
					lcall choose_coord
					mov dptr,#clear
					lcall display_char
				
                ;below 4 lines are to make sure that the coin is still in range...our range is 17h to 1dh so if it is at 1dh so next position will be 17h				
					mov a,12h
					cjne a,#17h,goto_nxt1 ;if it is at 1dh location i.e. last positoin then
					mov 12h,#1eh ;set it to first position again but 1 less than it bcz in next instruction it will be incremented
					goto_nxt1:dec 12h
					
					
					repeat:
					mov a,12h
					lcall choose_coord
					
					jnb 01h,player2 		;if 01h is set means p1's turn is going on , else p2 turn so display the cursor coin accordingly			
					
					mov dptr,#c_p1
					lcall display_char
					
					sjmp returnback
					
					player2:
					mov dptr,#c_p2
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
			
		clear:  db 00h,00h,00h,00h,00h,00h,00h,00h
		cursor: db 0x00, 0xFF, 0xFF, 0x7E, 0x7E, 0x3C, 0x18, 0x00  ;Code for Cursor (>)
		
		grid: db 0ffh,0c3h,81h,81h,81h,81h,0c3h,0ffh;
		
		coin1: db 0ffh,0ffh,0e7h,0dbh,0dbh,0e7h,0ffh,0ffh;
		coin2: db 0ffh,0ffh,0e7h,0c3h,0c3h,0e7h,0ffh,0ffh;
		
		c_p1: db 00h,3ch,42h,5ah,5ah,42h,3ch,00h; player 1 coin
		c_p2: db 00h,3ch,42h,42h,42h,42h,3ch,00h; player 2 coin
		
		start:db 11h,6eh,17h,61h,22h,5dh,28h,55h,33h,49h,16h,64h,15h,51h,25h,63h,37h,59h,44h,1eh
		
		player: DB 127,127,9,9,15,6,0,0 ;P
				DB 127,127,64,64,64,64,0,0 ;L
				DB 124,126,19,19,126,124,0,0 ;A
				DB 7,15,120,120,15,7,0,0 ;Y
				DB 127,127,73,73,65,65,0,0 ;E
				DB 127,127,9,25,127,102,0,0 ;R
				
			
org 700h; _4_in_a_row game starts here
	
		;reg bank 2 used for game operations
		;r2 (12h)-> col position info stored in this reg
		;r1 (11h)-> used as pointers to memory loaction of which column is filled by what amount which is from r0 to r6 of rb-3
		;r3 -> temporarily store the the value upto which a given selected column is filled
		;r4 -> contains the glcd coordinates where the coin is suppose to fell once the user presses select
		;bit 00h -> column where coin is to be placed is seletcted this bit is used to indicate that
		;bit 01h -> to determine a given players turn
		
		;also for ram location 30h to 59h the data in these memory locations are mapped to corresponding grid element coordinates of glcd 
		;data present in them means the follwing thing
		;00h means the given grid element is void of any coin
		;01h means the given grid element is filled with coin of player-1
		;02h means the given grid element is filled with coin of player-2
		
		_4_in_a_row:
		
		setb psw.4
		clr psw.3
		;starting functions called once to setup the starting of game screen
		lcall display_grid
		lcall display_other ;display score and player whose turn is there
		lcall clr_ram
		
		setb 01h ;bit set to mark that starting turn will be of player 1
		
		mov r0,#30h ;r0 points to the memory mapped locations for the GLCD Screen Which contains information about type of data in a given grid cell
		mov r1,#21h ;r1 points to the location which cointain the no. of filled cell of chosen col
		
		main_game:
		
		clr 00h ;is low until select is pressed till that player is deciding position where he/she has to fill coin
		
		wait:jnb 00h ,wait
		
		lcall coin_drop;once position is selected by given player select is pressed then first coin has to get in chosen coloumn
	  
		lcall update_cursor ; based on change that turn of next player display changes in screen
		
		sjmp main_game
		
		ret;return for game2
		
		clr_ram: ;used to clear 42(D) ram loactions with 00h starting from 30h
		
		mov r7,#42 ;no. of ram locations to be cleared
		
		repeate_till_done:
		
		mov @r0,#00h ;initialize all the ram locations with 00h which means all grid elements are empty
		inc r0
		djnz r7,repeate_till_done
		
		mov r0,#30h ;make sure to re-initialize r0 to correct default value
		
		ret ;for clr_ram
	
		display_grid:
				
				mov r7,#7 ;no. of columns
				mov r6,#6 ;no. of rows
				
				mov r5,#27h ;coordinate location from where 1st element of grid starts
				
				nxt:
					
					mov a,r5 ;display grind character at location value present in r5
					lcall choose_coord
					mov dptr,#grid
					lcall display_char
					
					inc r5	
					
					djnz r7,nxt ;this is repeated  7-times i.e. till a row is completed 
					
					mov a,r5 ;the following subtraction is done because while the loop rotates 7-times an extra increment takes
					clr c	;place when the condition turns out to be false and hence to match things properly we subtract 1 from value of r5 reg
					subb a,#1
					
					add a,#10h ;this is done to transverse to next row 
					anl a,#0f0h
					add a,#07h
					mov r5,a
					
					mov r7,#7 ;reinitialize r7 to cover for the new row
					
					djnz r6,nxt ;repeat the process till entire grid is drawn on screen
					
					mov a,#17h ;this is to place the coin of initial player as cursor
					mov r2,a
					lcall choose_coord
					mov dptr,#c_p1
					lcall display_char
					
		ret; return for display grid
	
		display_other: ;used to display other useful info at start of the game
			
			mov a,#10h ;set the coordinates from where 1st character of string is to be displayed
			lcall choose_coord
			mov dptr ,#player
			mov b,a ; first char location in b
			mov a,#6 ;total characters in a
			lcall display_string ;location of string first element in dptr
			
			mov a,#30h  //this cursor position will change after each turn
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
	
		coin_drop: ;deals with where to place the coin after select button is pressed  		
						
				mov a,r2 ;used to clear coin from current cursor location 
				lcall choose_coord
				mov dptr,#clear ;now p2 turn has started thus his/her coin as cursor 
				lcall display_char
			
				lcall fill_cell
				
				jb 01h,pl2_2 ; jump if 01h is set , if its set then p1 has selected the position and coin has to go in that so grid coin of p1 but cursor coin of p2 as now p2 turn is there				
				;seeing the logic it may be hard to digest it is because the 01h bit is complemented in keyboard isr as soon as select is pressed and because of that we follow an invereted logic here
				
				lcall choose_coord
				mov dptr,#coin1 ;grid coin of p1...as bit is clr means its turn is just over
				lcall display_char
				lcall update_ram
				
				mov a,r2 
				lcall choose_coord 
				mov dptr,#c_p2 ;now p2 turn has started thus his/her coin as cursor 
				lcall display_char
				sjmp exit_coin_drop
						
		
				pl2_2:
				lcall choose_coord
				mov dptr,#coin2
				lcall display_char
				lcall update_ram
				
				mov a,r2
				lcall choose_coord
				mov dptr,#c_p1 ;now p1 turn has started thus his/her coin as cursor 
				lcall display_char
				
				
		exit_coin_drop:
		ret;return for coin_drop
	
		fill_cell:;r1 points to 21h, 21h to 27h contains the value till which given column is filled
		
			mov a,r2; lower nibble of r2 contains the col which is selected , 
			anl a,#0fh ; col which is selected is now in a
			add a,r1 ; a points to the location which contains the information that how much cells are filled in chosen col
			; say r2=18h => a=08h then a=>29h
			
			clr c ;now this is done because the grid starts from 7th column till dth column for each row
			subb a,#07h ;while r1 is to point form 21 to 28h only so to avoid the indexing issue
			mov r1,a ;we subtract 7 from the masked column value so that correct ram loaction corresponding to selected column can be choosen
			mov a,@r1 ;content of 38h in a ; say it is zero so last row will be filled
			mov r3,a ;temp reg to store the content of 38h
			
			;below 3 lines are logic to change the memory content 
			inc a ; inc the content in 38h
			mov @r1,a ; save it in 38h
			mov r1,#21h ; r1 again points to first location
			
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
	
	update_ram: ;used to update ram memory locations correspoding to the grid filled by a given player
	
			mov a,r4 ;restore the currently filled cell location in reg-a
			
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
			
			jb 01h,updt_p2 ;to take apt decision as to what value is to be filled
			
			mov @r0,#01h ;player-1's coin is filled at corresponding memory location
			
			sjmp exit_update_ram
			
			updt_p2:
			
			mov @r0,#02h
			
		exit_update_ram:
		
		mov r0,#30h
	
	ret ;for update_ram
			
	score_update:
	ret;return for score_update
			
	update_cursor:


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
