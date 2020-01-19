import os
import io
import sys
import ast
import json
import gzip
import copy
import astor
import random


WORDBANK = [
  'foo',
  'bar',
  'baz',
  'brent',
  'zoo',
  'snow',
  'winter',
  'tree',
  'fall',
  'plant',
  'each',
  'everything'
]


def generate_renaming(defs, min_name_len, max_name_len):
  renames = {}
  for the_def in defs.keys():
    subtokens_len = random.randint(min_name_len, max_name_len)
    renames[the_def] = '_'.join(
      random.sample(WORDBANK, subtokens_len)
    )
  return renames


def t_rename_fields(the_ast):
  pass


def t_rename_parameters(the_ast):
  pass


def t_rename_local_variables(the_ast, select_percantage=0.8, min_name_len=1, max_name_len=5):
  candidates = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store):
      if node.id not in [ c.id for c in candidates ]:
        # print(node.id, node.lineno)
        candidates.append(node)

  selections = random.sample(
    candidates, int(float(len(candidates)) * select_percantage)
  )

  local_var_defs = {}
  for selected in selections:
    local_var_defs[selected.id] = selected

  renames = generate_renaming(local_var_defs, min_name_len, max_name_len)

  to_rename = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.Name) and node.id in local_var_defs:
      to_rename.append(node)
  
  for node in to_rename:
    node.id = renames[node.id]

  return astor.to_source(the_ast)


def t_shuffle_parameters(the_ast):
  pass


def t_shuffle_local_variables(the_ast):
  pass


def t_insert_print_statements(the_ast):
  pass


def t_replace_true_false(the_ast):
  pass


def t_all(the_ast):
  pass


def t_identity(the_ast):
  return astor.to_source(the_ast)


if __name__ == "__main__":
  for split in ['test']:
    counter = 0
    for line in gzip.open('/mnt/inputs/{}.jsonl.gz'.format(split)):
      as_json = json.loads(line)
      # Working with normalized *.jsonl.gz's so source_code exists
      the_code = as_json['source_code']
      try:
        print(the_code)
        the_ast = ast.parse(the_code)
        print(
          t_rename_local_variables(copy.deepcopy(the_ast))
        )
      except Exception as ex:
        print(str(ex))
      counter += 1
      if counter > 5:
        exit()


