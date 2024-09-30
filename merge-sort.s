.align 2
.data

arr: .word 600, 500, 400, 300, 200, 100
len: .word 6
re : .asciiz ", "
arr_sorted: .space 3


.text

main:
    la $a0, arr
    la $t0, len
    la $a3, arr_sorted
    lw $s0, 0($t0)
    addi $a1, $0, 0
    addi $a2, $s0, 0
    jal merge
    j PRINT

merge:
    addi $t0, $a1, 0        # i = start
    add $t9, $a1, $a2
    srl $t2, $t9, 1        
    addi $t1, $t2, 0        # mid
    addi $t2, $a2, 0        # end
    addi $sp, $sp, -12
    sw $a1, 0($sp)
    sw $a2, 4($sp)
    sw $ra, 8($sp)
    addi $t8, $0, 1
    sub $t9, $t2, $t1    # end - mid == 1
    beq $t8, $t9, BASE_1_1 # when end - mid == 1 and mid - start = 1/0 goes to the base cases

NO_RETURN:
    addi $sp, $sp, -12
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)

    add $a2, $t1, $0
    jal merge
    lw $t1, 4($sp)
    lw $t2, 8($sp)

    add $a1, $t1, $0
    add $a2, $t2, $0
    jal merge
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    addi $sp, $sp, 12

    lw $a2, 4($sp)    # this is the end
    lw $a1, 0($sp)    # this is the start
    add $t3, $t1, $0  # a variable for j
    sub $t6, $t0, $t2  # start - end = end - start
    addi $t6, $t6, -1
    sll $t6, $t6, 2
    add $sp, $sp, $t6  # for the merged array
    addi $t4, $sp, 0   # offset for stack pointer adderess

WHILE_BOTH:
    slt $t9, $t0, $t1
    slt $t8, $t3, $a2
    and $t7, $t9, $t8
    beq $t7, $0, WHILE_I

    sll $t8, $t0, 2
    add $t8, $t8, $a0
    sll $t9, $t3, 2
    add $t9, $t9, $a0
    lw $t5, 0($t8)
    lw $t6, 0($t9)

    slt $t7, $t5, $t6  # a[j] > a[i]
    beq $t7, $0, ELSE 
    sw $t5, 0($t4)
    addi $t0, $t0, 1
    addi $t4, $t4, 4
    j WHILE_BOTH
ELSE:
    sw $t6, 0($t4)
    addi $t3, $t3, 1
    addi $t4, $t4, 4
    j WHILE_BOTH
WHILE_I:
    slt $t9, $t0, $t1
    beq $t9, $0, WHILE_J
    sll $t8, $t0, 2
    add $t8, $t8, $a0
    lw $t5, 0($t8)
    sw $t5, 0($t4)
    addi $t0, $t0, 1
    addi $t4, $t4, 4
    j WHILE_I
WHILE_J:
    slt $t8, $t3, $a2
    beq $t8, $0, TRANSFER
    sll $t9, $t3, 2
    add $t9, $t9, $a0
    lw $t6, 0($t9)
    sw $t6, 0($t4)
    addi $t3, $t3, 1
    addi $t4, $t4, 4
    j WHILE_J
TRANSFER:
    addi $t9, $a1, 0
T_FOR:
    slt $t7, $t9, $a2
    beq $t7, $0, RETURN_f
    sll $t8, $t9, 2
    add $t8, $a0, $t8
    lw $t6, 0($sp)
    sw $t6, 0($t8)
    addi $t9, $t9, 1
    addi $sp, $sp, 4
    j T_FOR

BASE_1_1:
    addi $t8, $0, 1
    sub $t7, $t1, $t0
    beq $t7, $0, RETURN    # returns when mid - start == 0 and end - mid == 1

    sll $t8, $t0, 2
    sll $t9, $t1, 2
    add $t9, $a0, $t9
    add $t8, $a0, $t8

    lw $t5, 0($t8)
    lw $t6, 0($t9)
    slt $t7, $t6, $t5
    beq $t7, $0, RETURN
    sw $t5, 0($t9)
    sw $t6, 0($t8)
    j RETURN

RETURN:
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra
RETURN_f:
    addi $sp, $sp, 4
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra
PRINT:
    ori $t0, $0, 0
    addi $t2, $a0, 0
FOR:
    bge $t0, $s0, EXIT
    sll $t1, $t0, 2
    add $t1, $t1, $t2
    lw $a0, 0($t1)
    ori $v0, $0, 1
    syscall
    ori $v0, $0, 4
    la $a0, re
    syscall
    addi $t0, $t0, 1
    j FOR
EXIT:
ori $v0, $0, 10
syscall
    
