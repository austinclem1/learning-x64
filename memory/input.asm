%define O_RDONLY 0

%define PROT_READ   0x1
%define PROT_WRITE  0x2
%define PROT_EXEC   0x4
%define PROT_NONE   0x0

%define MAP_PRIVATE 0x2

%include "../lib.inc"

section .data
    filename: db "input.txt", 0
    str_true: db "true", 0
    str_false: db "false", 0
    str_colon: db ": ", 0
    str_factorial_of: db "Factorial of ", 0
    str_is_prime: db " is prime: ", 0
    str_sum_digits: db "Sum of digits ", 0
    str_fib_of: db "Fibonacci of ", 0
    str_is_fib: db " is Fibonacci number: ", 0

    str_buffer_too_small: db "Buffer wasn't long enough", 0

section .text
global _start
_start:
    ; sub rsp, 256

    ; mov rdi, rsp
    ; mov rsi, str_true
    ; mov rdx, 256
    ; call read_word_str
    ; mov rdi, str_buffer_too_small
    ; test rax, rax
    ; cmovnz rdi, rax
    ; call print_string
    ; call print_newline

    ; mov rdi, rsp
    ; mov rsi, str_false
    ; mov rdx, 256
    ; call read_word_str
    ; mov rdi, str_buffer_too_small
    ; test rax, rax
    ; cmovnz rdi, rax
    ; call print_string
    ; call print_newline

    ; mov rdi, rsp
    ; mov rsi, str_factorial_of
    ; mov rdx, 256
    ; call read_word_str
    ; mov rdi, str_buffer_too_small
    ; test rax, rax
    ; cmovnz rdi, rax
    ; call print_string
    ; call print_newline
    sub rsp, 8

    ; open file
    mov rax, 2
    mov rdi, filename
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall

    ; mmap
    mov r8, rax ; file descriptor
    mov rax, 9  ; sys mmap
    xor rdi, rdi ; no preferred starting address
    mov rsi, 4096 ; region size
    mov rdx, PROT_READ ;protection flags
    mov r10, MAP_PRIVATE ; utility flags
    xor r9, r9 ; offset in file
    syscall
    mov [rsp], rax

    mov rdi, str_factorial_of
    call print_string
    mov rdi, [rsp]
    push rdi
    call parse_uint
    pop rdi
    add rdi, rdx
    mov [rsp], rdi
    mov rdi, rax
    push rdi
    call print_uint
    mov rdi, str_colon
    call print_string
    pop rdi
    call factorial
    mov rdi, rax
    call print_uint
    call print_newline

    ;exit
    mov rax, 60
    xor rdi, rdi
    syscall


factorial:
    mov rax, rdi
.loop:
    cmp rdi, 1
    jle .end
    dec rdi
    xor rdx, rdx
    mul rdi
    jmp .loop
.end:
    ret


is_prime:
    cmp rdi, 2
    jl .not_prime
    je .prime
    mov rax, rdi
    xor rdx, rdx
    mov rsi, 2
    div rsi
    mov rsi, rax ; holds the highest divisor we will test against
    test rdx, rdx
    jz .not_prime ; if input was evenly divisible by 2, it's not prime
    mov rcx, 3    ; otherwise start by trying 3 as a divisor, and testing other odd numbers
.loop:
    cmp rcx, rsi
    jge .prime   ; if we made it to the max trial divisor without finding a factor, input is prime
    xor rdx, rdx
    mov rax, rdi
    div rcx
    test rdx, rdx
    jz .not_prime ; if input was evenly divisible, it's not prime
    add rcx, 2
.not_prime:
    mov rax, 1
    ret
.prime:
    xor rax, rax
    ret
