import sys
import os
import code

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
        
        print('treebank_name:', treebank_name)
        print('    len(list_of_conllu_objs):', len(list_of_conllu_objs))
        
        code.interact(local=locals()); return 33
        
        
        deprel_to_freq = {}
        
        for conllu_obj in list_of_conllu_objs:
            
            len_in_words = len(conllu_obj)
            _len_in_words = 0
            len_in_chars = 0
            dep_len = 0
            
            for word in conllu_obj:
                _len_in_words += 1
                
                form = word['form']
                assert isinstance(form, str)
                assert 0 < len(form)
                len_in_chars += len(form)
                
                id = word['id']
                head = word['head']
                assert isinstance(id, int)
                assert 0 < id
                assert id <= len_in_words
                assert isinstance(head, int)
                assert 0 <= head
                assert head < len_in_words
                dep_len += abs(head - id)
                
                deprel = word['deprel']
                if deprel not in deprel_to_freq
                    deprel_to_freq[deprel] = 0
                deprel_to_freq[deprel] += 1
                
                print(type(word))
                print(str(word))
                print(word.__str__())
                print(word['form'])
                print(word)
                return 2
            
            assert _len_in_words == len_in_words
            assert len_in_words <= len_in_chars
            assert 1 <= dep_len
            assert dep_len <= len_in_words ** 2
            
            assert 'len_in_words' not in conllu_obj.metadata
            assert 'len_in_chars' not in conllu_obj.metadata
            assert 'dep_len' not in conllu_obj.metadata
            
            
            conllu_obj.metadata['len_in_words'] = len_in_words
            conllu_obj.metadata['len_in_chars'] = len_in_chars
            conllu_obj.metadata['dep_len']      = dep_len
            conllu_obj.metadata['dep_len_norm'] = dep_len / len_in_words

        
        return 1
    
    if __debug__:
        print('len(file_str)        :', len(file_str))
        print('len(file_str.strip()):', len(file_str.strip()))
    file_str = file_str.strip() # remove the terminating '\n\n'
    sent_strs = file_str.split('\n\n')
    if __debug__:
        print('len(sent_strs)       :', len(sent_strs))
        #print('first sent           :\n', sent_strs[0])
        #print('last sent            :\n', sent_strs[-1])
    
    if 'ewt' == treebank_name:
        genres = [
           'answer',
           'email',
           'newsgroup',
           'reviews',
           'weblog'
        ]
    else:
        assert 'gum' == treebank_name
        genres = [
            'GUM_academic',
            'GUM_bio',
            'GUM_conversation',
            'GUM_fiction',
            'GUM_interview',
            'GUM_news',
            'GUM_speech',
            'GUM_textbook',
            'GUM_vlog',
            'GUM_voyage',
            'GUM_whow'
        ]
    
    genre_to_sent_strs = dict([(genre, []) for genre in genres])
    for sent_str in sent_strs:
        sent_genres = set()
        for genre in genres:
            sent_id_prefix = f'sent_id = {genre}'
            if 0 < sent_str.find(sent_id_prefix):
                sent_genres.add(genre)
        assert len(sent_genres) <= 1
        if 0 == len(sent_genres):
            idx_of_id = sent_str.find('sent_id = ')
            assert 0 < idx_of_id
            idx_of_nl = sent_str[idx_of_id:].find('\n')
            assert 0 < idx_of_nl
            print('unkown genre', file=sys.stderr)
            print('============', file=sys.stderr)
            print('   ', sent_str[idx_of_id:idx_of_id+idx_of_nl], file=sys.stderr)
            sys.exit(-1)
        genre = sent_genres.pop()
        assert genre in genre_to_sent_strs
        assert isinstance(genre_to_sent_strs[genre], list)
        genre_to_sent_strs[genre].append(sent_str)
    
    genre_to_updated_sent_strs = dict([(genre, []) for genre in genres])
    for genre, sent_strs in genre_to_sent_strs.items():
        for sent_str in sent_strs:
            updated_sent_str = f'# domain = {genre}\n' + sent_str
            assert '\n' != updated_sent_str[-1]
            genre_to_updated_sent_strs[genre].append(updated_sent_str)
    
    out_file = open(out_path, 'wb')
    pickle.dump(genre_to_updated_sent_strs, out_file)
    out_file.close()
    
    return 0


if '__main__' == __name__:
    sys.exit(preprocess())


