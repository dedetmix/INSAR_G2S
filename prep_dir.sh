#!/bin/bash

######################################################################
# 01
# script to prepare the directory 
# GMT5SAR processing for sentinel1A/B
# 2017.01.30 "Noorlaila Hayati"
# email: n.isya@tu-braunschweig.de or noorlaila@geodesy.its.ac.id
######################################################################

raw_path=$1
suffix_tiff=$2
type_data=$3
orb=$4

mkdir batch_"$orb"
cd batch_"$orb"
mkdir raw_orig
cd ..
ls "$raw_path" -1 | sed -e 's/\.zip$//' > data_orb_"$orb".txt
ls "$raw_path" | awk '{print substr($0,18,8)}' > date_"$orb".txt
paste -d\  data_orb_"$orb".txt date_"$orb".txt > data_"$orb"_grub.txt
# sorted data
sort -k 2 data_"$orb"_grub.txt > data_"$orb"_grub_tmp.txt
mv data_"$orb"_grub_tmp.txt data_"$orb"_grub.txt
sort -k 1 date_"$orb".txt > date_"$orb"_tmp.txt
mv date_"$orb"_tmp.txt date_"$orb".txt
rm -f data_orb_"$orb".txt
dir_path=$(pwd)
suffix_tmp=$suffix_tiff

shopt -s extglob
IFS=" "
while read name date
do

  # identify Single or Dual Polarisation
  if [ $type_data == "mix" ]; then
         polar=$(echo $name | awk '{print substr ($0, 14, 3)}')
	 if [ $polar == "SDV" ]; then
            i=$(expr $suffix_tiff + 3)
            suffix_tiff=$(printf "%03d" "$i")
            echo "            TIFF number has changed $suffix_tiff , Dual Polarisation is identified"
         elif [ $polar == "SSV" ]; then
            suffix_tiff=$suffix_tmp
            echo "            Keep TIFF number $suffix_tiff, Single Polarisation is identified"
         fi
  elif [ $type_data == "single" ]; then
         echo "               TIFF number doesn't change, all data are Single Polarisation"
  elif [ $type_data == "dual" ]; then
         echo "               TIFF number doesn't change, all data are Dual Polarisation"
  fi

  unzip "$raw_path"/"$name".zip "$name".SAFE/measurement/*"$suffix_tiff".tiff
  mv "$name".SAFE/measurement/*"$suffix_tiff".tiff $dir_path/batch_"$orb"/raw_orig/.
  unzip "$raw_path"/"$name".zip "$name".SAFE/manifest.safe
  mv "$name".SAFE/manifest.safe $dir_path/batch_"$orb"/raw_orig/"$date"_manifest.safe
  unzip "$raw_path"/"$name".zip "$name".SAFE/annotation/*"$suffix_tiff".xml
  mv "$name".SAFE/annotation/*"$suffix_tiff".xml $dir_path/batch_"$orb"/raw_orig/.
  rm -r -f $name.SAFE
  suffix_tiff=$suffix_tmp
done < data_"$orb"_grub.txt


cd $dir_path

