from numpy import binary_repr

from ply import lex


def find_col(token):
    last_cr = token.lexer.lexdata.rfind('\n', 0, token.lexpos)
    if last_cr < 0:
        last_cr = 0
    return token.lexpos - last_cr


class VasmLexer:

    literals = ":,()[]"
    t_ignore = ' \t\v\f'
    tokens = ['LABEL', 'NUM', 'STRING']

    def __init__(self, reserved: dict):
        self.reserved = reserved
        self.tokens = self.tokens + list(reserved.keys())
        self.lexer = None

    def build(self):
        self.lexer = lex.lex(object=self)

    def input(self, text):
        self.lexer.input(text)

    def token(self):
        return self.lexer.token()

    def t_bin(self, token):
        r"""(0|1){1,16}b"""
        token.value = binary_repr(int(token.value[:-1], 2), 16)
        token.type = 'NUM'
        return token

    def t_hex(self, token):
        r"""(\d|a|A|b|B|c|C|d|D|e|E|f|F){1,4}h"""
        token.value = binary_repr(int(token.value[:-1], 16), 16)
        token.type = 'NUM'
        return token

    def t_dec(self, token):
        r"""-?\d+d?"""
        num = int(token.value[:-1] if token.value[-1] == 'd' else token.value)
        token.value = binary_repr(num, 16)
        token.type = 'NUM'
        if not -2**15 <= num <= 2**15 - 1:
            print('WARNING: integer numeral {num} at line {ln} exceeded '
                  'possible value range and was truncated to 16 least '
                  'significant bits'.format(num=num, ln=token.lexer.lineno))
        return token

    def t_string(self, token):
        r'".+?"'
        token.type = 'STRING'
        token.value = token.value[1:-1]
        return token

    def t_keyword_or_label(self, token):
        r"""[a-zA-Z_]\w*"""
        token.type = 'LABEL'
        for category, instructions in self.reserved.items():
            if token.value in instructions:
                token.type = category
                break
        return token

    def t_newline_win(self, token):
        r"""(\r\n)+"""
        token.lexer.lineno += len(token.value) // 2

    def t_newline_ux(self, token):
        r"""\n+"""
        token.lexer.lineno += len(token.value) // 2

    def t_comment(self, token):
        r""";.*"""
        pass

    def t_error(self, token):
        token.lexer.errors = True
        print("Illegal character '{char}' ({cp}) encountered at column {col} "
              "in line {ln}".format(char=token.value[0],
                                    cp=hex(ord(token.value[0])),
                                    col=find_col(token),
                                    ln=token.lexer.lineno))
        token.lexer.skip(1)
