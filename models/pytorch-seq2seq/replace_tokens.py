import json
import pandas as pd 
import argparse
import tqdm

def parse_args():
	parser = argparse.ArgumentParser()
	parser.add_argument('--source_data_path', required=True)
	parser.add_argument('--dest_data_path', required=True)
	parser.add_argument('--mapping_json', required=True)
	opt = parser.parse_args()
	return opt

opt = parse_args()

data = pd.read_csv(opt.source_data_path, sep='\t', index_col=0)

mapping = json.load(open(opt.mapping_json))

removed = []
for index, row in data.iterrows():
	delete = True
	for col_name in mapping:
		if str(index) in mapping[col_name]:
			delete=False
			break
	if delete:
		removed.append(index)

print('Original data size',len(data))
data = data.drop(removed)
print('%d indices were removed from set because no mapping data was found'%len(removed))
print('New data size',len(data))
# exit()

for index, row in tqdm.tqdm(data.iterrows(), total=len(data)):
	# print(data.loc[index])
	for col_name, v in row.items():
		if col_name not in mapping:
			continue
		if str(index) not in mapping[col_name]:
			if data[col_name][index].find("@R_")!=-1:
				print('Missing index %d for column name %s, but it appears to have replaceable tokens'%(index, col_name))
			continue
		for repl_tok in mapping[col_name][str(index)]:
			data[col_name][index] = data[col_name][index].replace(repl_tok, mapping[col_name][str(index)][repl_tok])

	# print(data.loc[index])
	# print('-'*50)

	# break

data.to_csv(opt.dest_data_path, sep='\t')
print('Output file written', opt.dest_data_path)