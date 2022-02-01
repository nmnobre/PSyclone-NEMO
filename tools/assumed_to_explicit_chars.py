#!/usr/bin/env python3

import codecs
import sys
import os
import re

def main():

    all_procedure = ['function', 'subroutine']
    all_statement = ['if', 'do', 'call', 'allocate', 'rewind', 'read', 'write', 'print']

    for input_file in sys.argv[1:]:

        with codecs.open(input_file,          'r', encoding='ascii', errors='replace') as fi, \
             codecs.open(input_file + '.new', 'w', encoding='ascii', errors='replace') as fo:

            var_decl = False
            var_list_in  = []
            var_list_out = []

            for line in fi:
                comment       = re.match(r'\s*!',                                                                     line, flags=re.I)
                procedure_beg = re.match(r'\s*' + r'\b|\s*'.join(all_procedure) + r'\b',                              line, flags=re.I)
                procedure_end = re.match(r'\s*end\s*' + r'\b|\s*end\s*'.join(all_procedure) + r'\b',                  line, flags=re.I)
                cdeclaration  = re.match(r'(?P<type>.*)\(len\s*=\s*\*\)(?P<attributes>.*::\s*)(?P<var>[\w|\s|,]+)!*', line, flags=re.I)
                statement     = re.match(r'[\s|\d]*' + r'\b|[\s|\d]*'.join(all_statement) + r'\b|=',                  line, flags=re.I)

                if not comment and not procedure_beg and not procedure_end and not cdeclaration and var_list_in + var_list_out:
                    line = re.sub(r'\b' + r'\b|\b'.join(var_list_in + var_list_out) + r'\b', r'\g<0>_explicit', line, flags=re.I)

                if not comment and procedure_beg:
                    var_decl = True
                    var_list_in  = []
                    var_list_out = []

                elif not comment and cdeclaration and var_decl and not re.search(r'optional', line, flags=re.I):
                    new_vars = [var.strip() for var in cdeclaration.group('var').split(',')]

                    intent_regex = re.compile(r',\s*intent\s*\(.*?\)', flags=re.I)
                    intent_match = intent_regex.search(cdeclaration.group('attributes'))
                    if re.search(r'out', intent_match.group(0), flags=re.I):
                        var_list_out.extend(new_vars)
                    if re.search(r'in[^t]', intent_match.group(0), flags=re.I):
                        var_list_in.extend(new_vars)

                    attributes = intent_regex.sub(r'', cdeclaration.group('attributes'))

                    assumed_shape_regex = re.compile(r'dimension\s*\((?P<shape>[\s|:|,]*)\)', flags=re.I)
                    assumed_shape_match = assumed_shape_regex.search(attributes)
                    if assumed_shape_match:
                        for var in new_vars:
                            explicit_shape = ','.join(['size(' + var + ', ' + str(dim + 1) + ')'
                                                       for dim in range(len(assumed_shape_match.group('shape').split(',')))])
                            attributes_mod = assumed_shape_regex.sub('dimension(' + explicit_shape + ')', attributes)
                            line+= cdeclaration.expand(r'\g<type>(len=len(' + var + r'))' + attributes_mod + var + r'_explicit\n')

                    else:
                        line+= ''.join([cdeclaration.expand(r'\g<type>(len=len(' + var + r'))' + attributes + var + r'_explicit\n')
                                               for var in new_vars])

                elif not comment and statement and var_decl and var_list_in:
                    var_decl = False
                    line = ''.join([var + '_explicit' + ' = ' + var + '\n' for var in var_list_in]) + line

                elif not comment and procedure_end and var_list_out:
                    line = ''.join([var + ' = ' + var + '_explicit' + '\n' for var in var_list_out]) + line

                fo.write(line)

            os.rename(input_file, input_file + '.bak')
            os.rename(input_file + '.new', input_file)

if __name__ == "__main__":
    main()
