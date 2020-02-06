import os
import sys
import json


def blend_hex(alpha, color=[255,0,0], base=[255,255,255]):
    return '#' + ''.join(["%02x" % e for e in [
      int(round((alpha * color[i]) + ((1 - alpha) * base[i]))) for i in range(3)
    ]])


def generate(N, template_str, json_nrm, json_adv):
  TARGET_TOKEN_BLOCK = '<div class="mdl-card" style="min-height: 0;"><h3>{}</h3></div>'
  SOURCE_TOKEN_ROW = '<tr><td class="mdl-data-table__cell--non-numeric">{}</td><td style="background-color: {}">{}</td><td style="background-color: {}">{}</td></tr>'
  SOURCE_TOKEN_BLOCK = '<div class="mdl-card"><table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp"><thead><tr><th class="mdl-data-table__cell--non-numeric">Source Token</th><th>IG (N)</th><th>IG (A)</th></tr></thead><tbody>{}</tbody></table></div>'

  target_token_blocks = ''
  source_token_blocks = ''

  for i in range(min(len(json_nrm['pred_seq']), len(json_adv['pred_seq']))):
    target_token_blocks += (
      TARGET_TOKEN_BLOCK.format(json_nrm['pred_seq'][i] + '|' + json_adv['pred_seq'][i]) + '\n'
    )
  
    source_token_rows = ''
    max_ig1 = max([ float(f) for f in json_nrm['IG_attrs'][i] ])
    max_ig2 = max([ float(f) for f in json_adv['IG_attrs'][i] ])
    max_ig = max(max_ig1, max_ig2)
    for tok, ig1, ig2 in zip(json_nrm['input_seq'], json_nrm['IG_attrs'][i], json_adv['IG_attrs'][i]):
      formatted = SOURCE_TOKEN_ROW.format(
        # tok, blend_hex(float(ig1) / max_ig), blend_hex(float(ig1) / max_ig1), blend_hex(float(ig2) / max_ig), blend_hex(float(ig2) / max_ig2)
        tok, blend_hex(float(ig1) / max_ig), ig1, blend_hex(float(ig2) / max_ig), ig2
      )
      source_token_rows += (formatted + '\n')
    
    source_token_blocks += (
      SOURCE_TOKEN_BLOCK.format(source_token_rows) + '\n'
    )

  template_str = template_str.replace('<!TARGET_TOKEN_BLOCKS>', target_token_blocks)
  template_str = template_str.replace('<!SOURCE_TOKEN_BLOCKS>', source_token_blocks)
  template_str = template_str.replace('<!NEXT_NUM>', str(N+1))

  return template_str


def select_example(normal, adversarial):
  count = 0
  for line_n, line_a in zip(open(normal).readlines(), open(adversarial).readlines()):
    try:
      nrm = json.loads(line_n)
      adv = json.loads(line_a)
    except:
      continue

    if adv['pred_seq'] == adv['target_seq'] and len(nrm['input_seq']) < 40:
      big_swing = False
      big_drop = False
      exclude = False
      for i in range(min(len(adv['pred_seq']), len(nrm['pred_seq']))):
        for tok, ig1, ig2 in zip(nrm['input_seq'], nrm['IG_attrs'][i], adv['IG_attrs'][i]):
          if float(ig2) - float(ig1) > 0.2:
            big_swing = True
            break
      if big_swing and not exclude:
        count += 1 
        yield nrm, adv

  print("Have {} choices...".format(count))


if __name__ == "__main__":
  
  the_template = open('template.html').read()
  for i, (nrm, adv) in enumerate(list(select_example(sys.argv[1], sys.argv[2]))):
    with open('temps/temp-{}.html'.format(i), 'w') as outf:
      outf.write(generate(
        i, the_template, nrm, adv
      ))
  
