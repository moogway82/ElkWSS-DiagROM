; ------------------------------------------------------------
; ElkWSS-DiagROM - The Elk 'Why So Sad?' Diagnostics ROM
; 
; An Acorn Electron Diagnostics ROM by Chris Jamieson
; ------------------------------------------------------------

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

; * Set Pallette Regs
;
; &FE08 X B1 X B0 X G1 X X
; &FE09 X X X G0 X R1 X R0
;
; RGB0 = 111
; RGB1 = 000
; ...therefore...
; &FE08 X 0 X 1 X 0 X X
; &FE09 X X X 1 X 0 X 1
	LDA 	#%00010000
	STA 	$FE08
	LDA 	#%00010001
	STA 	$FE09

; 0. Test CPU
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
; Just 8 short flashes
	LDA 	#$8
FLASH_SCREEN_ERR:
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SEC
	SBC 	#1
	BNE 	FLASH_SCREEN_ERR:
	SETSCREEN_BLACK()
	JMP 	HALT

; 1. Test ZP RAM
;
ZP_TEST:
	LDA 	#$A5
	STA 	$0
	CMP 	$0
	BNE 	ZP_ERROR

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