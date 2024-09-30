# int a[] = {1,5,3,7,2,8,9,4};
#     int len = sizeof(a) / sizeof(a[0]);
#     for (int i = 0; i < len; i++){
#         for (int j = 0; j < len - 1 - i; j++){
#             if (a[j] > a[j + 1]){
#                 int temp = a[j];
#                 a[j] = a[j + 1];
#                 a[j + 1] = temp;
#             }
#         }
#     }

.data
arr: .word 134, 234, 5464, 23, 0, 91, 90, 0, 1234, 4500, 54
len: .word 11
re : .asciiz ", "


.text

main: 
    
    la $s0, arr
    la $s1, len
    lw $s1, 0($s1)
    ori $t0, $0, 0 # i
    ori $t1, $0, 0 # j

FOR_outer:
    bge		$t0, $s1, PRINT	# if $t0 >= $s1 then goto EXIT
FOR_inner:
    addi $t8, $s1, -1
    sub $t8, $t8, $t0
    bge	    $t1, $t8, EXIT_inner
    sll $t2, $t1, 2         # offset calculation
    add $t2, $t2, $s0
    addi $t3, $t2, 4
    lw $t4, 0($t2)
    lw $t5, 0($t3)
    slt $t9, $t5, $t4
    beq $t9, $0, PASS
    sw $t5, 0($t2)
    sw $t4, 0($t3)
PASS:
    addi $t1, $t1, 1
    j FOR_inner
EXIT_inner:
    ori $t1, $0, 0
    addi $t0, $t0, 1
    j FOR_outer

PRINT:
    ori $t0, $0, 0
FOR:
    bge $t0, $s1, EXIT
    sll $t1, $t0, 2
    add $t1, $t1, $s0
    lw $a0, 0($t1)
    ori $v0, $0, 1
    syscall
    ori $v0, $0, 4
    la $a0, re
    syscall
    addi $t0, $t0, 1
    j FOR

EXIT:
    addi $v0, $0, 10
    syscall




    



