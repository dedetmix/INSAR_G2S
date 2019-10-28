#!/bin/bash

infile=$1
master=$2
raw=$3
suffix=$4

rm -f temp_bperp_combination_SM.txt intf_SM.in
shopt -s extglob
while read date_acq
do

   #calculate perpendicular baseline for SM network
   dir_path=$(pwd)
   cd $raw
   echo S1_$master"_ALL_$suffix.PRM" S1_$date_acq"_ALL_$suffix.PRM"
   SAT_baseline S1_$master"_ALL_$suffix.PRM" S1_$date_acq"_ALL_$suffix.PRM" > tmp
   BPR=$(grep B_perpendicular tmp | awk '{print $3}')
   BPR2=${BPR%.*}
   rm -f tmp

   cd $dir_path

   #calculate temporal baseline from combination
   master_ts=$(date -d "$master" '+%s')
   slave_ts=$(date -d "$date_acq" '+%s')
   temporal=$(echo "scale=0; ( $slave_ts - $master_ts)/(60*60*24)" | bc)

   #make parameter baseline
   echo $master $date_acq $temporal $BPR >> temp_bperp_combination_SM.txt
   if [ "$master" = "$date_acq" ]; then
      echo "Exclude $master - $master line"
   else
      echo "write intf_SM.in"
      echo "S1_"$master"_ALL_"$suffix":S1_"$date_acq"_ALL_"$suffix"" >> intf_SM.in
   fi

done < $1
