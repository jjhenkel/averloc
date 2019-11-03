import sys, os


def calculate_metrics_from_files(pred_file, labels_file):

	f_pred = open(pred_file, 'r')
	f_true = open(labels_file, 'r')

	a = calculate_metrics(f_pred.readlines(), f_true.readlines())
	for m in a:
		print('%s: %.3f'%(m,a[m]))
	print()
	f_pred.close()
	f_true.close()


def get_freqs(pred, true):
	all_words = set(pred+true)
	d_pred = {x: pred.count(x) for x in all_words}
	d_true = {x: true.count(x) for x in all_words}
	return d_pred, d_true

def calculate_metrics(y_pred, y_true):
	''' 
	Calculate exact match accuracy, precision, recall, F1 score, word-level accuracy
	y_pred and y_true are lists of strings
	function returns dict with the calculated metrics
	'''

	N = min(len(y_pred),len(y_true))
	# N = 4500
	if len(y_pred)!=len(y_true):
		print('Warning: The number of predictions and ground truths are not equal, calculating metrics over %d points'%N)

	

	# for precision, recall, f1
	tp = 0
	fp = 0
	fn = 0

	# for exact match
	exact_match = 0

	# for word-level accuracy
	correct_words = 0
	total_words = 0

	for i in range(N):
		# print(i)
		pred = y_pred[i].split()
		true = y_true[i].split()

		total_words += len(true)
		for j in range(min(len(true), len(pred))):
			if pred[j]==true[j]:
				correct_words += 1


		d_pred, d_true = get_freqs(pred, true)
		if d_pred == d_true:
			exact_match += 1

		# print(d_pred, d_true)
		for word in d_pred:
			tp += min(d_pred[word], d_true[word])
			fp += max(0, d_pred[word]-d_true[word])
			fn += max(0, d_true[word]-d_pred[word])

	# print(tp, fp, fn)
	precision = tp / (tp+fp)
	recall = tp / (tp+fn)
	f1 = 2*precision*recall / (precision+recall)
	exact_match /= N
	word_level_accuracy = correct_words / total_words

	return {'precision': precision, 'recall': recall, 'f1': f1, 'exact_match':exact_match, 'word-level accuracy': word_level_accuracy}

def parse_args():
	import argparse

	parser = argparse.ArgumentParser()
	parser.add_argument('--f_true', help='File with ground truth labels', required=True)
	parser.add_argument('--f_pred', help='File with predicted labels', required=True)

	args = parser.parse_args()
	assert os.path.exists(args.f_true), 'Invalid file for ground truth labels'
	assert os.path.exists(args.f_pred), 'Invalid file for predicted labels'
	return args


if __name__=="__main__":
	args = parse_args()
	calculate_metrics_from_files(args.f_pred, args.f_true)
