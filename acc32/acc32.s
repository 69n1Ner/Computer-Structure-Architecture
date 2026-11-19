    .data
count:           .word  0
mask:            .word  1
n:               .word  0

    .text
_start:
    load_addr    0x80
    store        n
    beqz         end_first_iter

while:
    load         n
    and          mask
    bnez         end
    load         count
    add          mask
    store        count
    load         n
    shiftr       mask
    store        n
    jmp          while

end_first_iter:
    load_imm     32
    jmp          stop
end:
    load         count
stop:
    store_addr   0x84
    halt
;https://wrench.edu.swampbuds.me/report/d0079b0d-1fa1-4f68-bc6d-00521a39ce24
