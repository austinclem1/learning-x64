%include "../lib.inc"

global _start

%define pc r15
%define w r14
%define rstack r13

%define previous 0
%macro native 2
native %1, %2, 0
%endmacro

%macro native 3
section .data
w_%2:
    dq previous
    db %1, 0
    db %3
xt_%2:
    dq %2_impl

%define previous w_%2

section .text
%2_impl:

%endmacro

%macro colon 2
colon %1, %2, 0
%endmacro

%macro colon 3
w_%2:
    dq previous
    db %1, 0
    db %3
xt_%2: dq docol_impl
%define previous w_%2
%endmacro

section .bss
resq 1023
rstack_start: resq 1
input_buf: resb 1024

user_mem: resq 0xFFFF

section .data
program_stub: dq xt_main
xt_interpreter: dq .interpreter
.interpreter: dq _start.loop

section .text


; Aritmetic

native '+', plus
    pop rax
    add rax, [rsp]
    mov [rsp], rax
    jmp next

native '-', minus
    pop rax
    pop rcx
    sub rcx, rax
    push rcx
    jmp next

native '*', multiply
    pop rax
    pop rdx
    mul rdx
    push rax
    jmp next

native '/', divide
    pop rcx
    pop rax
    xor rdx, rdx
    div rcx
    push rax
    jmp next


; Comparisons

native '<', less_than
    mov rcx, [rsp]
    mov rax, [rsp + 8]
    xor rdx, rdx
    cmp rax, rcx
    setl dl
    push rdx
    jmp next

native "<=", less_or_eq
    mov rcx, [rsp]
    mov rax, [rsp + 8]
    xor rdx, rdx
    cmp rax, rcx
    setle dl
    push rdx
    jmp next

native '=', equal
    mov rcx, [rsp]
    mov rax, [rsp + 8]
    xor rdx, rdx
    cmp rax, rcx
    sete dl
    push rdx
    jmp next

native ">=", greater_or_eq
    mov rcx, [rsp]
    mov rax, [rsp + 8]
    xor rdx, rdx
    cmp rax, rcx
    setge dl
    push rdx
    jmp next

native '>', greater
    mov rcx, [rsp]
    mov rax, [rsp + 8]
    xor rdx, rdx
    cmp rax, rcx
    setg dl
    push rdx
    jmp next


; Boolean Logic

native "and", and
    pop rax
    pop rcx
    test rax, rax
    mov rax, 0
    setnz al
    test rcx, rcx
    mov rcx, 0
    setnz cl
    and rax, rcx
    push rax
    jmp next

native "or", or
    pop rax
    pop rcx
    test rax, rax
    mov rax, 0
    setnz al
    test rcx, rcx
    mov rcx, 0
    setnz cl
    or rax, rcx
    push rax
    jmp next

native "xor", xor
    pop rax
    pop rcx
    test rax, rax
    mov rax, 0
    setnz al
    test rcx, rcx
    mov rcx, 0
    setnz cl
    xor rax, rcx
    push rax
    jmp next

native "not", not
    pop rax
    test rax, rax
    mov rax, 0
    setz al
    push rax
    jmp next


; Stack Manipulation

native "rot", rot
    pop rdx
    pop rcx
    pop rax
    push rcx
    push rdx
    push rax
    jmp next

native "swap", swap
    pop rcx
    pop rax
    push rcx
    push rax
    jmp next

native "dup", dup
    mov rax, [rsp]
    push rax
    jmp next

native "drop", drop
    add rsp, 8
    jmp next

native ".", pop
    pop rdi
    call print_int
    call print_newline
    jmp next

native ".S", print_stack
    mov rdi, '<'
    call print_char
    mov rdi, rbp
    sub rdi, rsp
    sar rdi, 3
    call print_uint
    mov rdi, '>'
    call print_char
    mov rdi, ' '
    call print_char
    lea rcx, [0 + rbp - 8] ; address of first value on stack
.loop:
    cmp rcx, rsp
    jb .end
    mov rdi, [rcx]
    push rcx
    call print_int
    mov rdi, ' '
    call print_char
    pop rcx
    sub rcx, 8
    jmp .loop
.end:
    call print_newline
    jmp next

; native "init", init
;     mov rstack, rstack_start
;     mov pc, main_stub
;     jmp next

native "docol", docol
    sub rstack, 8
    mov [rstack], pc
    add w, 8
    mov pc, w
    jmp next

native "exit", exit
    mov pc, [rstack]
    add rstack, 8
    jmp next


; I/O

native "key", key
    call read_char
    movzx rcx, al
    push rcx
    jmp next

native "emit", emit
    pop rdi
    call print_char
    call print_newline
    jmp next

native "number", number
    mov rdi, input_buf
    mov rsi, 1024
    call read_word
    mov rdi, rax
    call parse_int
    push rax
    jmp next

native "!", store
    pop rax ; data to store
    pop rdi ; dest address
    mov [rdi], rax
    jmp next

native "c!", store_char
    pop rax ; data to store
    pop rdi ; dest address
    mov byte [rdi], al
    jmp next

native "@", fetch
    pop rax
    mov rax, [rax]
    push rax
    jmp next

native "c@", fetch_char
    pop rax
    mov al, byte [rax]
    and rax, 0xFF
    push rax
    jmp next

native "mem", mem
    mov rax, user_mem
    push rax
    jmp next

native "word", word
    pop rdi
    mov rsi, 1024
    call read_word
    push rdx
    jmp next

native "prints", prints
    pop rdi
    call print_string
    jmp next

native "bye", bye
    mov rax, 60
    xor rdi, rdi
    syscall

native "inbuf", inbuf
    push qword input_buf
    jmp next

colon "main", main
    dq xt_number
    dq xt_number
    dq xt_plus
    dq xt_exit

last_word: dq w_main

; The inner interpreter. These three lines
; fetch the next instruction and start its
; execution
next:
    mov w, [pc]
    add pc, 8
    jmp [w]

_start:
    mov rbp, rsp
    mov rstack, rstack_start
.loop:
    mov rdi, input_buf
    mov rsi, 1024
    call read_word
    test rdx, rdx ; if stdin was empty, end
    jz .end
    mov rdi, input_buf
    call find_word
    test rax, rax ; if word wasn't found, see if it's a literal
    jz .try_push_literal
    mov rdi, rax
    call cfa
    mov [program_stub], rax
    mov pc, program_stub
    jmp next
.try_push_literal:
    mov rdi, input_buf
    call parse_int
    push rax
    jmp .loop
.end:
    mov rax, 60
    xor rdi, rdi
    syscall


; args:
; rdi = string for forth word
;
; return:
; rax = word header start address, or 0 if not found
find_word:
    mov rsi, last_word
.loop:
    mov rsi, [rsi]
    test rsi, rsi
    jz .end        ; we tested all headers without finding a match
    add rsi, 8     ; address of header string is header start + 8
    push rdi
    call str_cmp
    pop rdi
    sub rsi, 8     ; bump back to header start
    test rax, rax
    jz .loop       ; if strings didn't match continue searching
                   ; otherwise this is the result
.end:
    mov rax, rsi
    ret

; args:
; rdi = header start
; return:
; rax = execution token address of header
cfa:
    add rdi, 8 ; address of header string
skip_string_loop:
    mov al, byte [rdi]
    inc rdi
    test al, al
    jnz skip_string_loop
    ; skipped string, now skip flags byte
    inc rdi
    mov rax, rdi
    ret


section .data
no_exist: db "Don't exist", 0
