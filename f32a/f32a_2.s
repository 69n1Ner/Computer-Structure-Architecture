\ https://wrench.edu.swampbuds.me/report/acc809e6-d600-4216-8841-d66cda081959
.data
ans: .byte 'Hello, '

 .text
_start:
    19 lit q \ длина/адрес
    print_word 
    drop
    0x20 -7 + -2 + 0x7 \ длина буфера/адрес буфера
    read_word 
    if correct_handle
    0x84 a!
    !
    end ;
    correct_handle:
    handle_ending
    lit ans
    print_word \ здесь длина слова просто совпадает с выводом read_word
    end:
    halt

.data 
byte_mask: .word 0x00_00_00ff
q: .byte 'What is your name?', 0x0a
error: .word -858993460

.text
.org 0x88

\ Аргумент: S=[длина строки], T=[адрес строки]
\ Возвращает: T=[адрес конца слова + 1]
\ Выводит слово определенной длины в 0x84
print_word:
    a!
    -1 + >r \ положили счетчик (длина - 1)
    0x84 b!
    pw_loop:
        @+ 
        @p byte_mask 
        and
        !b
        next pw_loop
    a
    ; 



\ Аргументы: S=[длина буфера], T=[адрес буфера]
\ Возвращает: S=[адрес конца слова + 1], T=[код возврата]
\ Читает слово оканчивающееся на '\n' или '\0' из 0x80, не пишет '\n' или '\0' в конец слова
\ При коде возврата (КВ) 0 в T корректный адрес, а при КВ 1 значение переполнения 
read_word:
    a!
    -1 + >r
    0x80 b!
    rw_loop:
        @b 
        dup dup
        0x0a xor \ проверяем на '\n'
        if rw_n_end
        0x0 xor 
        if rw_0_end
        !+
        next rw_loop
    rw_bad_end:
        @p error
        1
        ;
    rw_0_end:
        a 0
        rw_loop_2: \ не очень понятно зачем в целом считывать строку до конца
            @b
            0x0a xor
            if rw_end
            next rw_loop_2
    rw_n_end:
        a 0
    rw_end:
        r> drop 
        ;



\ Аргументы: T=[адрес начала вписывания]
\ Возвращет: T=[адрес конца вписывания]
handle_ending:
    a!
    '!' !+
    a \ для возврата
    0x0 !+
    he_loop:
        a -32 +
        if he_end
        '_' !+
        he_loop ;
    he_end:
        ; 

.data
    buf_len: .word 23 \0x20 -7 + -2 + 