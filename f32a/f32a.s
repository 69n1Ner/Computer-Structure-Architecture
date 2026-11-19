	.data
	
res2: .byte 'Hello, ' \0x6 - конец
q: .byte 'What is your name?',0x0a




	.text
	.org 0x88
_start:
\ без учета некорректного ввода (overflow)
	
	

	0x7 dup !p temp1 \ temp1 - адрес начала фарзы вопроса, и байта сразу за началом
	1
	read_till_lf_2 \ ищет адрес конца фразы приветствия
	!p curr_addr
	@p temp1 !p start_addr
	0 @p output_addr
	write_word_to_byte_2 \ пишет вопрос

	@p temp1 @p input_addr 0
	read_till_lf_2 \ считывает имя и записывает за приветствием, не в output 
	dup !p curr_addr 
	1 + !p temp \ длина строки с именем и приветствием
	@p curr_addr @p temp
	write_ending_symbols
	0 !p start_addr 
	0 @p output_addr 
	write_word_to_byte_2 \ пишет приветствие 
	
	halt

	0x80 dup !p curr_addr !p start_addr
	1 0x2
	write_word_to_byte_2

	0x80 dup !p curr_addr !p start_addr
	1 0x2
	write_word_to_byte_2
	

	halt
	0x2 0x80 0
	read_till_lf_2

	halt

	0xdd dup !p start_addr !p curr_addr
	 0x1 1
	read_till_lf_2
	@p start_addr
	@p curr_addr
	halt

	halt
	
	0x1 29
	write_ending_symbols

	halt
	
	0x0
	0x80 0
	read_till_lf
	\@p start_addr

	halt

	
\Оптимизированная версия rtl
read_till_lf_2:
	dup !p temp
	if rtl2_wr_on
	rtl2_wr_off ;
  rtl2_wr_on:
   	over !p write_addr_2
  rtl2_wr_off:
	dup dup !p curr_addr !p start_addr
	@p temp if rtl2_mode_2
	rtl2_mode_1:
		a! @
		rtl2_loop:
			@p mask1 and 
			@p mask2 xor
			if rtl2_m1_end
			@+
			rtl2_loop ;

	rtl2_m1_end: a -1 + a! a ; \ по итогу получаем адрес конца слова \n

	rtl2_mode_2:
		0 a! \ используется для длины слова
		dup !p start_addr !p curr_addr 
		drop \ убираем последствия over
		32 -7 + -1 + !p overflow_counter2 \ количество символов для имени
		0 !p overflow_counter
		rtl2_m2_loop:
			1 @p write_addr_2 \ подготовка к wwtb
			write_word_to_byte_2

			\проверка переполнения
	 	  ov_check:
			1 @p overflow_counter + !p overflow_counter
			@p overflow_counter inv 1 + @p overflow_counter2 +
			if rtl2_ov_true 

			a @p mask2 xor \ работа с последним байтом
			if rtl2_end_m2
			@p write_addr_2 1 + !p write_addr_2
			rtl2_m2_loop ;
		rtl2_end_m2: 
			@p write_addr_2 dup b! 0 !b ; \ тк запись идет всех символов, то здесь я очищаю символ \n
		
		rtl2_ov_true:
			1 !p overflow_flag
			@p overflow 0x7 b! !b \ записываем ov после приветствия
			0x7 4 + ; \ корректируем адрес конца приветствия 




\Читает строку с начального байта,
\ пока не встретит \n, если T=1, то идет по памяти последовательно,
\ иначе считывает значение из адреса начала слова и 
\ тут же вписывает его значение в ячейки начиная с адреса записи. 
\ Итог: T=[адрес конца слова (\n)]
\ Изменяет А, B, curr_addr, start_addr.
\ стек: S=[адрес начала слова], T=[0/1], 1S=[адрес записи] (нужен при T=0), 
\ [N]S (пример - 1S) - N означает порядковый номер после S
read_till_lf:	
	dup !p temp
	if rtl_wr_on
	rtl_wr_off ;
  rtl_wr_on:
   	over !p write_addr_2
  rtl_wr_off:
	dup dup !p curr_addr !p start_addr
	@p temp if rtl_mode_2
	rtl_mode_1:
		a! @  
		0 a! \ используется для sh_number
		rtl_loop:
			dup
			@p mask1 sh_number sh_mask and
			@p mask2 sh_number sh_mask xor
			if end_rtl \ проверка на символ \n
			
			\ обновляем A и curr_addr
			@+ drop  
			@p curr_addr 1 + !p curr_addr
			a -3 + if restore_a \ если А = 3, то сбросить. Нужно для sh_number
			rtl_loop ;
			restore_a: 
				drop @p curr_addr a! @
				0 a! 
				rtl_loop ;
			
		end_rtl: 
			drop @p curr_addr ;

	rtl_mode_2:
		0 a! \ используется для длины слова в [0]
		dup !p start_addr !p curr_addr 
		drop \ убираем последствия over
		rtl_m2_loop:
			1 @p write_addr_2 \ подготовка к wwtb
			write_word_to_byte
			a @p mask2 xor \ работа с последним байтом
			if rtl_end_m2
			@p write_addr_2 1 + !p write_addr_2
			rtl_m2_loop ;
		rtl_end_m2: 
			@p write_addr_2 dup b! 0 !b ; \ тк запись идет всех символов, то здесь я очищаю символ \n


\для работы состояние стека: S=[маска], T=N, 
\ где N = 0[4b] / 7[3b] / 15[2b] / 23[1b] - количество сдвигов для нужного байта
\ в итоге T=[нужная маска для выбора бита]
sh_mask:
	dup if sh_end
	>r
	sh_next:
		2* next sh_next ;
	sh_end:	drop ;

\Работает точно также как и sh_mask, но сдивгает байты вправо
sh_mask_left:
	dup if shl_end
	>r
	shl_next:
		2/ next shl_next ;
	shl_end:	drop ;

\Cчитывает из A значение 0-3 и выводит соответствующее N в T
\ A=0[4b] ... 3[1b]
sh_number:
	a dup if b4_end  
  b3: 
	-1 +
	dup if b3_end
  b2: 
	-1 +
	dup if b2_end
  b1: 
	-1 +
	dup if b1_end
  b4_end: drop lit 0 ;
  b3_end: drop lit 7 ;
  b2_end: drop lit 15 ;
  b1_end: drop lit 23 ;

\Записывает слово определенной длины в байт, если T=1, 
\ то идет по памяти последовательно и возвращает в A последний байт изначального слова,
\ иначе пишет все в один байт.
\ Может оставлять после себя от 0 до 3х нулевых байт.
\ Изменяет A, B; Не Изменяет входные переменные конца и начала слова.
\ стек: S=[0/1], T=[адрес назначения]
\ переменные: start_addr=[адрес начала слова], curr_addr=[адрес конца слова]
write_word_to_byte:
		!p write_addr
		!p temp
	\ищем длину слова
		@p curr_addr
		@p start_addr inv 1 +
		1 + + 	
		
		@p temp if mode_2
	mode_1:
		\А используется как счетчик количества
		\ нечёнтых четырём байтов
			0 a! 
		m1_loop:
			dup 
			\ проверка делимости на 4
			0x3 and
			0 xor	
			if b4_loop 

			@+ drop
			-1 + 
			m1_loop ;

		\Записывает данные пачкой по 4 байта последовательно в байты
		b4_loop:
			@p start_addr !p curr_addr
			dup if b4_end_l
			>r \ записываем длину
			@p curr_addr
		b4_next:
			b! @b
			dup !p written_bytes 3 !p mask_pos \ сохраняем данные о последнем байте
			@p write_addr b! 
			!b

		\обновляем счетчик длины, адрес текущих 
		\ 4х байтов считывания и записи
			r> -4 + >r
			@p write_addr 4 + !p write_addr
			@p curr_addr 4 + dup !p curr_addr

		\делаем jump с коррекцией 'next', тк считаем четверками,
		\ а не единицами
			next b4_next_correction
			b4_end_l ;
		b4_next_correction:
			r> 1 + >r
			b4_next ;

		b4_end_l:
			drop b1_loop ;

		\Записывает данные (1 байт) в байты последовательно
		b1_loop:
			a if wwtb_end_correct
			a -1 + a! \изменяем A для работы sh_number
			-1 !p temp	
			
		\получаем маску для нужных байтов 
		\ создаем несколько разных масок, а после: 
		\ temp раз применяем &
		b1_next_mask:
			@p mask1
			sh_number sh_mask
			@p temp 1 + !p temp 
			a dup  
			if b1_fin_mask 
			-1 + a! 
			b1_next_mask ;

		b1_fin_mask:
			@p temp >r
		b1_next_fm:	
			xor
			next b1_next_fm
			@p curr_addr b! @b and
			dup !p written_bytes @p temp !p mask_pos \сохраняем данные о последнем байте
			@p write_addr b! !b

			\ корректируем, чтобы оно по итогу было неизменным
			@p curr_addr @p temp + !p curr_addr
			
			wwtb_end ;
			
	mode_2:
		
		-1 + >r \ Делаем поправку, чтобы next сработал нужное количество раз
		@p start_addr !p curr_addr
		m2_loop:
			@p mask1
			@p curr_addr b! @b and
			@p write_addr b! !b 
			@p curr_addr 1 + !p curr_addr
			next m2_loop
			@p curr_addr -1 + !p curr_addr \ делаем curr_addr таким же как до функции
	
	wwtb_end: 
		@p mask1 
		@p mask_pos a! sh_number  
		sh_mask
		@p written_bytes and
		@p mask_pos a! sh_number
		sh_mask_left
		a! ;
		wwtb_end_correct: 
			@p curr_addr -1 + !p curr_addr 
			wwtb_end ;

\Записывает в указанное место строку вида '\u00'+'!'+'_'*N, где N - число байт, до длины в 32 бита
\ стек: T=[длина имеющейся строки], S=[адрес вписывания]
write_ending_symbols:
	!p temp a!
	0x21 !+
	0 !+
	@p temp 
	-33 + 1 + inv
	dup !p temp \ расчет оставшихся байт для заполнения
	-if wes_loop
	wes_end ;

	wes_loop:
		@p temp if wes_end
		0x5f !+
		@p temp -1 + !p temp
		wes_loop ;

	wes_end: ;


write_word_to_byte_2:
	!p write_addr
	!p temp

	@p curr_addr 
	@p start_addr
	dup a! \ для инкремента адреса считываемого слова
	inv 1 + + \ получили корректную длину слова для итераций next 
	>r

	wwtb2_next:
		@+ dup
		@p mask1 and
		@p write_addr b! !b

		@p temp if wwtb2_mode_2
		wwtb2_mode_1:
			@p write_addr 1 + !p write_addr
		wwtb2_mode_2:
		\просто скип
		next wwtb2_next_correct
		wwtb2_end ;
		wwtb2_next_correct:
			drop wwtb2_next ; \ убираем последствия dup
		wwtb2_end: a! ;


.data
write_addr: .word 0x0
write_addr_2: .word 0x0
written_bytes: .word 0
mask_pos: .byte 0 \0-3
temp: .word 0x0
temp1: .word 0
input_addr: .word 0x80
output_addr: .word 0x84
curr_addr: .word 0x0
start_addr: .word 0
mask2: .word 0x0a  \line feed
mask1: .word 0xff
overflow: .word 0xcccccccc
overflow_counter: .word 0
overflow_counter2: .word 0
overflow_flag: .word 0