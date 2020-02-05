import re
import sys
import json
import numpy as np


MIN_SUPPORT = 100
FILTER_REGEX = re.compile(r'^[a-zA-Z]+$')

def get_supported_tuples(nrm_attributions, adv_attributions):
  nrm_tuples = {}
  adv_tuples = {}

  for as_json in nrm_attributions:
    for i, in_word in enumerate(as_json['input_seq']):
      for j, pred_word in enumerate(as_json['pred_seq']):
        if not FILTER_REGEX.match(in_word) or not FILTER_REGEX.match(pred_word):
          continue
        if in_word == pred_word:
          continue
        if in_word not in nrm_tuples:
          nrm_tuples[in_word] = {}
        if pred_word not in nrm_tuples[in_word]:
          nrm_tuples[in_word][pred_word] = []
        nrm_tuples[in_word][pred_word].append((
          float(as_json['IG_attrs'][j][i]),
          float(as_json['attn_attrs'][j][i])
        ))

  for as_json in adv_attributions:
    for i, in_word in enumerate(as_json['input_seq']):
      for j, pred_word in enumerate(as_json['pred_seq']):
        if not FILTER_REGEX.match(in_word) or not FILTER_REGEX.match(pred_word):
          continue
        if in_word == pred_word:
          continue
        if in_word not in adv_tuples:
          adv_tuples[in_word] = {}
        if pred_word not in adv_tuples[in_word]:
          adv_tuples[in_word][pred_word] = []
        adv_tuples[in_word][pred_word].append((
          float(as_json['IG_attrs'][j][i]),
          float(as_json['attn_attrs'][j][i])
        ))

  for src_word in nrm_tuples.keys():
    for tgt_word in nrm_tuples[src_word].keys():
      if src_word not in adv_tuples or tgt_word not in adv_tuples[src_word]:
        continue
      the_support = len(nrm_tuples[src_word][tgt_word]) + len(adv_tuples[src_word][tgt_word])
      if the_support > MIN_SUPPORT:
        yield (
          the_support,
          src_word,
          tgt_word,
          np.mean([ (x[0]) for x in nrm_tuples[src_word][tgt_word] ]),
          np.mean([ (x[0]) for x in adv_tuples[src_word][tgt_word] ]),
          np.mean([ (x[1]) for x in nrm_tuples[src_word][tgt_word] ]),
          np.mean([ (x[1]) for x in adv_tuples[src_word][tgt_word] ])
        )


def load_data():
  nrm_attributions = []
  with open('{}/normal/complete/attributions.txt'.format(sys.argv[1]), 'r') as nrm_attrs_f:
    for line in nrm_attrs_f.readlines():
      try:
        as_json = json.loads(line)
        if 'IG_attrs' not in as_json or as_json['IG_attrs'] is None:
          continue
        nrm_attributions.append(as_json)
      except Exception as ex:
        print(line)

  adv_attributions = []
  with open('{}/adversarial-all/complete/attributions.txt'.format(sys.argv[1]), 'r') as adv_attrs_f:
    for line in adv_attrs_f.readlines():
      try:
        as_json = json.loads(line)
        if 'IG_attrs' not in as_json or as_json['IG_attrs'] is None:
          continue
        adv_attributions.append(as_json)
      except Exception as ex:
        print(line)
  return nrm_attributions, adv_attributions


if __name__ == '__main__':
  nrm_attributions, adv_attributions = load_data()
  
  supported_tuples = sorted(list(
    get_supported_tuples(nrm_attributions, adv_attributions)
  ), key=lambda x: -x[0])
  
  relative_changes = []
  for count, src, tgt, avg_nrm_ig, avg_adv_ig, avg_nrm_attn, avg_ig_attn in supported_tuples:
    # rel_ig_increase = ((avg_adv_ig - avg_nrm_ig) / avg_nrm_ig) * 100.0
    abs_ig_increase = (avg_adv_ig - avg_nrm_ig)
    relative_changes.append((abs_ig_increase, src, tgt))

  relative_changes = sorted(relative_changes, key=lambda x: -x[0])
  for inc, src, tgt in relative_changes[:100]:
    print("+{:.3f} increase in IG when predicting {} from {}".format(
      inc, tgt, src
    ))
  