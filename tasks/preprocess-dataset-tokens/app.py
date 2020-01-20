import re
import gzip
import json
import tqdm
import multiprocessing


def camel_case_split(identifier):
  matches = re.finditer(
    '.+?(?:(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])|$)',
    identifier
  )
  return [m.group(0) for m in matches]


def subtokens(in_list):
  good_list = []
  for tok in in_list:
    for subtok in tok.replace('_', ' ').split(' '):
      if subtok.strip() != '':
        good_list.extend(camel_case_split(subtok))
  
  return good_list


def clean_name(in_list):
  return subtokens(in_list)


def normalize_subtoken(subtoken):
  normalized = re.sub(
    r'[^\x00-\x7f]', r'',  # Get rid of non-ascii
    re.sub(
      r'["\',`]', r'',     # Get rid of quotes and comma 
      re.sub(
        r'\s+', r'',       # Get rid of spaces
        subtoken.lower()
          .replace('\\\n', '')
          .replace('\\\t', '')
          .replace('\\\r', '')
      )
    )
  )

  return normalized


def process(item):
  return (
    item[0],
    ' '.join([ 
      normalize_subtoken(subtok) for subtok in subtokens(item[1])
    ]),
    ' '.join([
      normalize_subtoken(subtok) for subtok in clean_name(item[2])
    ])
  )


if __name__ == "__main__":
  print("Loading inputs...")

  tasks = []
  for split in ["test", "train", "valid"]:
    for line in gzip.open('/mnt/inputs/{}.jsonl.gz'.format(split)):
      as_json = json.loads(line)
      tasks.append((split, as_json['source_tokens'], as_json['target_tokens']))
  
  pool = multiprocessing.Pool()
  print("  + Inputs loaded")

  out_map = {
    'train': open('/mnt/outputs/train.tsv', 'w'),
    'test': open('/mnt/outputs/test.tsv', 'w'),
    'valid': open('/mnt/outputs/valid.tsv', 'w'),
  }
  print("  + Output files opened")

  out_map['train'].write('src\ttgt\n')
  out_map['test'].write('src\ttgt\n')
  out_map['valid'].write('src\ttgt\n')

  print("  - Processing in parallel...")
  iterator =  tqdm.tqdm(
    pool.imap_unordered(process, tasks, 10000),
    desc="    - Tokenizing",
    total=len(tasks)
  )
  for split, src, tgt in iterator:
    out_map[split].write(
      '{}\t{}\n'.format(src, tgt)
    )
  print("    + Tokenizing complete")
  print("  + Done extracting tokens")
