void printf(char *format, ...) {
    register char * reg_format = format;
    register int arg_ptr = 0;
    for(register char c = *reg_format; c != 0; c = *++reg_format) {
        switch(c) {
            case '%':
                c = *++reg_format;
                if(c == 0) break;

                switch(c) {
                    case 'd':
                        __print_signed_int(((int*)va_args)[arg_ptr++]);
                        break;
                    case 's':
                        __print_char_array(((char**)va_args)[arg_ptr++]);
                        break;
                    case 'c':
                        putchar(((char*)va_args)[arg_ptr++]);
                        break;
                    case 'l':
                        c = *++reg_format;
                        if(c != 'u'){
                            reg_format--;
                            __print_signed_long(((long*)va_args)[arg_ptr++]);
                        }else
                            __print_unsigned_long(((unsigned long*)va_args)[arg_ptr++]);
                        break;
                    case 'u':
                        __print_unsigned_int(((unsigned int*)va_args)[arg_ptr++]);
                        break;
                    case '%':
                        putchar('%');
                    
                }
                break;
            default:
                putchar(c);
        }
    }
}

int scanf(char *format, ...) {
    register char *reg_format = format;
    register int arg_ptr = 0;
    for(register char c = *reg_format; c != 0; c = *++reg_format) {
        switch(c) {
            case '%':
                c = *++reg_format;
                if(c==0) return arg_ptr;
                switch(c) {
                    case 'd':
                        __scan_signed_int(((int**)va_args)[arg_ptr++]);
                        break;
                    case 's':
                        __scan_char_array(((char**)va_args)[arg_ptr++], 32767);
                        break;
                    case 'c':
                        *(((char**)va_args)[arg_ptr++]) = getchar();
                        break;
                    case 'l':
                        c = *++reg_format;
                        
                        if(c != 'u') {
                            if(c==0) reg_format--;
                            __scan_signed_long(((long**)va_args)[arg_ptr++]);
                        }else{
                            __scan_unsigned_long(((unsigned long**)va_args)[arg_ptr++]);
                        }
                        break;
                    case 'u':
                        __scan_unsigned_int(((unsigned int**)va_args)[arg_ptr++]);
                        break;
                    default:
                        if(getchar() != '%') return arg_ptr;
                        if(c != getchar()) return arg_ptr;
                }
                break;
            default:
                if(c != getchar()) return arg_ptr;
                putchar(c);
        }
    }

    return arg_ptr;
}