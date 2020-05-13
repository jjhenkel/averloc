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

## Normalized

```
```
