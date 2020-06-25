#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo -n "modelName,trainingType"
echo -n ",ctsJavaSmallId,ctsJavaSmallQOneR,ctsJavaSmallQOneG,ctsJavaSmallQFiveR,ctsJavaSmallQFiveG"
echo -n ",csnJavaId,csnJavaQOneR,csnJavaQOneG,csnJavaQFiveR,csnJavaQFiveG"
echo -n ",csnPythonId,csnPythonQOneR,csnPythonQOneG,csnPythonQFiveR,csnPythonQFiveG"
echo    ",sriPyId,sriPyQOneR,sriPyQOneG,sriPyQFiveR,sriPyQFiveG"

for MODEL in normal-model augmented-model adv-random-model adv-gradient-model; do
  if [ "${MODEL}" = "normal-model" ]; then
    FULL_STR='seq2seq,$\nrmTrain{}$,'
  elif [ "${MODEL}" = "augmented-model" ]; then
    FULL_STR=',$\augTrain{}$,'
  elif [ "${MODEL}" = "adv-random-model" ]; then
    FULL_STR=',$\advTrain{\testRandDepthOne{}}$,'
  else
    FULL_STR=',$\advTrain{\testGradDepthOne{}}$,'
  fi

  for DATASET in c2s/java-small csn/java csn/python sri/py150; do
    for ATTACK in no-attack depth-1-random-attack depth-1-gradient-attack depth-5-random-attack depth-5-gradient-attack; do
      if [ "${ATTACK}" = "no-attack" ]; then
        THE_PATH="${DIR}/seq2seq/${DATASET}/${MODEL}/depth-1-random-attack/log-normal.txt"

        F1_NORM=0.0
        if [ -f "${THE_PATH}" ]; then
          F1_NORM=$(grep -Po 'f1: \d+.\d+' "${THE_PATH}" | awk '{ print $2 }')
        else
          echo "MISSING: ${THE_PATH}"
        fi

        FULL_STR+=$(printf %.1f, ${F1_NORM})
      else
        THE_PATH="${DIR}/seq2seq/${DATASET}/${MODEL}/${ATTACK}/attacked_metrics.txt"
        ALT_PATH="${DIR}/seq2seq/${DATASET}/normal-model/${ATTACK}/attacked_metrics.txt"
        
        F1_ATTACK=0.0
        DELTA=0.0
        if [ -f "${THE_PATH}" ]; then
          F1_ATTACK=$(grep -Po 'f1"?: \d+.\d+' "${THE_PATH}" | awk '{ print $2 }')
          DELTA=$(grep -Po 'f1"?: \d+.\d+' "${ALT_PATH}" | awk "{ print $F1_ATTACK - \$2 }")
        else
          echo "MISSING: ${THE_PATH}"
        fi

        if [ "${MODEL}" = "normal-model" ]; then
          FULL_STR+=$(printf "%.1f", ${F1_ATTACK})
        else
          FULL_STR+=$(printf "%.1f [+%.1f]", ${F1_ATTACK} ${DELTA})
        fi
      fi
    done
  done

  TEMP=${FULL_STR::-1}
  echo ${TEMP//+-/-}
done
