#!/bin/bash

region=$1
R=$2
A=$3
ov_R=$4
ov_A=$5

x2=$(echo $region $ov_R | sed -r 's/[/]+/\t/g' | cut -f 2 | awk '{print $1}')
x1=$(echo $region | sed -r 's/[/]+/\t/g' | cut -f 1 | awk '{print $1}')
y2=$(echo $region $ov_A | sed -r 's/[/]+/\t/g' | cut -f 4 | awk '{print $1}')
y1=$(echo $region | sed -r 's/[/]+/\t/g' | cut -f 3 | awk '{print $1}')

range_x=$(( $x2-$x1+1 )); echo "width = "$range_x
range_y=$(( $y2-$y1+1 )); echo "length = "$range_y
echo $range_x > width.txt
echo $range_y > len.txt
shift_x=$(expr $range_x / $R); echo "width range = "$shift_x
shift_y=$(expr $range_y / $A); echo "length azimuth = "$shift_y
#x1=$(( $x1-50 ))
#y1=$(( $y1-50 ))
num=1
rm -f -r PATCH.loc PATCH_*

# create patch.in and patch.noover.in
echo " "
stamps_reg.csh $range_x $range_y $R $A $ov_R $ov_A
echo " "

# create PATCH.loc

n=1
shopt -s extglob
IFS=" "
while read start_rg end_rg start_az end_az
do
#if [ $i == 1 ]; then
   x1_coor=$(( $x1+$start_rg-1 ))
   x2_coor=$(( $x1_coor+($end_rg-$start_rg) ))
   y1_coor=$(( $y1+$start_az-1 ))
   y2_coor=$(( $y1_coor+($end_az-$start_az) ))
   echo $x1_coor/$x2_coor/$y1_coor/$y2_coor >> PATCH.loc
#else
   #x1_coor=$(( $x2_coor+$start_rg-1 ))

done < patch_all.in
