#!/bin/bash

# set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Type , Transform Name                   , F1    , Precision, Recall, Accuracy, Rouge-1 F1, Rouge-2 F1, Rouge-L F1"
for f in $(find "${1}" -type f -name "results-*.txt" | sort); do
  
  LENGTH=$(cat "${f}" | grep -P 'Accuracy:|Precision:|Rouge:' | wc -l)
  
  if [ "${LENGTH}" == "3" ]; then
  
    NAME=$(
      basename "${f}" .txt
    )
    ACCURACY=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n3 \
      | head -n1 \
      | awk '{ print $2 }'
    )
    PRECISION=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n2 \
      | head -n1 \
      | awk '{ print $2 }'
    )
    RECALL=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n2 \
      | head -n1 \
      | awk '{ print $4 }'
    )
    F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n2 \
      | head -n1 \
      | awk '{ print $6 }'
    )
    ROUGE1_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-1"].f'
    )
    ROUGE2_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-2"].f'
    )
    ROUGEL_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-l"].f'
    )

    printf \
      "(TRN), %-33s,  %.3f,     %.3f,  %.3f,    %.3f,      %.3f,      %.3f,      %.3f\n" \
      ${NAME/results-/} \
      ${F1::-1} \
      ${PRECISION::-1} \
      ${RECALL::-1} \
      ${ACCURACY::-1} \
      ${ROUGE1_F1} \
      ${ROUGE2_F1} \
      ${ROUGEL_F1}

  else

    NAME=$(
      basename "${f}" .txt
    )
    ACCURACY=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n6 \
      | head -n1 \
      | awk '{ print $2 }'
    )
    PRECISION=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n5 \
      | head -n1 \
      | awk '{ print $2 }'
    )
    RECALL=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n5 \
      | head -n1 \
      | awk '{ print $4 }'
    )
    F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n5 \
      | head -n1 \
      | awk '{ print $6 }'
    )
    ROUGE1_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n4 \
      | head -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-1"].f'
    )
    ROUGE2_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n4 \
      | head -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-2"].f'
    )
    ROUGEL_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n4 \
      | head -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-l"].f'
    )
    BASE_ACCURACY=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n3 \
      | head -n1 \
      | awk '{ print $2 }'
    )
    BASE_PRECISION=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n2 \
      | head -n1 \
      | awk '{ print $2 }'
    )
    BASE_RECALL=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n2 \
      | head -n1 \
      | awk '{ print $4 }'
    )
    BASE_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n2 \
      | head -n1 \
      | awk '{ print $6 }'
    )
    BASE_ROUGE1_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-1"].f'
    )
    BASE_ROUGE2_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-2"].f'
    )
    BASE_ROUGEL_F1=$(
      cat "${f}" \
      | grep -P 'Accuracy:|Precision:|Rouge:' \
      | tail -n1 \
      | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' \
      | sed "s/'/\"/g" \
      | "${DIR}/jq" -r '.["rouge-l"].f'
    )

    printf \
      "(BSE), %-33s,  %.3f,     %.3f,  %.3f,    %.3f,      %.3f,      %.3f,      %.3f\n" \
      ${NAME/results-/} \
      ${BASE_F1::-1} \
      ${BASE_PRECISION::-1} \
      ${BASE_RECALL::-1} \
      ${BASE_ACCURACY::-1} \
      ${BASE_ROUGE1_F1} \
      ${BASE_ROUGE2_F1} \
      ${BASE_ROUGEL_F1}
    printf \
      "(TRN), %-33s,  %.3f,     %.3f,  %.3f,    %.3f,      %.3f,      %.3f,      %.3f\n" \
      ${NAME/results-/} \
      ${F1::-1} \
      ${PRECISION::-1} \
      ${RECALL::-1} \
      ${ACCURACY::-1} \
      ${ROUGE1_F1} \
      ${ROUGE2_F1} \
      ${ROUGEL_F1}
    printf \
      "(REL), %-33s, %.3f,    %.3f, %.3f,   %.3f,     %.3f,     %.3f,     %.3f\n" \
      ${NAME/results-/} \
      $(awk "BEGIN{print ${F1::-1}-${BASE_F1::-1}}") \
      $(awk "BEGIN{print ${PRECISION::-1}-${BASE_PRECISION::-1}}") \
      $(awk "BEGIN{print ${RECALL::-1}-${BASE_RECALL::-1}}") \
      $(awk "BEGIN{print ${ACCURACY::-1}-${BASE_ACCURACY::-1}}") \
      $(awk "BEGIN{print ${ROUGE1_F1}-${BASE_ROUGE1_F1}}") \
      $(awk "BEGIN{print ${ROUGE2_F1}-${BASE_ROUGE2_F1}}") \
      $(awk "BEGIN{print ${ROUGEL_F1}-${BASE_ROUGEL_F1}}")

  fi

done 
