import tqdm
import random


if __name__ == "__main__":
  print("Creating augmented dataset...")

  out_file = open('/staging/train.tsv', 'w')
  out_file.write("src\ttgt\n")
  first = True
  for line in tqdm.tqdm(open('/mnt/inputs/train.tsv').readlines()):
    if first:
      first = False
      continue
    parts = line.split('\t')
    label = parts[2]
    selection = random.randint(3, len(parts) - 1) 
    out_file.write("{}\t{}\n".format(
      parts[selection].strip(), label.strip()
    ))
