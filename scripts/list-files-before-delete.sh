echo -e "Datasets:\n  + c2s/..." 
du -hs /mnt/c2s/*/* | while read -r line; do
  the_file=$(echo "${line}" | awk '{ print $2 }')
  the_size=$(echo "${line}" | awk '{ print $1 }')
  echo "    - '${the_file}' (${the_size})"
done 
echo "  + csn/..." 
du -hs /mnt/csn/*/* | while read -r line; do
  the_file=$(echo "${line}" | awk '{ print $2 }')
  the_size=$(echo "${line}" | awk '{ print $1 }')
  echo "    - '${the_file}' (${the_size})"
done 
echo "  + sri/..." 
du -hs /mnt/sri/*/* | while read -r line; do
  the_file=$(echo "${line}" | awk '{ print $2 }')
  the_size=$(echo "${line}" | awk '{ print $1 }')
  echo "    - '${the_file}' (${the_size})"
done 
