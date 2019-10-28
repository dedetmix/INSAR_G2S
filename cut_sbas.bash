#!/bin/bash

inputfile=$1
region=$2
raw=$3

rm re_*.grd im_*.grd
[ -d crop_SB ] && echo "Directory crop exists" || mkdir crop_SB
 
shopt -s extglob
IFS=":"
while read master slave
do
  echo "cut $master"_"$slave grd files to size area"
  master_id=$(grep SC_clock_start $raw/$master.PRM | awk '{printf("%d",int($3))}')
  slave_id=$(grep SC_clock_start $raw/$slave.PRM | awk '{printf("%d",int($3))}')
  gmt grdmath real_$master_id"_""$slave_id".grd FLIPUD = tmp.grd=bf
  gmt grdsample tmp.grd -T -Gtmp.grd 
  gmt grdcut tmp.grd -R$region -Gre_$master_id"_""$slave_id".grd=bf
  gmt grdmath imag_$master_id"_""$slave_id".grd FLIPUD = tmp.grd=bf
  gmt grdsample tmp.grd -T -Gtmp.grd 
  gmt grdcut tmp.grd -R$region -Gim_$master_id"_""$slave_id".grd=bf
  mv im_$master_id"_""$slave_id".grd re_$master_id"_""$slave_id".grd crop_SB/.
done < $inputfile
rm tmp.grd
