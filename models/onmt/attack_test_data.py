import os, keyword, random

def replace_elifs(body):
	replacement = 'else : if '
	if 'elif' in body:
		body = body.replace('elif',replacement)
		return body
	else:
		return body


def remove_vowels_from_argname(body):
	body_l = body.split()
	if body_l[0] == 'self':
		if body_l[1] == ',':
			new_var_name = body_l[2]
			for vowel in ['a','e','i','o','u']:
				if random.random() < 0.75:
					new_var_name = new_var_name.replace(vowel,'')
			return body.replace(body_l[2], new_var_name)
		else:
			# dont change anything if self is the only argument
			return body
	else:
		if keyword.iskeyword(body_l[0]):
			return body
		else:
			new_var_name = body_l[0]
			for vowel in ['a','e','i','o','u']:
				new_var_name = new_var_name.replace(vowel,'')
		return body.replace(body_l[0], new_var_name)


def insert_dummy_if_statement(body):
	statement = 'if true : '

	if 'return' in body:
		i = body.index('return')
		modified = body[:i] + statement + body[i:]
		return modified
	else:
		return body


def insert_print_statement(body):
	statement = ' print ( )'
	return body + ' ' + statement


def replace_self(body):
	replacement = 'me'
	if 'self' in body:
		body = body.replace('self',replacement)
		return body
	else:
		return body


TRANSFORMS = [insert_print_statement, insert_dummy_if_statement, replace_elifs, remove_vowels_from_argname]

if __name__=="__main__":


	body = 'self , dummy_varname a = 1 if a > 1 : pass elif a < 1 : pass else : return self . copy ( dummy_varname )'
	print(body)
	print(insert_dummy_if_statement(body))
	print(insert_print_statement(body))
	print(replace_elifs(body))
	print(remove_vowels_from_argname(body))
	print(replace_self(body))

	
	data_dir = os.path.join('..','data','python_data')

	test_data_file = os.path.join(data_dir,'test_500000.data')
	test_adv_data_file = os.path.join(data_dir,'test_adv_500000.data')

	f_orig = open(test_data_file, 'r')
	f_adv = open(test_adv_data_file, 'w')

	for body in f_orig.readlines():
		adv_body = body[:-1]
		for t in TRANSFORMS:
			adv_body = t(adv_body)
		f_adv.write(adv_body+'\n')

	f_orig.close()
	f_adv.close()








