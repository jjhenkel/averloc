import os

def insert_dummy_if_statement(body):
	statement = ['if', '1', '>', '2', ':', 'return', 'None', 'else', ':']

	if 'return' in body:
		i = body.index('return')
		modified = body[:i] + ' '.join(statement) + body[i:]
		return modified, True
	else:
		return body, False


def insert_print_statement(body):
	statement = ' print ( )'
	return body[:-1] + ' ' + statement, True

def replace_self(body):
	replacement = 'me'
	if 'self' in body:
		body = body.replace('self',replacement)
		return body, True
	else:
		return body, False



body = 'self return self . copy ( )'
print(body)
print(insert_dummy_if_statement(body)[0])
print(insert_print_statement(body)[0])
print(replace_self(body)[0])

TRANSFORMS = [insert_print_statement, insert_dummy_if_statement, replace_self]

data_dir = os.path.join('..','data','python_data')

test_data_file = os.path.join(data_dir,'test_5000.data')
test_adv_data_file = os.path.join(data_dir,'test_adv_5000.data')

f_orig = open(test_data_file, 'r')
f_adv = open(test_adv_data_file, 'w')

for body in f_orig.readlines():
	adv_body = body
	for t in TRANSFORMS:
		adv_body = t(adv_body)[0]
	f_adv.write(adv_body+'\n')

f_orig.close()
f_adv.close()








