#!/bin/bash

infile=$1
master=$2
raw=$3
suffix=$4

rm -f temp_bperp_combination_SM.txt intf_SM.in
shopt -s extglob
IFS=" "
while read aligned
do

   #calculate perpendicular baseline for SM network
   dir_path=$(pwd)
   cd $raw
   echo $master".PRM" $aligned".PRM"
   SAT_baseline $master".PRM" $aligned".PRM" > tmp
   BPR=$(grep B_perpendicular tmp | awk '{print $3}')
   BPR2=${BPR%.*}
   rm -f tmp

   cd $dir_path

   #calculate temporal baseline from combination
   master_tmp=$(echo $master | awk '{print substr($0,23,6)}')
   master_full=$(echo $master_tmp | sed 's/^/20/')
   date_acq=$(echo $aligned | awk '{print substr($0,23,6)}')
   date_acq_full=$(echo $date_acq | sed 's/^/20/')
   master_ts=$(date -d "$master_full" '+%s')
   slave_ts=$(date -d "$date_acq_full" '+%s')
   temporal=$(echo "scale=0; ( $slave_ts - $master_ts)/(60*60*24)" | bc)

   #make parameter baseline
   echo $master $aligned $temporal $BPR >> temp_bperp_combination_SM.txt
   if [ "$master" = "$date_acq" ]; then
      echo "Exclude $master - $master line"
   else
      echo "write intf_SM.in"
      echo "$master":"$aligned" >> intf_SM.in
   fi

done < $1
