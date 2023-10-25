import sys
import os

import conllu


def check_progress():
    
    DATA_DIR = os.environ['DATA_DIR']
    assert os.path.isdir(DATA_DIR)
    
    treebanks_dir = os.path.join(DATA_DIR, 'treebanks')
    assert os.path.isdir(treebanks_dir)
    
    n_positive = 0
    n_negative = 0
    
    # treebank
    for treebank_name in ['ewt']:

        
        treebank_dir = os.path.join(treebanks_dir, treebank_name)
        assert os.path.isdir(treebank_dir)
        
        predictions_dir = os.path.join(treebank_dir, 'predictions')
        assert os.path.isdir(predictions_dir)
        
        # difficulty function
        for df in [
            'len_in_words', 'len_in_chars',
            'dep_len',      'dep_len_norm',
            'n_deprels',    'n_deprels_norm'
        ]:
            df_dir_path = os.path.join(predictions_dir, df)
            assert os.path.isdir(df_dir_path)
            
            # competence function
            for cf in ['linear', 'fancy']:
                cf_dir_path = os.path.join(df_dir_path, cf)
                assert os.path.isdir(cf_dir_path)
                
                # curriculum duration
                for cd in [
                    '00_000', '02_500', '05_000', '07_500', 
                    '10_000', '12_500', '15_000', '17_500',
                    '20_000', '22_500', '25_000', '27_500',
                    '30_000', '32_500', '35_000', '37_500',
                    '40_000', '42_500', '45_000', '47_500',
                    '50_000', '52_500', '55_000', '57_500',
                    '60_000', '62_500', '65_000', '67_500',
                    '70_000', '72_500', '75_000', '77_500',
                    '80_000'
                ]:
                    cd_dir_path = os.path.join(cf_dir_path, cd)
                    if not os.path.isdir(cd_dir_path):
                        os.mkdir(cd_dir_path)
                    
                    # training run
                    for tr in ['a']:
                        tr_dir_path = os.path.join(cd_dir_path, tr)
                        if not os.path.isdir(tr_dir_path):
                            os.mkdir(tr_dir_path)
                        
                        predictions_file_path = os.path.join(tr_dir_path, 'test.conllu')
                        
                        if os.path.isfile(predictions_file_path):
                            n_positive += 1
                        else:
                            n_negative += 1

    print('done:', n_positive, '/', n_positive + n_negative)
    print('    :', n_positive / (n_positive + n_negative))
    
    return 0
    
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
    
    return 99


if '__main__' == __name__:
    sys.exit(check_progress())


