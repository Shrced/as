
// The program applies the Caesar cipher (with a specified shift) to the input lines of the stdin and outputs then to the file.
//
// Specified shift and path to file are set by the environment variables(SHIFT and OUTPUT).
//-------------------------------------

// x20 - shift
// x21 - file descriptor
// x22 - const '\n'
// x23 - const '\0'
// x24 - filename

        .arch armv8-a

        .data
mes1:
        .string  "Enter the lines (end input with ctrl+D):\n"
        .equ    mes1len, .-mes1
mes2:
        .string  "File exists. Rewrite(Y/N)?\n"
        .equ    mes2len, .-mes2
buf:
        .skip   10
        .equ    buflen, .-buf

        .text
        .align 2
        .global _start
        .type   _start, %function
_start:
        mov     x21, #0         // file descriptor
        mov     x22, '\n'
        mov     x23, '\0'
        // find SHIFT and OUTPUT
        bl      getenv
        cmp     x0, #-7         // bad env variables
        beq     write_error
// x0 - shift, x1 - output filename
// Shift from string to int
        mov     x24, x1         // save x1 (output filename)
        bl      getshift
        cmp     x0, #-22        // bad shift
        beq     write_error
        mov     x20, x0         // shift in int format from 0-25
// Creating or overwriting file
        mov     x1, x24         // restore x1
        mov     x0, #-100
        mov     x2, #0xc1       // O_CREAT | O_EXCL | O_WRONLY
        mov     x3, #0600
        mov     x8, #56
        svc     #0
        cmp     x0, #-17        // if this file doens't exists go to 3f
        bne     3f
        mov     x0, #1
        adr     x1, mes2
        mov     x2, mes2len
        mov     x8, #64
        svc     #0
        mov     x0, #0
        adr     x1, buf
        mov     x2, #3
        mov     x8, #63
        svc     #0
        cmp     x0, #2
        beq     1f
        mov     x0, #-17
        b       write_error
1:
        adr     x1, buf
        ldrb    w0, [x1]
        cmp     w0, 'Y'
        beq     2f
        cmp     w0, 'y'
        beq     2f
        mov     x0, #-17
        b       write_error
2:                              // rewrite
        mov     x0, #-100
        mov     x1, x24         // filename
        mov     x2, #0x201      // O_CREAT | O_WRONLY | O_TRUNC
        mov     x3, #0600
        mov     x8, #56
        svc     #0
3:
        cmp     x0, #0
        blt     write_error
        mov     x21, x0         // descriptor saved to x21
        mov     x9, #1          // x9 - if this buf is the last for this line
        // mes1, enter lines
        mov     x0, #1
        adr     x1, mes1
        mov     x2, mes1len
        mov     x8, #64
        svc     #0
// Main cycle
1:
        mov     x0, #0
        adr     x1, buf
        mov     x2, buflen
        mov     x8, #63
        svc     #0
        cmp     x0, #0
        mov     x3, x0
        ble     exit1           // last line
        adr     x1, buf
        add     x0, x0, x1
        ldrb    w0, [x0, #-1]
        cmp     w0, '\n'
        bne     notlast
        mov     x9, #1          // last word in line
notlast:
        mov     x9, #0
        mov     x1, x20
        adr     x2, buf
        mov     x4, #0
        mov     x5, #0
L0:                             // delete first ' ' and '\t'
        cmp     x4, x3
        beq     1b              // nothing to write, go to next buf
        ldrb    w0, [x2, x4]
        add     x4, x4, #1
        cmp     w0, ' '
        beq     L0
        cmp     w0, '\t'
        beq     L0
        sub     x4, x4, #1
        mov     x6, #1          // new word has began
L1:                             // read and shift
        // x0 - current symbol
        // x1 - shift
        // x2 - buf
        // x3 - length of readed line
        // x4 - iterator for input
        // x5 - iterator for output
        // x6 - indicator if word
        cmp     x4, x3
        beq     WRITE
        ldrb    w0, [x2, x4]
        add     x4, x4, #1
        cmp     w0, ' '
        beq     3f
        cmp     w0, '\t'
        beq     3f
        mov     x6, #1
        bl      shift
2:
        strb    w0, [x2, x5]
        add     x5, x5, #1
        b       L1
3:
        cbz     x6, L1
        mov     x6, #0
        mov     w0, ' '
        b       2b
WRITE:                          // writes 1 buf
        cbz     x9, 5f
        // delete last ' '
        sub     x5, x5, #2
        ldrb    w0, [x2, x5]
        cmp     w0, ' '
        bne     6f              // if a == ' ' then a = '\n'
        strb    w22, [x2, x5]
        add     x5, x5, #1
        b       5f
6:
        add     x5, x5, #2
5:
        mov     x0, x21
        mov     x1, x2
        mov     x2, x5
        mov     x8, #64
        svc     #0
        cmp     x0, #0
        blt     write_error
        b       1b
write_error:
        bl      writeerr
        cmp     x21, #0
        bne     exit1
        mov     x0, #1
        b       exit2
exit1:
        mov     x0, x21
        mov     x8, #57
        svc     #0
        mov     x0, #0
exit2:
        mov     x8, #93
        svc     #0

        .size   _start, .-_start

        .type writeerr, %function
        .data
usage:
        .string "Usage error, set enviroment variables: SHIFT=12 and OUTPUT=output.txt\n"
        .equ    usagelen, .-usage
permission:
        .string "Permission denied\n"
        .equ    permissionlen, .-permission
exist:
        .string "File already exist\n"
        .equ    existlen, .-exist
isdir:
        .string "Is a directory\n"
        .equ    isdirlen, .-isdir
unknown:
        .string "Unknown error\n"
        .equ    unklen, .-unknown
invalidargument:
        .string "Invalid argument\n"
        .equ    invalidargumentlen, .-invalidargument

        .text
        .align 2
writeerr:
        cmp x0, #-7
        bne 0f
        adr x1, usage
        mov x2, usagelen
        b   5f
0:
        cmp x0, #-13
        bne 1f
        adr x1, permission
        mov x2, permissionlen
        b   5f
1:
        cmp x0, #-17
        bne 2f
        adr x1, exist
        mov x2, existlen
        b   5f
2:
        cmp x0, #-21
        bne 3f
        adr x1, isdir
        mov x2, isdirlen
        b   5f
3:
        cmp x0, #-22
        bne 4f
        adr x1, invalidargument
        mov x2, invalidargumentlen
        b   5f
4:
        adr x1, unknown
        mov x2, unklen
5:
        mov x0, #2
        mov x8, #64
        svc #0
        ret
        .size   writeerr, .-writeerr

        .type   getshift, %function

        // x0 - addres of input shift
        // x1 - current symbol
        // x2 - flag if minus
        // x3 - number
        // x4 - count of symbols
        // x5 - iterator from x4 to 0(or 1 if minus)
        // x6 - 10 in the power of x4-x5-1

        // x7 - number 10
        // x8 - number 26

        // return x0 - shift from 0 to 25

        .text
        .align  2
getshift:
        mov     x1, #0          // clear bits from 32-63
        mov     x3, #0
        ldrb    w1, [x0]
        cmp     w1, #45         // if minus x2 = 1, else 0
        cset    x2, eq
        // go to the end of number and count symbols
        mov     x4, #0
1:
        add     x4, x4, #1
        ldrb    w1, [x0, x4]
        cmp     w1, #0
        bne     1b
        sub     x8, x4, x2
        cmp     x8, #18         // if this is a number, its too big
        bgt     3f
        // get the shift value
        mov     x5, x4
        mov     x6, #1
        mov     x7, #10         // just 10 for mul
        mov     x8, #26
2:
        cmp     x5, x2
        beq     4f
        sub     x5, x5, #1
        ldrb    w1, [x0, x5]
        //check if it a number (from 48 - 57 ascii code)
        cmp     w1, #48
        blt     3f
        cmp     w1, #57
        bgt     3f
        //
        sub     x1, x1, #48
        madd    x3, x6, x1, x3  // number += t * s[i]
        mul     x6, x6, x7      // t = t*10
        b       2b
3:
        mov     x0, #-22        // invalid argument
        b       5f
4:
        udiv    x4, x3, x8
        msub    x0, x4, x8, x3  // mod of shift from 0-25
        cmp     x2, #1
        bne     5f
        sub     x0, x8, x0      // if shift negative x0 = 26 - x0
        cmp     x0, #26         // if x0 was zero, x0 = 26 -> x0 = 0
        csel    x0, xzr, x0, eq
5:
        ret

        .size   getshift, .-getshift

        .type   shift, %function

        // x0  - symbol
        // x1  - shift

        .text
        .align 2
shift:
        cmp     w0, 'A'
        blt     3f
        cmp     w0, 'Z'
        blt     1f
        cmp     w0, 'a'
        blt     3f
        cmp     w0, 'z'
        bgt     3f
        // a - z
        add     w0, w0, w1
        cmp     w0, 'z'
        b       2f
1:      // A - Z
        add     w0, w0, w1
        cmp     w0, 'Z'
2:
        ble     3f
        sub     w0, w0, #26
3:
        ret
        .size   shift, .-shift

        .type   getenv, %function
        .data

var1:
        .asciz     "SHIFT="
var2:
        .asciz     "OUTPUT="

        // sp
        // return x0 - adress of SHIFT      // also adress for env
        //        x1 - adress of OUTPUT     // also adress in word (env)
        //        x2 - adress of var1
        //        x3 - adress of var2
        //        x4 - symbol of var1
        //        x5 - symbol of var2
        //        x6 - curremt symbol of enviromental value
        //        x7 - temp for var1
        //        x8 - temp for var2


        .text
        .align  2
getenv:
        mov     x0, sp              // Adress for env variables
        mov     x7, #0
        mov     x8, #0
0:
        // to the env variables
        ldr     x1, [x0], #8
        cmp     x1, #0
        bne     0b
1:
        ldr     x1, [x0], #8
        adr     x2, var1
        adr     x3, var2
        cmp     x1, #0              // check if it is 0
        beq     err
        ldrb    w6, [x1], #1
        ldrb    w4, [x2], #1
        ldrb    w5, [x3], #1
        cmp     w6, w4
        bne     3f
        // check if it is var1
2:
        ldrb    w6, [x1], #1
        ldrb    w4, [x2], #1
        cmp     w6, w4
        bne     1b
        cmp     w6, '='             // yes it is var1
        bne     2b
        mov     x7, x1
        b       5f                  // find var2
3:
        cmp     w6, w5
        bne     1b
        // check if it is var2
4:
        ldrb    w6, [x1], #1
        ldrb    w5, [x3], #1
        cmp     w6, w5
        bne     1b
        cmp     w6, '='             // yes it is var1
        bne     4b
        mov     x8, x1
        b       7f
5:                                  // var1 found, find var2
        ldr     x1, [x0], #8
        adr     x3, var2
        cmp     x1, #0              // check if it is 0
        beq     err
6:
        ldrb    w6, [x1], #1
        ldrb    w5, [x3], #1
        cmp     w6, w5
        bne     5b
        cmp     w6, '='
        bne     6b
        mov     x0, x7
        b       9f                  // out, x6 -> x0 var1 adr, x1 - var2 adr
7:                                  // var2 found, find var1
        ldr     x1, [x0], #8
        adr     x2, var1
        cmp     x1, #0              // check if it is 0
        beq     err
8:
        ldrb    w6, [x1], #1
        ldrb    w4, [x2], #1
        cmp     w6, w4
        bne     7b
        cmp     w6, '='
        bne     8b
        mov     x0, x8
        b       9f
err:
        mov     x0, #-7
9:
        ret
        .size   getenv, .-getenv
