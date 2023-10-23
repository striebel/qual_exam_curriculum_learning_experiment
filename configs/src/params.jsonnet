local transformer_model = "bert-base-cased";
local transformer_dim = 768;

local max_len       =  512;
local my_batch_size =   32;
local my_patience   =    8;
local my_num_epochs =  192;  # 24;

{
    "random_seed": 13370,
    "numpy_seed": 1337,
    "pytorch_seed": 133,
    "dataset_reader": {
        "type": "machamp_universal_reader",
        "target_max_tokens": max_len,
        "source_max_tokens": max_len,
        "do_lowercase": false,

        "token_indexers": {
            "tokens": {
                "type": "pretrained_transformer_mixmatched",
                "max_length": max_len,
                "model_name": transformer_model
            }
        },
        "tokenizer": {
            "type": "pretrained_transformer",
            "add_special_tokens": false,
            "model_name": transformer_model
        },
        "target_token_indexers": {
            "tokens": {
                "namespace": "target_words"
            }
        }
    },
    "vocabulary": {
        "max_vocab_size": {"target_words": 32000},
        "min_count": {
            "source_words": 1,
            "target_words": 1
        }
    },
    "model": {
        "type": "machamp_model",
        "dataset_embeds_dim": 0,
        "decoders": {
            "classification": {
                "type": "machamp_sentence_decoder"
            },
            "default": {
                "input_dim": transformer_dim,
                "loss_weight": 1,
                "order": 1
            },
            "dependency": {
                "type": "machamp_dependency_decoder",
                "arc_representation_dim": transformer_dim,
                "tag_representation_dim": 256,
                "use_mst_decoding_for_validation": true
            },
            "multiseq": {
                "type": "machamp_multiseq_decoder",
                "metric": "multi_span_f1"
            },
            "seq": {
                "type": "machamp_tag_decoder"
            },
            "seq2seq": {
                "type": "machamp_seq2seq_decoder",
                "attention": "dot_product",
                "beam_size": 6,
                "max_decoding_steps": 128,
                "target_decoder_layers": 2,
                "target_embedding_dim": 512,
                "use_bleu": true
            },
            "seq_bio": {
                "type": "machamp_crf_decoder",
                "metric": "span_f1"
            },
            "string2string": {
                "type": "machamp_tag_decoder"
            },
            "mlm": {
                "type": "machamp_mlm_decoder",
                "pretrained_model": transformer_model
            }
        },
        "default_max_sents": 0,
        "dropout": 0.3,
        "encoder": {
            "type": "cls_pooler",
            "cls_is_last_token": false,
            "embedding_dim": transformer_dim
        },
        "text_field_embedder": {
            "type": "basic",
            "token_embedders": {
                "tokens": {
                    "type": "machamp_pretrained_transformer_mismatched",
                    "last_layer_only": true,
                    "max_length": max_len,
                    "model_name": transformer_model,
                    "train_parameters": true
                }
            }
        }
    },
    "data_loader": {
        "type"       : "dependency_data_loader",
        "batch_size" : my_batch_size,
        "batch_sampler": {
            "type": "dataset_buckets",
            "max_tokens": 1024,
            "batch_size": my_batch_size,
            "sampling_smoothing": 1.0, //1.0 == original size
            "sorting_keys": [
                "tokens"
            ]
        }
    },
    "trainer": {
        "checkpointer": {
            "num_serialized_models_to_keep": 1
        },
        //"use_amp": true, // could save some memory on gpu
        "grad_norm": 1,
        "learning_rate_scheduler": {
            "type": "slanted_triangular",
            "cut_frac": 0.2,
            "decay_factor": 0.38,
            "discriminative_fine_tuning": true,
            "gradual_unfreezing": true
        },
        "patience" : my_patience,
        "num_epochs": my_num_epochs,
        "optimizer": {
            "type": "huggingface_adamw",
            "betas": [0.9, 0.99],
            "correct_bias": false,
            "lr": 0.0001,
            "parameter_groups": [
                [
                    [
                        "^_text_field_embedder.*.transformer_model.*"
                    ],
                    {}
                ],
                [
                    [
                        "^decoders.*",
                        "dataset_embedder.*"
                    ],
                    {}
                ]
            ],
            "weight_decay": 0.01
        },
        //"patience": 5, // disabled, because slanted_triangular changes the lr dynamically
       "validation_metric": "+.run/.sum"
    },
    "datasets_for_vocab_creation": [
        "train",
        "validation"//TODO can this be removed now that we add padding/unknown?
    ]
}
