format ELF64

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


section '.text' executable
public _start
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
        ; 69 usize
        mov rax, 69
        zoc_push_qword rax
        ; 37 usize
        mov rax, 37
        zoc_push_qword rax
        ; + usize
        zoc_add_qword
zoc_ret_qword


;; add
; usize usize
; --
; usize
zoc_fn 1

        
zoc_ret_qword
