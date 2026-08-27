    .global _start
    .text
_start:
    mov x0, xzr
    adr x1, root_path
    mov x2, xzr
    mov x3, #32
    mov x4, xzr
    mov x8, #40
    svc #0
    cmp x0, #0
    cset w0, lt
    mov x8, #93
    svc #0
root_path:
    .asciz "/"
