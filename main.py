import os
import math
import argparse

from cpu_spec import reserved
from scanner import VasmLexer
from parser import VasmParser


def add_arguments(parser):
    parser.add_argument(
        '-f', '--file_path',
        action='store',
        help='path of file to compile',
        dest='file_path')


def digits_num(num):
    if num == 0:
        return 1
    else:
        return int(math.log10(num))+1 if num > 0 else int(math.log10(-num))+2


def gen_file(fpath, content, depth=65536, width=16, default=0,
             addr_radix='dec', data_radix='bin'):
    with open(fpath, 'w') as f:
        f.write('DEPTH = {depth};\n'
                'WIDTH = {width};\n\n'
                'ADDRESS_RADIX = {addr_radix};\n'
                'DATA_RADIX = {data_radix};\n\n'
                'CONTENT BEGIN\n'
                '\t[0..{range}] : {default:0{width}b};\n'
                ''.format(depth=depth, width=width,
                          range=depth-1,
                          addr_radix=addr_radix,
                          data_radix=data_radix,
                          default=default))

        wd = digits_num(depth)
        for i, line in enumerate(content):
            f.write('\t{ln:0{width}d} : {content};\n'.format(ln=i, width=wd,
                                                             content=line))
        f.write('END;')


def main():
    parser = argparse.ArgumentParser()
    add_arguments(parser)
    args = parser.parse_args()

    if not os.path.isfile(args.file_path):
        print("\n{fp} is not a file.\n".format(fp=args.file_path))
    else:
        lexer = VasmLexer(reserved)
        lexer.build()
        parser = VasmParser(lexer)

        with open(args.file_path) as src:
            parser.parse('\n'.join(src.readlines()))

        if not parser.errors:
            print('\nCompilation succeeded.\n')
            gen_file('data.mif', parser.data, depth=2**10)
            gen_file('code.mif', parser.code, depth=2**8, width=32)


if __name__ == "__main__":
    main()
