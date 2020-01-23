from seq2seq.loss import Perplexity
from seq2seq.util.checkpoint import Checkpoint
from seq2seq.dataset import SourceField, TargetField
from seq2seq.evaluator import Evaluator
import os
import csv
import torchtext
import torch
import argparse
import json


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data_path', action='store', dest='data_path',
                        help='Path to test data')
    parser.add_argument('--expt_dir', action='store', dest='expt_dir', default='./experiment',
                        help='Path to experiment directory. If load_checkpoint is True, then path to checkpoint directory has to be provided')
    parser.add_argument('--load_checkpoint', action='store', dest='load_checkpoint',
                        help='The name of the checkpoint to load, usually an encoded time string')
    parser.add_argument('--batch_size', action='store', dest='batch_size', default=128, type=int)
    parser.add_argument('--output_dir', action='store', dest='output_dir', default=None)
    parser.add_argument('--output_fname', action='store', dest='output_fname', default='exp')
    parser.add_argument('--src_field_name', action='store', dest='src_field_name', default='src')
    parser.add_argument('--save', action='store_true')

    opt = parser.parse_args()

    return opt


def load_model_data_evaluator(expt_dir, model_name, data_path, batch_size=128):
    checkpoint_path = os.path.join(expt_dir, Checkpoint.CHECKPOINT_DIR_NAME, model_name)
    checkpoint = Checkpoint.load(checkpoint_path)
    seq2seq = checkpoint.model
    input_vocab = checkpoint.input_vocab
    output_vocab = checkpoint.output_vocab

    src = SourceField()
    tgt = TargetField()

    dev = torchtext.data.TabularDataset(
        path=data_path, format='tsv',
        fields=[('src', src), ('tgt', tgt)], 
        csv_reader_params={'quoting': csv.QUOTE_NONE}
        )

    src.vocab = input_vocab
    tgt.vocab = output_vocab

    seq2seq.eval()

    weight = torch.ones(len(tgt.vocab))
    pad = tgt.vocab.stoi[tgt.pad_token]
    loss = Perplexity(weight, pad)
    if torch.cuda.is_available():
        loss.cuda()
    evaluator = Evaluator(loss=loss, batch_size=batch_size)

    return seq2seq, dev, evaluator

def evaluate_model(evaluator, seq2seq, data, save=False, output_dir=None, output_fname=None, src_field_name='src'):
    print('Size of Test Set', sum(1 for _ in getattr(data, src_field_name)))
    loss, acc, other, (output_seqs, ground_truths) = evaluator.evaluate(seq2seq, data, verbose=True, src_field_name=src_field_name)
    other.update({'Loss':loss, 'Acc (torch)': acc*100})
    for m in other:
        print('%s: %.3f'%(m,other[m]))

    if save:
        with open(os.path.join(output_dir,'%s_preds.txt'%output_fname), 'w') as f:
           f.writelines([a+'\n' for a in output_seqs])
        with open(os.path.join(output_dir,'%s_true.txt'%output_fname), 'w') as f:
            f.writelines([a+'\n' for a in ground_truths])
        with open(os.path.join(output_dir,'%s_stats.txt'%output_fname), 'w') as f:
            try:
                f.write(json.dumps(vars(opt)))
            except:
                pass
            for m in other:
                f.write('%s: %.3f'%(m,other[m]))
        print('Output files written')




if __name__=="__main__":
    opt = parse_args()
    if opt.load_checkpoint == 'all':
        models = ['Best_Acc', 'Best_F1', 'Latest']
    else:
        models = [opt.load_checkpoint]

    for model_name in models:
        print(opt.expt_dir, model_name)
        if opt.load_checkpoint == 'all':
            output_fname = model_name.lower()
        else:
            output_fname = opt.output_fname

        if opt.output_dir is None:
            opt.output_dir = opt.expt_dir

        seq2seq, data, evaluator = load_model_data_evaluator(opt.expt_dir, model_name, opt.data_path, opt.batch_size)
        evaluate_model(evaluator, seq2seq, data, opt.save, opt.output_dir, output_fname, opt.src_field_name)


