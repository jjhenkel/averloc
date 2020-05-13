# Datasets

## Summary

4 datasets, from 3 different sources, 2 datasets comprised of
Python functions and 2 comprised of Java functions.

- `c2s/java-small` (from `code2seq`'s evaluation)
- `csn/java` (from GitHub's `CodeSearchNet`) 
- `csn/python` (from GitHub's `CodeSearchNet`)
- `sri/py150` (from SRI Lab's `py150k` dataset)

## Raw Format

Already, at this stage, things are normalized into a `jsonl.gz` encoding. That is,
each file is `gzip` compressed and each line of the file is a `json` object with the
following keys: `granularity`, `code`, `language`.

The key problem is, at this stage, some data points are of `file` granularity whereas
other data points are already at the `method` granularity (which is what we desire
downstream).

From scratch, raw datasets are generated on a decently powerful workstation in under ten minutes. (This mostly depends on download speeds.)

```
Raw Datasets:

  + c2s/...
    - '/mnt/c2s/java-small/test.jsonl.gz' (7.1M)
    - '/mnt/c2s/java-small/train.jsonl.gz' (69M)
    - '/mnt/c2s/java-small/valid.jsonl.gz' (1.9M)

  + csn/...
    - '/mnt/csn/java/test.jsonl.gz' (3.7M)
    - '/mnt/csn/java/train.jsonl.gz' (60M)
    - '/mnt/csn/java/valid.jsonl.gz' (1.8M)

    - '/mnt/csn/python/test.jsonl.gz' (5.4M)
    - '/mnt/csn/python/train.jsonl.gz' (97M)
    - '/mnt/csn/python/valid.jsonl.gz' (5.7M)

  + sri/...
    - '/mnt/sri/py150/test.jsonl.gz' (24M)
    - '/mnt/sri/py150/train.jsonl.gz' (190M)
    - '/mnt/sri/py150/valid.jsonl.gz' (23M)
```

## Normalized Format

Here, everything is at the `method` granularity. Datasets are also trimmed and re-sampled (although sampling is kept within original train/test/valid splits). Things like parsability for Java/Python are enforced. Things like `abstract` methods
in Java are filtered out. The normalizer operates in parallel and can take advantage of a large workstations. The files are kept in the `.jsonl.gz` encoding.

From the raw datasets, normalization takes about an hour on a decently powerful workstation machine. (32 core / 64 thread, 256GB mem.)

```
Normalized Datasets:

  + c2s/...
    - '/mnt/c2s/java-small/test.jsonl.gz' (6.8M)
    - '/mnt/c2s/java-small/train.jsonl.gz' (20M)
    - '/mnt/c2s/java-small/valid.jsonl.gz' (2.1M)

  + csn/...
    - '/mnt/csn/java/test.jsonl.gz' (7.9M)
    - '/mnt/csn/java/train.jsonl.gz' (28M)
    - '/mnt/csn/java/valid.jsonl.gz' (3.6M)

    - '/mnt/csn/python/test.jsonl.gz' (12M)
    - '/mnt/csn/python/train.jsonl.gz' (39M)
    - '/mnt/csn/python/valid.jsonl.gz' (5.8M)

  + sri/...
    - '/mnt/sri/py150/test.jsonl.gz' (6.5M)
    - '/mnt/sri/py150/train.jsonl.gz' (23M)
    - '/mnt/sri/py150/valid.jsonl.gz' (3.2M)
```

***Note:*** These numbers are for normalized datasets trimmed to `70,000` samples for train, `10,000` samples for valid, and `20,000` samples for test.

## Preprocessed Format

Here, we pre-process datasets for the two different models we use (`code2seq` and a `seq2seq` baseline model).

