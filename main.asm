; ------------------------------------------------------------
; ElkWSS-DiagROM - The Elk 'Why So Sad?' Diagnostics ROM
; 
; An Acorn Electron Diagnostics ROM by Chris Jamieson
; ------------------------------------------------------------

;#define TestCPUFailure #50 			; Dummy value to compare to Register bits
;#define TestZPRAMFailure #%10000000 	; Dummy bits failed
;#define TestStackRAMFailure #%01000000 ; Dummy bits failed
;#define TestMainRAMFailure #%01010101 	



; Zero Page Usage
#define ZP0 	 $00 	; General Purpose ZP Var 0
#define ZP1 	 $01 	; General Purpose ZP Var 1
#define ZP2 	 $02 	; General Purpose ZP Var 2
#define ZP3 	 $03 	; General Purpose ZP Var 3
#define ZP4 	 $04 	; General Purpose ZP Var 4
#define ZP5 	 $05 	; General Purpose ZP Var 5
#define ZP6 	 $06 	; General Purpose ZP Var 6
#define ZP7 	 $07 	; General Purpose ZP Var 7

#define STRPTRL 	 $10 	; Print string Pointer LSB - address of a string to print
#define STRPTRH 	 $11 	; Print string Pointer MSB - address of a string to print

#define CHARPOSL $D8 	; contain the address of the top scan line of the current text character (Same as Acorn MOS, I think)
#define CHARPOSH $D9

#define PREV_CHARPOSL 	$DA 
#define PREV_CHARPOSH 	$DB 

#define RAMTESTL 	$DC  
#define RAMTESTH 	$DD 

#define RAMTEST_ERROR_LIST_POSL 	$DE
#define RAMTEST_ERROR_LIST_POSH 	$DF

#include "macros.inc"

* =	$C000

#include "print.inc"

RESET:

; ------------------------------------------------------------
; ** Init
; ------------------------------------------------------------
; * Disable Interrupts but clear other Flags
	SEI
	CLD
	CLC
	CLV

; * Set Screen mode
;
; &FE07 - Miscellaneous control
; - b0=N/A
; - b12=01 Sound (on)
; - b345=110 Mode 6 - Colours 2, Text 40x25
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
	CLC
	ADC		#1
	BEQ		CPU_ERROR 	; Z should be 0
	BCS 	CPU_ERROR 	; C should be 0
	BMI 	CPU_ERROR	; N should be 0
	BVS 	CPU_ERROR 	; V should be 0
	SEC
	SBC	 	#$81 		; N set, V set
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
#ifdef TestCPUFailure
	CMP 	TestCPUFailure
#endif
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
#ifdef TestZPRAMFailure
	LDA 	#0
	EOR 	TestZPRAMFailure
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
	JMP 	STACK_TEST

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
; ZP error first nibble is 0001
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
	SETSCREEN_WHITE()
	DELAY(#$03)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	DELAY(#$03)	
; Second nibble is the lowest bad bit number
ZP_ERROR_SHOW_BIT2:
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
	JMP 	HALT

ZP_TEST_FINISH:

; ------------------------------------------------------------
; 2. Test Stack RAM
;
;	- ZP tested and 'passed' so can use that now
; ------------------------------------------------------------

STACK_TEST:
	LDY 	#$FF
	TYA 
STACK_TEST_LOOP:
	LDX 	#0 			; Index of the stack
STACK_FILL_LOOP:
	STA 	$0100, X
	INX
	BNE 	STACK_FILL_LOOP
STACK_READ_LOOP:
	EOR 	$0100, X
#ifdef TestStackRAMFailure
	LDA 	#0
	EOR 	TestStackRAMFailure
#endif ; TestStackRAMFailure
	BNE  	STACK_ERROR
	TYA 					; Put test pattern back into A
	INX
	BNE 	STACK_READ_LOOP  	; Keep testing until we wrap around back to 00 again
	CPY 	#0 				; Are we using 00 as pattern or FF?
	BEQ 	STACK_TEST_FINISH_JMP 	; 00, then we're done
	LDY 	#$00 			; No was FF, so now do 00 and start again
	TYA
	JMP 	STACK_TEST_LOOP 	
STACK_TEST_FINISH_JMP:
	JMP 	RAM_TEST

STACK_ERROR:
; We should have the bad bits in A...
	LDX 	#0 	; Bit position counter
	CLC
STACK_ERROR_TEST_BIT_LOOP:
	LSR 							; Move bits Left - has a '1' ended up in the carry flag?
	BCS		STACK_ERROR_SHOW_BIT 		; Carry set? Lets stop there then
	INX 							; No carry set, try the next bit
	CPX 	#8 						; All bits checked now?
	BNE 	STACK_ERROR_TEST_BIT_LOOP 
	JMP  	STACK_ERROR_SHOW_BIT 	; Shouldn't get here, but flash 8 times if it does...

STACK_ERROR_SHOW_BIT:
; X = Lowest Bad Bit
	TXA
; Stack error first nibble is 0010 '2'
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$03)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	SETSCREEN_WHITE()
	DELAY(#$01)	
	SETSCREEN_BLACK()
	DELAY(#$03)	
	DELAY(#$03)	
	JMP ZP_ERROR_SHOW_BIT2 		; This is the same now

; We should be able to rely on the ZP and Stack so can use subroutines

; ------------------------------------------------------------
; 3. Test All RAM
; ------------------------------------------------------------

RAM_TEST:
	JSR 	INIT_SCREEN
	LDA 	#<CPU_OK_STR
	STA 	STRPTRL
	LDA 	#>CPU_OK_STR
	STA 	STRPTRH
	JSR 	PRINT

	LDA 	#$40
	STA 	CHARPOSL
	LDA 	#$61
	STA 	CHARPOSH

	LDA 	#<ZP_OK_STR
	STA 	STRPTRL
	LDA 	#>ZP_OK_STR
	STA 	STRPTRH
	JSR 	PRINT

	LDA 	#$80
	STA 	CHARPOSL
	LDA 	#$62
	STA 	CHARPOSH

	LDA 	#<STACK_OK_STR
	STA 	STRPTRL
	LDA 	#>STACK_OK_STR
	STA 	STRPTRH
	JSR 	PRINT

	LDA 	#$C0
	STA 	CHARPOSL
	LDA 	#$63
	STA 	CHARPOSH

	LDA 	#<RAM_STR
	STA 	STRPTRL
	LDA 	#>RAM_STR
	STA 	STRPTRH
	JSR 	PRINT

; I'm going to store every value in every address in RAM above 0x200!!
	LDA 	#$65
	STA 	RAMTEST_ERROR_LIST_POSH
	LDA 	#$00
	STA 	RAMTEST_ERROR_LIST_POSL
	LDY 	#$00
	LDA  	#$02
	STA 	RAMTESTH
	JSR 	PRINT_HEX_BYTE
	LDA 	#$00
	STA 	RAMTESTL
; Write to all locations in page
RAMTESTLOOP_WRITE: 
	STA 	($DC), Y
	INY 
	BNE 	RAMTESTLOOP_WRITE
; Read back from all locations in page
RAMTESTLOOP_READ:
	STA 	ZP3
	LDA 	($DC), Y

#ifdef TestMainRAMFailure
	CPY 	TestMainRAMFailure
	BNE 	TestMainRAMFailure_CarryOn
	LDA 	TestMainRAMFailure
TestMainRAMFailure_CarryOn:
#endif

	CMP 	ZP3
	BNE 	RAMTEST_ERROR
	JMP 	RAMTEST_CARRYON
RAMTEST_ERROR:
	JSR 	RAMTEST_PRINT_ERROR
RAMTEST_CARRYON:
	INY
	BNE 	RAMTESTLOOP_READ
	CLC 
	ADC 	#1
	BNE 	RAMTESTLOOP_WRITE
; Update the Page counter
	LDA 	#$08
	JSR 	PRINT_CHAR
	LDA 	#$08
	JSR 	PRINT_CHAR
	INC 	RAMTESTH
	LDA 	RAMTESTH
	JSR 	PRINT_HEX_BYTE
	CMP 	#$80
	BNE 	RAMTESTLOOP_WRITE
RAMTEST_DONE:
	LDA 	#$08
	JSR 	PRINT_CHAR
	LDA 	#$08
	JSR 	PRINT_CHAR
	LDA 	#<OK_STR
	STA 	STRPTRL
	LDA 	#>OK_STR
	STA 	STRPTRH
	JSR 	PRINT
	DELAY(#$03)	
	JMP 	RAM_TEST

RAMTEST_PRINT_ERROR:
	STA 	ZP4 	; Failed Bit
	STY 	ZP5 	; Failed offset

	LDA 	CHARPOSL
	STA 	PREV_CHARPOSL
	LDA 	CHARPOSH
	STA 	PREV_CHARPOSH

	LDA 	RAMTEST_ERROR_LIST_POSL
	STA 	CHARPOSL
	LDA 	RAMTEST_ERROR_LIST_POSH
	STA 	CHARPOSH

	LDA 	#<AT_STR
	STA 	STRPTRL
	LDA 	#>AT_STR
	STA 	STRPTRH
	JSR 	PRINT

	LDA 	RAMTESTH
	JSR 	PRINT_HEX_BYTE
	LDA 	ZP5
	JSR 	PRINT_HEX_BYTE

	LDA 	#<EXP_STR
	STA 	STRPTRL
	LDA 	#>EXP_STR
	STA 	STRPTRH
	JSR 	PRINT

	LDA 	ZP3
	JSR 	PRINT_HEX_BYTE

	LDA 	#<GOT_STR
	STA 	STRPTRL
	LDA 	#>GOT_STR
	STA 	STRPTRH
	JSR 	PRINT

	LDA 	ZP4 
	JSR 	PRINT_HEX_BYTE

; Update error list to the next line
	LDA 	RAMTEST_ERROR_LIST_POSH
	CMP 	#$7E
	BNE 	RAMTEST_ERROR_INC_LIST_POS
; Be good if it printed a message and said 'screen full, press space to continue'
	JSR 	SPACE_TO_CONT
	LDA 	#$65
	STA 	RAMTEST_ERROR_LIST_POSH
	LDA 	#$00
	STA 	RAMTEST_ERROR_LIST_POSL
	JMP 	RAMTEST_PRINT_ERROR_DONE

RAMTEST_ERROR_INC_LIST_POS:
	CLC
	LDA 	RAMTEST_ERROR_LIST_POSL
	ADC 	#$40
	STA 	RAMTEST_ERROR_LIST_POSL
	LDA 	RAMTEST_ERROR_LIST_POSH
	ADC 	#$1
	STA 	RAMTEST_ERROR_LIST_POSH

RAMTEST_PRINT_ERROR_DONE:

	LDA 	PREV_CHARPOSL
	STA 	CHARPOSL
	LDA 	PREV_CHARPOSH
	STA 	CHARPOSH

	LDY 	ZP5
	LDA 	ZP4

	RTS

SPACE_TO_CONT:
	LDA 	#<SPACE_CONT_STR
	STA 	STRPTRL
	LDA 	#>SPACE_CONT_STR
	STA 	STRPTRH
	JSR 	PRINT
SPACE_TO_CONT_LOOP:
	LDA 	#%00001000
	STA 	$FE05
	LDA 	$BFFE
	AND 	#$08
	BEQ 	SPACE_TO_CONT_LOOP
	LDX 	#13
SPACE_TO_CONT_DEL_STR:
	LDA 	#$08
	JSR 	PRINT_CHAR
	DEX
	BNE 	SPACE_TO_CONT_DEL_STR

	RTS

; 4. Test Interrupts (&FE00)

; 5. Test ...			


NMISR:

ISR:

HALT:
; Do it all again so we don't end up in la-la-land
 	JMP 	HALT


CPU_OK_STR 		.asc "CPU: OK                 = Elk WSS v0.1 =" : .byt $00
ZP_OK_STR 		.asc "ZP RAM (0x00-0xFF): OK" : .byt $00
STACK_OK_STR 	.asc "Stack RAM (0x100-0x1FF): OK" : .byt $00
RAM_STR 		.asc "Main RAM (0x200-0x7FFF): " : .byt $00
OK_STR 			.asc "OK" : .byt $00
ERROR_STR 		.asc "ERROR" : .byt $00
AT_STR 			.asc " Addr: " : .byt $00
EXP_STR 		.asc " Exp: " : .byt $00
GOT_STR 		.asc " Act: " : .byt $00
SPACE_CONT_STR 	.asc " SPC To Cont." : .byt $00

SETLOC($F900)

#include "charset.inc"

SETLOC($FFFA)

NMI:
	.word 	NMISR
RES:
	.word 	RESET
IRQ:
	.word 	ISR