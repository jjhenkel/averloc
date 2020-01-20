from seq2seq.loss import Perplexity
from seq2seq.util.checkpoint import Checkpoint
from seq2seq.dataset import SourceField, TargetField
from seq2seq.evaluator import Evaluator
from evaluate import evaluate_model

import os
import torchtext
import torch
import argparse
import json
import csv


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
    parser.add_argument('--save', action='store_true')

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
	src_adv = SourceField()
	tgt = TargetField()

	fields = []
	with open(data_path, 'r') as f:
		cols = f.readline()[:-1].split('\t')
		for col in cols:
			if col=='src':
				fields.append(('src', src))
			elif col=='tgt':
				fields.append(('tgt', tgt))
			else:
				fields.append((col, src_adv))

	print('Fields', [field[0] for field in fields])

	dev = torchtext.data.TabularDataset(
									path=data_path, format='tsv',
									fields=fields,
									skip_header=True, 
									csv_reader_params={'quoting': csv.QUOTE_NONE}
									)

	return dev, fields, src, src_adv, tgt


def attack_model():
	pass


if __name__=="__main__":
	opt = parse_args()
	if opt.load_checkpoint == 'all':
		models = ['Best_Acc', 'Best_F1', 'Latest']
	else:
		models = [opt.load_checkpoint]

	if opt.output_dir is None:
		opt.output_dir = opt.expt_dir

	data, fields, src, src_adv, tgt = load_data(opt.data_path)

	print('Loaded Data')

	for model_name in models:
		print(opt.expt_dir, model_name)      

		seq2seq, input_vocab, output_vocab = load_model(opt.expt_dir, model_name)

		print('Loaded model')

		src.vocab = input_vocab
		src_adv.vocab = input_vocab
		tgt.vocab = output_vocab

		weight = torch.ones(len(tgt.vocab))
		pad = tgt.vocab.stoi[tgt.pad_token]
		loss = Perplexity(weight, pad)
		if torch.cuda.is_available():
			loss.cuda()
		evaluator = Evaluator(loss=loss, batch_size=opt.batch_size)

		for input_src, _ in fields:
			if input_src == 'tgt':
				continue
			print(input_src)

			output_fname = model_name.lower() + '_' + input_src

			evaluate_model(evaluator, seq2seq, data, opt.save, opt.output_dir, output_fname, src_field_name=input_src)




