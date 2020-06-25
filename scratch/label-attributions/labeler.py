import os
import re
import sys
import json


PY_KEYWORDS = re.compile(
  r'^(False|class|finally|is|return|None|continue|for|lambda|try|True|def|from|nonlocal|while|and|del|global|not|with|as|elif|if|or|yield|assert|else|import|pass|break|except|in|raise)$'
)

JAVA_KEYWORDS = re.compile(
  r'^(abstract|assert|boolean|break|byte|case|catch|char|class|continue|default|do|double|else|enum|exports|extends|final|finally|float|for|if|implements|import|instanceof|int|interface|long|module|native|new|package|private|protected|public|requires|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while)$'
)

NUMBER = re.compile(
  r'^\d+(\.\d+)?$'
)

DELIMITERS = re.compile(
  r'^(\{|\(|\[|\]|\)|\}|;|,)$'
)

OPERATORS = re.compile(
  r'^(=|!=|<=|>=|<|>|\?|!|\*|\+|\*=|\+=|/|%|@|&|&&|\||\|\||\.|:)$'
)


def classify_tok(tok):
  if PY_KEYWORDS.match(tok):
    return 'KEYWORD'
  elif JAVA_KEYWORDS.match(tok):
    return 'KEYWORD'
  elif NUMBER.match(tok):
    return 'NUMBER'
  elif DELIMITERS.match(tok):
    return 'DELIMITER'
  elif OPERATORS.match(tok):
    return 'OPERATOR'
  else:
    return 'OTHER'


def label_it(file_path):
  with open(file_path.replace('.txt', '_labeled.txt'), 'w') as fout:
    with open(file_path) as fin:
      for line in fin.readlines():
        as_json = {}
        try:
          as_json = json.loads(line)
        except:
          continue
        
        labels = []
        for tok in as_json['input_seq']:
          labels.append(classify_tok(tok))
        
        as_json['input_labels'] = labels
        fout.write(json.dumps(as_json) + '\n')


if __name__ == "__main__":
  label_it(sys.argv[1])
