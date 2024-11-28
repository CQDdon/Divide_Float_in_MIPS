#===================================
# LUU Y KHI SU DUNG GITHUB
# Tao branch rieng de code, khong code tren branch main
# Truoc khi code, phai git pull origin main ve branch cua minh, de khong bi lech lich su commit
# Khong duoc push truc tiep len main, phai push ben branch cua ban than, sau do thong bao cho thanh vien con lai de kiem tra roi moi merge pull request
# Khuyen khich viet description cho pull request 
#===================================

#Chuong trinh: BTL de 4
.include "macro.mac" 
# Data segment 
.data 
# Cac dinh nghia bien 
mau: .space 4 
tu: .space 4 
tenfile: .asciiz "FLOAT2.BIN" 
fdescr: .word 0 

result: .word 0

# Cac cau nhac nhap/xuat du lieu 
str_loi: .asciiz "Mo file bi loi." 
div0: .asciiz "Error: Division by zero\n"
#----------------------------------- 
# Code segment 
 .text 
#----------------------------------- 
# Chuong trinh chinh 
#----------------------------------- 
main: 
# Nhap (syscall) 
# Xu ly 
    # mo file doc 
    la $a0,tenfile 
    addi $a1,$zero,0 #a1=0 (read only)
    addi $v0,$zero,13 
    syscall 
    bgez $v0,tiep 
    baoloi: #puts str_loi #mo file bi loi 
    addi $v0,$zero,4 # puts str_loi 
    la $a0, str_loi
    syscall
    j Kthuc 
tiep: sw $v0,fdescr #luu file descriptor 
    # doc file 
    # 4 byte dau 
    lw $a0,fdescr 
    la $a1,mau 
    addi $a2,$zero,4 
    addi $v0,$zero,14 
    syscall 
    # 4 byte sau 
    la $a1,tu 
    addi $a2,$zero,4 
    addi $v0,$zero,14 
    syscall 
    # dong file 
    lw $a0,fdescr 
    addi $v0,$zero,16 
    syscall 

    #===================================
    # Dua du lieu tu dang nhi phan ve IEEE 754
    # Truoc tien, ta lay sign bang cach dich phai 31 bit
    lw $a0, mau
    jal extractSign
    move $s1, $v0
    
    jal extractExponent
   	move $s3, $v0
    
    jal extractMantissa
    move $s5, $v0
    
    # Lam tuong tu voi tu so    
    lw $a0, tu
    jal extractSign
    move $s2, $v0
    jal extractExponent
    move $s4, $v0
    jal extractMantissa
    move $s6, $v0
    
    
    xor	$s0, $s1, $s2
    
	move $a0, $s5
	move $a1, $s6
	jal DivisionAlgorithm
	andi $v0, $v0, 0x007fffff # xoa bit an
	
	
	sub $s3, $s3, $s4
    addi $s3, $s3, 127   
    sub $s3, $s3, $v1          
	sll $s3, $s3, 23
	or $s0, $s0, $s3 
		
	or $s0, $s0, $v0
	sw $s0, result
	
	lwc1	$f12,result
  	addi	$v0,$zero,2
  	syscall
	
    #===================================

#ket thuc chuong trinh (syscall)
Kthuc:	
    addi $v0,$zero,10
	syscall
# -------------------------------	
# Cac chuong trinh khac

### Print a float to screen
### Input  : $a0 -> 32-bit float
### Output : None
writeFloat:
   mtc1 $a0, $f12    # Move the input to $f12
   li $v0, 2         # Syscall code for printing float
   syscall
   jr $ra

### Extract the sign bit of the float
### Input  : $a0 -> 32-bit float
### Output : $v0 -> 1 if the float is negative, 0 otherwise
extractSign:
    srl $v0, $a0, 31  # Extract the sign bit (MSB)
    jr $ra
   
### Extract the biased exponent field of the float
### Input  : $a0 -> 32-bit float
### Output : $v0 -> Biased exponent (8 bits)
extractExponent:
	srl $v0, $a0, 23  
    andi $v0, $v0, 0xFF
    jr $ra
   
### Extract the fraction field of the float
### Input  : $a0 -> 32-bit float
### Output : $v0 -> Fraction (23 bits)
extractMantissa:
    li $t0, 0x007FFFFF  # Bit mask for fraction (23 bits)
    and $v0, $a0, $t0
    ori  $v0, 0x800000
    jr $ra


DivisionAlgorithm:
    addi $sp, $sp, -12      # T?o kh�ng gian tr�n stack �? l�u d? li?u
    sw $s0, 0($sp)          # L�u gi� tr? c? c?a $s0 v�o stack
    sw $ra, 4($sp)          # L�u �?a ch? tr? v? ($ra) v�o stack
    sw $s1, 8($sp)          # L�u gi� tr? c? c?a $s1 v�o stack


    move $t0, $a0           # $t0 nh?n gi� tr? mantissa c?a s? b? chia (dividend)
    move $t1, $a1           # $t1 nh?n gi� tr? mantissa c?a s? chia (divisor)

    add $s0, $0, $0         # $s0 (quotient) kh?i t?o b?ng 0
    add $v1, $0, $0         # $v1 kh?i t?o 0 (v? tr� d?u th?p ph�n ban �?u)
    li $t8, 0               # $t8 kh?i t?o 0 (bi?n �?m s? l?n l?p)

	
loop:   
    bgtu $t8, 23, check     # L?p 24 l?n (t?i �a s? bit mantissa)
    addi $t8, $t8, 1        # T�ng b? �?m v?ng l?p
    sub $t0, $t0, $t1       # $t0 = $t0 - $t1 (th? tr? s? chia)
    sll $s0, $s0, 1         # D?ch tr�i $s0 (��ng k? quotient)
    slt $t2, $t0, $0        # $t2 = ($t0 < 0)? 1 : 0
    bne $t2, $0, else       # N?u $t0 < 0 (th? sai), nh?y t?i else
    addi $s0, $s0, 1        # �?t bit LSB c?a $s0 th�nh 1 (chia ��ng)
    j out

else:   
    add $t0, $t0, $t1       # Kh�i ph?c gi� tr? $t0 (do th? sai)

out:    
    sll $t0, $t0, 1         # D?ch tr�i $t0 (chu?n b? cho bit ti?p theo)
    j loop                  # Quay l?i �?u v?ng l?p


check:  
    slt $t2, $a0, $a1       # N?u dividend < divisor, c?n chu?n h�a
    beq $t2, $0, exit       # N?u dividend >= divisor, nh?y t?i exit
    move $a0, $s0           # L�u quotient v�o $a0
    jal Normalization       # G?i h�m chu?n h�a
    j return


exit:   
    move $v0, $s0           # $v0 ch?a k?t qu? mantissa

return: 
    lw $ra, 4($sp)          # Kh�i ph?c gi� tr? $ra
    lw $s0, 0($sp)          # Kh�i ph?c gi� tr? $s0
    lw $s1, 8($sp)          # Kh�i ph?c gi� tr? $s1
    addi $sp, $sp, 8        # Gi?i ph�ng stack
    jr $ra          #Return	
	
	
Normalization:
    lui $t0, 0x0040         # $t0 = 0x40 (�?t bit th? 23 th�nh 1)
    addi $t2, $0, 1         # Kh?i t?o b? �?m d?ch (s? l?n d?ch)

loop2:  
    and $t1, $a0, $t0       # Ki?m tra bit 23 c?a dividend
    bne $t1, $0, else2      # N?u bit 23 = 1, tho�t kh?i v?ng l?p
    addi $t2, $t2, 1        # T�ng b? �?m d?ch
    sll $a0, $a0, 1         # D?ch tr�i dividend
    j loop2

else2:  
    sll $a0, $a0, 1         # D?ch th�m 1 l?n �? �?t bit 24 = 1
    move $v0, $a0           # L�u mantissa �? chu?n h�a v�o $v0
    move $v1, $t2           # L�u s? l?n d?ch (v? tr� d?u th?p ph�n) v�o $v1
    jr $ra                  # Quay l?i

# -------------------------------
