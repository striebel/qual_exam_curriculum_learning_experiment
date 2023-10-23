import sys
import os

import conllu


def stats():
    
    DATA_DIR = os.environ['DATA_DIR']
    assert os.path.isdir(DATA_DIR)
    
    treebanks_dir = os.path.join(DATA_DIR, 'treebanks')
    assert os.path.isdir(treebanks_dir)
    
    for treebank_name in ['ewt', 'gum']:
        treebank_dir = os.path.join(treebanks_dir, treebank_name)
        assert os.path.isdir(treebank_dir)
        
        clean_dir = os.path.join(treebank_dir, 'clean')
        assert os.path.isdir(clean_dir)
        
        dev_file_path = os.path.join(clean_dir, 'dev.conllu')
        assert os.path.isfile(dev_file_path)
        
        test_file_path = os.path.join(clean_dir, 'test.conllu')
        assert os.path.isfile(test_file_path)
        
        preprocessed_dir = os.path.join(treebank_dir, 'preprocessed')
        assert os.path.isdir(preprocessed_dir)
        
        train_file_path = os.path.join(preprocessed_dir, 'train.conllu')
        assert os.path.isfile(train_file_path)
        
        for file_path in [train_file_path, dev_file_path, test_file_path]:
            file = open(file_path, 'r')
            file_str = file.read()
            file.close()
            n_sents = file_str.strip().count('\n\n') + 1
            print(
                treebank_name,
                '{:<5}'.format(os.path.splitext(os.path.basename(file_path))[0], n_sents),
                '{:>5}'.format(n_sents)
            )
    
    return 0


if '__main__' == __name__:
    sys.exit(stats())


