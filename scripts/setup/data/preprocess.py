import sys
import os

import conllu


def preprocess():
    
    DATA_DIR = os.environ['DATA_DIR']
    assert os.path.isdir(DATA_DIR)
    
    treebanks_dir = os.path.join(DATA_DIR, 'treebanks')
    assert os.path.isdir(treebanks_dir)
    
    for treebank_name in ['ewt', 'gum']:
        treebank_dir = os.path.join(treebanks_dir, treebank_name)
        assert os.path.isdir(treebank_dir)
        
        clean_dir = os.path.join(treebank_dir, 'clean')
        assert os.path.isdir(clean_dir)
        
        train_file_path = os.path.join(clean_dir, 'train.conllu')
        assert os.path.isfile(train_file_path)
        
        train_file = open(train_file_path, 'r')
        train_file_str = train_file.read()
        train_file.close()
        
        list_of_conllu_objs = conllu.parse(train_file_str)
        
        preprocessed_dir = os.path.join(treebank_dir, 'preprocessed')
        if not os.path.isdir(preprocessed_dir):
            os.mkdir(preprocessed_dir)
        
        train_out_file_path = os.path.join(preprocessed_dir, 'train.conllu')
        
        print('treebank_name:', treebank_name)
        print('    len(list_of_conllu_objs):', len(list_of_conllu_objs))
        
        #import code
        #code.interact(local=locals()); return 33
        
        
        for conllu_obj_idx, conllu_obj in enumerate(list_of_conllu_objs):
            
            len_in_words = 0
            len_in_chars = 0
            dep_len = 0
            deprels = set()
            
            assert 0 < len(conllu_obj)
            for word in conllu_obj:
                
                len_in_words += 1
                
                form = word['form']
                assert isinstance(form, str)
                assert 0 < len(form)
                len_in_chars += len(form)
                
                id = word['id']
                head = word['head']
                assert isinstance(id, int)
                assert 0 < id
                assert id <= len(conllu_obj)
                assert isinstance(head, int)
                if 0 == head:
                    pass
                else:
                    assert 0 < head
                    assert head <= len(conllu_obj)
                    dep_len += abs(head - id)
                
                deprel = word['deprel']
                deprels.add(deprel)
                
            assert len(conllu_obj) == len_in_words
            assert len_in_words <= len_in_chars
            assert 0 <= dep_len
            assert dep_len <= len_in_words ** 2
            assert 0 < len(deprels)
            assert len(deprels) <= len_in_words
            
            assert 'len_in_words' not in conllu_obj.metadata
            assert 'len_in_chars' not in conllu_obj.metadata
            assert 'dep_len' not in conllu_obj.metadata
            assert 'n_deprels' not in conllu_obj.metadata
            
            conllu_obj.metadata['len_in_words'] = str( len_in_words )
            conllu_obj.metadata['len_in_chars'] = str( len_in_chars )
            conllu_obj.metadata['dep_len']      = str( dep_len      )
            conllu_obj.metadata['n_deprels']    = str( len(deprels) )
            
            #if 3 == conllu_obj_idx:
            #    print(conllu_obj.serialize())
            #    return 34
        
        train_out_file = open(train_out_file_path, 'w')
        train_out_file.write(
            ''.join([
                conllu_obj.serialize() for conllu_obj in list_of_conllu_objs
            ])
        )
        train_out_file.close()
    
    return 0


if '__main__' == __name__:
    sys.exit(preprocess())


