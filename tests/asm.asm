format ELF64 executable 3

wstack_len = 1024*4  ; 4 kio


;;; Common doc
;
;; Stacks
; wstack: stack of pointers to the system stack
; dstack: stack of program's data
;
;; Registers
; rax: return value and scratch register
; rbx: pointer to the top of wstack
; rdx: dereference of rbx, points to the dstack


; reg: bytes to push
; --
; none
macro zoc_push_qword reg* {
        push reg
        sub rbx, 8
        mov qword [rbx], rsp
}

; none
; --
; reg: bytes popped
macro zoc_pop_qword reg* {
        mov rdx, qword [rbx]
        mov reg, qword [rdx]
        add rbx, 8
}


macro zoc_dup {
        mov rax, qword [rbx]
        zoc_push_qword rax
}

macro zoc_drop {
        add rbx, 8
}

macro zoc_swap {
        mov rax, qword [rbx]
        mov rcx, qword [rbx + 8]
        mov qword [rbx], rcx
        mov qword [rbx + 8], rax
}

; id: the number identifier of the function
; ret_bytes: the number of bytes is takes to store the return type
; --
; none
macro zoc_call_fn id*, ret_bytes {
        ; Reserve space for the return value
        sub rsp, ret_bytes
        call fn_#id
}

; id: the number identifier of the function
; --
; none
macro zoc_fn id* {
fn_#id:
        push rbp
        mov rbp, rsp
}

; none
; --
; none
macro zoc_ret {
        ;; Return to caller
        mov rsp, rbp
        pop rbp
        ret
}

; none
; --
; none
macro zoc_ret_qword {
        ;; Move the return value to its position
        mov rdx, qword [rbx]  ; rdx may already contain [rbx] (fasm detects is)
        mov rax, qword [rdx]
        mov qword [rbp + 16], rax
        ; Overwrite the now obsolete wstack TOS
        mov rax, rbp
        add rax, 16
        mov qword [rbx], rax

        zoc_ret
}

macro zoc_add_qword {
        zoc_pop_qword rax
        mov rdx, qword [rbx]
        add qword [rdx], rax
}

macro zoc_syscall argc* {
        zoc_pop_qword rax
        if argc >= 1
            zoc_pop_qword rdi
        end if
        if argc >= 2
            zoc_pop_qword rsi
        end if
        if argc >= 3
            zoc_pop_qword r12  ; rdx is used by zoc_pop_qword
        end if
        if argc >= 4
            zoc_pop_qword r10
        end if
        if argc >= 5
            zoc_pop_qword r8
        end if
        if argc >= 6
            zoc_pop_qword r9
        end if

        if argc >= 3
            mov r13, rdx
            mov rdx, r12
        end if

        syscall

        if argc >= 3
            mov rdx, r13
        end if

        zoc_push_qword rax
}

macro zoc_gt {
        zoc_pop_qword rdi
        zoc_pop_qword rsi
        mov rax, 0
        mov rcx, 1
        cmp rsi, rdi
        cmovg rax, rcx
        zoc_push_qword rax
}

macro zoc_lt {
        zoc_pop_qword rdi
        zoc_pop_qword rsi
        mov rax, 0
        mov rcx, 1
        cmp rsi, rdi
        cmovl rax, rcx
        zoc_push_qword rax
}

macro zoc_eq {
        zoc_pop_qword rdi
        zoc_pop_qword rsi
        mov rax, 0
        mov rcx, 1
        cmp rsi, rdi
        cmove rax, rcx
        zoc_push_qword rax
}

macro zoc_ne {
        zoc_pop_qword rdi
        zoc_pop_qword rsi
        mov rax, 0
        mov rcx, 1
        cmp rsi, rdi
        cmovne rax, rcx
        zoc_push_qword rax
}
; id: the if number identifier
; --
; none
; TODO: use byte instead of qword
macro zoc_if id* {
        zoc_pop_qword rax
        cmp rax, 1
        jne if_end_#id
}

macro zoc_if_else id*, else_id {
        zoc_pop_qword rax
        cmp rax, 1
        if else_id eq
            jne else_#id
        else
            jne else_#id_#else_id
        end if
}

; id: the if number identifier
; else_id: the else number identifier
;    if else_id is null, jump to the end on false
; stack: pop a qword
; --
; none
macro zoc_elif id*, else_id {
        zoc_pop_qword rax
        cmp rax, 1
        if else_id eq ; empty
            jne if_end_#id
        else
            jne else_#id_#else_id
        end if
}

; id: the if number identifier
; else_id: the else number identifier
; --
; none
macro zoc_else id*, else_id {
        jmp if_end_#id
        if else_id eq 
else_#id:
        else
else_#id_#else_id:
        end if
}

macro zoc_if_end id* {
if_end_#id:
}

macro zoc_while id* {
while_#id:
}

macro zoc_do id* {
        zoc_pop_qword rax
        cmp rax, 1
        jnz while_end_#id
}

macro while_end id* {
        jmp while_#id
while_end_#id:
}


segment executable
entry _start
_start:
        ;; Set up wstack frame
        push rbp
        ; Save all calle-saved registers
        push rbx
        push r12
        push r13
        push r14
        push r15
        
        mov rbp, rsp
        mov rbx, rsp  ; rbx is used as the pointer to the top of the wstack
        
        ; Reserve bytes for wstack
        sub rsp, wstack_len

        ;; Call the main function
        ; Reserve space for the return code
        zoc_call_fn 0, 8

        ; Get the return code
        zoc_pop_qword rdi  ; for exit syscall

        ;; Restore the state
        mov rsp, rbp
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp

        ;; Exit syscall
        ; The return code is already in rdi
        mov rax, 60
        syscall

;; main
; void
; --
; usize
zoc_fn 0
        ; call ifTest
        ;zoc_call_fn 1, 8
        ; call ifTest2
        ;zoc_call_fn 2, 8
        mov rax, data_1
        zoc_push_qword rax
        mov rax, data_0
        zoc_push_qword rax
        mov rax, 1
        zoc_push_qword rax

        zoc_call_fn 3, 8

        mov rax, 0
        zoc_push_qword rax
        
        zoc_lt

        zoc_if_else 3
        mov rax, 1
        zoc_push_qword rax
        zoc_else 3
        mov rax, 0
        zoc_push_qword rax
        zoc_if_end 3

        ; + usize
        ;zoc_add_qword
zoc_ret_qword

; ifTest2
; none
; --
; usize
zoc_fn 2
        ; 0 usize
        mov rax, 0
        zoc_push_qword rax
        ; if
        zoc_if_else 1
            mov rax, 20
            zoc_push_qword rax
        zoc_else 1
            mov rax, 40
            zoc_push_qword rax
        zoc_if_end 1
        
zoc_ret_qword


;; ifTest
; none
; --
; usize
zoc_fn 1
        ; 0 usize
        mov rax, 1
        zoc_push_qword rax
        ; if
        zoc_if_else 0, 0
                ; 37 usize
                mov rax, 37
                zoc_push_qword rax
        ; else
        zoc_else 0, 0
                ; 0 usize
                mov rax, 0
                zoc_push_qword rax
        ; elif
        zoc_elif 0, 1
                ; 10 usize
                mov rax, 10
                zoc_push_qword rax
        ; else
        zoc_else 0, 1
                ; 1 usize
                mov rax, 0
                zoc_push_qword rax
        ; elif
        zoc_elif 0, 2
                ; 100 usize
                mov rax, 100
                zoc_push_qword rax
        zoc_else 0, 2
                ; 0 usize
                mov rax, 10
                zoc_push_qword rax
        ; if_end
        zoc_if_end 0
        
zoc_ret_qword

; write
; usize: text len
; usize: pointer to text
; usize: fd
; --
; none
zoc_fn 3
        mov rax, 1
        zoc_push_qword rax
        zoc_syscall 3
zoc_ret_qword

segment readable

data_0 db 'Hello, World',10
align 8
data_1 = $ - data_0

