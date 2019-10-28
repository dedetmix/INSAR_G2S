#!/bin/bash

######################################################################
# 03
# script to prepare product information (.xml) combined to auxilary calibration
# GMT5SAR processing for sentinel1A/B
# 2017.01.30 "Noorlaila Hayati"
# email: n.isya@tu-braunschweig.de or noorlaila@geodesy.its.ac.id
###################################################################### 

orb=$1
dir_path=$(pwd)

if [[ ! -d xml_origin ]]; then
    mkdir xml_origin
    cp *.xml $dir_path/xml_origin/.
else
    echo "xml_origin already exists, OK"
fi

#make sure date_dsc_sp.txt & data_sp.in are exist
paste -d\  date_"$orb"_sp.txt data_"$orb"_sp.in | sed -r 's/[:]+/ /g'> date_xml.in

shopt -s extglob
IFS=" "
while read date_acq xml orb
do

type=$(echo $xml | awk '{print substr ($0, 0, 3)}')

awk 'NR>1 {print $0}' < "$date_acq"_manifest.safe > tmp_file
#cat $xml.xml tmp_file > ./"$xml"_a.xml       #if there is no file aux_cal during the SAR images, use this command

# define s1a or s1b
if [ $type = "s1a" ]; then 
    echo "Date: $date_acq | Use S1A aux cal"
    cat $xml.xml tmp_file s1a-aux-cal.xml > ./"$xml"_a.xml 
elif [ $type = "s1b" ]; then 
    echo "Date: $date_acq | Use S1B aux cal" 
    cat $xml.xml tmp_file s1b-aux-cal.xml > ./"$xml"_a.xml 
else
    echo "$type is unknown"
fi
rm tmp_file
rm $xml.xml
mv "$xml"_a.xml $xml.xml

done < date_xml.in

