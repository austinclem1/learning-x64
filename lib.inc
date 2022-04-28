section .data
whitespace: db ` \t\r\n`, 0
my_test: db "0", 0

section .text


exit:
    mov rax, 60
    syscall


string_length:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .end
    inc rax
    jmp .loop
.end:
    ret


print_string:
    push rdi
    call string_length
    pop rdi
    mov rsi, rdi ; string address
    mov rdx, rax ; string length
    mov rdi, 1 ; stdout file descriptor
    mov rax, 1 ; write syscall number
    syscall
    ret


print_char:
    dec rsp
    mov [rsp], dil
    mov rsi, rsp ; pointer to char on stack
    mov rdx, 1   ; string length
    mov rdi, 1   ; stdout file descriptor
    mov rax, 1   ; write syscall number
    syscall
    inc rsp
    ret


print_newline:
    dec rsp
    mov byte [rsp], 0x0A ; newline
    mov rsi, rsp    ; pointer to char on stack
    mov rdx, 1      ; string length
    mov rdi, 1      ; stdout file descriptor
    mov rax, 1      ; write syscall number
    syscall
    inc rsp
    ret


print_uint:
    mov rax, rdi ; put number to print in rax so we can divide it
    mov rsi, 10 ; for division later
    xor rcx, rcx ; will hold current index of string buffer (and length)
.loop:
    xor rdx, rdx ; must be zero to get correct division result
                 ; will also hold remainder after dividing by 10
    idiv rsi ; div rax (input num) by 10
    dec rsp
    add rdx, '0'
    mov [rsp], dl
    inc rcx
    test rax, rax ; if quotient is now zero, we're done
    jz .end
    jmp .loop

.end:
    mov rsi, rsp ; print from string buffer on stack
    mov rdx, rcx ; string length
    mov rdi, 1 ; stdout file descriptor
    mov rax, 1 ; write syscall number
    push rcx
    syscall
    pop rcx
    add rsp, rcx ; deallocate buffer on stack
    ret


print_int:
    xor r8, r8 ; this will hold a value indicating whether original input num was negative
    test rdi, rdi
    jns .skip_negate
    neg rdi
    mov r8, -1
.skip_negate:
    mov rax, rdi ; put number to print in rax so we can divide it
    mov rsi, 10 ; for division later
    xor rcx, rcx ; will hold current index of string buffer (and length)
.loop:
    xor rdx, rdx ; must be zero to get correct division result
                 ; will also hold remainder after dividing by 10
    div rsi ; div rax (input num) by 10
    dec rsp
    add rdx, '0'
    mov [rsp], dl
    inc rcx
    test rax, rax ; if quotient is now zero, we're done
    jz .end
    jmp .loop

.end:
    ; if original number was negative, put minus sign here
    test r8, r8
    jns .not_negative
    dec rsp
    mov byte [rsp], '-'
    inc rcx
.not_negative:
    mov rsi, rsp ; print from string buffer on stack
    mov rdx, rcx ; string length
    mov rdi, 1 ; stdout file descriptor
    mov rax, 1 ; write syscall number
    push rcx
    syscall
    pop rcx
    add rsp, rcx ; deallocate buffer on stack
    ret


read_char:
    dec rsp
    mov rax, 0 ; syscall number: read
    mov rdi, 0
    mov rsi, rsp ; read to stack
    mov rdx, 1 ; read one byte
    syscall
    test rax, rax
    mov rax, 0 ; if read syscall read greater than 0 bytes, return the char, else return 0
    jz .done
    mov al, [rsp]
.done:
    inc rsp
    ret


is_whitespace:
    xor rcx, rcx
.loop:
    cmp byte [whitespace + rcx], 0
    je .false
    cmp dil, [whitespace + rcx]
    je .true
    inc rcx
    jmp .loop
.true:
    mov rax, -1
    ret
.false:
    xor rax, rax
    ret


read_word:
    sub rsp, 16
    xor rcx, rcx
    xor rdx, rdx
    cmp rsi, 1 ; if buffer length is zero or one, end early
    jle .end
    mov [rsp + 8], rsi ; dest buffer size
    mov [rsp], rdi ; dest buffer address
.eat_whitespace_loop:
    push rcx
    call read_char
    pop rcx
    test rax, rax
    jz .end ; if we reach end of stream here, end early and return 0
    mov rdi, rax
    push rdi
    push rcx
    call is_whitespace
    pop rcx
    pop rdi
    test rax, rax
    jnz .eat_whitespace_loop
    mov rax, [rsp]
    mov [rax], dil
    inc rcx
.loop:
    xor rax, rax
    cmp rcx, [rsp + 8]
    jge .end
    push rcx
    call read_char
    pop rcx
    test rax, rax
    jz .add_null_byte
    mov rdi, rax
    push rdi
    push rcx
    call is_whitespace
    pop rcx
    pop rdi
    test rax, rax
    jnz .add_null_byte
    mov rax, [rsp]
    mov byte [rax + rcx], dil
    inc rcx
    jmp .loop
.out_of_space:
    xor rax, rax
    jmp .end
.add_null_byte:
    mov rax, [rsp]
    mov byte [rax + rcx], 0
.end:
    mov rdx, rcx
    add rsp, 16
    ret


read_word_str:
    cmp rdx, 1 ; if buffer length is zero or one, end early
    jle .out_of_space
    dec rdx
    xor rax, rax
.eat_whitespace_loop:
    mov al, byte [rsi]
    test rax, rax
    jz .add_null_byte ; if we reach end of string here, end early
    push rdi
    mov rdi, rax
    call is_whitespace
    pop rdi
    test rax, rax
    inc rsi
    jnz .eat_whitespace_loop
    xor rcx, rcx
.loop:
    mov al, byte [rsi + rcx]
    test rax, rax
    jz .add_null_byte
    push rdi
    push rcx
    push rax
    mov rdi, rax
    call is_whitespace
    test rax, rax
    pop rax
    pop rcx
    pop rdi
    jnz .add_null_byte
    cmp rcx, rdx ; see if we still have space in dest buffer
    jge .out_of_space
    mov byte [rdi + rcx], al
    inc rcx
    jmp .loop
.out_of_space:
    xor rax, rax
    jmp .end
.add_null_byte:
    mov rax, rdi
    mov byte [rdi + rcx], 0
.end:
    ret


parse_uint:
    push rbx
    xor rax, rax
    mov rbx, 10
    xor rcx, rcx
    xor rsi, rsi
.loop:
    mov sil, [rdi + rcx]
    test sil, sil
    jz .end
    cmp sil, '0'
    jl .end
    cmp sil, '9'
    jg .end
    sub sil, '0'
    mul rbx
    add al, sil
    inc rcx
    jmp .loop
.end:
    mov rdx, rcx
    pop rbx
    ret


parse_int:
    dec rsp
    mov al, [rdi]
    cmp al, '-'
    sete [rsp]
    mov rcx, 1
    jne .not_negative
    inc rdi
    mov rcx, -1
.not_negative:
    push rcx
    call parse_uint
    pop rcx
    mov dil, [rsp]
    add dl, dil
    push rdx
    mul rcx
    pop rdx
    inc rsp
    ret


string_equals:
    xor rcx, rcx
    mov rax, 1
    cmp rdi, rsi
    je .end
.loop:
    mov dl, byte [rdi + rcx]
    cmp dl, byte [rsi + rcx]
    sete al
    jne .end
    test dl, dl
    jz .end
    inc rcx
    jmp .loop
.end:
    ret


string_copy:
    xor rcx, rcx
.loop:
    xor rax, rax
    cmp rcx, rdx
    jge .end
    mov r8b, [rdi + rcx]
    test r8b, r8b
    jz .add_null_byte
    mov [rsi + rcx], r8b
    inc rcx
    jmp .loop
.add_null_byte:
    mov byte [rsi + rcx], 0
    mov rax, rdi
.end:
    ret
