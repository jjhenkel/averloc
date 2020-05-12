import os
import io
import sys
import ast
import json
import gzip
import copy
import tqdm
import astor
import random
import multiprocessing


PY_2_BUILTINS = [
  'bytearray',
  'IndexError',
  'all',
  'help',
  'vars',
  'SyntaxError',
  'unicode',
  'UnicodeDecodeError',
  'memoryview',
  'isinstance',
  'copyright',
  'NameError',
  'BytesWarning',
  'dict',
  'input',
  'oct',
  'bin',
  'SystemExit',
  'StandardError',
  'format',
  'repr',
  'sorted',
  'False',
  'RuntimeWarning',
  'list',
  'iter',
  'reload',
  'Warning',
  '__package__',
  'round',
  'dir',
  'cmp',
  'set',
  'bytes',
  'reduce',
  'intern',
  'issubclass',
  'Ellipsis',
  'EOFError',
  'locals',
  'BufferError',
  'slice',
  'FloatingPointError',
  'sum',
  'getattr',
  'abs',
  'exit',
  'print',
  'True',
  'FutureWarning',
  'ImportWarning',
  'None',
  'hash',
  'ReferenceError',
  'len',
  'credits',
  'frozenset',
  '__name__',
  'ord',
  'super',
  '_',
  'TypeError',
  'license',
  'KeyboardInterrupt',
  'UserWarning',
  'filter',
  'range',
  'staticmethod',
  'SystemError',
  'BaseException',
  'pow',
  'RuntimeError',
  'float',
  'MemoryError',
  'StopIteration',
  'globals',
  'divmod',
  'enumerate',
  'apply',
  'LookupError',
  'open',
  'quit',
  'basestring',
  'UnicodeError',
  'zip',
  'hex',
  'long',
  'next',
  'ImportError',
  'chr',
  'xrange',
  'type',
  '__doc__',
  'Exception',
  'tuple',
  'UnicodeTranslateError',
  'reversed',
  'UnicodeEncodeError',
  'IOError',
  'hasattr',
  'delattr',
  'setattr',
  'raw_input',
  'SyntaxWarning',
  'compile',
  'ArithmeticError',
  'str',
  'property',
  'GeneratorExit',
  'int',
  '__import__',
  'KeyError',
  'coerce',
  'PendingDeprecationWarning',
  'file',
  'EnvironmentError',
  'unichr',
  'id',
  'OSError',
  'DeprecationWarning',
  'min',
  'UnicodeWarning',
  'execfile',
  'any',
  'complex',
  'bool',
  'ValueError',
  'NotImplemented',
  'map',
  'buffer',
  'max',
  'object',
  'TabError',
  'callable',
  'ZeroDivisionError',
  'eval',
  '__debug__',
  'IndentationError',
  'AssertionError',
  'classmethod',
  'UnboundLocalError',
  'NotImplementedError',
  'AttributeError',
  'OverflowError'
]


def derange(defs):
  def swap(lst, s1, s2):
    tmp = lst[s1]
    lst[s1] = lst[s2]
    lst[s2] = tmp

  og_names = list(defs.keys())
  just_names = list(defs.keys())
  for a in range(1, len(just_names)):
    b = random.choice(range(0, a))
    swap(just_names, a, b)
  
  renames = {}
  for i in range(0, len(just_names)):
    renames[just_names[i]] = og_names[i]
  
  return renames

def generate_renaming(wordbank, defs, min_name_len, max_name_len):
  renames = {}
  for the_def in defs.keys():
    subtokens_len = random.randint(min_name_len, max_name_len)
    renames[the_def] = '_'.join(
      random.sample(wordbank, subtokens_len)
    )
  return renames


def t_rename_fields(the_ast, wordbank, select_percantage=1.0, min_name_len=1, max_name_len=5):
  changed = False

  # Going to need parent info
  for node in ast.walk(the_ast):
    for child in ast.iter_child_nodes(node):
        child.parent = node

  candidates = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.Name) and node.id == 'self':
      if isinstance(node.parent, ast.Attribute):
        if isinstance(node.parent.parent, ast.Call) and node.parent.parent.func == node.parent:
          continue
        if node.parent.attr not in [ c.attr for c in candidates ]:
          candidates.append(node.parent)

  selections = random.sample(
    candidates, int(float(len(candidates)) * select_percantage)
  )

  field_references = {}
  for selected in selections:
    field_references[selected.attr] = selected

  renames = generate_renaming(wordbank, field_references, min_name_len, max_name_len)

  to_rename = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.Name) and node.id == 'self':
      if isinstance(node.parent, ast.Attribute) and node.parent.attr in renames:
        if isinstance(node.parent.parent, ast.Call) and node.parent.parent.func == node.parent:
          continue
        to_rename.append(node.parent)

  for node in to_rename:
    changed = True
    node.attr = renames[node.attr]

  return changed, the_ast


def t_rename_parameters(the_ast, wordbank, shuffle=False, select_percantage=1.0, min_name_len=1, max_name_len=5):
  changed = False
  candidates = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.arg):
      if node.arg != 'self' and node.arg not in [ c.arg for c in candidates ]:
        # print(node.arg, node.lineno)
        candidates.append(node)

  selections = random.sample(
    candidates, int(float(len(candidates)) * select_percantage)
  )

  parameter_defs = {}
  for selected in selections:
    parameter_defs[selected.arg] = selected

  if shuffle and len(parameter_defs) < 2:
    return False, the_ast

  renames = generate_renaming(
    wordbank, parameter_defs, min_name_len, max_name_len
  ) if not shuffle else derange(parameter_defs)

  to_rename = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.Name) and node.id in parameter_defs:
      to_rename.append(node)
    elif isinstance(node, ast.arg) and node.arg in parameter_defs:
      to_rename.append(node)
  
  for node in to_rename:
    changed = True
    if hasattr(node, 'arg'):
      node.arg = renames[node.arg]
    else:
      node.id = renames[node.id]

  return changed, the_ast


def t_rename_local_variables(the_ast, wordbank, shuffle=False, select_percantage=0.8, min_name_len=1, max_name_len=5):
  changed = False
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

  if shuffle and len(local_var_defs) < 2:
    return False, the_ast

  renames = generate_renaming(
    wordbank, local_var_defs, min_name_len, max_name_len
  ) if not shuffle else derange(local_var_defs)

  to_rename = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.Name) and node.id in local_var_defs:
      to_rename.append(node)
  
  for node in to_rename:
    changed = True
    node.id = renames[node.id]

  return changed, the_ast


def t_shuffle_parameters(the_ast, wordbank):
  return t_rename_parameters(the_ast, wordbank, True)


def t_shuffle_local_variables(the_ast, wordbank):
  return t_rename_local_variables(the_ast, wordbank, True)


def t_insert_print_statements(the_ast, wordbank, min_insertions=2, max_insertions=6, literal_min_len=2, literal_max_len=7):
  
  if len(the_ast.body) == 0 or not isinstance(the_ast.body[0], ast.FunctionDef):
    return False, the_ast

  num_done = 0
  while num_done < random.randint(min_insertions, max_insertions):
    subtokens_len = random.randint(literal_min_len, literal_max_len)
    literal = '_'.join(
      random.sample(wordbank, subtokens_len)
    )
  
    if bool(random.getrandbits(1)):
      the_ast.body[0].body.insert(
        0,
        ast.Expr(
          ast.Call(
            func=ast.Name(id="print", ctx=ast.Load()),
            args=[ast.Str(literal)],
            keywords=[]
          )
        )
      )
    else:
      the_ast.body[0].body.append(
        ast.Expr(
          ast.Call(
            func=ast.Name(id="print", ctx=ast.Load()),
            args=[ast.Str(literal)],
            keywords=[]
          )
        )
      )
    
    num_done += 1
      
  return True, the_ast


def t_replace_true_false(the_ast, wordbank):
  class ReplaceTrueFalse(ast.NodeTransformer):
    def visit_NameConstant(self, node):
      if node.value != True and node.value != False:
        return node
      rand_int = random.choice([0, 1])
      return ast.Compare(
        left=ast.Num(n=rand_int),
        ops=[ast.Eq() if node.value == True else ast.NotEq()],
        comparators=[ast.Num(n=rand_int)]
      ) 

  changed = False
  
  for node in ast.walk(the_ast):
    if isinstance(node, ast.NameConstant) and node.value == True:
      changed = True
    elif isinstance(node, ast.NameConstant) and node.value == False:
      changed = True
 
  return changed, ReplaceTrueFalse().visit(the_ast)


def t_all(the_ast, wordbank):
  changed1, s1 = t_rename_local_variables(the_ast, wordbank, False)
  changed2, s2 = t_rename_parameters(s1, wordbank, False)
  changed3, s3 = t_rename_fields(s2, wordbank)
  changed4, s4 = t_replace_true_false(s3, wordbank)
  changed5, s5 = t_insert_print_statements(s4, wordbank)

  changed = changed1 or changed2 or changed3 or changed4 or changed5

  return changed, s5


class t_seq(object):
  def __init__(self, transforms):
    self.transforms = transforms
  def __call__(self, the_ast, wordbank):
    did_change = False
    cur_ast = the_ast
    for t in self.transforms:
      changed, cur_ast = t(cur_ast, wordbank) 
      if changed:
        did_change = True
    return did_change, cur_ast


def t_identity(the_ast, wordbank):
  return True, the_ast


def process(item):
  (split, t_name, the_hash, og_code, transformer, wordbank) = item

  try:
    changed, result = transformer(
      ast.parse(og_code), wordbank
    )
    return changed, split, t_name, the_hash, astor.to_source(result) 
  except Exception as ex:
    import traceback
    traceback.print_exc()
    return False, split, t_name, the_hash, og_code


if __name__ == "__main__":
  print("Starting transform:")
  pool = multiprocessing.Pool()

  WORDBANK = []
  with open('/app/wordbank.txt') as wordf:
    WORDBANK = list(filter(None, [ x.strip() for x in wordf.readlines() ]))

  tasks = []

  transforms = [
    (
      'transforms.Identity',
      t_identity
    ),
    (
      'transforms.Seq(RenameFields)',
      t_seq([t_rename_fields])
    ),
    (
      'transforms.Seq(RenameParameters)',
      t_seq([t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse)',
      t_seq([t_replace_true_false])
    ),
    (
      'transforms.Seq(RenameLocalVariables)',
      t_seq([t_rename_local_variables])
    ),
    (
      'transforms.Seq(InsertPrintStatements)',
      t_seq([t_insert_print_statements])
    ),
    (
      'transforms.Seq(RenameFields,RenameParameters)',
      t_seq([t_rename_fields,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,RenameFields)',
      t_seq([t_replace_true_false,t_rename_fields])
    ),
    (
      'transforms.Seq(RenameFields,RenameLocalVariables)',
      t_seq([t_rename_fields,t_rename_local_variables])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,RenameParameters)',
      t_seq([t_replace_true_false,t_rename_parameters])
    ),
    (
      'transforms.Seq(InsertPrintStatements,RenameFields)',
      t_seq([t_insert_print_statements,t_rename_fields])
    ),
    (
      'transforms.Seq(RenameLocalVariables,RenameParameters)',
      t_seq([t_rename_local_variables,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,RenameLocalVariables)',
      t_seq([t_replace_true_false,t_rename_local_variables])
    ),
    (
      'transforms.Seq(InsertPrintStatements,RenameParameters)',
      t_seq([t_insert_print_statements,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements)',
      t_seq([t_replace_true_false,t_insert_print_statements])
    ),
    (
      'transforms.Seq(InsertPrintStatements,RenameLocalVariables)',
      t_seq([t_insert_print_statements,t_rename_local_variables])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,RenameFields,RenameParameters)',
      t_seq([t_replace_true_false,t_rename_fields,t_rename_parameters])
    ),
    (
      'transforms.Seq(RenameFields,RenameLocalVariables,RenameParameters)',
      t_seq([t_rename_fields,t_rename_local_variables,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,RenameFields,RenameLocalVariables)',
      t_seq([t_replace_true_false,t_rename_fields,t_rename_local_variables])
    ),
    (
      'transforms.Seq(InsertPrintStatements,RenameFields,RenameParameters)',
      t_seq([t_insert_print_statements,t_rename_fields,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements,RenameFields)',
      t_seq([t_replace_true_false,t_insert_print_statements,t_rename_fields])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,RenameLocalVariables,RenameParameters)',
      t_seq([t_replace_true_false,t_rename_local_variables,t_rename_parameters])
    ),
    (
      'transforms.Seq(InsertPrintStatements,RenameFields,RenameLocalVariables)',
      t_seq([t_insert_print_statements,t_rename_fields,t_rename_local_variables])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements,RenameParameters)',
      t_seq([t_replace_true_false,t_insert_print_statements,t_rename_parameters])
    ),
    (
      'transforms.Seq(InsertPrintStatements,RenameLocalVariables,RenameParameters)',
      t_seq([t_insert_print_statements,t_rename_local_variables,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements,RenameLocalVariables)',
      t_seq([t_replace_true_false,t_insert_print_statements,t_rename_local_variables])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,RenameFields,RenameLocalVariables,RenameParameters)',
      t_seq([t_replace_true_false,t_rename_fields,t_rename_local_variables,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements,RenameFields,RenameParameters)',
      t_seq([t_replace_true_false,t_insert_print_statements,t_rename_fields,t_rename_parameters])
    ),
    (
      'transforms.Seq(InsertPrintStatements,RenameFields,RenameLocalVariables,RenameParameters)',
      t_seq([t_insert_print_statements,t_rename_fields,t_rename_local_variables,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements,RenameFields,RenameLocalVariables)',
      t_seq([t_replace_true_false,t_insert_print_statements,t_rename_fields,t_rename_local_variables])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements,RenameLocalVariables,RenameParameters)',
      t_seq([t_replace_true_false,t_insert_print_statements,t_rename_local_variables,t_rename_parameters])
    ),
    (
      'transforms.Seq(ReplaceTrueFalse,InsertPrintStatements,RenameFields,RenameLocalVariables,RenameParameters)',
      t_seq([t_replace_true_false,t_insert_print_statements,t_rename_fields,t_rename_local_variables,t_rename_parameters])
    )
  ]

  print("  + Will apply {} transforms".format(len(transforms)))

  print("  + Loading tasks...")
  for split in ['test']:
    for line in gzip.open('/mnt/inputs/{}.jsonl.gz'.format(split)):
      as_json = json.loads(line)
      the_code = as_json['source_code']
      for t_name, t_func in transforms:
        os.makedirs('/mnt/raw-outputs/{}/{}'.format(t_name, split), exist_ok=True)
        tasks.append((split, t_name, as_json['sha256_hash'], the_code, t_func, WORDBANK))
  print("    + Loaded {} transform tasks".format(len(tasks)))

  results = pool.imap_unordered(process, tasks, 5000)

  print("  + Transforming in parallel...")
  for changed, split, t_name, the_hash, code in tqdm.tqdm(results, desc="    + Progress", total=len(tasks)):
    if not changed:
      continue
    with open('/mnt/raw-outputs/{}/{}/{}.java'.format(t_name, split, the_hash), 'w') as fout:
      fout.write('{}\n'.format(code))

  print("  + Transforms complete!")
