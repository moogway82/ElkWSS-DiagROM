; Some helpful Macros
;
; SETLOC(location)
;
; location - the Address to skip to

#define SETLOC(location)  .dsb (location-*),$00:* = location

; DELAY(noxloops)
;
; noxloops = Number of times the X loop should go round, only 0, 1, 2 or 3 as this is OR'd to maintain 6bits of A reg
; Trashes all Registers apart from first 6 bits of X? :)

#define DELAY(noxloops) 	ROL : ROL : ORA 	noxloops : TAX : LDY 	#0 : LDA 	#0 : SBC 	#1 : .byt $D0,$FC : DEY : .byt $D0,$F7 : DEX : TXA : AND 	#%00000011 : .byt $D0,$EF : TXA : LSR : LSR 

;=========================================================================
; Delay by ~1/2 Second
;
; Trashes all Registers apart from first 6 bits of X? :)
; - 2MHz clock needs about 1M cycles to waste 0.5s
; 
;-------------------------------------------------------------------------

;	ROL 	 				; Shift 6bits of current contents high to preserve it
;	ROL 	
;	ORA 	#$03 			; Set 3 into bits 0 & 1
;	TAX
;DELAY_LOOP_X
;	LDY 	#0 				; 2c
;DELAY_LOOP_Y
;	LDA 	#0				; 2c
;DELAY_LOOP_A 				
;	SBC 	#1 				; 2c
;	BNE		DELAY_LOOP_A 	; ~2c - total 4c * 255 = 1020c | $D0,$FC
;	DEY 					; 2c
;	BNE		DELAY_LOOP_Y 	; ~2c - total (4c + 1020c) * 255 = 1024 * 255 = 261120c | $D0,$F7
;	DEX 					; 2c
;	TXA
;	AND 	#%00000011 		; Mask off all but lower 2 bits - is it now 0?
;	BNE		DELAY_LOOP_X	; ~2c - total (4c + 261120c) * 4 = 261124 * 4 = 1044496c ~ = 0.522248s close enough! | $D0,$EF
;	TXA
;	LSR 	 				; Restore the original 6bits of A
;	LSR 	 				

; SETSCREEN_[colour]
;
; Trashes X, preserves A
; Just sets the pallete registers to all being 1 colour to flash the screen

#define SETSCREEN_BLACK() 	TAX : LDA 	#%01010100 : STA 	$FE08 : LDA 	#%00010101 : STA 	$FE09 : TXA

	; Set all colours BLACK
	; &FE08 X B1 X B0 X G1 X X
	; &FE09 X X X G0 X R1 X R0
	;
	; RGB0 = 111
	; RGB1 = 111
	; ...therefore...
	; &FE08 X 1 X 1 X 1 X X
	; &FE09 X X X 1 X 1 X 1
;	LDA 	#%01010100
;	STA 	$FE08
;	LDA 	#%00010101
;	STA 	$FE09

#define SETSCREEN_WHITE() 	TAX : LDA 	#%00000000 : STA 	$FE08 : LDA 	#%00000000 : STA 	$FE09 : TXA 

	; Set all colours WHITE
	; &FE08 X B1 X B0 X G1 X X
	; &FE09 X X X G0 X R1 X R0
	;
	; RGB0 = 000
	; RGB1 = 000
	; ...therefore...
	; &FE08 X 0 X 0 X 0 X X
	; &FE09 X X X 0 X 0 X 0
;	LDA 	#%00000000
;	STA 	$FE08
;	LDA 	#%00000000
;	STA 	$FE09

#define PRINT_STRING(thestring)		LDA 	#<thestring : STA 	STRPTRL : LDA 	#>thestring : STA 	STRPTRH : JSR 	PRINT

