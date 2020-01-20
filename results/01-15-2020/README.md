# Results on `java-small` (01-15-2020)

## Config

Use `100` top target sub-tokens as pool for random name building.

Used the follow transformers config:
```java
transformers.add(new InsertPrintStatements(
  2,                 // Min insertions
  6,                 // Max insertions
  2,                 // Min literal length
  7,                 // Max literal length
  topTargetSubtokens // Subtokens to use to build literal
));

transformers.add(new RenameFields(
  1,                 // Name min length
  5,                 // Name max length
  1.0,               // Percent to rename
  topTargetSubtokens // Subtokens to use to build names
));

transformers.add(new RenameLocalVariables(
  1,                 // Name min length
  5,                 // Name max length
  0.8,               // Percent to rename
  topTargetSubtokens // Subtokens to use to build names
));

transformers.add(new RenameParameters(
  1,                 // Name min length
  5,                 // Name max length
  1.0,               // Percent to rename
  topTargetSubtokens // Subtokens to use to build names
));

transformers.add(new ReplaceTrueFalse(
  1.0 // Replacement chance
));

// Use all the previous in our "All" transformer
transformers.add(new All(
  (ArrayList<AverlocTransformer>)transformers.clone()
));

transformers.add(new ShuffleLocalVariables(
  0.8 // Percentage to shuffle
));

transformers.add(new ShuffleParameters(
  1.0 // Percentage to shuffle
));

transformers.add(new Identity(
  // No params
));
```

## Metrics

```
Type , Transform Name                   , F1    , Precision, Recall, Accuracy, Rouge-1 F1, Rouge-2 F1, Rouge-L F1
(TRN), transforms.All                   ,  0.312,     0.343,  0.287,    0.104,      0.304,      0.101,      0.280
(TRN), transforms.Identity              ,  0.613,     0.672,  0.564,    0.312,      0.606,      0.312,      0.572
(TRN), transforms.InsertPrintStatements ,  0.372,     0.419,  0.334,    0.147,      0.365,      0.140,      0.339
(TRN), transforms.RenameFields          ,  0.481,     0.507,  0.457,    0.213,      0.485,      0.206,      0.454
(TRN), transforms.RenameLocalVariables  ,  0.419,     0.457,  0.387,    0.130,      0.421,      0.146,      0.390
(TRN), transforms.RenameParameters      ,  0.473,     0.477,  0.470,    0.227,      0.471,      0.217,      0.444
(TRN), transforms.ReplaceTrueFalse      ,  0.513,     0.604,  0.446,    0.218,      0.516,      0.213,      0.479
(TRN), transforms.ShuffleLocalVariables ,  0.471,     0.544,  0.416,    0.137,      0.462,      0.155,      0.425
(TRN), transforms.ShuffleParameters     ,  0.535,     0.581,  0.496,    0.269,      0.529,      0.241,      0.499
```
