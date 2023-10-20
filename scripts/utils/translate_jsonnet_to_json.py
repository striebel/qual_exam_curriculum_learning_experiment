# https://jsonnet.org/ref/bindings.html

import sys
import _jsonnet

def translate(in_path, out_path):
    json_str = _jsonnet.evaluate_file(in_path)
    open(out_path, 'w').write(json_str)

if '__main__' == __name__:
    translate(sys.argv[1], sys.argv[2])
