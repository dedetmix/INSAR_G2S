#!/bin/bash

######################################################################
# 
# script to make master-slave configuration 
# based on temporal and perpendicular baseline
# 2017.10.30 "Noorlaila Isya"
# email: n.isya@tu-bs.de or noorlaila@geodesy.its.ac.id
######################################################################

  if [[ $# -ne 5 ]]; then
    echo ""
    echo "Usage: pair_config.sh date_file temporal perpendicular PATH_PRM_file"
    echo ""
    echo "  script to make master - slave configuration"
    echo ""
    echo "  temporal = threshold number for temporal baseline (days), example : 100"
    echo "  perpendicular = theshold number for spatial baseline (m), example : 100"
    echo ""
    echo "  example : pair_config.sh date_asc.txt 100 100 /home/user/batch/raw"
    echo ""
    echo "  format of date_asc.txt:"
    echo "                          20160101"
    echo "                          20160113"
    echo "                          20160224"
    echo ""
    echo "  output : "
    echo "           - result_combination.txt (all of possibilties for master-slave pairs)"
    echo "           - temp_bperp_combination.txt (+ with temporal & perp baseline parameters)"
    echo "           - intf.in (to be used for intf_tops.csh)" 
    echo ""
    exit 1
  fi

infile=$1
raw=$4
suffix=$5


combination $infile

rm -f temp_bperp_combination_SB.txt intf_SB.in
shopt -s extglob
IFS=" "
while read master slave
do

#calculate perpendicular baseline from combination
dir=$(pwd)
cd $raw
master_short=$(echo $master | sed -E 's/(^| )20/\1/g')
echo $master_short
slave_short=$(echo $slave | sed -E 's/(^| )20/\1/g')
echo $slave_short
master_full=$(find -maxdepth 1 -name "*$master_short*".PRM -printf "%P" | sed 's/\.[^.]*$//')
slave_full=$(find -maxdepth 1 -name "*$slave_short*".PRM -printf "%P" | sed 's/\.[^.]*$//')
echo $master_full $slave_full
SAT_baseline $master_full.PRM $slave_full.PRM > tmp
BPR=$(grep B_perpendicular tmp | awk '{print $3}')
#BPR2=$(echo "scale=0; $BPR" | bc)
BPR2=${BPR%.*}
rm -f tmp

cd $dir

#calculate temporal baseline from combination
master_ts=$(date -d "$master" '+%s')
slave_ts=$(date -d "$slave" '+%s')
temporal=$(echo "scale=0; ( $slave_ts - $master_ts)/(60*60*24)" | bc)

#make parameter baseline
if [ "$temporal" -lt $2 ]
then
    if [ "$BPR2" -gt -$3 ] && [ "$BPR2" -lt $3 ]
    then
        echo "--Matching -- Write the data:" $master_full $slave_full $temporal $BPR 
	echo $master_full $slave_full $temporal $BPR >> temp_bperp_combination_SB.txt
	echo $master_full:$slave_full >> intf_SB.in
    fi
fi

done < result_combination.txt
