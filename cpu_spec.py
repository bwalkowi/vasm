register_num = 32
opcode_len = 5
jump_cond_len = 4


cpu_instr = ('nop', 'jxx', 'add', 'sub', 'cmp', 'and', 'or',
             'xor', 'not', 'neg', 'shl', 'shr', 'st', 'ld',
             'mov', 'hlt', 'ldump', 'sdump', 'free', 'spawn')

jumps = ('jz', 'jnz', 'jg', 'jge', 'jl', 'jle',
         'jc', 'jnc', 'jo', 'jno', 'jn', 'jnn', 'jmp')

un_expr = ('not', 'neg', 'mov')

bin_expr = ('add', 'sub', 'and', 'or', 'xor', 'shl', 'shr')

dumps = ('ldump', 'sdump')

free_spawn = ('free', 'spawn')

nop_hlt = ('nop', 'hlt')

rest_keywords = ('data', 'enddata', 'dup',
                 'code', 'endcode', 'pc',
                 'cmp', 'st', 'ld', 'lea')


cpu_opcode = {instr: '{:0{width}b}'.format(num, width=opcode_len)
              for num, instr in enumerate(cpu_instr)}
assert all(len(opcode) == opcode_len for opcode in cpu_opcode.values())


jumps_cond = {jump: '{:0{width}b}'.format(num, width=jump_cond_len)
              for num, jump in enumerate(jumps)}
assert all(len(cond) == jump_cond_len for cond in jumps_cond.values())


registers = {'r{}'.format(num): '{:05b}'.format(num)
             for num in range(register_num)}


reserved = {'JXX': jumps,
            'UN_EXPR': un_expr,
            'BIN_EXPR': bin_expr,
            'REGISTER': registers,
            'NOP_HLT': nop_hlt,
            'DUMP': dumps,
            'FREE_SPAWN': free_spawn}
assert all(keyword.upper() not in reserved.keys() for keyword in rest_keywords)

reserved.update({keyword.upper(): (keyword,) for keyword in rest_keywords})
