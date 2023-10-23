from typing import Iterator
import sys
import random
import math

import torch
import allennlp
from allennlp.data.dataloader import DataLoader


N_SENT_EWT_TRAIN = 12_544
N_SENT_EWT_DEV   =  2_001
N_SENT_GUM_TRAIN =  8_548
N_SENT_GUM_DEV   =  1_117

N_BATCHES_PER_EPOCH = 64
BATCH_SIZE        = 32

@DataLoader.register("dependency_data_loader")
class DependencyDataLoader(allennlp.data.dataloader.DataLoader):
    
    def __init__(
        self,
        dataset    : allennlp.data.dataset_readers.dataset_reader.AllennlpDataset,
        batch_size : int,
        batch_sampler # not used
    ):
        assert BATCH_SIZE == batch_size
        
        #import code
        #code.interact(local=locals())
        #sys.exit(-1)
        #sys.stderr.write('DependencyDataLoader : begin\n')
        #sys.stderr.write('type(dataset)        : ' + str(type(dataset)) + '\n')
        #sys.stderr.write('len(dataset)         : ' + str(len(dataset)) + '\n')
        #sys.stderr.write('batch_size           : ' + str(batch_size) + '\n')
        #sys.stderr.write('dir(dataset[3])      :\n')
        #import pprint
        #pprint.pprint(dir(dataset[3]), stream=sys.stderr)
        #sys.stderr.write('dataset[3].fields    :\n')
        #pprint.pprint(dataset[3].fields, stream=sys.stderr)
        ##sys.stderr.write('dir(dataset[3].fields) :\n')
        ##pprint.pprint(dir(dataset[3].fields), stream=sys.stderr)
        #sys.stderr.write('dir(dataset[3].fields["dataset"]) :\n')
        #pprint.pprint(dir(dataset[3].fields['dataset']), stream=sys.stderr)
        #sys.stderr.write('dir(dataset[3].fields["metadata"]):\n')
        #pprint.pprint(dir(dataset[3].fields['metadata']), stream=sys.stderr)
        #pprint.pprint(dataset[3].fields['metadata'].keys()     , stream=sys.stderr)
        #pprint.pprint(dataset[3].fields['metadata']['col_idxs'], stream=sys.stderr)
        ##sys.stderr.write('type(sampler)        : ' + str(type(sampler)) + '\n')
        ##sys.stderr.write('type(batch_sampler)  : ' + str(type(batch_sampler)) + '\n')
        ##sys.stderr.write('dir(batch_sampler)   : \n')
        ##import pprint
        ##pprint.pprint(dir(batch_sampler), stream=sys.stderr)
        #sys.stderr.write('DependencyDataLoader : end\n')
        #sys.exit(-1)
        
        
        self._difficulty_function = dataset[0].difficulty_function
        self._competence_function = dataset[0].competence_function
        
        assert self._difficulty_function in [
            'len_in_words',
            'len_in_chars',
            'dep_len',
            'dep_len_norm',
            'n_deprels',
            'n_deprels_norm'
        ]
        
        name_param_pair = self._competence_function.split(',')
        assert 2 == len(name_param_pair)
        func_name = name_param_pair[0]
        param     = int(name_param_pair[1])
        
        assert func_name in ['linear']
        assert 0 <= param
        
        if len(dataset) == N_SENT_EWT_TRAIN:
            self._treebank = 'ewt'
            self._split    = 'train'
        elif len(dataset) == N_SENT_EWT_DEV:
            self._treebank = 'ewt'
            self._split    = 'dev'
        elif len(dataset) == N_SENT_GUM_TRAIN:
            self._treebank = 'gum'
            self._split    = 'train'
        elif len(dataset) == N_SENT_GUM_DEV:
            self._treebank = 'gum'
            self._split    = 'dev'
        else:
            self._treebank = None
            self._split    = None
            print('error: unrecognized dataset length:', len(dataset))
            sys.exit(-1)
        
        if 'train' == self._split:
            self._idx_to_attrs = list()
            self._ordered_dataset = list()
            list_of_difficulty_idx_pairs = list()
        else:
            assert 'dev' == self._split
            self._unordered_dataset = dataset
        
        for idx in range(len(dataset)):
            instance = dataset[idx]
            
            assert self._difficulty_function == instance.difficulty_function
            assert self._competence_function == instance.competence_function
            
            assert hasattr(instance.conllu_obj, 'metadata')
            
            if 'train' == self._split:
                self._idx_to_attrs.append(dict())
                assert self._idx_to_attrs[idx] == self._idx_to_attrs[-1]
                
                len_in_words   = instance.conllu_obj.metadata['len_in_words']
                len_in_chars   = instance.conllu_obj.metadata['len_in_chars']
                dep_len        = instance.conllu_obj.metadata['dep_len']
                dep_len_norm   = dep_len / len_in_words
                n_deprels      = instance.conllu_obj.metadata['n_deprels']
                n_deprels_norm = n_deprels / len_in_words
                
                self._idx_to_attrs[idx]['len_in_words']   = len_in_words
                self._idx_to_attrs[idx]['len_in_chars']   = len_in_chars
                self._idx_to_attrs[idx]['dep_len']        = dep_len
                self._idx_to_attrs[idx]['dep_len_norm']   = dep_len_norm
                self._idx_to_attrs[idx]['n_deprels']      = n_deprels
                self._idx_to_attrs[idx]['n_deprels_norm'] = n_deprels_norm
                
                list_of_difficulty_idx_pairs.append(
                    (
                        self._idx_to_attrs[idx][self._difficulty_function],
                        idx
                    )
                )
                
            else:
                assert 'dev' == self._split
                pass
            
        if 'train' == self.split:
            self._ordered_dataset = list()
            list_of_difficulty_idx_pairs.sort()
            for _, idx in list_of_difficulty_idx_pairs:
                self._ordered_dataset.append(dataset[idx])
            
            if 'linear' == func_name:
                def get_linear_func(last_global_batch_idx):
                    def linear_func(
                        current_global_batch_idx,
                        last_global_batch_idx=last_global_batch_idx
                    ):
                        if last_global_batch_idx <= current_global_batch_idx:
                            return 1.0
                        else:
                            assert 0 <= current_global_batch_idx
                            return current_global_batch_idx / last_global_batch_idx
                    return linear_func
                self._competence_function = get_linear_func(param)
            else:
                assert False


    def get_next_batch(self) -> list:
        if 'dev' == self._split:
            assert not hasattr(self, '_epoch_batch_idx')
            assert not hasattr(self, '_global_batch_idx')
            
            init = False
            if (
                not hasattr(self, '_batches')
                or not hasattr(self, '_epoch_idx')
            ):
                assert not hasattr(self, '_batches')
                assert not hasattr(self, '_epoch_idx')
                self._batches = list()
                self._epoch_idx = 0
                init = True
            if 0 == len(self._batches):
                batch = list()
                for idx in range(len(self._dataset)):
                    if BATCH_SIZE <= len(batch):
                        assert len(batch) == BATCH_SIZE
                        self._batches.append(batch)
                        batch = list()
                    assert len(batch) < BATCH_SIZE
                    batch.append(self._dataset[idx])
                if 0 < len(batch):
                    assert len(batch) <= BATCH_SIZE
                    self._batches.append(batch)
                if init is True:
                    assert 0 == self._epoch_idx
                    return self._batches.pop()
                else:
                    self._epoch_idx += 1
                    return None
            else:
                assert 0 < len(self._batches)
                return self._batches.pop()
        else:
            assert 'train' == self._split
            
            assert not hasattr(self, '_epoch_idx')
            assert not hasattr(self, '_unordered_dataset')
            
            if (
                not hasattr(self, '_epoch_batch_idx')
                or not hasattr(self, '_global_batch_idx')
            ):
                assert not hasattr(self, '_epoch_batch_idx')
                assert not hasattr(self, '_global_batch_idx')
                self._epoch_batch_idx = 0
                self._global_batch_idx = 0
                
            if N_BATCHES_PER_EPOCH <= self._epoch_batch_idx:
                assert N_BATCHES_PER_EPOCH == self._epoch_batch_idx
                assert (
                    0 < self._global_batch_idx
                    and 0 == self._global_batch_idx % N_BATCHES_PER_EPOCH
                )
                self._epoch_batch_idx = 0
                return None
            else:
                assert 0 <= self._epoch_batch_idx
                assert self._epoch_batch_idx < N_BATCHES_PER_EPOCH
                assert 0 <= self._global_batch_idx
                
                fraction = self._competence_function(self._global_batch_idx)
                assert 0.0 <= fraction
                assert fraction <= 1.0
                
                n_samples = round(fraction * len(self._ordered_dataset))
                if n_samples < BATCH_SIZE:
                    n_samples = BATCH_SIZE
                
                batch = random.sample(self._ordered_dataset[:n_samples], BATCH_SIZE)
                assert len(batch) == BATCH_SIZE
                
                self._epoch_batch_idx  += 1
                self._global_batch_idx += 1
                
                return batch
        

    def __len__(self) -> int:
        if 'train' == self.split:
            return N_BATCHES_PER_EPOCH
        else:
            assert 'dev' == self.split:
            return math.ceil(len(self._unordered_dataset) / BATCH_SIZE)
    

    def __iter__(self) -> Iterator[allennlp.data.dataloader.TensorDict]:
        return self

    
    def __next__(self) -> allennlp.data.dataloader.TensorDict:
        
        instances = self.get_next_batch()
        if instances is None:
            raise StopIteration
        else:
            return allennlp.data.dataloader.allennlp_collate(instances)
        

