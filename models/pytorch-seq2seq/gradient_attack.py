import os
import re
import sys
import json

from seq2seq.loss import Perplexity
from seq2seq.util.checkpoint import Checkpoint
from seq2seq.dataset import SourceField, TargetField
from seq2seq.evaluator import Evaluator
from torch.autograd import Variable

import seq2seq
import os
import torchtext
import torch
import argparse
import json
import csv
import tqdm
import numpy as np
import random

random.seed(0)

def parse_args():
	parser = argparse.ArgumentParser()
	parser.add_argument('--data_path', action='store', dest='data_path', help='Path to data')
	parser.add_argument('--expt_dir', action='store', dest='expt_dir', required=True,
						help='Path to experiment directory. If load_checkpoint is True, then path to checkpoint directory has to be provided')
	parser.add_argument('--load_checkpoint', action='store', dest='load_checkpoint', default='Best_F1')
	parser.add_argument('--num_replacements', default=50)
	parser.add_argument('--distinct', action='store_true', dest='distinct', default=True)
	parser.add_argument('--no-distinct', action='store_false', dest='distinct')
	parser.add_argument('--batch_size', type=int, default=32)
	parser.add_argument('--save_path', default=None)
	parser.add_argument('--random', action='store_true', default=False, help='Also generate random attack')
	opt = parser.parse_args()

	return opt


def classify_tok(tok):
	PY_KEYWORDS = re.compile(
	  r'^(False|class|finally|is|return|None|continue|for|lambda|try|True|def|from|nonlocal|while|and|del|global|not|with|as|elif|if|or|yield|assert|else|import|pass|break|except|in|raise)$'
	)

	JAVA_KEYWORDS = re.compile(
	  r'^(abstract|assert|boolean|break|byte|case|catch|char|class|continue|default|do|double|else|enum|exports|extends|final|finally|float|for|if|implements|import|instanceof|int|interface|long|module|native|new|package|private|protected|public|requires|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while)$'
	)

	NUMBER = re.compile(
	  r'^\d+(\.\d+)?$'
	)

	BRACKETS = re.compile(
	  r'^(\{|\(|\[|\]|\)|\})$'
	)

	OPERATORS = re.compile(
	  r'^(=|!=|<=|>=|<|>|\?|!|\*|\+|\*=|\+=|/|%|@|&|&&|\||\|\|)$'
	)

	PUNCTUATION = re.compile(
	  r'^(;|:|\.|,)$'
	)

	WORDS = re.compile(
	  r'^(\w+)$'
	)


	if PY_KEYWORDS.match(tok):
		return 'KEYWORD'
	elif JAVA_KEYWORDS.match(tok):
		return 'KEYWORD'
	elif NUMBER.match(tok):
		return 'NUMBER'
	elif BRACKETS.match(tok):
		return 'BRACKET'
	elif OPERATORS.match(tok):
		return 'OPERATOR'
	elif PUNCTUATION.match(tok):
		return 'PUNCTUATION'
	elif WORDS.match(tok):
		return 'WORDS'
	else:
		return 'OTHER'


device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

def load_model(expt_dir, model_name):
    checkpoint_path = os.path.join(expt_dir, Checkpoint.CHECKPOINT_DIR_NAME, model_name)
    checkpoint = Checkpoint.load(checkpoint_path)
    model = checkpoint.model
    input_vocab = checkpoint.input_vocab
    output_vocab = checkpoint.output_vocab
    return model, input_vocab, output_vocab

def load_data(data_path, 
	fields=(SourceField(), TargetField(), SourceField(), torchtext.data.Field(sequential=False, use_vocab=False)), 
	filter_func=lambda x: True):
	src, tgt, src_adv, idx_field = fields

	fields_inp = []
	with open(data_path, 'r') as f:
		first_line = f.readline()
		cols = first_line[:-1].split('\t')
		for col in cols:
			if col=='src':
				fields_inp.append(('src', src))
			elif col=='tgt':
				fields_inp.append(('tgt', tgt))
			elif col=='index':
				fields_inp.append(('index', idx_field))
			else:
				fields_inp.append((col, src_adv))

	data = torchtext.data.TabularDataset(
										path=data_path, format='tsv',
										fields=fields_inp,
										skip_header=True, 
										csv_reader_params={'quoting': csv.QUOTE_NONE}, 
										filter_pred=filter_func
										)

	return data, fields_inp, src, tgt, src_adv, idx_field


def get_best_token_replacement(inputs, grads, vocab, indices, replace_tokens, distinct):
	'''
	inputs is numpy array with indices (batch, max_len)
	grads is numpy array (batch, max_len, vocab_size)
	vocab is Vocab object
	indices is numpy array of size batch
	'''
	def valid_replacement(s, exclude=[]):
		return classify_tok(s)=='WORDS' and s not in exclude
    
	best_replacements = {}    
	for i in range(inputs.shape[0]):
		inp = inputs[i]
		gradients = grads[i]
		index = str(indices[i])
		

		d = {}				
		for repl_tok in replace_tokens:
			repl_tok_idx = vocab.stoi[repl_tok]
			if repl_tok_idx not in inp:
				continue
				
			mask = inp==repl_tok_idx

			# Is mean the right thing to do here? 
			avg_tok_grads = np.mean(gradients[mask], axis=0)

			exclude = list(d.values()) if distinct else []
			
			max_idx = np.argmax(avg_tok_grads)
			if not valid_replacement(vocab.itos[max_idx], exclude=exclude):
				idxs = np.argsort(avg_tok_grads)[::-1]
				for idx in idxs:
					if valid_replacement(vocab.itos[idx], exclude=exclude):
						max_idx = idx
						break
			d[repl_tok] = vocab.itos[max_idx]

		if len(d)>0:
			best_replacements[index] = d
	
	return best_replacements


def get_random_token_replacement(inputs, vocab, indices, replace_tokens, distinct):
	'''
	inputs is numpy array with indices (batch, max_len)
	grads is numpy array (batch, max_len, vocab_size)
	vocab is Vocab object
	indices is numpy array of size batch
	'''
	def valid_replacement(s, exclude=[]):
		return classify_tok(s)=='WORDS' and s not in exclude
    
	rand_replacements = {}    
	for i in range(inputs.shape[0]):
		inp = inputs[i]
		index = str(indices[i])
		
		d = {}		
		for repl_tok in replace_tokens:
			repl_tok_idx = input_vocab.stoi[repl_tok]
			if repl_tok_idx not in inp:
				continue
				
			exclude = list(d.values()) if distinct else []
			
			rand_idx = random.randint(0, len(vocab)-1)
			while not valid_replacement(vocab.itos[rand_idx], exclude=exclude):
				rand_idx = random.randint(0, len(vocab)-1)

			d[repl_tok] = vocab.itos[rand_idx]

		if len(d)>0:
			rand_replacements[index] = d
	
	return rand_replacements


def apply_gradient_attack(data, model, input_vocab, replace_tokens, field_name, opt):

	def convert_to_onehot(inp, vocab_size):
		return torch.zeros(inp.size(0), inp.size(1), vocab_size, device=device).scatter_(2, inp.unsqueeze(2), 1.)

	batch_iterator = torchtext.data.BucketIterator(
		dataset=data, batch_size=opt.batch_size,
		sort=False, sort_within_batch=True,
		sort_key=lambda x: len(x.src),
		device=device, repeat=False
		)
	batch_generator = batch_iterator.__iter__()
	c = 0

	weight = torch.ones(len(tgt.vocab))
	pad = tgt.vocab.stoi[tgt.pad_token]
	loss = Perplexity(weight, pad)
	if torch.cuda.is_available():
		loss.cuda()
	model.train()

	d = {}

	for batch in tqdm.tqdm(batch_generator, total=len(batch_iterator)):
		indices = getattr(batch, 'index')
		input_variables, input_lengths = getattr(batch, field_name)
		target_variables = getattr(batch, 'tgt')

		# convert input_variables to one_hot
		input_onehot = Variable(convert_to_onehot(input_variables, vocab_size=len(input_vocab)), requires_grad=True)
	  
		# Forward propagation		
		decoder_outputs, decoder_hidden, other = model(input_onehot, input_lengths, target_variables, already_one_hot=True)

		# print outputs for debugging
		# for i,output_seq_len in enumerate(other['length']):
		#	print(i,output_seq_len)
		#	tgt_id_seq = [other['sequence'][di][i].data[0] for di in range(output_seq_len)]
		#	tgt_seq = [output_vocab.itos[tok] for tok in tgt_id_seq]
		#	print(' '.join([x for x in tgt_seq if x not in ['<sos>','<eos>','<pad>']]), end=', ')
		#	gt = [output_vocab.itos[tok] for tok in target_variables[i]]
		#	print(' '.join([x for x in gt if x not in ['<sos>','<eos>','<pad>']]))
		
		# Get loss
		loss.reset()
		for step, step_output in enumerate(decoder_outputs):
			batch_size = target_variables.size(0)
			loss.eval_batch(step_output.contiguous().view(batch_size, -1), target_variables[:, step + 1])
		# Backward propagation
		model.zero_grad()
		input_onehot.retain_grad()
		loss.backward(retain_graph=True)
		grads = input_onehot.grad
		del input_onehot

		c+=1
		if c==3:
			pass
			# break


		best_replacements = get_best_token_replacement(input_variables.cpu().numpy(), grads.cpu().numpy(), 
																	input_vocab, indices.cpu().numpy(), replace_tokens, opt.distinct)

		d.update(best_replacements)

	return d


def apply_random_attack(data, model, input_vocab, replace_tokens, field_name, opt):

	batch_iterator = torchtext.data.BucketIterator(
		dataset=data, batch_size=opt.batch_size,
		sort=False, sort_within_batch=True,
		sort_key=lambda x: len(x.src),
		device=device, repeat=False)
	batch_generator = batch_iterator.__iter__()
	c = 0

	d = {}

	for batch in tqdm.tqdm(batch_generator, total=len(batch_iterator)):
		indices = getattr(batch, 'index')
		input_variables, input_lengths = getattr(batch, field_name)
		target_variables = getattr(batch, 'tgt')

		c+=1
		if c==3:
			pass
			# break

		rand_replacements = get_random_token_replacement(input_variables.cpu().numpy(),
																	input_vocab, indices.cpu().numpy(), replace_tokens, opt.distinct)

		d.update(rand_replacements)

	return d


if __name__=="__main__":
	opt = parse_args()
	print(opt)

	replace_tokens = ["@R_%d@"%x for x in range(1,opt.num_replacements+1)]
	print('Replace tokens:', replace_tokens)

	model, input_vocab, output_vocab = load_model(opt.expt_dir, opt.load_checkpoint)

	data, fields_inp, src, tgt, src_adv, idx_field = load_data(opt.data_path, filter_func=lambda x: len(x.src)<250)
	src.vocab = input_vocab
	tgt.vocab = output_vocab
	src_adv.vocab = input_vocab

	print('Data size:', len(data))


	if opt.random:
		rand_d = {}

		for field_name, _ in fields_inp:
			if field_name in ['src', 'tgt', 'index', 'transforms.Identity']:
				continue

			print('Random Attack', field_name)
			rand_d[field_name] = apply_random_attack(data, model, input_vocab, replace_tokens, field_name, opt)

		save_path = opt.save_path
		if save_path is None:
			fname = opt.data_path.replace('/', '|').replace('.','|') + "%s.json"%("-distinct" if opt.distinct else "")
			save_path = os.path.join(opt.expt_dir, fname)

		# Assuming save path ends with '.json'
		save_path = save_path[:-5] + '-random.json'
		json.dump(rand_d, open(save_path, 'w'), indent=4)
		print('Saved:', save_path)



	d = {}
	for field_name, _ in fields_inp:
		if field_name in ['src', 'tgt', 'index', 'transforms.Identity']:
			continue

		print('Attacking using Gradient', field_name)
		d[field_name] = apply_gradient_attack(data, model, input_vocab, replace_tokens, field_name, opt)
		# break

	save_path = opt.save_path
	if save_path is None:
		fname = opt.data_path.replace('/', '|').replace('.','|') + "%s.json"%("-distinct" if opt.distinct else "")
		save_path = os.path.join(opt.expt_dir, fname)
	# Assuming save path ends with '.json'
	save_path = save_path[:-5] + '-gradient.json'
	json.dump(d, open(save_path, 'w'), indent=4)
	print('Saved:', save_path)


	

