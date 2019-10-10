import os
import ast
import sys
import glob
import json
import click
import hashlib
import datetime
import asttokens


@click.group()
def cli():
  pass


@cli.command()
@click.argument('directory', type=click.Path(
  exists=True, dir_okay=True, file_okay=False, allow_dash=False, resolve_path=True
))
def parse_directory(directory):
  def _clean_code_string(xs):
    return json.dumps(
      xs.replace('\t', '\\t')
        .replace('\r', '\\r')
    )[1:-1]

  class VisitGenericToSeq(ast.NodeVisitor):
    def __init__(self):
      self.seq = []
      super(VisitGenericToSeq, self).__init__()

    def results(self):
      return ' '.join(self.seq)

    def generic_visit(self, node):
      self.seq.append('(')

      self.seq.append(type(node).__name__)
      if hasattr(node, 'id'):
        self.seq.append(node.id)

      for child in ast.iter_child_nodes(node):
        self.generic_visit(child)
      self.seq.append(')')


  class VisitFunctions(ast.NodeVisitor):
    def __init__(self, gidx, the_path, the_hash, helper):
      self.gidx = gidx
      self.fidx = 0
      self.the_path = the_path
      self.the_hash = the_hash
      self.helper = helper
      super(VisitFunctions, self).__init__()
    
    def visit_FunctionDef(self, node):
      self.fidx += 1

      # Get traversal of AST nodes (and get tokens of body)
      body_tokens = []
      inner_visitor = VisitGenericToSeq()

      # Process both args and body
      inner_visitor.visit(node.args)
      body_tokens.extend(self.helper.get_tokens(node.args, include_extra=True))
      for stmt in node.body:
        inner_visitor.visit(stmt)
        body_tokens.extend(self.helper.get_tokens(stmt, include_extra=True))
      
      body_ast_nodes = inner_visitor.results()

      # Format token string
      body_tokens_str = ' '.join(
        [ _clean_code_string(x.string) for x in body_tokens ]
      )

      # Get doc_string
      doc_string = ast.get_docstring(node, clean=True)

      # Print output data
      click.echo("{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}".format(
        self.gidx,
        self.the_path,
        self.the_hash,
        self.fidx,
        'YES' if doc_string else 'NO',
        node.name,
        body_tokens_str,
        body_ast_nodes,
        _clean_code_string(doc_string) if doc_string else '<MISSING>',
        datetime.datetime.utcnow().isoformat()
      ), file=sys.stdout)


  click.echo("Parsing files in '{}'...".format(directory), file=sys.stderr)
  
  click.echo("Global Index\tFile Path\tFile SHA\tFunction Index\tHas Docstring\tFunction Name\tFunction Tokenized\tFunction AST\tProcessed At", file=sys.stdout)

  gidx = 0
  for fname in glob.iglob(directory + '/**/*.py', recursive=True):
    if not fname.endswith('.py'):
      continue
    
    gidx += 1
    click.echo("  + parsing '{}'".format(fname), file=sys.stderr)

    try:
      with open(os.path.join(directory, fname), 'r') as fhandle:
        source_text = fhandle.read()

        the_hash = hashlib.sha256(source_text.encode('utf-8')).hexdigest()

        as_ast = asttokens.ASTTokens(
          source_text, filename=fname, parse=True
        )

        VisitFunctions(
          str(gidx),
          os.path.join(directory, fname),
          the_hash,
          as_ast
        ).visit(as_ast.tree)
    except Exception as ex:
      click.echo(ex, file=sys.stderr)
      click.echo("    - failed to parse and save results. Continuing...", file=sys.stderr)


if __name__ == '__main__':
  cli()
