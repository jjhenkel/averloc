#!/bin/bash

f_0='attacked_metrics_Q_0.txt'
f_1='attacked_metrics_Q_1.txt'
f_2='attacked_metrics_Q_2.txt'
f_3='attacked_metrics_Q_3.txt'
f_4='attacked_metrics_Q_4.txt'
f_5='attacked_metrics_Q_5.txt'
f_le5='attacked_metrics_Q_<=5.txt'
f_15='attacked_metrics_Q_1,5.txt'

echo "Dataset,F1 Q_0,F1 Q_1,F1 Q_2,F1 Q_3,F1 Q_4,F1 Q_5,F1 Q_<=5,F1 Q_1,5"

for ds in c2s/java-small csn/java sri/py150 csn/python; do

  F1_0=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_0}" | awk '{ print $2 }')
  F1_1=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_1}" | awk '{ print $2 }')
  F1_2=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_2}" | awk '{ print $2 }')
  F1_3=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_3}" | awk '{ print $2 }')
  F1_4=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_4}" | awk '{ print $2 }')
  F1_5=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_5}" | awk '{ print $2 }')
  F1_LE_5=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_le5}" | awk '{ print $2 }')
  F1_1_5=$(grep -Po 'f1"?: \d+.\d+' "${1}/${ds}/${f_15}" | awk '{ print $2 }')

  echo $(printf %s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f ${ds} ${F1_0} ${F1_1} ${F1_2} ${F1_3} ${F1_4} ${F1_5} ${F1_LE_5} ${F1_1_5})

done
