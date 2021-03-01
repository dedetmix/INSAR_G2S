#!/bin/bash

raw_org=$1
orb=$2

dir=$(pwd)

mkdir -p tmp

shopt -s extglob
IFS=" "
while read dataname date_aqc
do

  type=$(echo $dataname | awk '{print substr ($0, 0, 3)}')
  cd tmp
  date_tmp=$(date -I -d "$date_aqc + 20 day")
  year=$(echo $date_tmp | awk '{print substr($0,1,4)}')
  month=$(echo $date_tmp | awk '{print substr($0,6,2)}')
  day=$(echo $date_tmp | awk '{print substr($0,9,2)}')

  # download POE
  wget -r -l1 -nd "http://aux.sentinel1.eo.esa.int/POEORB/$year/$month/$day/" --no-check-certificate --no-parent
  orb_fix=$(ls -1 "$type"*.EOF)
  echo "put $orb_fix in raw_orig"
  find -name "$type*.EOF" -exec mv '{}' $raw_org/. \;

  #write data.in
  cd $raw_org
  tiffname=$(find -name "*$date_aqc*.tiff" -print | sed 's/^..//' | sed -e 's/\.tiff$//')
  cd $dir
  echo "$tiffname":"$orb_fix" >> data_$orb.in

done < data_"$orb"_grub.txt

rm -f -r tmp
