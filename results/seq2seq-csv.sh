#!/bin/bash



for MODEL in normal adversarial-one-step adversarial-all; do
    
  if [ "${MODEL}" = "normal" ]; then
    FULL_STR='seq2seq,Natural,'
  elif [ "${MODEL}" = "adversarial-one-step" ]; then
    FULL_STR=',Adv-${\seqs^1}$,'
  else
    FULL_STR=',Adv-${\seqs^{1,5}}$,'
  fi
  
  for DATASET in c2s/java-small csn/java sri/py150 csn/python; do

    THE_PATH_NORM="${1}/${DATASET}/${MODEL}/normal/stats.txt"
    THE_PATH_ONE="${1}/${DATASET}/${MODEL}/just-one-step-attacks/attacked_metrics.txt"
    THE_PATH_ALL="${1}/${DATASET}/${MODEL}/all-attacks/attacked_metrics.txt"
    
    F1_NORM=0.0
    if [ -f "${THE_PATH_NORM}" ]; then
      F1_NORM=$(grep -Po 'f1"?: \d+.\d+' "${THE_PATH_NORM}" | awk '{ print $2 }')
    fi
    
    F1_ONE=0.0
    if [ -f "${THE_PATH_ONE}" ]; then
      F1_ONE=$(grep -Po 'f1"?: \d+.\d+' "${THE_PATH_ONE}" | awk '{ print $2 }')
    fi
    
    F1_ALL=0.0
    if [ -f "${THE_PATH_ALL}" ]; then
      F1_ALL=$(grep -Po 'f1"?: \d+.\d+' "${THE_PATH_ALL}" | awk '{ print $2 }')
    fi

    FULL_STR+=$(printf %.2f,%.2f,%.2f, ${F1_NORM} ${F1_ONE} ${F1_ALL})
  done

  echo ${FULL_STR::-1}
done
