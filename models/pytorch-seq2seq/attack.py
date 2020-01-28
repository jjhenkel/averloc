from seq2seq.loss import Perplexity
from seq2seq.util.checkpoint import Checkpoint
from seq2seq.dataset import SourceField, TargetField
from seq2seq.evaluator import Evaluator
import seq2seq
from seq2seq.evaluator.metrics import calculate_metrics


import os
import torchtext
import torch
import argparse
import json
import csv
import tqdm


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

    opt = parser.parse_args()

    return opt

def load_model(expt_dir, model_name):
    checkpoint_path = os.path.join(expt_dir, Checkpoint.CHECKPOINT_DIR_NAME, model_name)
    checkpoint = Checkpoint.load(checkpoint_path)
    seq2seq = checkpoint.model
    input_vocab = checkpoint.input_vocab
    output_vocab = checkpoint.output_vocab
    seq2seq.eval()
    return seq2seq, input_vocab, output_vocab

def load_data(data_path):
    src = SourceField()
    tgt = TargetField()

    fields = []
    with open(data_path, 'r') as f:
        cols = f.readline()[:-1].split('\t')
        for col in cols:
            if col=='tgt':
                fields.append(('tgt', tgt))
            else:
                fields.append((col, src))

    dev = torchtext.data.TabularDataset(
                                    path=data_path, format='tsv',
                                    fields=fields,
                                    skip_header=True, 
                                    csv_reader_params={'quoting': csv.QUOTE_NONE}
                                    )

    return dev, fields, src, tgt


def get_best_attack(batch, model, attacks, src_vocab, tgt_vocab):
    d = {}
    with torch.no_grad():
        for attack in attacks:
            input_variables, input_lengths  = getattr(batch, attack)
            target_variables = getattr(batch, seq2seq.tgt_field_name)

            decoder_outputs, decoder_hidden, other = model(input_variables, input_lengths.tolist(), target_variables)

            loss.reset()
            for step, step_output in enumerate(decoder_outputs):
                batch_size = target_variables.size(0)
                loss.eval_batch(step_output.contiguous().view(batch_size, -1), target_variables[:, step + 1])

            d["loss_%s"%attack] = loss.get_loss()

            # other['length'] should be a list of length 1 only, so the loop is redundant
            for i,output_seq_len in enumerate(other['length']):
                tgt_id_seq = [other['sequence'][di][i].data[0] for di in range(output_seq_len)]
                tgt_seq = [tgt_vocab.itos[tok] for tok in tgt_id_seq]
                output_seq = ' '.join([x for x in tgt_seq if x not in ['<sos>','<eos>','<pad>']])
                gt = [tgt_vocab.itos[tok] for tok in target_variables[i]]
                ground_truth = ' '.join([x for x in gt if x not in ['<sos>','<eos>','<pad>']])
            
    d['best_attack'] = max(d, key=d.get)
    d['output_seq'] = output_seq
    d['ground_truth'] = ground_truth

    return d

def attack_model(model, data, attacks, src_vocab, tgt_vocab):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    # batch size of 1 used as we need to find the worst attack for each data point individually
    batch_iterator = torchtext.data.BucketIterator(dataset=data, batch_size=1,sort=False, sort_within_batch=True,sort_key=lambda x: len(x.src),device=device, repeat=False)
    batch_generator = batch_iterator.__iter__()
    outputs = []
    gts = []

    with open(os.path.join(opt.output_dir,'%s_%s_attacked.txt'%(opt.load_checkpoint, opt.data_path.replace('/','_')[:-4])), 'w') as f:
        for batch in tqdm.tqdm(batch_generator):
            d  = get_best_attack(batch, model, attacks, src_vocab, tgt_vocab)
            outputs.append(d['output_seq'])
            gts.append(d['ground_truth'])
            f.write(json.dumps(d)+'\n')

    metrics = calculate_metrics(outputs, gts)

    print('Details written to', os.path.join(opt.output_dir,'%s_%s_attacked.txt'%(opt.load_checkpoint, opt.data_path.replace('/','_')[:-4])))

    print(metrics)

    with open(os.path.join(opt.output_dir,'%s_%s_attacked_metrics.txt'%(opt.load_checkpoint, opt.data_path.replace('/','_')[:-4])), 'w') as f:
        f.write(json.dumps(metrics)+'\n')

    print('Metrics written to', os.path.join(opt.output_dir,'%s_%s_attacked_metrics.txt'%(opt.load_checkpoint, opt.data_path.replace('/','_')[:-4])))


if __name__=="__main__":
    opt = parse_args()

    if opt.output_dir is None:
        opt.output_dir = opt.expt_dir

    data, fields, src, tgt = load_data(opt.data_path)
    attacks = [field[0] for field in fields if field[0] not in ['tgt']]

    print('Loaded Data')

    model_name = opt.load_checkpoint

    print(opt.expt_dir, model_name)      

    model, input_vocab, output_vocab = load_model(opt.expt_dir, model_name)

    print('Loaded model')

    src.vocab = input_vocab
    tgt.vocab = output_vocab

    weight = torch.ones(len(tgt.vocab))
    pad = tgt.vocab.stoi[tgt.pad_token]
    loss = Perplexity(weight, pad)
    if torch.cuda.is_available():
        loss.cuda()


    attack_model(model, data, attacks, input_vocab, output_vocab)




