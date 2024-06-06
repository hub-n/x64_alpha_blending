section .text
    global f

; Function: f
; Arguments:
;   rdi - pointer to image1 pixel array
;   rsi - pointer to image2 pixel array
;   rbx - pointer to result image pixel array
;   rcx - image1 width
;   r8 - image1 height
;   r9 - image2 width
;   r10 - image2 height
;   r11 - circle center x coordinate
;   r12 - circle center y coordinate
; Returns:
;   void

f:
    push rbp
	mov	rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rbx, rdx

    mov r10, [rbp+16]
    mov r11, [rbp+24]
    mov r12, [rbp+32]

;   r12 - current x
;   r13 - current y
    mov r12, -1
    mov r13, 0

begin:
    inc r12

;   alpha to r15d
    cvtsi2ss xmm0, r12d      ; convert current x to float and store in xmm0
    mov eax, [rbp+24]
    cvtsi2ss xmm1, eax      ; convert circle x to float and store in xmm1
    cvtsi2ss xmm2, r13d      ; convert current y to float and store in xmm2
    mov eax, [rbp+32]
    cvtsi2ss xmm3, eax      ; convert circle y to float and store in xmm3

    subps xmm1, xmm0           ; xmm1 = x2 - x1
    subps xmm3, xmm2           ; xmm3 = y2 - y1

;   Square the differences
    mulps xmm1, xmm1           ; xmm1 = (x2 - x1)^2
    mulps xmm3, xmm3           ; xmm3 = (y2 - y1)^2

;   Add the squared differences
    addps xmm1, xmm3

;   Calculate square root
    sqrtss xmm1, xmm1
    cvtss2si eax, xmm1

;   calculate alpha
    xor edx, edx
    mov r14, 16
    idiv r14
    mov eax, 8
    cmp eax, edx
    jl reverse

    mov eax, edx
    mov r14, 255
    mul r14
    shr eax, 3

    jmp set_alpha

reverse:
    sub edx, 8
    mov eax, edx
    mov r14, 255
    mul r14
    shr eax, 3
    mov r14d, 255
    sub r14d, eax
    mov eax, r14d

set_alpha:
    mov r15d, eax
    shl r15d, 24

;   check range
    mov r10, [rbp+16]
    cmp r13, r10
    jge next

blend_alpha:
;   get image2 pixel to r11d
    mov rax, r13
    mul r9
    mov r14, r12
    add r14, rax
    shl r14, 2
    mov r11d, [rsi+r14]
;   set image2 alpha
    ;mov eax, 0x80000000
    and r11d, 0x00FFFFFF
    add r11d, r15d
    mov [rsi+r14], r11d

;   get image1 pixel to r10d
    mov rax, r13
    mul rcx
    mov r14, r12
    add r14, rax
    shl r14, 2
    mov r10d, [rdi+r14]

calculate_r:
;   calculate 255 - alpha2
    mov r15d, r11d
    and r15d, 0xFF000000
    shr r15d, 24
    mov r14, 255
    sub r14d, r15d
    mov rax, r14

;   calculate R1 * (255 - alpha2)
    mov r15d, r10d
    and r15d, 0x000000FF
    mul r15
    mov r14, rax

;   calculate R2 * alpha2
    mov r15d, r11d
    and r15d, 0xFF000000
    shr r15d, 24
    mov rax, r15

    mov r15d, r11d
    and r15d, 0x000000FF
    mul r15
    mov r15, rax

;   calculate new R
    add r14, r15
    shr r14, 8
    and r10d, 0xFFFFFF00
    add r10d, r14d

calculate_g:
;   calculate 255 - alpha2
    mov r15d, r11d
    and r15d, 0xFF000000
    shr r15d, 24
    mov r14, 255
    sub r14d, r15d
    mov rax, r14

;   calculate G1 * (255 - alpha2)
    mov r15d, r10d
    and r15d, 0x0000FF00
    shr r15d, 8
    mul r15
    mov r14, rax

;   calculate G2 * alpha2
    mov r15d, r11d
    and r15d, 0xFF000000
    shr r15d, 24
    mov rax, r15

    mov r15d, r11d
    and r15d, 0x0000FF00
    shr r15d, 8
    mul r15
    mov r15, rax

;   calculate new G
    add r14, r15
    shr r14, 8
    and r10d, 0xFFFF00FF
    shl r14d, 8
    add r10d, r14d

calculate_b:
;   calculate 255 - alpha2
    mov r15d, r11d
    and r15d, 0xFF000000
    shr r15d, 24
    mov r14, 255
    sub r14d, r15d
    mov rax, r14

;   calculate B1 * (255 - alpha2)
    mov r15d, r10d
    and r15d, 0x00FF0000
    shr r15d, 16
    mul r15
    mov r14, rax

;   calculate B2 * alpha2
    mov r15d, r11d
    and r15d, 0xFF000000
    shr r15d, 24
    mov rax, r15

    mov r15d, r11d
    and r15d, 0x00FF0000
    shr r15d, 16
    mul r15
    mov r15, rax

;   calculate new B
    add r14, r15
    shr r14, 8
    and r10d, 0xFF00FFFF
    shl r14d, 16
    add r10d, r14d

    ;mov r10d, 0xFFFFFFFF
    mov r14, r12
    mov r15, r13
    jmp set_pixel

next:
    mov r10, r12
    add r10, r13
    mov r11, rcx
    add r11, r8
    sub r11, 2
    cmp r10, r11
    je end

    mov r15, rcx
    sub r15, 1
    cmp r12, r15
    jne begin

    mov r12, -1
    inc r13
    jmp begin

; Function: set_pixel
; Arguments:
;   r10d - new pixel value
;   r14 - pixel x coordinate
;   r15 - pixel y coordinate
; Returns:
;   void
set_pixel:
    mov rax, r15
    mul rcx
    add r14, rax
    shl r14, 2
    mov [rbx+r14], r10d
    mov r14, 0
    jmp next

end:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
