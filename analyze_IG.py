import argparse
import json
import os
import numpy as np
import sys
import matplotlib.pyplot as plt
import math

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
        s = 0
        for i in range(attr_matrix.shape[0]):
            x = np.abs(attr_matrix[i,:])
            mad = np.abs(np.subtract.outer(x, x)).mean()
            # Relative mean absolute difference
            rmad = mad/(np.mean(x)+0.00000001)
            # Gini coefficient
            g = 0.5 * rmad
            s += g

        return s/attr_matrix.shape[0]

opt = parse_args()

models = ['normal', 'adversarial-all']

filename = 'attributions_labeled.txt'

keywords = {'get': ['return'], 'set': ['=']}


data = {}

for model in models:
    print(model)
    d = {}
    d['IG_gini'] = []
    d['attn_gini'] = []
    for keyword in keywords:
        d[keyword] = {x: {'IG':[], 'attn':[]} for x in keywords[keyword]}
    with open(os.path.join(opt.results_dir, model, opt.dataset, filename), 'r') as f:
        c = 0 
        l = f.readline()
        while l:
            p = json.loads(l)
            src = p['input_seq']
            tgt = p['target_seq']
            pred = p['pred_seq']
            
            IG = None
            attn = None

            if p['IG_attrs'] is not None:
                IG = np.array(p['IG_attrs']).astype(float) # Shape len(pred) x len(src)
                d['IG_gini'].append(calc_gini(IG))
            else:
                d['IG_gini'].append(np.nan)
            
            if p['attn_attrs'] is not None:
                attn = np.array(p['attn_attrs']).astype(float)
                d['attn_gini'].append(calc_gini(attn))
            else:
                d['IG_gini'].append(np.nan)

            # for keyword in keywords:
            #     if keyword in pred:
            #         for inp_word in keywords[keyword]:
            #             if inp_word in src:
            #                 d[keyword][inp_word]['IG'].append(IG[pred.])

            # exit()
            l = f.readline()
            c+=1
            if c%200==0:
                print(c, end='\t')
                sys.stdout.flush()

    print()


    data[model] = d

# print(np.array(data[model]['IG_gini']))

for model in models:
    print(model, 'IG gini', np.nanmean(np.array(data[model]['IG_gini'])))
    print(model, 'attn_gini', np.nanmean(np.array(data[model]['attn_gini'])))




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









