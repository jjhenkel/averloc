import argparse
import json
import os
import numpy as np
import sys
import matplotlib.pyplot as plt
import math
from tabulate import tabulate


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--results_dir', action='store', dest='results_dir', required=True)
    parser.add_argument('--dataset', required=True)
    opt = parser.parse_args()
    return opt


def calc_gini(attr_matrix, method=2):
    if method==1:
        x = np.abs(attr_matrix.flatten())
        # Mean absolute difference
        mad = np.abs(np.subtract.outer(x, x)).mean()
        # Relative mean absolute difference
        rmad = mad/(np.mean(x)+0.00000001)
        # Gini coefficient
        g = 0.5 * rmad
        return g
    else:
        l = []
        if len(attr_matrix.shape)==1:
            attr_matrix = np.reshape(attr_matrix, (1,-1))
        s = 0
        for i in range(attr_matrix.shape[0]):
            x = np.abs(attr_matrix[i,:])
            mad = np.abs(np.subtract.outer(x, x)).mean()
            # Relative mean absolute difference
            rmad = mad/(np.mean(x)+0.00000001)
            # Gini coefficient
            g = 0.5 * rmad
            s += g
            l.append(g)

        return s/attr_matrix.shape[0], l



opt = parse_args()

models = ['normal', 'adversarial-all']

filename = 'attributions_labeled.txt'

data = {}

# most prominient predicted tokens for java-small
l = ['add', 'assert', 'base', 'class', 'create', 'delete', 'do', 'get', 'handle', 'help', 'id', 'is', 'main', 'name', 'path', 'read', 'remove', 'service', 'set', 'subsystem', 'test', 'write']
filter_pred_words = set(l)

for model in models:
    print(model)
    d = {}
    d['IG_gini'] = []
    d['attn_gini'] = []
    d['output_gini'] = {}
    d['input_tokens_map'] = {}
    d['input_classes_map'] = {}
    d['input_classes_agg'] = {}

    with open(os.path.join(opt.results_dir, model, opt.dataset, filename), 'r') as f:
        c = 0 
        l = f.readline()
        while l:
            p = json.loads(l)
            src = p['input_seq']
            tgt = p['target_seq']
            pred = p['pred_seq']
            src_labels = p['input_labels']
            
            IG = None
            attn = None

            if p['IG_attrs'] is not None:
                IG = np.array(p['IG_attrs']).astype(float) # Shape len(pred) x len(src)
                IG_matrix_gini, IG_vectors_gini = calc_gini(IG)
                d['IG_gini'].append(IG_matrix_gini)
            else:
                d['IG_gini'].append(np.nan)
            
            if p['attn_attrs'] is not None:
                attn = np.array(p['attn_attrs']).astype(float)
                attn_matrix_gini, attn_vectors_gini = calc_gini(attn)
                d['attn_gini'].append(attn_matrix_gini)

            else:
                d['IG_gini'].append(np.nan)

            for j, pred_word in enumerate(pred):
                if pred_word not in filter_pred_words:
                    pass
                    # continue

                if pred_word not in d['output_gini']:
                    d['output_gini'][pred_word] = {'sum_IG': 0, 'sum_attn': 0, 'count_IG': 0, 'count_attn': 0}

                if IG is not None:
                    d['output_gini'][pred_word]['sum_IG'] += IG_vectors_gini[j]
                    d['output_gini'][pred_word]['count_IG'] += 1

                if attn is not None:
                    d['output_gini'][pred_word]['sum_attn'] += attn_vectors_gini[j]
                    d['output_gini'][pred_word]['count_attn'] += 1



                if pred_word not in d['input_tokens_map']:
                    d['input_tokens_map'][pred_word] = {}
                if pred_word not in d['input_classes_map']:
                    d['input_classes_map'][pred_word] = {}

                for i, input_word in enumerate(src):

                    if input_word not in d['input_tokens_map'][pred_word]:
                        d['input_tokens_map'][pred_word][input_word] = {'sum_IG': 0, 'sum_attn': 0, 'count_IG': 0, 'count_attn': 0}

                    if IG is not None:
                        d['input_tokens_map'][pred_word][input_word]['sum_IG'] += IG[j][i]
                        d['input_tokens_map'][pred_word][input_word]['count_IG'] += 1

                    if attn is not None:
                        d['input_tokens_map'][pred_word][input_word]['sum_attn'] += attn[j][i]
                        d['input_tokens_map'][pred_word][input_word]['count_attn'] += 1    

                    label = src_labels[i]
                    if label not in d['input_classes_map'][pred_word]:
                        d['input_classes_map'][pred_word][label] = {'sum_IG': 0, 'sum_attn': 0, 'count_IG': 0, 'count_attn': 0}

                    if IG is not None:
                        d['input_classes_map'][pred_word][label]['sum_IG'] += IG[j][i]
                        d['input_classes_map'][pred_word][label]['count_IG'] += 1

                    if attn is not None:
                        d['input_classes_map'][pred_word][label]['sum_attn'] += attn[j][i]
                        d['input_classes_map'][pred_word][label]['count_attn'] += 1 


            for i, src_label in enumerate(src_labels):
                if src_label not in d['input_classes_agg']:
                    d['input_classes_agg'][src_label] = {'sum_IG': 0, 'sum_attn': 0, 'count_IG': 0, 'count_attn': 0}

                if IG is not None:
                    IG_mean = np.mean(IG, axis=0)
                    d['input_classes_agg'][src_label]['sum_IG'] += IG_mean[i]
                    d['input_classes_agg'][src_label]['count_IG'] += 1

                if attn is not None:
                    attn_mean = np.mean(attn, axis=0)
                    d['input_classes_agg'][src_label]['sum_attn'] += attn_mean[i]
                    d['input_classes_agg'][src_label]['count_attn'] += 1


            # exit()
            l = f.readline()
            c+=1

            if c==100:
                pass
                # break

            if c%200==0:
                print(c, end='\t')
                sys.stdout.flush()

    print()


    data[model] = d

# print(np.array(data[model]['IG_gini']))

#####################################################################################################################
for model in models:
    print(model, 'IG gini', np.nanmean(np.array(data[model]['IG_gini'])))
    print(model, 'attn_gini', np.nanmean(np.array(data[model]['attn_gini'])))
print('\n\n\n')

#####################################################################################################################
N = 40
print('N =', N)
print('Top N Output tokens in normal')
n1 = sorted([(x, data['normal']['output_gini'][x]['count_IG']) for x in data['normal']['output_gini']], reverse=True, key=lambda x:x[1])[:N]
print(n1)
print('Top N Output tokens in adversarial-all')
n2 = sorted([(x, data['adversarial-all']['output_gini'][x]['count_IG']) for x in data['adversarial-all']['output_gini']], reverse=True, key=lambda x:x[1])[:N]
print(n2)

t1 = [x[0] for x in n1]
t2 = [x[0] for x in n2]
t3 = [x for x in t1 if x in t2]
print(t1, t2, t3)


print(sorted(t3))

print('\n\n\n')
#####################################################################################################################

topk = 3

to_tabulate = {}

for pred_token in filter_pred_words:
    # print(pred_token)
    to_tabulate[pred_token] = {}

    for model in models:
        to_tabulate[pred_token][model] = {}
        # print(model)
        if pred_token not in data[model]['input_tokens_map']:
            continue
        t = data[model]['input_tokens_map'][pred_token]
        l1 = []
        l2 = []
        for x in t:
            avg_IG = t[x]['sum_IG']/(t[x]['count_IG']+0.0000001)
            l1.append((avg_IG, x))
            avg_attn = t[x]['sum_attn']/(t[x]['count_attn']+0.0000001)
            l2.append((avg_attn, x))
            # print(x, 'Avg IG:', avg_IG, 'Avg attn: ', avg_attn)
        l1 = sorted(l1, reverse=True)[:topk]
        l2 = sorted(l2, reverse=True)[:topk]
        # print(tabulate([l1,l2]))
        to_tabulate[pred_token][model]['IG'] = l1
        to_tabulate[pred_token][model]['attn'] = l2

    # print('\n\n')

c1 = []
c2 = []
c3 = []
c4 = []
c5 = []

sep = '_'*27

for pred_token in to_tabulate:
    if pred_token not in ['set', 'get', 'class', 'read', 'write', 'delete', 'do']:
        continue

    c1.extend([pred_token]+[' ']*(topk-1)+[sep])
    if 'IG' in to_tabulate[pred_token]['normal']:
        c2.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['normal']['IG']]+[sep])
    else:
        c2.extend([' ']*topk+[sep])
    if 'IG' in to_tabulate[pred_token]['adversarial-all']:
        c3.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['adversarial-all']['IG']]+[sep])
    else:
        c3.extend([' ']*topk+[sep])


    if 'attn' in to_tabulate[pred_token]['normal']:
        c4.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['normal']['attn']]+[sep])
    else:
        c4.extend([' ']*topk+[sep])
    if 'attn' in to_tabulate[pred_token]['adversarial-all']:
        c5.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['adversarial-all']['attn']]+[sep])
    else:
        c5.extend([' ']*topk+[sep])


# print(c1)
# print(c2)
# print(c3)

print('\n\n\n')

print(tabulate({'predicted word':c1, 'normal top IG':c2, 'adversarial-all top IG':c3, 
                    'normal top attn':c4, 'adversarial-all top attn':c5}, headers='keys', tablefmt="github"))

print('\n\n\n')

#####################################################################################################################

topk = 3

to_tabulate = {}

for pred_token in filter_pred_words:
    # print(pred_token)
    to_tabulate[pred_token] = {}

    for model in models:
        to_tabulate[pred_token][model] = {}
        # print(model)
        if pred_token not in data[model]['input_classes_map']:
            continue
        t = data[model]['input_classes_map'][pred_token]
        l1 = []
        l2 = []
        for x in t:
            avg_IG = t[x]['sum_IG']/(t[x]['count_IG']+0.0000001)
            l1.append((avg_IG, x))
            avg_attn = t[x]['sum_attn']/(t[x]['count_attn']+0.0000001)
            l2.append((avg_attn, x))
            # print(x, 'Avg IG:', avg_IG, 'Avg attn: ', avg_attn)
        l1 = sorted(l1, reverse=True)[:topk]
        l2 = sorted(l2, reverse=True)[:topk]
        # print(tabulate([l1,l2]))
        to_tabulate[pred_token][model]['IG'] = l1
        to_tabulate[pred_token][model]['attn'] = l2

    # print('\n\n')

c1 = []
c2 = []
c3 = []
c4 = []
c5 = []

sep = '_'*27

for pred_token in to_tabulate:
    if pred_token not in ['set', 'get', 'class', 'read', 'write', 'delete', 'do']:
        continue

    c1.extend([pred_token]+[' ']*(topk-1)+[sep])
    if 'IG' in to_tabulate[pred_token]['normal']:
        c2.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['normal']['IG']]+[sep])
    else:
        c2.extend([' ']*topk+[sep])
    if 'IG' in to_tabulate[pred_token]['adversarial-all']:
        c3.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['adversarial-all']['IG']]+[sep])
    else:
        c3.extend([' ']*topk+[sep])


    if 'attn' in to_tabulate[pred_token]['normal']:
        c4.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['normal']['attn']]+[sep])
    else:
        c4.extend([' ']*topk+[sep])
    if 'attn' in to_tabulate[pred_token]['adversarial-all']:
        c5.extend(['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate[pred_token]['adversarial-all']['attn']]+[sep])
    else:
        c5.extend([' ']*topk+[sep])

# print(c1)
# print(c2)
# print(c3)

print('\n\n\n')

print(tabulate({'predicted word':c1, 'normal top IG':c2, 'adversarial-all top IG':c3, 
                    'normal top attn':c4, 'adversarial-all top attn':c5}, headers='keys', tablefmt="github"))

print('\n\n\n')


#####################################################################################################################


topk = 100

to_tabulate = {}

for model in models:
    to_tabulate[model] = {}
    # print(model)
    t = data[model]['input_classes_agg']
    l1 = []
    l2 = []
    for x in t:
        avg_IG = t[x]['sum_IG']/(t[x]['count_IG']+0.0000001)
        l1.append((avg_IG, x))
        avg_attn = t[x]['sum_attn']/(t[x]['count_attn']+0.0000001)
        l2.append((avg_attn, x))
        # print(x, 'Avg IG:', avg_IG, 'Avg attn: ', avg_attn)
    l1 = sorted(l1, reverse=True)[:topk]
    l2 = sorted(l2, reverse=True)[:topk]
    # print(tabulate([l1,l2]))
    to_tabulate[model]['IG'] = l1
    to_tabulate[model]['attn'] = l2

    # print('\n\n')

c1 = ['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate['normal']['IG']]
c2 = ['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate['adversarial-all']['IG']]
c3 = ['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate['normal']['attn']]
c4 = ['%s (%.3f)'%(x[1], x[0]) for x in to_tabulate['adversarial-all']['attn']]





print(tabulate({
                'normal IG': c1, 
                'adv IG': c2,
                'normal attn': c3,
                'adv attn': c4
                }, headers='keys', tablefmt="github"))

print('\n\n\n')



#####################################################################################################################


# for pred_token in filter_pred_words:
#     if pred_token not in ['set', 'get']:
#         continue
#     print(pred_token)


#     for model in models:
#         print(model)
#         t = data[model]['input_classes_map'][pred_token]
#         for x in t:
#             avg_IG = t[x]['sum_IG']/t[x]['count_IG']
#             avg_attn = t[x]['sum_attn']/t[x]['count_attn']
#             print(x, 'Avg IG:', avg_IG, 'Avg attn: ', avg_attn)

#     print('\n\n')

exit()



plt.figure()

plt.subplot(2,2,1)
plt.boxplot([[i for i in data[model]['IG_gini'] if not np.isnan(i)] for model in models], labels=models, whis='range')
plt.title('IG Gini')


plt.subplot(2,2,2)
plt.boxplot([data[model]['attn_gini'] for model in models], labels=models, whis='range')
plt.title('Attention Gini')

plt.subplot(2,2,3)
l = []
print(len(data['adversarial-all']['IG_gini']), len(data['normal']['IG_gini']))
l1 = [data['adversarial-all']['IG_gini'][i]-data['normal']['IG_gini'][i] for i in range(len(data['adversarial-all']['IG_gini'])) 
    if not np.isnan(data['adversarial-all']['IG_gini'][i]-data['normal']['IG_gini'][i])]
l.append(l1)
plt.boxplot(l, labels=['delta-GINI(IG)'], whis='range') #, showfliers=False)
plt.title('Delta Gini Plot (IG)')

plt.subplot(2,2,4)
l = []
l.append([data['adversarial-all']['attn_gini'][i]-data['normal']['attn_gini'][i] for i in range(len(data['adversarial-all']['attn_gini']))])
plt.boxplot(l, labels=['delta-GINI(attn)'], whis='range')
plt.title('Delta Gini Plot (attention)')

plt.show()









