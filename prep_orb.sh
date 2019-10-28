#!/bin/bash

######################################################################
# 02
# script to prepare the precise orbit ephemeris (POEORB)
# GMT5SAR processing for sentinel1A/B
# 2017.02.28 "Noorlaila Hayati"
# email: n.isya@tu-braunschweig.de or noorlaila@geodesy.its.ac.id
######################################################################

sen_orbit=$1
raw_org=$2
orb=$3

dir_path=$(pwd)
#rm -f data_orb_$orb.txt
rm -f data_$orb.in
rm -f -r $raw_org/aux_poeorb

shopt -s extglob
IFS=" "
while read dataname date_aqc
do
  type=$(echo $dataname | awk '{print substr ($0, 0, 3)}')
  if [ $type = "S1A" ]; then 
    echo "Date: $date_aqc | go to S1A POE"
    cd $sen_orbit/S1A
  elif [  $type = "S1B" ]; then
    echo "Date: $date_aqc | go to S1B POE"
    cd $sen_orbit/S1B
  else
    echo "$type is unknown"
  fi 
  yesterday=$( date -d "${date_aqc} -1 days" +'%Y%m%d' )
  orb_fix=$(grep -r -l V"$yesterday"T | head -1)
  ln -s $sen_orbit/"$type"/"$orb_fix" $raw_org/.
  #cd $raw_org
  #ls *.EOF > data_orb.txt
  #mv data_orb.txt $dir_path

  #write data.in
  cd $raw_org
  tiffname=$(find -name "*$date_aqc*.tiff" -print | sed 's/^..//' | sed -e 's/\.tiff$//')
  cd $dir_path
  echo "$tiffname":"$orb_fix" >> data_$orb.in

done < data_"$orb"_grub.txt

