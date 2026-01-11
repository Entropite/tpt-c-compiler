
# tpt-c-compiler

A C compiler that emits TPTASM instructions specifically for [@lbphacker](https://github.com/lbphacker)'s R3 (a line of computers built in the simulation game "The Powder Toy")

The compiler is roughly based around ANSI C89 although some C features have not been implemented yet. A basic standard library is included with the compiler. Read further for the standard library documentation.

  
  

# Dependencies

### LPEG 1.1.0
You can install this pattern matching library via luarocks or learn more about it [here](https://luarocks.org/modules/gvvaughan/lpeg)

  

### TPTASM 1.1.3

First install The Powder Toy's [Script Manger](https://powdertoy.co.uk/Discussions/Thread/View.html?Thread=19400) or alternatively, just install [Jacob1's Mod](https://powdertoy.co.uk/Discussions/Thread/View.html?Thread=11117) which has the Script Manager pre-installed. TPTASM can be installed by downloading it from the Script Manager.

  

### R3Plot (Recommended)

This script is not necessary but helps with configuring and generating custom R3s. Learn more about how to install and use it [here](https://github.com/LBPHacker/R316/blob/v2/manual.md#configuration).

  

Without this script, you will be confined to loading your custom programs on pre-existing R3s such as those in stamps or in saves made by others.

  

# Usage

First, you must have an R3 in the simulation area. You can either use R3Plot to generate a custom R3 (recommended) or use the original [R3 demo](https://powdertoy.co.uk/Browse/View.html?ID=3236906) save (make sure not to start it).

  

In a terminal, use cli.lua to compile your program like in the following snippet. Note that the arguments encased in brackets represent optional arguments.

  

```bash

lua cli.lua input.c [--output output.asm] [--size total-memory-size]

```
|Optional Argument|Description|Default value|
|-|:-:|:-:|
|\-\-output|The name of the outputted .asm file|\<input-file-name\>.asm
|\-\-size|The total memory size in words or memory_rows * 128|2048|
|\-\-offset|The global offset of the program in memory|0
  

This command should produce an assembly file. Keep track of the directory the file appears in and pass this directory to TPTASM using The Powder Toy's console (accessible via the keyboard shortcut "~" or the "C" icon in the GUI). Note that the R3 must be in the simulation area for the following command to work.

  

```bash

tptasm("path/to/output.asm")

```

  

Your compiled program should now be stored in the R3's memory. By turning decorations off, you can view the encoded FILT representation of your program. Now you can spark the start button (the rightmost button on the computer) and have it execute your program.

  
  

#### If you encounter any problems during the compilation process, make sure to reach out to me on [TPT's discord](https://powdertoy.co.uk/Discussions/Thread/View.html?Thread=25871) where I have the username lithium404.

# Standard Library Documentation
Many of the methods in this library have the prefix "`--`" which usually indicates that these methods are for the compiler's internal use. However, since a formal standard library is still being designed, these temporary methods can still be tremendously useful.

## `void __print_unsigned_int(int i)`
Displays an unsigned integer.
- **Parameters**
	-  `i` — The integer (interpreted as unsigned) to display
- **Returns**
	- `void`
	
## `void __print_signed_int(int i)`
Displays a signed integer.

- **Parameters**
	-  `i` — The integer (interpreted as signed) to display
- **Returns**
	- `void`

## `void putchar(char c)`

Displays a single character.

- **Parameters**
  - `c` — The character to output.
- **Returns**
  - `void`

---

## `char getchar()`

Reads a single inputted character.

- **Parameters**
  - None.
- **Returns**
  - The character read.

---

## `void __scan_unsigned_int(int* out)`

Reads an unsigned integer from the input and stores it in the provided integer

- **Parameters**
  - `out` — Address of the integer to store the result in
- **Returns**
  - `void`

---

## `void set_colour(int value)`

Sets the text colour.

- **Parameters**
  - `value` — Encoded colour value.
- **Returns**
  - `void`

---

## `void set_cursor(int position)`

Moves the cursor to a specified position.

- **Parameters**
  - `position` — Encoded cursor position.
- **Returns**
  - `void`

---

## `void __send_raw(int value, int location)`

Stores the value 'value' at the address represented by 'location'.
This method is mostly only used for debugging or for efficient manipulation of the terminal.

- **Parameters**
  - `value` — Value to store
  - `location` — Location to store the value at
- **Returns**
  - `void`

---

## `void __set_zero_char(int left_low, int left_high, int right_low, int right_high)`

Uses 4 16 bit values to construct an 8x8 bitmap for the 0th character.

- **Parameters**
  - `left_low` — The 2 even columns on the left side of the bitmap
  - `left_high` — The 2 odd columns on the right side of the bitmap 
  - `right_low` — The 2 even columns on the right side of the bitmap
  - `right_low` — The 2 odd columns on the right side of the bitmap
- **Returns**
  - `void`

---

## `void __print_char_array(char* str)`

Displays a null-terminated array of characters.

- **Parameters**
  - `str` — Pointer to a character array.
- **Returns**
  - `void`

