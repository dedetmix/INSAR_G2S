#!/bin/bash

raw_org=$1
orb=$2

dir=$(pwd)

mkdir -p tmp

rm -f data_asc.in

shopt -s extglob
IFS=" "
while read dataname date_aqc
do

  type=$(echo $dataname | awk '{print substr ($0, 0, 3)}')
  cd tmp
  date_tmp=$(date '+%C%y%m%d' -d"$date_aqc + 20 day")
  year=$(echo $date_aqc | awk '{print substr($0,1,4)}')
  month=$(echo $date_aqc | awk '{print substr($0,5,2)}')
  day=$(echo $date_aqc | awk '{print substr($0,7,2)}')
  
  #anticipate for the first day of month
  if [ $day == 01 ]; then
     yesterday=$( date -d "${date_aqc} -1 days" +'%Y%m%d')
     lastmonth=$( echo $yesterday | awk '{print substr($0,5,2)}')
     month=$lastmonth  
  fi
  
  #find list EOF name in the online directory
  wget --no-remove-listing "http://step.esa.int/auxdata/orbits/Sentinel-1/POEORB/$type/$year/$month"
  grep '</a></td>' $month | tail -n +2 | cut -d'>' -f7 | cut -d'<' -f1 > list_tmp
  EOF_name=$(grep S1A_OPER_AUX_POEORB_OPOD_$date_tmp list_tmp | head -n 1)
  rm $month

  # download POE
  wget -r -l1 -nd "http://step.esa.int/auxdata/orbits/Sentinel-1/POEORB/$type/$year/$month/$EOF_name" --no-parent
  unzip -j $EOF_name
  rm $EOF_name
  #orb_fix=$(ls -1 "$type"*.EOF)
  orb_fix=$(echo "${EOF_name%.*}")

  echo "put $orb_fix in raw_orig"
  #mv $orb_fix $raw_org/.
  # fixed by andretheronsa
  find -name "$type*.EOF" -exec mv '{}' $raw_org/. \;

  #write data.in
  cd $raw_org
  tiffname=$(find -name "*$date_aqc*.tiff" -print | sed 's/^..//' | sed -e 's/\.tiff$//')
  cd $dir
  echo "$tiffname":"$orb_fix" >> data_$orb.in

done < data_"$orb"_grub.txt

rm -f -r tmp
