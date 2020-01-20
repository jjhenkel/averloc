import os
import io
import sys
import ast
import json
import gzip
import copy
import astor
import random


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
  
  print(renames)
  return renames

def generate_renaming(defs, min_name_len, max_name_len):
  renames = {}
  for the_def in defs.keys():
    subtokens_len = random.randint(min_name_len, max_name_len)
    renames[the_def] = '_'.join(
      random.sample(WORDBANK, subtokens_len)
    )
  return renames


def t_rename_fields(the_ast, select_percantage=1.0, min_name_len=1, max_name_len=5):
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

  renames = generate_renaming(field_references, min_name_len, max_name_len)

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


def t_rename_parameters(the_ast, shuffle, select_percantage=1.0, min_name_len=1, max_name_len=5):
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
    parameter_defs, min_name_len, max_name_len
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


def t_rename_local_variables(the_ast, shuffle, select_percantage=0.8, min_name_len=1, max_name_len=5):
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
    local_var_defs, min_name_len, max_name_len
  ) if not shuffle else derange(local_var_defs)

  to_rename = []
  for node in ast.walk(the_ast):
    if isinstance(node, ast.Name) and node.id in local_var_defs:
      to_rename.append(node)
  
  for node in to_rename:
    changed = True
    node.id = renames[node.id]

  return changed, the_ast


def t_shuffle_parameters(the_ast):
  return t_rename_parameters(the_ast, True)


def t_shuffle_local_variables(the_ast):
  return t_rename_local_variables(the_ast, True)


def t_insert_print_statements(the_ast, min_insertions=2, max_insertions=6, literal_min_len=2, literal_max_len=7):
  
  if len(the_ast.body) == 0 or not isinstance(the_ast.body[0], ast.FunctionDef):
    return False, the_ast

  num_done = 0
  while num_done < random.randint(min_insertions, max_insertions):
    subtokens_len = random.randint(literal_min_len, literal_max_len)
    literal = '_'.join(
      random.sample(WORDBANK, subtokens_len)
    )
  
    if bool(random.getrandbits(1)):
      the_ast.body[0].body.insert(
        0,
        ast.Expr(
          ast.Call(
            func=ast.Name("print"),
            args=[ast.Str(literal)],
            keywords=[]
          )
        )
      )
    else:
      the_ast.body[0].body.append(
        ast.Expr(
          ast.Call(
            func=ast.Name("print"),
            args=[ast.Str(literal)],
            keywords=[]
          )
        )
      )
    
    num_done += 1
      
  return True, the_ast


def t_replace_true_false(the_ast):
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


def t_all(the_ast):
  changed1, s1 = t_rename_local_variables(the_ast, False)
  changed2, s2 = t_rename_parameters(s1, False)
  changed3, s3 = t_rename_fields(s2)
  changed4, s4 = t_replace_true_false(s3)
  changed5, s5 = t_insert_print_statements(s4)

  changed = changed1 or changed2 or changed3 or changed4 or changed5

  return changed, s5


def t_identity(the_ast):
  return True, the_ast


if __name__ == "__main__":
  for split in ['test']:
    counter = 0
    for line in gzip.open('/mnt/inputs/{}.jsonl.gz'.format(split)):
      as_json = json.loads(line)
      # Working with normalized *.jsonl.gz's so source_code exists
      the_code = as_json['source_code']
      try:
        # print(the_code)
        the_ast = ast.parse(the_code)
        # print(astor.dump_tree(the_ast))
        changed, result = t_all(copy.deepcopy(the_ast))
        if changed:
          counter += 1
         
      except Exception as ex:
        print(str(ex))


