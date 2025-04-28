.globl main 
.equ STDOUT, 1
.equ STDIN, 0
.equ __NR_READ, 63
.equ __NR_WRITE, 64
.equ __NR_EXIT, 93
.equ NEWLINE, 10
.equ CANARY, 0x534B5254

.text
main:
    # main() prolog WITH CANARY
    addi sp, sp, -28
    li t0, CANARY               # load canary value
    sw t0, 24(sp)               # store canary at 24
    sw ra, 20(sp)
    
    # main() body
    la a0, prompt
    call puts
    
    mv a0, sp
    call gets
    
    mv a0, sp
    call puts
    
    # main() epilog WITH CANARY CHECK
    lw t0, 24(sp)
    li t1, CANARY               # load expected canary
    bne t0, t1, canary_fail     # bne, jump to fail
    lw ra, 20(sp)               # restore ra
    addi sp, sp, 28
    li s1, 8
    ret

canary_fail:
    li s1, 7
    li a0, 0
    li a7, __NR_EXIT
    ecall

.space 12288

sekret_fn:
    addi sp, sp, -4
    sw ra, 0(sp)
    la a0, sekret_data
    call puts
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

##############################################################
# Add your implementation of puts() and gets() below here
##############################################################

# reads a single character from stdin, returns ASCII
getchar:
# prolog
    addi sp, sp, -4             # space for 1 word
    sw x0, 0(sp)                # clear memory location of sp

# body
    li a0, STDIN                # a0 = STDIN
    addi a1, sp, 0              # a1 = addr of sp
    li a2, 1                    # a2 = 1 byte
    li a7, __NR_READ            # a7 = __NR_READ
    ecall

# epilog
    lw a0, 0(sp)                # restore a0
    addi sp, sp, 4              # restore stack
    ret



# writes char to STDOUT
putchar:
# prolog
    addi sp, sp, -1             # space for 1 word
    sb a0, 0(sp)                # store a0 in sp

# body
    li a0, STDOUT               # a0 = STDOUT
    addi a1, sp, 0              # a1 = addr of sp
    li a2, 1                    # a2 = 1 byte
    li a7, __NR_WRITE           # a7 = __NR_WRITE
    ecall

# epilog
    lbu a0, 0(sp)               # restore a0
    addi sp, sp, 1              # restore stack
    ret



# read line from STDIN into buffer pointed by s, returns bytes read
gets:
# prolog
    addi sp, sp, -12            # space for 3 items on stack
    sw ra, 8(sp)                # save ra on stack
    sw a0, 4(sp)                # save addr of buf (s) on stack

# body
    mv t0, a0                   # t0 = addr of buf (from a0)
    
gets_loop:
    sw t0, 0(sp)                # save t0 to stack
    call getchar
    lw t0, 0(sp)                # restore t0 from stack

    bltz a0, gets_exit          # if EOF, exit

    sb a0, 0(t0)                # t0 = a0
    addi t0, t0, 1              # incr buf pointer

    # if != NEWLINE, continue
    li t1, NEWLINE              # t1 = newline
    bne a0, t1, gets_loop       # if a0 != t1, loop again

    # if == NEWLINE, replace w/ NULL
    sb zero, -1(t0)             # store NULL at end

    # get length of string
    lw a0, 4(sp)                # a0 = buf addr
    sub a0, t0, a0              # a0 = t0 - buf (str length)

# epilog
gets_exit:
    lw ra, 8(sp)                # restore ra
    addi sp, sp, 12             # restore sp
    ret



# write string s to STDOUT, followed by NEWLINE
puts:
# prolog
    addi sp, sp, -8             # space for 2 items on stack
    sw ra, 4(sp)                # save ra to stack

# body
    mv t0, a0                   # t0 = addr of string

puts_loop:
    lb a0, 0(t0)                # a0 = byte at t0
    beqz a0, puts_exit          # if null, exit

    sw t0, 0(sp)                # save t0 to stack
    call putchar
    lw t0, 0(sp)                # restore t0 from stack

    addi t0, t0, 1              # incr str ptr
    bltz a0, puts_exit          # If a0 < 0, exit
    j puts_loop

# epilog
puts_exit:
    li a0, NEWLINE              # a0 = NEWLINE
    call putchar

    li a0, 0                    # a0 = 0 on success
    lw ra, 4(sp)                # restore ra
    addi sp, sp, 8              # restore stack
    ret



.data
prompt:   .ascii  "Enter a message: "
prompt_end:

.word 0
sekret_data:
.word 0x73564753, 0x67384762, 0x79393256, 0x3D514762, 0x0000000A
