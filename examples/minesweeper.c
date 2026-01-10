char board[8][12];

char __scan_signed_int(int *num) {
    // Register variables can be more efficiently accessed and updated than local variables
    register char c;
    register int res = 0;
    register int sign = 1;
    if((c = getchar()) == '-') {
        sign = -1;
    }else{
        sign = 1;
        res = c - '0';
    }
    putchar(c);
    while((c = getchar()) >= '0' && c <= '9') {
        putchar(c);
        res = res * 10 + (c - '0');
    }

    if(sign == -1) {
        res = -res;
    }

    *num = res;
    return c;
}
int has_mine[8][12];
int is_interior[8][12] = {{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0}, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}};
int digit_colour[9] = {0x77, 0x79, 0x72, 0x7c, 0x71, 0x74, 0x76, 0x75, 0x78};
int revealed_cells = 0;
int row_map[96] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7};

void show_bombs() {
    for(register int i = 0; i < 8; i++) {
        for(register int j = 0; j < 12; j++) {
            if(has_mine[i][j] >= 9) {
                set_cursor((i << 5) + j);
                set_colour(0x4f);
                __set_zero_char(0x4e99, 0xcf7e, 0x7eff, 0x997e);
                putchar((char)0);
            }
        }
    }
}

void sweep_cell(int rowin, int colin) {
    register int row = rowin;
    register int col = colin;
    if(has_mine[row][col] >= 9) {
        show_bombs();
        set_cursor(0);
        set_colour(0x04);
        __print_char_array("Kaboom! You lose!");
        while(1) {}
    }

    int stack[192];
    register int *stack_pointer = stack;
    register int revealed_in_sweep = 0;
    stack_pointer[0] = row;
    stack_pointer[1] = col;
    stack_pointer += 2;
    while((int)stack_pointer > (int)stack) {
        row = stack_pointer[-2];
        col = stack_pointer[-1];
        stack_pointer -= 2;

        register int num_mines = has_mine[row][col];

        register int temp_char = num_mines + '0';
        board[row][col] = temp_char;
        set_cursor((row << 5) + col);
        set_colour(digit_colour[num_mines]);
        putchar(temp_char);
        revealed_in_sweep++;

        if(num_mines == 0) {
            register int row_minus_one = row - 1;
            register int col_minus_one = col - 1;
            register int row_plus_one = row + 1;
            register int col_plus_one = col + 1;
            // Verbosity is for optimization reasons
            // Macros would greatly help here
            // Checks for interior cells (hot path)
            if(is_interior[row][col]) {
                if(board[row_minus_one][col_minus_one] == 0 || board[row_minus_one][col_minus_one] == 'F') {
                    board[row_minus_one][col_minus_one] = 0x10;
                    stack_pointer[0] = row_minus_one;
                    stack_pointer[1] = col_minus_one;
                    stack_pointer += 2;
                }
                if(board[row_minus_one][col_plus_one] == 0 || board[row_minus_one][col_plus_one] == 'F') {
                    board[row_minus_one][col_plus_one] = 0x10;
                    stack_pointer[0] = row_minus_one;
                    stack_pointer[1] = col_plus_one;
                    stack_pointer += 2;
                }
                if(board[row_plus_one][col_minus_one] == 0 || board[row_plus_one][col_minus_one] == 'F') {
                    board[row_plus_one][col_minus_one] = 0x10;
                    stack_pointer[0] = row_plus_one;
                    stack_pointer[1] = col_minus_one;
                    stack_pointer += 2;
                }
                if(board[row_plus_one][col_plus_one] == 0 || board[row_plus_one][col_plus_one] == 'F') {
                    board[row_plus_one][col_plus_one] = 0x10;
                    stack_pointer[0] = row_plus_one;
                    stack_pointer[1] = col_plus_one;
                    stack_pointer += 2;
                }
                if(board[row][col_minus_one] == 0 || board[row][col_minus_one] == 'F') {
                    board[row][col_minus_one] = 0x10;
                    stack_pointer[0] = row;
                    stack_pointer[1] = col_minus_one;
                    stack_pointer += 2;
                }
                if(board[row][col_plus_one] == 0 || board[row][col_plus_one] == 'F') {
                    board[row][col_plus_one] = 0x10;
                    stack_pointer[0] = row;
                    stack_pointer[1] = col_plus_one;
                    stack_pointer += 2;
                }
                if(board[row_plus_one][col] == 0 || board[row_plus_one][col] == 'F') {
                    board[row_plus_one][col] = 0x10;
                    stack_pointer[0] = row_plus_one;
                    stack_pointer[1] = col;
                    stack_pointer += 2;
                }
                if(board[row_minus_one][col] == 0 || board[row_minus_one][col] == 'F') {
                    board[row_minus_one][col] = 0x10;
                    stack_pointer[0] = row_minus_one;
                    stack_pointer[1] = col;
                    stack_pointer += 2;
                }
            }else{
                if(row > 0) {
                    if(col > 0 && (board[row_minus_one][col_minus_one] == 0 || board[row_minus_one][col_minus_one] == 'F')) {
                        board[row_minus_one][col_minus_one] = 0x10;
                        stack_pointer[0] = row_minus_one;
                        stack_pointer[1] = col_minus_one;
                        stack_pointer += 2;
                    }
                    if(col < 11 && (board[row_minus_one][col_plus_one] == 0 || board[row_minus_one][col_plus_one] == 'F')) {
                        board[row_minus_one][col_plus_one] = 0x10;
                        stack_pointer[0] = row_minus_one;
                        stack_pointer[1] = col_plus_one;
                        stack_pointer += 2;
                    }
                    if(board[row_minus_one][col] == 0 || board[row_minus_one][col] == 'F') {
                        board[row_minus_one][col] = 0x10;
                        stack_pointer[0] = row_minus_one;
                        stack_pointer[1] = col;
                        stack_pointer += 2;
                    }
                }
            
                if(row < 7) {
                    if(col > 0 && (board[row_plus_one][col_minus_one] == 0 || board[row_plus_one][col_minus_one] == 'F')) {
                        board[row_plus_one][col_minus_one] = 0x10;
                        stack_pointer[0] = row_plus_one;
                        stack_pointer[1] = col_minus_one;
                        stack_pointer += 2;
                    }
                    if(col < 11 && (board[row_plus_one][col_plus_one] == 0 || board[row_plus_one][col_plus_one] == 'F')) {
                        board[row_plus_one][col_plus_one] = 0x10;
                        stack_pointer[0] = row_plus_one;
                        stack_pointer[1] = col_plus_one;
                        stack_pointer += 2;
                    }
                    if(board[row_plus_one][col] == 0 || board[row_plus_one][col] == 'F') { 
                        board[row_plus_one][col] = 0x10;
                        stack_pointer[0] = row_plus_one;
                        stack_pointer[1] = col;
                        stack_pointer += 2;
                    }
                }
                if(col > 0 && (board[row][col_minus_one] == 0 || board[row][col_minus_one] == 'F')) {
                    board[row][col_minus_one] = 0x10;
                    stack_pointer[0] = row;
                    stack_pointer[1] = col_minus_one;
                    stack_pointer += 2;
                }
                if(col < 11 && (board[row][col_plus_one] == 0 || board[row][col_plus_one] == 'F')) {
                    board[row][col_plus_one] = 0x10;
                    stack_pointer[0] = row;
                    stack_pointer[1] = col_plus_one;
                    stack_pointer += 2;
                }
            }
        }
    }

    revealed_cells += revealed_in_sweep;
}

void add_to_surrounding_cells(int rowin, int colin, int n) {
    register int row = rowin;
    register int col = colin;
    register int row_minus_one = row - 1;
    register int col_minus_one = col - 1;
    register int row_plus_one = row + 1;
    register int col_plus_one = col + 1;
    if(row > 0) {
        if(col > 0) {
            has_mine[row_minus_one][col_minus_one] += n;
        }
        has_mine[row_minus_one][col] += n;
        if(col < 11) {
            has_mine[row_minus_one][col_plus_one] += n;
        }
    }
    if(col > 0) {
        has_mine[row][col_minus_one] += n;
    }
    if(col < 11) {
        has_mine[row][col_plus_one] += n;
    }
    if(row < 7) {
        if(col > 0) {
            has_mine[row_plus_one][col_minus_one] += n;
        }
        has_mine[row_plus_one][col] += n;
        if(col < 11) {
            has_mine[row_plus_one][col_plus_one] += n;
        }
    }
}

int main() {
    
    has_mine[0][0] = 9;
    register int has_mine_base = (int)has_mine;
    int num;
    __print_char_array("Enter a\nnumber to\nhelp\nrandomize\n(1-100): ");
    __scan_signed_int(&num);
    register int rnum = -num;
    
    putchar('\n');
    set_colour(0x88);
    __print_char_array("            ");
    set_cursor(0xA0);
    set_colour(0x22);

    for(register int i = 0; i < 12; i++) {
        rnum ^= (rnum + 1) << 3;
        rnum ^= rnum >> 5;
        rnum ^= rnum << 2;
        register int candidate = rnum & 127;
        while(candidate >= 96 || ((int*)(has_mine_base + candidate))[0] >= 9) {
            rnum ^= (rnum + 1) << 3;
            rnum ^= rnum >> 5;
            rnum ^= rnum << 2;
            candidate = rnum & 127;
        }

        ((int*)(has_mine_base + candidate))[0] = 9;
        // update has_mine map
        register int row = row_map[candidate];
        register int col = candidate - row * 12;
        register int row_minus_one = row - 1;
        register int col_minus_one = col - 1;
        register int row_plus_one = row + 1;
        register int col_plus_one = col + 1;

        // Optimized away function call to add_to_surrounding_cells()
        if(row > 0) {
            if(col > 0) {
                has_mine[row_minus_one][col_minus_one] += 1;
            }
            has_mine[row_minus_one][col] += 1;
            if(col < 11) {
                has_mine[row_minus_one][col_plus_one] += 1;
            }
        }
        if(col > 0) {
            has_mine[row][col_minus_one] += 1;
        }
        if(col < 11) {
            has_mine[row][col_plus_one] += 1;
        }
        if(row < 7) {
            if(col > 0) {
                has_mine[row_plus_one][col_minus_one] += 1;
            }
            has_mine[row_plus_one][col] += 1;
            if(col < 11) {
                has_mine[row_plus_one][col_plus_one] += 1;
            }
        }
        putchar('.');
    }
    has_mine[0][0] -= 9;
    set_cursor(0);
    set_colour(0x7f);
    __set_zero_char(0x81ff, 0x8181, 0x8181, 0xff81);
    for(register int i = 0; i < 8; i++) {
        __send_raw(0, 0x9F80 + 0x24);
    }

    set_cursor(0);
    register int row = 0;
    register int col = 0;
    register int is_first_sweep = 1;
    while(1) {
        set_cursor((row << 5) + col);
        set_colour(0x09);
        register char board_char = board[row][col];
        if(board_char == 'F') {
            __set_zero_char(0x7000, 0x7000, 0x70, 0x7f);
            putchar((char)0);
        } else if(board_char == 0) {
            __set_zero_char(0x81ff, 0x8181, 0x8181, 0xff81);
            putchar((char)0);
        } else if(board_char == 'B') {
            __set_zero_char(0x4e99, 0xcf7e, 0x7eff, 0x997e);
            putchar((char)0);
        } else {
            if(board_char != '0') {
                putchar(board_char);
            } else {
                set_colour(0x90);
                putchar(' ');
            }
        }
        register int c = getchar();
        set_cursor((row << 5) + col);
        
        if(board_char == 'F') {
            set_colour(0x4f);
            __set_zero_char(0x7000, 0x7000, 0x70, 0x7f);
            putchar((char)0);
        } else if(board_char == 0) {
            set_colour(0x7f);
            __set_zero_char(0x81ff, 0x8181, 0x8181, 0xff81);
            putchar((char)0);
        } else if(board_char == 'B') {
            set_colour(0x4f);
            __set_zero_char(0x4e99, 0xcf7e, 0x7eff, 0x997e);
            putchar((char)0);
        } else {
            set_colour(digit_colour[board_char - '0']);
            putchar(board_char);
        }
        
        if(c == 'a' && col > 0) {
            col = col - 1;
        }else if(c == 'd' && col < 11) {
            col = col + 1;
        } else if(c == 'w' && row > 0) {
            row = row - 1;
        }else if(c == 's' && row < 7) {
            row = row + 1;
        }else if(c == 'f') {
            if(board[row][col] == 'F') {
                board[row][col] = (char)0;
            }else if(board[row][col] == 0) {
                board[row][col] = 'F';
            }
        }else if(c == 10 || c == 'r') {
            if(is_first_sweep) {
                if(has_mine[row][col] >= 9) {
                    has_mine[row][col] -= 9;
                    add_to_surrounding_cells(row, col, -1);
                }
                is_first_sweep = 0;
            }
            sweep_cell(row, col);
            if(revealed_cells >= 84) {
                set_cursor(0);
                set_colour(0x02);
                __print_char_array("You win!");
                return 0;
            }
        }
    }
}