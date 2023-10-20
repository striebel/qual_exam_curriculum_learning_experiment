from collections import defaultdict
from itertools import islice
from pathlib import Path
import argparse
import sys, copy

from lib.conll import CoNLLReader, get_pos_precedence_list

def main():
    parser = argparse.ArgumentParser(description="""Convert conllu to conll format""")
    parser.add_argument('input', help="conllu file")
    parser.add_argument('output', help="target file", type=Path)
    parser.add_argument('--replace_subtokens_with_fused_forms', help="By default removes fused tokens", default=False, action="store_true")
    parser.add_argument('--remove_deprel_suffixes', help="Restrict deprels to the common universal subset, e.g. nmod:tmod becomes nmod", default=False, action="store_true")
    parser.add_argument('--remove_node_properties', help="space-separated list of node properties to remove: form, lemma, cpostag, postag, feats", choices=['form', 'lemma', 'cpostag','postag','feats'],  metavar='prop', type=str, nargs='+')
    parser.add_argument('--lang', help="specify a language 2-letter code", default="default")
    parser.add_argument('--output_format', choices=['conll2006', 'conll2009', 'conllu'], default="conll2006")
    parser.add_argument('--remove_arabic_diacritics', help="remove Arabic short vowels", default=False, action="store_true")
    parser.add_argument('--print_comments',default=False,action="store_true")
    parser.add_argument('--print_fused_forms',default=False,action="store_true")

    args = parser.parse_args()

    if sys.version_info < (3,0):
        print("Sorry, requires Python 3.x.") #suggestion: install anaconda python
        sys.exit(1)

    current_pos_precedence_list = get_pos_precedence_list(args.lang)

    cio = CoNLLReader()
    orig_treebank = cio.read_conll_u(args.input)
    modif_treebank = copy.copy(orig_treebank)

    # As per Dec 2015 the args.lang variable is redundant once you have current_pos_precedence_list
    # We keep it for future modifications, i.e. any language-specific modules
    for s in modif_treebank:
        s.filter_sentence_content(args.replace_subtokens_with_fused_forms, args.lang, current_pos_precedence_list,args.remove_node_properties,args.remove_deprel_suffixes,args.remove_arabic_diacritics)

    cio.write_conll(modif_treebank,args.output, args.output_format,print_fused_forms=args.print_fused_forms, print_comments=args.print_comments)

if __name__ == "__main__":
    main()
