from scanner import find_col
from cpu_spec import cpu_opcode, jumps_cond, registers

from ply.yacc import yacc


class VasmParser(object):

    def __init__(self, lexer):
        self._parsed = False
        self._data = []
        self._code = []
        self._labels = {'code': {}, 'data': {}}

        self.errors = False
        self.lexer = lexer
        self.tokens = lexer.tokens
        self._parser = yacc(module=self)

    def parse(self, text):
        self._parser.parse(text, lexer=self.lexer)

    def clear(self):
        self._parsed = False
        self._data = []
        self._code = []
        self._labels = {'code': {}, 'data': {}}
        self.errors = False

    @property
    def data(self) -> list:
        if not self._parsed:
            return []
        return list(self._data)

    @property
    def code(self) -> list:
        if not self._parsed:
            return []
        return list(self._code)

    def _second_pass(self):
        for i, code in enumerate(self._code):
            if code[0]:
                self._code[i] = code[1]
            else:
                _, instr_code, labels = code
                for label, attr in labels.items():
                    mem_addr = self._labels[attr[0]].get(attr[1], None)
                    if mem_addr:
                        labels[label] = mem_addr
                    else:
                        self.errors = True
                        raise AttributeError('label "{label}" at {seg} '
                                             'segment not found: line {ln}'
                                             ''.format(label=attr[1],
                                                       seg=attr[0],
                                                       ln=attr[2]))
                else:
                    self._code[i] = instr_code.format(**labels)

    def p_error(self, p):
        if p:
            self.errors += 1
            print("Syntax error at line {ln}, column {col}: "
                  "LexToken({type}, '{val}')".format(ln=p.lineno,
                                                     col=find_col(p),
                                                     type=p.type,
                                                     val=p.value))
        else:
            print('At end of input')

    def p_program(self, _):
        """program : data_segment code_segment"""
        self._second_pass()
        self._parsed = True

    def p_datasegment(self, _):
        """data_segment : DATA ':' inits ENDDATA
                       | empty"""
        pass

    def p_inits(self, p):
        """inits : inits init
                 | init"""
        pass

    def p_init_label(self, p):
        """init : LABEL ':'"""
        if p[1] in self._labels['data']:
            self.errors = True
            raise AttributeError('label "{}" already in use: line {}'
                                 ''.format(p[1], p.lineno(1)))
        else:
            self._labels['data'][p[1]] = '{:016b}'.format(len(self._data))

    def p_init_dup(self, p):
        """init : NUM DUP '(' NUM ')' ','"""
        if p[1][0] == '1':
            num = int(p[1][1:], 2) - 2**(len(p[1])-1)
        else:
            num = int(p[1], 2)
        for _ in range(num):
            self._data.append(p[4])

    def p_init_string(self, p):
        """init : STRING ','"""
        for i in range(len(p[1])):
            self._data.append('{:016b}'.format(ord(p[1][i])))

    def p_init_num(self, p):
        """init : NUM ','"""
        self._data.append(p[1])

    def p_codesegment(self, _):
        """code_segment : CODE ':' instructions ENDCODE"""
        pass

    def p_instructions(self, _):
        """instructions : instructions instruction
                        | instruction"""
        pass

    def p_nop_hlt(self, p):
        """instruction : NOP_HLT"""
        opcode = cpu_opcode[p[1]]
        instr_format = '{opcode}{rest:027b}'
        instr_code = instr_format.format(opcode=opcode, rest=0)
        self._code.append((True, instr_code))

    def p_jxx_num(self, p):
        """instruction : JXX NUM"""
        opcode = cpu_opcode['jxx']
        cond = jumps_cond[p[1]]
        instr_format = '{opcode}{cond}{rest:06b}1{num}'
        instr_code = instr_format.format(opcode=opcode, cond=cond,
                                         num=p[2], rest=0)
        self._code.append((True, instr_code))

    def p_jxx_label(self, p):
        """instruction : JXX LABEL"""
        opcode = cpu_opcode['jxx']
        cond = jumps_cond[p[1]]
        instr_format = '{opcode}{cond}{rest:06b}1{{label}}'
        instr_code = instr_format.format(opcode=opcode, cond=cond, rest=0)
        self._code.append((False, instr_code,
                           {'label': ('code', p[2], p.lineno(2))}))

    def p_un_expr_num(self, p):
        """instruction : UN_EXPR REGISTER ',' NUM"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        instr_format = '{opcode}{dst_reg}{rest:05b}1{num}'
        instr_code = instr_format.format(opcode=opcode, dst_reg=dst_reg,
                                         num=p[4], rest=0)
        self._code.append((True, instr_code))

    def p_un_expr_reg(self, p):
        """instruction : UN_EXPR REGISTER ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        src_reg = registers[p[4]]
        instr_format = '{opcode}{dst_reg}{rest:05b}0{src_reg}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, dst_reg=dst_reg,
                                         src_reg=src_reg, rest=0)
        self._code.append((True, instr_code))

    def p_lea(self, p):
        """instruction : LEA REGISTER ',' LABEL"""
        opcode = cpu_opcode['mov']
        dst_reg = registers[p[2]]
        instr_format = '{opcode}{dst_reg}{rest:05b}1{{label}}'
        instr_code = instr_format.format(opcode=opcode, dst_reg=dst_reg, rest=0)
        self._code.append((False, instr_code,
                           {'label': ('data', p[4], p.lineno(4))})
                          )

    def p_bin_expr_num(self, p):
        """instruction : BIN_EXPR REGISTER ',' REGISTER ',' NUM"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        src_reg = registers[p[4]]
        instr_format = '{opcode}{dst_reg}{src_reg}1{num}'
        instr_code = instr_format.format(opcode=opcode, dst_reg=dst_reg,
                                         src_reg=src_reg, num=p[6])
        self._code.append((True, instr_code))

    def p_bin_expr_reg(self, p):
        """instruction : BIN_EXPR REGISTER ',' REGISTER ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        src_reg1 = registers[p[4]]
        src_reg2 = registers[p[6]]
        instr_format = '{opcode}{dst_reg}{src_reg1}0{src_reg2}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, dst_reg=dst_reg,
                                         src_reg1=src_reg1, src_reg2=src_reg2,
                                         rest=0)
        self._code.append((True, instr_code))

    def p_cmp_num(self, p):
        """instruction : CMP REGISTER ',' NUM"""
        opcode = cpu_opcode[p[1]]
        src_reg = registers[p[2]]
        instr_format = '{opcode}{rest:05b}{src_reg}1{num}'
        instr_code = instr_format.format(opcode=opcode, src_reg=src_reg,
                                         num=p[4], rest=0)
        self._code.append((True, instr_code))

    def p_cmp_reg(self, p):
        """instruction : CMP REGISTER ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        src_reg1 = registers[p[2]]
        src_reg2 = registers[p[4]]
        instr_format = '{opcode}{rest:05b}{src_reg1}0{src_reg2}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, src_reg1=src_reg1,
                                         src_reg2=src_reg2, rest=0)
        self._code.append((True, instr_code))

    def p_st_pc_reg_abs(self, p):
        """instruction : ST REGISTER ',' PC"""
        opcode = cpu_opcode[p[1]]
        addr_reg = registers[p[2]]
        instr_format = '{opcode}{rest:010b}0{addr_reg}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg=addr_reg,
                                         rest=0)
        self._code.append((True, instr_code))

    def p_st_pc_num(self, p):
        """instruction : ST NUM ',' PC"""
        opcode = cpu_opcode[p[1]]
        instr_format = '{opcode}{rest:010b}1{num}'
        instr_code = instr_format.format(opcode=opcode, num=p[2], rest=0)
        self._code.append((True, instr_code))

    def p_st_pc_reg_relative_reg(self, p):
        """instruction : ST REGISTER ':' '[' REGISTER ']' ',' PC"""
        opcode = cpu_opcode[p[1]]
        addr_reg1 = registers[p[2]]
        addr_reg2 = registers[p[5]]
        instr_format = '{opcode}{rest:05b}{addr_reg1}0{addr_reg2}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg1=addr_reg1,
                                         addr_reg2=addr_reg2, rest=0)
        self._code.append((True, instr_code))

    def p_st_pc_reg_relative_num(self, p):
        """instruction : ST REGISTER ':' '[' NUM ']' ',' PC"""
        opcode = cpu_opcode[p[1]]
        addr_reg1 = registers[p[2]]
        instr_format = '{opcode}{rest:05b}{addr_reg1}1{num}'
        instr_code = instr_format.format(opcode=opcode, addr_reg1=addr_reg1,
                                         num=p[5], rest=0)
        self._code.append((True, instr_code))

    def p_st_reg_reg_abs(self, p):
        """instruction : ST REGISTER ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        addr_reg = registers[p[2]]
        src_reg = registers[p[4]]
        instr_format = '{opcode}{src_reg}{rest:05b}0{addr_reg}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg=addr_reg,
                                         src_reg=src_reg, rest=0)
        self._code.append((True, instr_code))

    def p_st_reg_num_abs(self, p):
        """instruction : ST NUM ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        src_reg = registers[p[4]]
        instr_format = '{opcode}{src_reg}{rest:05b}1{num}'
        instr_code = instr_format.format(opcode=opcode, num=p[2],
                                         src_reg=src_reg, rest=0)
        self._code.append((True, instr_code))

    def p_st_reg_reg_relative_reg(self, p):
        """instruction : ST REGISTER ':' '[' REGISTER ']' ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        addr_reg1 = registers[p[2]]
        addr_reg2 = registers[p[5]]
        src_reg = registers[p[8]]
        instr_format = '{opcode}{src_reg}{addr_reg1}0{addr_reg2}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg1=addr_reg1,
                                         addr_reg2=addr_reg2, src_reg=src_reg,
                                         rest=0)
        self._code.append((True, instr_code))

    def p_st_reg_reg_relative_num(self, p):
        """instruction : ST REGISTER ':' '[' NUM ']' ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        addr_reg = registers[p[2]]
        src_reg = registers[p[8]]
        instr_format = '{opcode}{src_reg}{addr_reg}1{num}'
        instr_code = instr_format.format(opcode=opcode, addr_reg=addr_reg,
                                         num=p[5], src_reg=src_reg, rest=0)
        self._code.append((True, instr_code))

    def p_ld_pc_reg_abs(self, p):
        """instruction : LD PC ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        addr_reg = registers[p[4]]
        instr_format = '{opcode}{rest:010b}0{addr_reg}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg=addr_reg,
                                         rest=0)
        self._code.append((True, instr_code))

    def p_ld_pc_num(self, p):
        """instruction : LD PC ',' NUM"""
        opcode = cpu_opcode[p[1]]
        instr_format = '{opcode}{rest:010b}1{num}'
        instr_code = instr_format.format(opcode=opcode, num=p[4], rest=0)
        self._code.append((True, instr_code))

    def p_ld_pc_reg_relative_reg(self, p):
        """instruction : LD PC ',' REGISTER ':' '[' REGISTER ']'"""
        opcode = cpu_opcode[p[1]]
        addr_reg1 = registers[p[4]]
        addr_reg2 = registers[p[7]]
        instr_format = '{opcode}{rest:05b}{addr_reg1}0{addr_reg2}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg1=addr_reg1,
                                         addr_reg2=addr_reg2, rest=0)
        self._code.append((True, instr_code))

    def p_ld_pc_reg_relative_num(self, p):
        """instruction : LD PC ',' REGISTER ':' '[' NUM ']'"""
        opcode = cpu_opcode[p[1]]
        addr_reg = registers[p[4]]
        instr_format = '{opcode}{rest:05b}{addr_reg}1{num}'
        instr_code = instr_format.format(opcode=opcode, addr_reg=addr_reg,
                                         num=p[7], rest=0)
        self._code.append((True, instr_code))

    def p_ld_reg_reg_abs(self, p):
        """instruction : LD REGISTER ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        addr_reg = registers[p[4]]
        instr_format = '{opcode}{dst_reg}{rest:05b}0{addr_reg}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg=addr_reg,
                                         dst_reg=dst_reg, rest=0)
        self._code.append((True, instr_code))

    def p_ld_reg_num_abs(self, p):
        """instruction : LD REGISTER ',' NUM"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        instr_format = '{opcode}{dst_reg}{rest:05b}1{num}'
        instr_code = instr_format.format(opcode=opcode, num=p[4],
                                         dst_reg=dst_reg, rest=0)
        self._code.append((True, instr_code))

    def p_ld_reg_reg_relative_reg(self, p):
        """instruction : LD REGISTER ',' REGISTER ':' '[' REGISTER ']'"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        addr_reg1 = registers[p[4]]
        addr_reg2 = registers[p[7]]
        instr_format = '{opcode}{dst_reg}{addr_reg1}0{addr_reg2}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, addr_reg1=addr_reg1,
                                         addr_reg2=addr_reg2, dst_reg=dst_reg,
                                         rest=0)
        self._code.append((True, instr_code))

    def p_ld_reg_reg_relative_num(self, p):
        """instruction : LD REGISTER ',' REGISTER ':' '[' NUM ']'"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        addr_reg = registers[p[4]]
        instr_format = '{opcode}{dst_reg}{addr_reg}1{num}'
        instr_code = instr_format.format(opcode=opcode, addr_reg=addr_reg,
                                         num=p[7], dst_reg=dst_reg,
                                         rest=0)
        self._code.append((True, instr_code))

    def p_dumps(self, p):
        """instruction : DUMP REGISTER ',' REGISTER ',' REGISTER ',' REGISTER"""
        opcode = cpu_opcode[p[1]]
        dst_reg = registers[p[2]]
        where_reg = registers[p[4]]
        from_reg = registers[p[6]]
        count_reg = registers[p[8]]
        instr_format = '{opcode}{dst_reg}{where_reg}0{from_reg}{count_reg}{rest:06b}'
        instr_code = instr_format.format(opcode=opcode, dst_reg=dst_reg,
                                         where_reg=where_reg,
                                         from_reg=from_reg,
                                         count_reg=count_reg, rest=0)
        self._code.append((True, instr_code))

    def p_free_spawn(self, p):
        """instruction : FREE_SPAWN REGISTER"""
        opcode = cpu_opcode[p[1]]
        reg = registers[p[2]]
        instr_format = '{opcode}{rest:011b}{reg}{rest:011b}'
        instr_code = instr_format.format(opcode=opcode, reg=reg, rest=0)
        self._code.append((True, instr_code))

    def p_code_label(self, p):
        """instruction : LABEL ':'"""
        if p[1] in self._labels['code']:
            self.errors = True
            raise AttributeError('label "{}" already in use: line {}'
                                 ''.format(p[1], p.lineno(1)))
        else:
            self._labels['code'][p[1]] = '{:016b}'.format(len(self._code))

    def p_empty(self, _):
        """empty :"""
        pass
