import os
import csv
import sys
import tqdm


if __name__ == "__main__":
  csv.field_size_limit(sys.maxsize)

  ID_MAP = {}

  print("Loading identity transform...")
  with open("/mnt/inputs/transforms.Identity/{}.tsv".format(sys.argv[1]), 'r') as identity_tsv:
    reader = csv.reader(
      (x.replace('\0', '') for x in identity_tsv),
      delimiter='\t', quoting=csv.QUOTE_NONE
    )
    next(reader, None)
    for line in reader:
      ID_MAP[line[0]] = (line[1], line[2])
  print("  + Loaded {} samples".format(len(ID_MAP)))

  print("Loading transformed samples...")
  TRANSFORMED = {}
  for transform_name in sys.argv[2:]:
    TRANSFORMED[transform_name] = {}
    with open("/mnt/inputs/{}/{}.tsv".format(transform_name, sys.argv[1]), 'r') as current_tsv:
      reader = csv.reader(
        (x.replace('\0', '') for x in current_tsv),
        delimiter='\t', quoting=csv.QUOTE_NONE
      )
      next(reader, None)
      for line in reader:
        TRANSFORMED[transform_name][line[0]] = line[1]
    print("  + Loaded {} samples from '{}'".format(
      len(TRANSFORMED[transform_name]), transform_name
    ))

  print("Writing adv. {}ing samples...".format(sys.argv[1]))
  with open("/mnt/outputs/{}.tsv".format(sys.argv[1]), "w") as out_f:
    out_f.write('src\ttgt\t{}\n'.format(
      '\t'.join([ 
        'src_adv{}'.format(i) for i in sys.argv[2:]
      ])
    ))

    for key in tqdm.tqdm(ID_MAP.keys(), desc="  + Progress"):
      row = [ ID_MAP[key][0], ID_MAP[key][1] ]
      for transform_name in sys.argv[2:]:
        if key in TRANSFORMED[transform_name]:
          row.append(TRANSFORMED[transform_name][key])
        else:
          row.append(ID_MAP[key][0])
      out_f.write('{}\n'.format('\t'.join(row)))
  print("  + Adversarial {}ing file generation complete!".format(sys.argv[1]))
