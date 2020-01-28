import os
import sys
import json


def blend_hex(alpha, color=[255,0,0], base=[255,255,255]):
    return '#' + ''.join(["%02x" % e for e in [
      int(round((alpha * color[i]) + ((1 - alpha) * base[i]))) for i in range(3)
    ]])


def generate(template_str, json_nrm, json_adv):
  TARGET_TOKEN_BLOCK = '<div class="mdl-card mdl-cell mdl-cell--4-col" style="min-height: 0;"><h3>{}</h3></div>'
  SOURCE_TOKEN_ROW = '<tr><td class="mdl-data-table__cell--non-numeric">{}</td><td style="background-color: {}">{}</td><td style="background-color: {}">{}</td></tr>'
  SOURCE_TOKEN_BLOCK = '<div class="mdl-card mdl-cell mdl-cell--4-col"><table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp"><thead><tr><th class="mdl-data-table__cell--non-numeric">Source Token</th><th>IG (N)</th><th>IG (A)</th></tr></thead><tbody>{}</tbody></table></div>'

  target_token_blocks = ''
  source_token_blocks = ''

  for i, tok in enumerate(json_nrm['pred_seq']):
    target_token_blocks += (
      TARGET_TOKEN_BLOCK.format(tok) + '\n'
    )
  
    source_token_rows = ''
    max_ig1 = max([ float(f) for f in json_nrm['IG_attrs'][i] ])
    max_ig2 = max([ float(f) for f in json_adv['IG_attrs'][i] ])
    for tok, ig1, ig2 in zip(json_nrm['input_seq'], json_nrm['IG_attrs'][i], json_adv['IG_attrs'][i]):
      formatted = SOURCE_TOKEN_ROW.format(
        tok, blend_hex(float(ig1) / max_ig1), ig1, blend_hex(float(ig2) / max_ig2), ig2
      )
      source_token_rows += (formatted + '\n')
    
    source_token_blocks += (
      SOURCE_TOKEN_BLOCK.format(source_token_rows) + '\n'
    )

  template_str = template_str.replace('<!TARGET_TOKEN_BLOCKS>', target_token_blocks)
  template_str = template_str.replace('<!SOURCE_TOKEN_BLOCKS>', source_token_blocks)

  return template_str


def select_example(index, normal, adversarial):
  count = 0
  for line_n, line_a in zip(open(normal).readlines(), open(adversarial).readlines()):
    try:
      nrm = json.loads(line_n)
      adv = json.loads(line_a)
    except:
      continue

    if nrm['pred_seq'] == adv['pred_seq'] and len(adv['pred_seq']) == 3:
      count += 1 
      if count == index:
        return nrm, adv


if __name__ == "__main__":
  
  nrm, adv = select_example(
    int(sys.argv[1]), sys.argv[2], sys.argv[3]
  )
  
  print(
    generate(
      open('template.html').read(),
      nrm, adv
    )
  )
