
# tpt-c-compiler

A C compiler that emits TPTASM instructions specifically for [@lbphacker](https://github.com/lbphacker)'s R3 (a line of computers built in the simulation game "The Powder Toy")

The compiler is roughly based on ANSI C89 although some C features have not been implemented yet. A basic standard library is included with the compiler. Read further for the standard library documentation.

  
  

# Dependencies

### LUA 5.4
This compiler was developed and tested using Lua 5.4. You can download Lua 5.4 binaries from [here](https://sourceforge.net/projects/luabinaries/files/5.4.8/Tools%20Executables/).


<!-- ### LPEG 1.1.0
You can install this pattern matching library via luarocks or learn more about it [here](https://luarocks.org/modules/gvvaughan/lpeg) -->

  

### TPTASM 1.1.3

First install The Powder Toy's [Script Manager](https://powdertoy.co.uk/Discussions/Thread/View.html?Thread=19400) or alternatively, just install [Jacob1's Mod](https://powdertoy.co.uk/Discussions/Thread/View.html?Thread=11117) which has the Script Manager pre-installed. TPTASM can be installed by downloading it from the Script Manager.

  

### R3Plot (Recommended)

This script is not necessary but helps with configuring and generating custom R3s. Learn more about how to install and use it [here](https://github.com/LBPHacker/R316/blob/v2/manual.md#configuration).

  

Without this script, you will be confined to loading your custom programs on pre-existing R3s such as those in stamps or in saves made by others.

  

# Usage

First, you must have an R3 in the simulation area. You can either use R3Plot to generate a custom R3 (recommended) or use the original [R3 demo](https://powdertoy.co.uk/Browse/View.html?ID=3236906) save (make sure not to start it).

  

In a terminal, use cli.lua to compile your program like in the following snippet. Note that the arguments encased in brackets represent optional arguments.

  

```bash

lua cli.lua input.c [--output output.asm] [--size total-memory-size] [--term-height terminal-rows] [--term-width terminal-cols] [--offset global-offset] [--symbols symbols.json] [--breakpoints "[5, 8, 13, ...]"]

```
|Optional Argument|Description|Default value|
|-|:-:|:-:|
|\-\-output|The name of the outputted .asm file|\<input-file-name\>.asm|
|\-\-size|The total memory size in words or memory_rows * 128|2048|
|\-\-term-height|The number of character rows in the terminal|8|
|\-\-term-width|The number of character columns in the terminal|12|
|\-\-offset|The global offset of the program in memory|0|
|\-\-symbols|The file to store the symbol table in JSON format (requires dkjson)|N/A|
|\-\-breakpoints|The list of line numbers to place breakpoints in the program|"[]"|

  

This command should produce an assembly file. Keep track of the directory the file appears in and pass this file path to TPTASM using The Powder Toy's console (accessible via the keyboard shortcut "~" or the "C" icon in the GUI). Note that the R3 must be in the simulation area for the following command to work.

  

```bash

tptasm("path/to/output.asm")

```

  

Your compiled program should now be stored in the R3's memory. By turning decorations off, you can view the encoded FILT representation of your program. Now you can spark the start button (the rightmost button on the computer) and have it execute your program.

  
  

#### If you encounter any problems during the compilation process, make sure to reach out to me on [TPT's discord](https://powdertoy.co.uk/Discussions/Thread/View.html?Thread=25871) where I have the username lithium404.

# Standard Library Documentation
Many of the methods in this library have the prefix "`__`" which usually indicates that these methods are for the compiler's internal use. However, since a formal standard library is still being designed, these temporary methods can still be tremendously useful.

## `void __print_unsigned_int(int i)`
Displays an unsigned integer.
- **Parameters**
	-  `i` — The integer (interpreted as unsigned) to display
- **Returns**
	- `void`

---
	
## `void __print_signed_int(int i)`
Displays a signed integer.

- **Parameters**
	-  `i` — The integer (interpreted as signed) to display
- **Returns**
	- `void`

---

## `void putchar(char c)`

Displays a single character.

- **Parameters**
  - `c` — The character to output.
- **Returns**
  - `void`

---

## `void vscroll()`

Shifts the terminal's content upwards.

- **Parameters**
  - None.
- **Returns**
  - `void`

---

## `void hscroll()`

Shifts the terminal's content leftwards.

- **Parameters**
  - None.
- **Returns**
  - `void`

---

## `char getchar()`

Reads a single entered character.

- **Parameters**
  - None.
- **Returns**
  - The character read.

---

## `char getchar_nb()`

Reads a single entered character. Unlike `getchar()`, this function does not wait until a character is entered.

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

## `void set_colour(int background, int foreground)`

Sets the background and foreground colour. The following built-in colours are listed below

- **Parameters**
  - `background` — Background colour
  - `foreground` — Foreground colour
- **Returns**
  - `void`

| Colour Name     | Value |
|-----------------|-------|
| BLACK           | 0     |
| DARK_BLUE       | 1     |
| DARK_GREEN      | 2     |
| DARK_CYAN       | 3     |
| DARK_RED        | 4     |
| DARK_MAGENTA    | 5     |
| DARK_YELLOW     | 6     |
| GREY            | 7     |
| DARK_GREY       | 8     |
| BLUE            | 9     |
| GREEN           | 10    |
| CYAN            | 11    |
| RED             | 12    |
| MAGENTA         | 13    |
| YELLOW          | 14    |
| WHITE           | 15    |

---

## `void set_text_colour(int colour)`

Sets the foreground colour. Note that this function may also modify the background colour if the colour input parameter is greater than 15.

- **Parameters**
  - `colour` — Colour to set foreground to.
- **Returns**
  - `void`

---

## `void set_cursor(int row, int column)`

Moves the cursor to a specified position.

- **Parameters**
  - `row` — Row to move cursor to.
  - `column` — Column to move cursor to.
- **Returns**
  - `void`

---

## `void set_terminal_mode(int mode)`

Sets the terminal’s mode. The following mode settings are listed below. The semantics of these terminal modes are described [here](https://github.com/LBPHacker/R316/blob/v2/manual.md#scrollprint-sub-range-scroll-selection-and-print-character).

- **Parameters**
  - `mode` — The mode to set the terminal to.
- **Returns**
  - `void`

| Terminal Setting                 | Value |
|----------------------------------|-------|
| TERM_ENABLE_NL                   | 0x20  |
| TERM_ENABLE_TERM_MODE_SCROLL     | 0x10  |
| TERM_ENABLE_SCROLLMASK           | 0x08  |
| TERM_ENABLE_ROW_ORIENTED         | 0x04  |
| TERM_ENABLE_ENABLE_COLOUR        | 0x02  |
| TERM_ENABLE_TERM_MODE            | 0x01  |
| TERM_DEFAULT                     | 0x25  |


---

## `int get_terminal_mode()`

Retrieves the current terminal mode.

- **Parameters**
  - None.
- **Returns**
  - The current terminal mode.

---

## `void plot(int x, int y, int colour)`

Sets the colour of a pixel at the specified terminal position. The origin (0, 0) is located at the top left corner.

- **Parameters**
  - `x` — The x coordinate of the pixel.
  - `y` — The y coordinate of the pixel.
  - `colour` — The colour value of the pixel.
- **Returns**
  - `void`

---

## `void __send_raw(int value, int location)`

Stores the value `value` at the address represented by `location`.
This method is mostly only used for debugging or for efficient manipulation of the terminal.

- **Parameters**
  - `value` — Value to store.
  - `location` — Location to store the value at.
- **Returns**
  - `void`

---

## `void __set_zero_char(int left_low, int left_high, int right_low, int right_high)`

Uses 4 16 bit values to construct an 8x8 bitmap for the 0th character.

- **Parameters**
  - `left_low` — The 2 even columns on the left side of the bitmap.
  - `left_high` — The 2 odd columns on the left side of the bitmap.
  - `right_low` — The 2 even columns on the right side of the bitmap.
  - `right_high` — The 2 odd columns on the right side of the bitmap.
- **Returns**
  - `void`

---

## `void __print_char_array(char* str)`

Displays a null-terminated array of characters.

- **Parameters**
  - `str` — Pointer to a character array.
- **Returns**
  - `void`

---

## `void set_hrange(int minimum_column, int maximum_column)`

Sets the horizontal range of the scrollprint. Note that the origin is at the top left corner.

- **Parameters**
  - `minimum_column` — The lowest inclusive column in the scrollprint
  - `maximum_column` — The highest inclusive column in the scrollprint
- **Returns**
  - `void`

---

## `void set_vrange(int minimum_row, int maximum_row)`

Sets the vertical range of the scrollprint. Note that the origin is at the top left corner.

- **Parameters**
  - `minimum_row` — The lowest inclusive row in the scrollprint
  - `maximum_row` — The highest inclusive row in the scrollprint
- **Returns**
  - `void`

---

# Inline Assembly
The Powder Toy Compiler provides basic support for inline assembly. The following EBNF-like pseudocode describes how to use this feature.

```
asm(
    { <string-literal> }*
    [: <inputs>]
    [: <outputs>]
    [: <clobbers>]
    );
```

The inline assembly statement consists of the `asm` keyword followed by a pair of parentheses containing the body of the statement.
The statement body begins with zero or more assembly instructions in the form of string literals. Note that the compiler does not parse these instructions and instead simply copies them into the output assembly file. Additionally, three distinct kinds of optional operands are available that help to integrate the assembly snippet within the encompassing program.

The inputs operand defines which variables (if any) should be copied into which registers. It takes the form of a list of register names assigned to variables accessible in the current scope. The compiler will ensure that the contents of the variables are copied to their corresponding registers.

The outputs operand defines which variables (if any) should receive the output of the inline assembly statement. Like the input operand, it consists of a list of registers assigned to variables accessible in the current scope.

The clobbers operand allows the compiler to preserve a set of registers. The registers are specified in a list.

### Example Usage
```c
    int double_word_low = 0xffff, double_word_high = 0x8001;
    int result;
    asm(
        "exhs r3, r0, r2"
        "adds r3, r1"
        :r1=double_word_low, r2=double_word_high
        :r3=result
        :r1, r2, r3
    );
  ```