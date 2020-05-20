import re

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



def get_best_token_replacement(inputs, grads, vocab, indices, replace_tokens, distinct):
	'''
	inputs is numpy array with input vocab indices (batch, max_len)
	grads is numpy array (batch, max_len, vocab_size)
	vocab is Vocab object
	indices is numpy array of size batch
	returns a dict with {index: {"@R_1@":'abc', ...}}
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
			repl_tok_idx = input_vocab.stoi[repl_tok]
			if repl_tok_idx not in inp:
				continue
				
			inp[0] = repl_tok_idx
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
	inputs is numpy array with input vocab indices (batch, max_len)
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
				
			inp[0] = repl_tok_idx

			exclude = list(d.values()) if distinct else []
			
			rand_idx = random.randint(0, len(vocab)-1)
			while not valid_replacement(vocab.itos[rand_idx], exclude=exclude):
				rand_idx = random.randint(0, len(vocab)-1)

			d[repl_tok] = vocab.itos[rand_idx]

		if len(d)>0:
			rand_replacements[index] = d
	
	return rand_replacements