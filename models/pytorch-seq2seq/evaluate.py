from seq2seq.loss import Perplexity
from seq2seq.util.checkpoint import Checkpoint
from seq2seq.dataset import SourceField, TargetField
from seq2seq.evaluator import Evaluator
import os
import torchtext
import torch
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--data_path', action='store', dest='data_path',
                    help='Path to test data')
parser.add_argument('--expt_dir', action='store', dest='expt_dir', default='./experiment',
                    help='Path to experiment directory. If load_checkpoint is True, then path to checkpoint directory has to be provided')
parser.add_argument('--load_checkpoint', action='store', dest='load_checkpoint',
                    help='The name of the checkpoint to load, usually an encoded time string')
parser.add_argument('--batch_size', action='store', dest='batch_size', default=64)
parser.add_argument('--output_file', action='store', dest='output_file', default=None)

opt = parser.parse_args()

checkpoint_path = os.path.join(opt.expt_dir, Checkpoint.CHECKPOINT_DIR_NAME, opt.load_checkpoint)
checkpoint = Checkpoint.load(checkpoint_path)
seq2seq = checkpoint.model
input_vocab = checkpoint.input_vocab
output_vocab = checkpoint.output_vocab

src = SourceField()
tgt = TargetField()

dev = torchtext.data.TabularDataset(
    path=opt.data_path, format='tsv',
    fields=[('src', src), ('tgt', tgt)]
)

src.vocab = input_vocab
tgt.vocab = output_vocab


weight = torch.ones(len(tgt.vocab))
pad = tgt.vocab.stoi[tgt.pad_token]
loss = Perplexity(weight, pad)
if torch.cuda.is_available():
    loss.cuda()
evaluator = Evaluator(loss=loss, batch_size=opt.batch_size)

print('Size of Test Set', sum(1 for _ in dev.src))
loss, acc, other, output_seqs = evaluator.evaluate(seq2seq, dev)
other.update({'Loss':loss, 'Acc (torch)': acc})
for m in other:
	print(m,other[m])

print(len(output_seqs))

if opt.output_file is not None:
	with open(opt.output_file, 'w') as f:
		f.writelines([a+'\n' for a in output_seqs])
	print('Output file written')







