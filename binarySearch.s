
# #include <iostream>
# using namespace std;

# int bsearch(int *A, int len, int start, int end, int val){

#     int mid = (start + end)/2;
#     if ((start == end)) return -1;
#     if (A[mid] == val) return mid;
#     else if (A[mid] < val) return bsearch(A, len, mid + 1, end, val);
#     else if (A[mid] > val) return bsearch(A, len, start, mid, val);

# }

# int main(){
#     int A[10] = {1,2,3,4,5,6,7,8,9,10};
#     for (int i = 1; i <= 10; i++){
#         cout << i << endl;
#     } 
#     cout << "got out";
#     cout << bsearch(A, 10, 0, 9, -11); 
# }

.align 2
.data
arr: .word 0, 2, 4, 5, 10, 13, 34, 56, 67, 80


.text

main:

    # loading the array

    la $s0, arr
    addi $sp, $sp, -20
    sw $s0, 16($sp)

    # loading the len

    addi $t0, $0, 10
    sw $t0, 12($sp)
    
    # loading start

    addi $t0, $0, 0
    sw $t0, 8($sp)
    
    # loading end

    addi $t0, $0, 10
    sw $t0, 4($sp)
    
    # syscall for getting value

    ori $v0, $0, 5 
    syscall

    addi $t0, $v0, 0
    sw $t0, 0($sp)

    jal binsearch

    ori $a0, $v0, 0
    ori $v0, $0, 1
    syscall

    j EXIT

binsearch:
    lw $t0, 0($sp) # value
    lw $t1, 4($sp) # end
    lw $t2, 8($sp) # start
    lw $t3, 12($sp) # len
    lw $t4, 16($sp)  # array

    addi $sp, $sp, 20

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # checking if start == end
    
    beq $t1, $t2, notFound 

    # mid

    add $s0, $t2, $t1 
    srl $s0, $s0, 1 

    # covnerting into words for retrival

    sll $t9, $s0, 2 
    add $t9, $t9, $t4
    lw $t9, 0($t9)  # A[mid]
    
    addi $sp, $sp, -4
    sw $s0, 0($sp)
    beq $t9, $t0, found
    sw $s0, 0($sp)
    addi $sp, $sp, 4

    # if not found
    slt $t8, $t9, $t0
    beq $t8, $0, greaterThan
    bne $t8, $0, lessThan


lessThan:

    addi $sp, $sp, -20

    sw $t4, 16($sp)
    
    sw $t3, 12($sp)
    
    addi $t2, $s0, 1
    sw $t2, 8($sp)
    
    sw $t1, 4($sp)
    
    sw $t0, 0($sp)

    jal binsearch

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

greaterThan:

    addi $sp, $sp, -20
    
    sw $t4, 16($sp)

    sw $t3, 12($sp)
    
    sw $t2, 8($sp)
    
    addi $t1, $s0, 0
    sw $t1, 4($sp)
    
    sw $t0, 0($sp)

    jal binsearch
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

found:
    lw $v0, 0($sp)
    addi $sp, $sp, 4
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

notFound:
    addi $v0, $0, -1
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

EXIT:
    li $v0, 10
    syscall


