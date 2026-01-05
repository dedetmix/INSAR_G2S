#!/bin/bash

######################################################################
# 01
# script to prepare the directory 
# GMT5SAR processing for ALOS PALSAR 2
# 2025.12.25 "Noorlaila Hayati"
# email: n.isya@tu-braunschweig.de or noorlaila@geodesy.its.ac.id
######################################################################

raw_path=$1
suffix=$2
type_data=$3
orb=$4

mkdir batch_"$orb"
cd batch_"$orb"
mkdir raw_orig
cd ..
ls "$raw_path" -1 | grep '\.zip$' | sed -e 's/\.zip$//' > data_orb_"$orb".txt

# extract first zip files
cd batch_"$orb"/raw_orig
while read name
do
  unzip "$raw_path"/"$name".zip 
done < ../../data_orb_"$orb".txt
raw_orig=$(pwd)
cd ..

# extract second zip files and create list
ls "$raw_orig" -1 | grep '\.zip$' | sed -e 's/\.zip$//' > data_zip_"$orb".txt
ls "$raw_orig" | awk '{print substr($0,34,6)}' > date_"$orb".txt
paste -d\  data_zip_"$orb".txt date_"$orb".txt > data_"$orb"_grub.txt
# sorted data
sort -k 2 data_"$orb"_grub.txt > data_"$orb"_grub_tmp.txt
mv data_"$orb"_grub_tmp.txt data_"$orb"_grub.txt
sort -k 1 date_"$orb".txt > date_"$orb"_tmp.txt
mv date_"$orb"_tmp.txt date_"$orb".txt
rm -f data_orb_"$orb".txt
dir_path=$(pwd)
suffix=$suffix

mkdir raw
shopt -s extglob
IFS=" "
while read name date
do

  # identify Single or Dual Polarisation
  if [ $type_data == "mix" ]; then
         polar=$(echo $name | awk '{print substr ($0, 14, 3)}')
	 if [ $polar == "FBD" ]; then
            echo "            Dual Polarisation is identified"
         elif [ $polar == "FBS" ]; then
            echo "            Single Polarisation is identified"
         fi
  elif [ $type_data == "FBS" ]; then
         echo "               All data are Single Polarisation"
  elif [ $type_data == "FBD" ]; then
         echo "               All data are Dual Polarisation"
  fi

  unzip "$raw_orig"/"$name".zip IMG*"$suffix"*.1__A
  mv IMG*"$suffix"*.1__A raw/.
  unzip "$raw_orig"/"$name".zip LED*.1__A
  mv LED*.1__A raw/.
  unzip "$raw_orig"/"$name".zip TRL*.1__A
  mv TRL*.1__A raw/.
  unzip "$raw_orig"/"$name".zip VOL*.1__A
  mv VOL*.1__A raw/.
done < data_"$orb"_grub.txt

# create data list of IMG
ls -d raw/* | grep 'IMG' | xargs -n 1 basename > data.in
# delete raw_orig, let's save our storage
rm -r raw_orig

cd $dir_path
