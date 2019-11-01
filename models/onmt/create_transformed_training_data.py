from attack_test_data import TRANSFORMS
import os, random

data_dir = os.path.join('..','data','python_data')

train_data_file = os.path.join(data_dir,'train_500000.data')
train_labels_file = os.path.join(data_dir, 'train_500000.labels')
train_adv_data_file = os.path.join(data_dir,'train_adv2_500000.data')
train_adv_labels_file = os.path.join(data_dir, 'train_adv2_500000.labels')

f_orig_data = open(train_data_file, 'r')
f_adv_data = open(train_adv_data_file, 'w')

f_orig_labels = open(train_labels_file, 'r')
f_adv_labels = open(train_adv_labels_file, 'w')


## Retain original size of training set
for data_line in f_orig_data:
	label_line = f_orig_labels.readline()

	transformed_data = data_line
	for i in range(len(TRANSFORMS)):
		transform = random.choice(TRANSFORMS)
		transformed_data = transform(data_line)
		if transformed_data != data_line:
			break
	f_adv_data.write(transformed_data)
	f_adv_labels.write(label_line)


## Apply all possible transforms to create larger training set
# for data_line in f_orig_data:
# 	label_line = f_orig_labels.readline()
# 	f_adv_data.write(data_line)
# 	f_adv_labels.write(label_line)

# 	for transform in TRANSFORMS:
# 		transformed_data = transform(data_line)
# 		if transformed_data != data_line:
# 			f_adv_data.write(transformed_data)
# 			f_adv_labels.write(label_line)


f_orig_data.close()
f_adv_data.close()
f_orig_labels.close()
f_adv_labels.close()

print('Written to files', train_data_file, train_labels_file, train_adv_data_file, train_adv_labels_file)

