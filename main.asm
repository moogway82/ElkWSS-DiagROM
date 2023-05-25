; ------------------------------------------------------------
; ElkWSS-DiagROM - The Elk 'Why So Sad?' Diagnostics ROM
; 
; An Acorn Electron Diagnostics ROM by Chris Jamieson
; ------------------------------------------------------------

;#define TestRAMFailure #$20 	; Bit 6 failed

#include "macros.inc"

* =	$F000

RESET:

; ** Init
; * Disable Interrupts
	SEI
	CLD

; * Set Screen mode
;
; &FE07 - Miscellaneous control
; - b0=N/A
; - b12=01 Sound (on)
; - b345=110 Mode 6
; - b6=0 Cassette Motor (off)
; - b7=0 Caps LED (off)
	LDA 	#%00110000
	STA 	$FE07

; * Set Screen Start Addr
;
; SHEILA &FE02 and &FE03
; &6000 = 0110 0000 0000 0000
; 0 / [FE03] / [FE02] / 00 0000
; 0 / 110 000 / 0 00 / 00 0000
; FE02 = A8 A7 A6 X X X X X
; FE03 = X X A14 A13 A12 A11 A10 A9
; FE02 = 00000000 = &0
; FE03 = 00110000 = &30
	LDA 	#0
	STA 	$FE02
	LDA 	#$30
	STA 	$FE03

	SETSCREEN_BLACK()

; ------------------------------------------------------------
; 0. Test CPU
; ------------------------------------------------------------
; 
; 	Testing Flags
	LDA 	#0 			 
	BNE 	CPU_ERROR	; Z should be 1
	BMI 	CPU_ERROR 	; N should be 0
	ADC		#1
	BEQ		CPU_ERROR 	; Z should be 0
	BCS 	CPU_ERROR 	; C should be 0
	BMI 	CPU_ERROR	; N should be 0
	BVS 	CPU_ERROR 	; V should be 0
	SBC	 	#$80 		; N set, V set
	BPL 	CPU_ERROR 	; N should be 1
	BVC 	CPU_ERROR 	; V should be 1
	ASL 	 			; .V.IZC
	BMI 	CPU_ERROR 	; N should be 0
	BVC 	CPU_ERROR	; V should be 1
	BNE 	CPU_ERROR	; Z should be 1
	BCC 	CPU_ERROR	; C should be 1

; 	Testing Registers
	LDA 	#$AA 
	TAX
	TXA
	TAY
	TYA 
	CMP 	#$AA  		; Z = 1
	BNE 	CPU_ERROR 	; Z should be 1
	LDA 	#$55 
	TAX
	TXA
	TAY
	TYA 
	CMP 	#$55  		; Z = 1
	BNE 	CPU_ERROR 	; Z should be 1
	JMP 	ZP_TEST 

CPU_ERROR:
; Just 4 short flashes followed by another 4 short flahses
	LDA 	#$4
FLASH_SCREEN_ERR:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SEC
	SBC 	#1
	BNE 	FLASH_SCREEN_ERR:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	DELAY(#$03)	
	LDA 	#$4
FLASH_SCREEN_ERR2:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SEC
	SBC 	#1
	BNE 	FLASH_SCREEN_ERR2:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	DELAY(#$03)	
	JMP 	HALT

; ------------------------------------------------------------
; 1. Test ZP RAM
; ------------------------------------------------------------
;
ZP_TEST:
	LDY 	#$FF  			; Current test pattern
	TYA
ZP_TEST_LOOP:
	LDX 	#0
ZP_FILL_LOOP:
	STA 	0, X
	INX
	BNE 	ZP_FILL_LOOP
ZP_READ_LOOP:
	EOR 	0, X
#ifdef TestRAMFailure
	LDA 	#0
	EOR 	TestRAMFailure
#endif
	BNE  	ZP_ERROR
	TYA 					; Put test pattern back into A
	INX
	BNE 	ZP_READ_LOOP  	; Keep testing until we wrap around back to 00 again
	CPY 	#0 				; Are we using 00 as pattern or FF?
	BEQ 	ZP_TEST_FINISH_JMP 	; 00, then we're done
	LDY 	#$00 			; No FF, so now do 00 and start again
	TYA
	JMP 	ZP_TEST_LOOP 	

ZP_TEST_FINISH_JMP:
	JMP 	ZP_TEST_FINISH

ZP_ERROR:
; So we have a bad bit (or more) - lets find the lowest broken bit and flash the screen for that
; Either Y=1 and we have something like %11011111 so we need to find that '0'
; OR Y=0 and we have something like %00100000 so we need to find the '1'
; I think we could do something like a right shift until carry is set?
; We should have the bad bits in A...
	LDX 	#0 	; Bit position counter
	CLC
ZP_ERROR_TEST_BIT_LOOP:
	LSR 							; Move bits Left - has a '1' ended up in the carry flag?
	BCS		ZP_ERROR_SHOW_BIT 		; Carry set? Lets stop there then
	INX 							; No carry set, try the next bit
	CPX 	#8 						; All bits checked now?
	BNE 	ZP_ERROR_TEST_BIT_LOOP 
	JMP  	ZP_ERROR_SHOW_BIT 	; Shouldn't get here, but flash 8 times if it does...

ZP_ERROR_SHOW_BIT:
; X = Lowest Bad Bit
	TXA
; ZP error first nibble is 1000
	SETSCREEN_WHITE()
	DELAY(#$03)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	DELAY(#$03)	
; Second nibble is the lowest bad bit number
	TAX 	; Delays and flashing trash the top two bits of A so need to save it...
	ASL		; Shift low nibble high
	ASL
	ASL
	ASL

	ASL
	TXA 	; Restore no. to flash, should not affect carry
	BCS 	ZP_ERROR_SHOW_BITNO1_1
	SETSCREEN_WHITE()
	DELAY(#$01)	
	JMP 	ZP_ERROR_SHOW_BITNO2
ZP_ERROR_SHOW_BITNO1_1:
	SETSCREEN_WHITE()
	DELAY(#$03)	

ZP_ERROR_SHOW_BITNO2:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	TAX 	; Delays and flashing trash the top two bits of A so need to save it...
	ASL		; Shift low nibble high
	ASL
	ASL
	ASL
	
	ASL
	ASL
	TXA 	; Restore no. to flash, should not affect carry
	BCS 	ZP_ERROR_SHOW_BITNO2_1
	SETSCREEN_WHITE()
	DELAY(#$01)	
	JMP 	ZP_ERROR_SHOW_BITNO3
ZP_ERROR_SHOW_BITNO2_1:
	SETSCREEN_WHITE()
	DELAY(#$03)	

ZP_ERROR_SHOW_BITNO3:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	TAX 	; Delays and flashing trash the top two bits of A so need to save it...
	ASL		; Shift low nibble high
	ASL
	ASL
	ASL
	
	ASL
	ASL
	ASL
	TXA 	; Restore no. to flash, should not affect carry
	BCS 	ZP_ERROR_SHOW_BITNO3_1
	SETSCREEN_WHITE()
	DELAY(#$01)	
	JMP 	ZP_ERROR_SHOW_BITNO4
ZP_ERROR_SHOW_BITNO3_1:
	SETSCREEN_WHITE()
	DELAY(#$03)	

ZP_ERROR_SHOW_BITNO4:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	TAX 	; Delays and flashing trash the top two bits of A so need to save it...
	ASL		; Shift low nibble high
	ASL
	ASL
	ASL
	
	ASL
	ASL
	ASL
	ASL
	TXA 	; Restore no. to flash, should not affect carry
	BCS 	ZP_ERROR_SHOW_BITNO4_1
	SETSCREEN_WHITE()
	DELAY(#$01)	
	JMP 	ZP_ERROR_SHOW_BIT_DONE
ZP_ERROR_SHOW_BITNO4_1:
	SETSCREEN_WHITE()
	DELAY(#$03)	

ZP_ERROR_SHOW_BIT_DONE:
	SETSCREEN_BLACK()
	DELAY(#$03)	

ZP_TEST_FINISH:

; 2. Test Stack RAM

; 3. Test All RAM

; 4. Test Interrupts (&FE00)

; 5. Test ...			


NMISR:

ISR:

HALT:
; Do it all again so we don't end up in la-la-land
 	JMP 	HALT

SETLOC($FFFA)

NMI:
	.word 	NMISR
RES:
	.word 	RESET
IRQ:
	.word 	ISR