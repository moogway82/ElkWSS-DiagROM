; ------------------------------------------------------------
; Printing text routines
; ------------------------------------------------------------


; ------------------------------------------------------------
; Init screen
;
; - Set pallete to B/W
; - Fill Mode 6 with nothing &6000 - &7F3F
; - Set character pos to top of screen
; ------------------------------------------------------------
INIT_SCREEN:
	; Set colours to BLACK & WHITE
	; &FE08 X B1 X B0 X G1 X X
	; &FE09 X X X G0 X R1 X R0
	;
	; RGB0 = 111 - White?
	; RGB1 = 000 - Black?
	; 
	; &FE08 X 0 X 1 X 0 X X
	; &FE09 X X X 1 X 0 X 1
	LDA 	#%00010000
	STA 	$FE08
	LDA 	#%00010001
	STA 	$FE09

	; Using ZP0 & 1 for screen start address
	LDA 	#$00
	STA 	ZP0
	STA 	CHARPOSL 	; Also set the screen start pos
	LDA 	#$60
	STA 	ZP1
	STA 	CHARPOSH
	LDA 	#$00
	LDY 	#$00
INIT_SCREEN_FILL_VRAM_LOOP:
	STA 	($00),Y	
	INY
	BNE 	INIT_SCREEN_FILL_VRAM_LOOP 	
	INC 	ZP1
	LDA 	#$7F
	CMP		ZP1
	BEQ 	INIT_SCREEN_FILL_VRAM_LOOP2
	LDA 	#$00
	JMP 	INIT_SCREEN_FILL_VRAM_LOOP
INIT_SCREEN_FILL_VRAM_LOOP2:
	LDA 	#$00
	STA 	($00),Y 
	INY 	
	CPY 	#$40
	BNE 	INIT_SCREEN_FILL_VRAM_LOOP2

	RTS

; ------------------------------------------------------------
; PRINT_CHAR
; 
; A = ASCII Character to Print at current char location
; 
; Trashed: A, Y. ZP0, ZP1
;
; - Copy over character bytes to screen memory
; ------------------------------------------------------------

PRINT_CHAR:
	STA 	ZP0
	TYA 	
	PHA
	LDA 	ZP0

	TAY
; First Byte of ASCII char is ASCII * 8 + FB00 = Start location. "A" (0x41) * 8 = 0x208 + FB00 = 0xFD08
	LDA 	#0
	STA 	ZP1 	; High byte of address
	TYA 
	STA 	ZP0
	CLC
	ASL 	ZP0
	ROL 	ZP1
	ASL 	ZP0
	ROL 	ZP1
	ASL 	ZP0
	ROL 	ZP1
; Add FB00 to the offset, just need to add MSB
	CLC
	LDA		#$F8
	ADC 	ZP1
	STA 	ZP1
; Now move next 8 bytes to screen
	LDY 	#0
PRINT_CHAR_LOOP:
	LDA 	($00),Y
	STA 	($D8),Y
	INY
	CPY 	#8
	BNE 	PRINT_CHAR_LOOP
; Move the character location to the next space (+8)
	CLC
	LDA 	CHARPOSL
	ADC 	#8
	STA 	CHARPOSL
	LDA 	CHARPOSH
	ADC 	#0
	STA 	CHARPOSH

	PLA 
	TAY
	RTS

; ------------------------------------------------------------
; PRINT
; 
; ZP STRPTRL $10 & ZP STRPTRL $11 - Pointer to the start of a string to print. Prints until 0x00 or 256 chars.
; ------------------------------------------------------------

PRINT:
	LDY 	#0
PRINT_LOOP:
	LDA 	($10),Y
	CMP 	#$00
	BEQ 	PRINT_END
	JSR 	PRINT_CHAR
	INY 
	BNE 	PRINT_LOOP
PRINT_END:
	RTS



