#!/bin/bash

# created by N.Isya 01.11.2017

###################################################################
network=$5
if [ $network = "SM" ]; then
   inputfile=temp_bperp_combination_SM.txt
elif [ $network = "SB" ]; then
   inputfile=temp_bperp_combination_SB.txt
else
   echo "--------------> Input: Network is unknown"
fi
dir_path=$(pwd)
min=-150 #for y coordinate (baseline range)
max=150
raw_orig=$dir_path/raw_orig
###################################################################

start_date=$1 #for x coordinate (date range)
end_date=$2
suffix=$3
super_master=$4

#create baseline_configuration.txt
rm -f baseline_pair.ps base_config.txt
year=$(echo "$super_master" | awk '{print substr($0,1,4)}')
month=$(echo "$super_master" | awk '{print substr($0,5,2)}')
day=$(echo "$super_master" | awk '{print substr($0,7,2)}')
#echo "$year-$month-$day,0,S1A"$super_master"_ALL_F1" > base_config.txt

shopt -s extglob
IFS=" "
number=1
while read master slave temp bperp
do

cd $raw_orig
baseline_table.csh S1_"$super_master"_ALL_"$suffix".PRM S1_"$master"_ALL_"$suffix".PRM GMT > table.gmt
y_m=$(cat table.gmt | awk '{print $2}')
baseline_table.csh S1_"$super_master"_ALL_"$suffix".PRM S1_"$slave"_ALL_"$suffix".PRM GMT > table.gmt
y_s=$(cat table.gmt | awk '{print $2}')
cd $dir_path
year_m=$(echo "$master" | awk '{print substr($0,1,4)}')
month_m=$(echo "$master" | awk '{print substr($0,5,2)}')
day_m=$(echo "$master" | awk '{print substr($0,7,2)}')
year_s=$(echo "$slave" | awk '{print substr($0,1,4)}')
month_s=$(echo "$slave" | awk '{print substr($0,5,2)}')
day_s=$(echo "$slave" | awk '{print substr($0,7,2)}')
echo "#$number" >> base_config.txt
echo "$year_m-$month_m-$day_m,$y_m,$master" >> base_config.txt
echo "$year_s-$month_s-$day_s,$y_s,$slave" >> base_config.txt
echo ">" >> base_config.txt
(( number++ ))

done < $inputfile

# plot baseline using GMT

gmt gmtset PS_PAGE_ORIENTATION=Landscape
gmt gmtset FORMAT_DATE_IN yyyy-mm-dd FORMAT_DATE_MAP o FONT_ANNOT_PRIMARY +10p
gmt gmtset FORMAT_TIME_PRIMARY_MAP abbreviated PS_CHAR_ENCODING ISOLatin1+
#gmtset FORMAT_DATE_OUT yyyy-mm-dd
gmt psxy base_config.txt -R"$start_date"T/"$end_date"T/"$min"/"$max" -JX9i/6i -Bsx1Y -Bpxa3Of1o+l"Acqusition time" -Bpy50+l"Perpendicular Baseline (m)" -BWeSn+t"Sentinel-1 $network Network" -K -Wthinner > baseline_pair.ps
gmt pstext base_config.txt -R -J -B -F+f7p,Helvetica,blue+jTL -O -K >> baseline_pair.ps
gmt psxy base_config.txt -R -J -O -W -Si0.05i >> baseline_pair.ps
