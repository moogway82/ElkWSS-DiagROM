# Elk Diagnostics ROM
Going to try and make a simple Diag ROM in the vein of the ZX Spectrum/CPC Testing ROM. There is an Oric one which is a good example to follow as its simple and 6502 based.

## Tests

### 0. Basic CPU Test
Just do some basic arithmetic operations and see if they work - this is a little silly as the CPU is unlikely to execute code if it’s faulty :)

### 1. Zero Page RAM Test
Write all ones and then all zeros to whole of the Zero page RAM locations (&0000 - &0FF). It will stop at first failure and report only lowest bit failed.
Once this has passed then we can use Zero page instructions (I think this is helpful to use 16-bit addresses?)

### 2. Stack RAM Test
Write to all the stack. Failure code only shows the lowest failed bit.
Once this is passed we can use Subroutines

### 3. Full Memory Test
Write & Read back whole memory from 0x200 - 0x7FFF

### 4. Interrupt tests
Not sure, maybe enable one at a time and see if we can get them to interrupt the CPU? Will need to set up a ISR


## Errors
Errors will be shown by a nibble-based ‘morse code’ system which is communicated by:

* Beeps on the speaker (needs working ULA)
* Flashing the screen Black/White (needs working ULA)
* Toggling unused bit 7 on &FE00 (would need some kind of decoder card on expansion port, but ULA could be dead)
* Toggling the Cassette Motor Relay (needs working ULA)
* Toggling the Caps Lock LED (needs working ULA)

### Encoding:
Each error code is 2 hex nibbles - 2x 4-bit codes. ‘0’ is a short flash/beep and ‘1’ is a long flash/beep

### Error codes:
0x = Failed CPU Test (maybe x is the operations that failed?)

10 = 0000 0000 = s-s-s-l s-s-s-s = Failed Zero Page RAM Test, bit 0 wrong
11 = Failed Zero Page RAM Test, bit 1 wrong
12 = Failed Zero Page RAM Test, bit 2 wrong
13 = Failed Zero Page RAM Test, bit 3 wrong
14 = Failed Zero Page RAM Test, bit 4 wrong
15 = Failed Zero Page RAM Test, bit 5 wrong
16 = Failed Zero Page RAM Test, bit 6 wrong
17 = Failed Zero Page RAM Test, bit 7 wrong

2x = Failed Stack RAM Test: x = bit (ie, 26 = Stack Fail, bit 6 wrong)

3x = 

