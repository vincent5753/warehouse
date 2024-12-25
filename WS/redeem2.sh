#!/bin/bash

# usage: bash this.sh redeemcode

for i in $(seq 1 3)
do
  while IFS= read -r line
  do
    uid=$(echo $line | awk -F ":" '{print $1}')
    username=$(echo $line | awk -F ":" '{print $2}')
    alliancerank=$(echo $line | awk -F ":" '{print $3}')
    echo "兌換碼: \"$1\" RANK: \"${alliancerank}\" 遊戲ID: \"${uid}\" 名稱: \"${username}\""
#echo "RANK: ${alliancerank} 遊戲ID: ${uid} 名稱: ${username}"
    python3 redeem.py --user "${uid}" --code "$1"
#    sleep 1
  done < "list.txt"
done
