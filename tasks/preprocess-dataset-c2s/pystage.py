import sys
import json

from fissix import pygram, pytree
from fissix.pgen2 import driver, token


def parse_file(contents, from_file):
  parser = driver.Driver(pygram.python_grammar, convert=pytree.convert)

  names_map = token.tok_name
  for key, value in pygram.python_grammar.symbol2number.items():
    names_map[value] = key

  the_ast = parser.parse_string(contents)
  flattened_json = []

  def _traverse(node):
    cur_idx = len(flattened_json)
    if node.type in names_map:
      flattened_json.append({
        'type': names_map[node.type],
        'value': node.value if isinstance(node, pytree.Leaf) else names_map[node.type],
        'children': []
      })
    else:
      assert False, "Type not in map."
    if not isinstance(node, pytree.Leaf):
      for child in node.children:
        flattened_json[cur_idx]["children"].append(_traverse(child))
    return cur_idx

  _traverse(the_ast)

  final_tree = { 
    'from_file': from_file,
    'ast': flattened_json
  }
  
  return json.dumps(
    final_tree,
    separators=(',', ':')
  )


if __name__ == "__main__":
  fails = 0
  for line in sys.stdin:
    try:
      as_json = json.loads(line)
      result = parse_file(
        as_json['source_code'] + '\n',
        as_json['from_file']
      )
      print(result)
    except Exception:
      continue

