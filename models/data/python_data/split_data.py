import csv, sys, random, re, json
csv.field_size_limit(100000000)	

def process_method_name(name):
	if name[:2]=="__" and name[-2:]=="__":
		return name, False

	if name[:2]=="__":
		name = name[2:]

	name = name.replace('__','_').replace('_',' ').strip()

	# to split up camelcase
	name = ' '.join(re.sub('([A-Z][a-z]+)', r' \1', re.sub('([A-Z]+)', r' \1', name)).split()).lower()

	return name, True


def process_method_body(body, keep_docstring=False):

	body = body.replace('\\\"', ' " ').replace('"  "  "', '"""')
	body = body.replace('.',' . ').replace('\'',' \' ').replace('\\n','').replace(',',' , ').replace('_',' ').replace('-',' ')

	if not keep_docstring:
		i = body.find('"""')
		pre = body[:i]
		post = body[i+3:]
		post = post[post.find('"""')+3:]
		body = pre+post

	# to split up camelcase
	body = ' '.join(re.sub('([A-Z][a-z]+)', r' \1', re.sub('([A-Z]+)', r' \1', body)).split()).lower()

	a = [t for t in body.split(' ') if len(t)>0]

	return ' '.join(a), len(a)


NUM = 5000
MIN_LEN = 5
MAX_LEN = 128

config = {'NUM': NUM, 'MIN_LEN': MIN_LEN, 'MAX_LEN': MAX_LEN}

with open("python-data-1500k.tsv", encoding='utf8') as tsvfile:
	tsvreader = csv.reader(tsvfile, delimiter="\t", quoting=csv.QUOTE_NONE)

	random.seed(0)
	indices = list(range(NUM))
	random.shuffle(indices)

	file_X_train = open('train_%d.data'%NUM, 'w', encoding='utf8')
	file_Y_train = open('train_%d.labels'%NUM, 'w', encoding='utf8')

	file_X_val = open('val_%d.data'%NUM, 'w', encoding='utf8')
	file_Y_val = open('val_%d.labels'%NUM, 'w', encoding='utf8')

	file_X_test = open('test_%d.data'%NUM, 'w', encoding='utf8')
	file_Y_test = open('test_%d.labels'%NUM, 'w', encoding='utf8')

	TRAIN = sorted(indices[:int(NUM*0.8)])
	VAL = sorted(indices[int(NUM*0.8):int(NUM*0.9)])
	TEST = sorted(indices[int(NUM*0.9):NUM])

	train_ind = 0
	val_ind = 0
	test_ind = 0

	c = 0 
	header = True
	for line in tsvreader:
		if header:
			header = False
			continue

		name, flag = process_method_name(line[5])
		body, l = process_method_body(line[6])

		if flag and l>=MIN_LEN and l<=MAX_LEN:
			if c%1000==0:
				print(c, end=' ')
				sys.stdout.flush()
				file_X_train.flush()
				file_Y_train.flush()
				file_X_val.flush()
				file_Y_val.flush()
				file_X_test.flush()
				file_Y_test.flush()


			if len(TRAIN)>0 and c == TRAIN[train_ind]:
				train_ind += 1
				file_X_train.write(body+'\n')
				file_Y_train.write(name+'\n')
			elif len(VAL)>0 and c == VAL[val_ind]:
				val_ind += 1
				file_X_val.write(body+'\n')
				file_Y_val.write(name+'\n')
			elif len(TEST)>0 and c == TEST[test_ind]:
				test_ind += 1
				file_X_test.write(body+'\n')
				file_Y_test.write(name+'\n')
			else:
				raise Exception('Something is wrong')

			c += 1
			if c==NUM:
				break

	file_X_train.close()
	file_Y_train.close()
	file_X_val.close()
	file_Y_val.close()
	file_X_test.close()
	file_Y_test.close()

	config['c'] = c
	json.dump(config, open('config_%d.json'%NUM, 'w'), indent=4)
	print(config)




