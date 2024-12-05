;random food generation
; generate random value btw 00 to 1f and store in r0 whenever interrupt is there

org 0000h
	ljmp main
org 0300h
	main:
		mov ie,#81h
		setb tcon.0
		mov tmod, #02h
		mov th0,#00h
		again:
		setb tr0
		wait: jnb tf0,wait
		clr tr0
		clr tf0
		sjmp again

org 0003h
	ljmp main_isr
	return:mov ie,#81h
	reti
	org 0400h
	main_isr:
	mov ie,#00h
	mov r0,tl0 ;random no. in r0
	mov a,r0 
	anl a,#1fh ; upper nibble either 1 or 0 randomly depends on the value
	mov r0,a 
	ljmp return
	
	