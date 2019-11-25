#!/bin/bash

# INSAR_G2S 1.0
# InSAR processing Sentinel-1 TOPS SAR data to be able run by the time series InSAR processing (StaMPS software | PS and Small Baseline Method)
# A bundle script to generate the interferogram from GMTSAR software and further export to STAMPS format 
# This program is established by the scripts of gmtsar_process, gmtsar2stamps, and gmtsar2stamps_sbas.
# gmtsar2stamps is originally from :
#                                   - Xiaopeng Tong - Chinese Academy of Sciences
#                                   - David Sandwell - Scripps Institution of Oceanography

# Created by Noorlaila Isya	01.10.2019
# 	     IGP, TU Braunschweig - Germany
#            Department of Geomatics Engineering, ITS - Indonesia
#            n.isya@tu-bs.de / noorlaila@geodesy.its.ac.id

  dir=$(pwd)
  if [[ $# -ne 2 ]]; then
    echo ""
    echo "Usage: INSAR_G2S [step] [parameter_with_path_directory]"
    echo ""
    echo "  Script to pre-process SAR data and export to STAMPS format"
    echo ""
    echo "  example : INSAR_G2S 1 /home/isya/3d_disp/param_INSAR_G2S.txt"
    echo ""
    echo "  Step: Data Preparation --> "
    echo "        1  Prepare the directory arrangement"
    echo "        2  Prepare the POE data"
    echo "        3  Prepare the EAP data"
    echo "        4  Preprocess SAR data: Compute Baseline and Alignment"
    echo "        5  Create a configuration of master-slave for SM or SB network"
    echo ""
    echo "        Interferogram Generation --> "
    echo "        6  Project DEM to radar coordinates"
    echo "        7  Generate Interferogram (Real and Imaginary format) [SM | SB]"
    echo "        8  Overview the sample of amplitude and phase file on Google Earth (optional)"
    echo "        9  Cut the interferograms based on ROI (optional) [SM | SB]"
    echo ""
    echo "        GMTSAR2STAMPS (PS Method) --> "
    echo "        10 Create Amplitude Dispersion Index"
    echo "        11 Convert GMTSAR result to be able processed by STAMPS PS"
    echo "        12 Fix the result of PS Candidates (PS)"
    echo ""
    echo "        GMTSAR2STAMPS (Small Baseline [SB] Method) --> "
    echo "        13 Create Amplitude Difference Dispersion Index"
    echo "        14 Convert GMTSAR result to be able processed by STAMPS SB"
    echo "        15 Fix the result of PS Candidates (SB)"
    echo ""
    echo ""
    exit 1
  fi

step=$1
path=$2

# define parameter from param_INSAR_G2S.txt
orbit=$(grep dataorbit $path | sed 's/^.*= //')
raw_path=$(grep raw_path $path | sed 's/^.*= //')
sen_orbit=$(grep sen_POE $path | sed 's/^.*= //')
temp_bl=$(grep temp_bl $path | sed 's/^.*= //')
spatial_bl=$(grep spatial_bl $path | sed 's/^.*= //')
region=$(grep region $path | sed 's/^.*= //');
region_ll=$(grep reg_ll $path | sed 's/^.*= //');
R=$(grep n_range $path | sed 's/^.*= //')
A=$(grep n_azimuth $path | sed 's/^.*= //')
ov_R=$(grep ov_range $path | sed 's/^.*= //')
ov_A=$(grep ov_azimuth $path | sed 's/^.*= //')
threshold=$(grep threshold $path | sed 's/^.*= //')
master_date=$(grep master_date $path | sed 's/^.*= //')
master_PRM=$(grep master_PRM $path | sed 's/^.*= //')
suffix=$(grep suffix $path | sed 's/^.*= //')
suffix_tiff=$(grep tiff_id $path | sed 's/^.*= //')
type_data=$(grep type_data $path | sed 's/^.*= //')
heading=$(grep heading $path | sed 's/^.*= //')

# define orbit data
if [ $orbit = "ascending" ]; then
   echo "--------------> Prepare the directory arrangement for ascending SAR data"
   orb=asc
elif [ $orbit = "descending" ]; then
   echo "--------------> Prepare the directory arrangement for descending SAR data"
   orb=dsc
else
   echo "--------------> Input: orbit is unknown"
fi

# go to Step [1]

if [ $step -eq 1 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "1  Prepare the directory arrangement"
echo "Path must be located on the basement"
echo " "

   prep_dir.sh $raw_path $suffix_tiff $type_data $orb

   echo "raw_orig= $dir/batch_$orb/raw_orig" > param_dir_$orb.txt
   echo "raw_data= $dir/batch_$orb/raw" >> param_dir_$orb.txt
   echo "topo    = $dir/batch_$orb/topo" >> param_dir_$orb.txt
   echo "SLC     = $dir/batch_$orb/raw" >> param_dir_$orb.txt
   echo "stack   = $dir/batch_$orb/stack" >> param_dir_$orb.txt
   echo "crop_SM = $dir/batch_$orb/stack/crop_SM" >> param_dir_$orb.txt
   echo "crop_SB = $dir/batch_$orb/stack/crop_SB" >> param_dir_$orb.txt
   echo "PS      = $dir/batch_$orb/stack/PS" >> param_dir_$orb.txt
   echo "SB      = $dir/batch_$orb/stack/PS/SMALL_BASELINES" >> param_dir_$orb.txt

fi

# go to Step [2]
if [ $step -eq 2 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "2  Prepare the POE data"
echo "Path must be located on the basement"
echo " "

   raw_org=$dir/batch_"$orb"/raw_orig
   echo "--------------> Prepare the precise orbit ephemeris (POE) data"
   echo "--------------> Please choose an option "
   echo -n "Do you have the POE data on your local computer [type: yes or no]? "
   read option
        if [ $option = "yes" ]; then
          
           echo "Use the POE data on your local directory"
           prep_orb.sh $sen_orbit $raw_org $orb

        elif [ $option = "no" ]; then
           
           echo "Download the POE files and put in raw_orig directory"
           scihub_poeorb_download.sh $raw_org $orb

        else
           echo "--------------> Input: Option is unknown"
        fi
   echo " "

fi

# go to Step [3]
if [ $step -eq 3 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "3  Prepare the EAP data"
echo "Path must be located on the basement"
echo " "

   cd $dir/batch_"$orb"/raw_orig
   cp ../../date_"$orb".txt .
   cp ../../data_"$orb".in .
   rm -f date_"$orb"_sp.txt
   rm -f data_"$orb"_sp.in
 
   # create date_sp.txt and data_sp.in
   echo $master_date >> date_"$orb"_sp.txt
   echo $(grep "$master_date" data_"$orb".in) | sed 's/ /:/g' >> data_"$orb"_sp.in
   IFS=':'
   while read -r -u3 date_num && read -r -u4 tiff_name POE_name 
   do
      if [ $date_num = "$master_date" ]; then
         echo "Arrange the master date at the first line"
      else
         echo $date_num >> date_"$orb"_sp.txt
         echo ""$tiff_name":"$POE_name"" >> data_"$orb"_sp.in
      fi
   done  3<date_"$orb".txt 4<data_"$orb".in

   # apply EAP on the xml files
   prep.sh $orb

   rm -f date_"$orb".txt
   rm -f data_"$orb".in

   cd $dir/batch_"$orb"
   mkdir topo
   cd $dir
   echo " "
   echo "==== Please save dem.grd file in topo folder ===="
   echo " "

fi

# go to Step [4]
if [ $step -eq 4 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "4  Preprocess SAR data: Compute Baseline and Alignment"
echo "Path must be located on the basement"
echo " "
    
   cd $dir/batch_"$orb"/raw_orig
   ln -s ../topo/dem.grd .
   preproc_batch_tops.csh data_"$orb"_sp.in dem.grd 1
   preproc_batch_tops.csh data_"$orb"_sp.in dem.grd 2
   cd $dir

   cd $dir/batch_"$orb"
   ln -s ../param* .
   mkdir raw
   cd raw
   ln -s ../raw_orig/*.PRM .
   ln -s ../raw_orig/*.PRM0 .
   ln -s ../raw_orig/*.LED .
   ln -s ../raw_orig/*.SLC .
   ln -s ../raw_orig/*.dat .
   ln -s ../raw_orig/*.grd .
   ln -s ../raw_orig/*.xml .

   echo " "
   echo "From now you will work on batch_"$orb" directory"
   echo " "

fi

# go to Step [5]
if [ $step -eq 5 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "5  Create a configuration of master-slave for SM or SB network"
echo "Path must be located on batch_$orb"
echo " "
   
   cp ../date_"$orb".txt .
   tmp_start=$(head -n 1 date_"$orb".txt)
   start_date=$(date -I -d "$tmp_start - 15 day")
   tmp_end=$(tail -n 1 date_"$orb".txt)
   end_date=$(date -I -d "$tmp_end + 45 day")


   echo "--------------> Create Master-Slave network for PS (SM) and SB mentod"
   echo "--------------> Please choose an option "
   echo -n "Single Master (MS) or Small Baseline (SB) network [type: SM or SB]? "
   read option
        if [ $option = "SM" ]; then
          
           echo "SM network is created with date of master: $master_date"
           sm_config.sh date_"$orb".txt $master_date $dir/raw $suffix 
           baseline_sen.sh $start_date $end_date $suffix $master_date SM
           mv baseline_pair.ps baseline_pair_SM.ps

        elif [ $option = "SB" ]; then
           
           echo "SB network is created"
           pair_config.sh date_"$orb".txt $temp_bl $spatial_bl $dir/raw $suffix
           baseline_sen.sh $start_date $end_date $suffix $master_date SB
           mv baseline_pair.ps baseline_pair_"$temp_bl"_"$spatial_bl".ps

        else
           echo "--------------> Input: Option is unknown"
        fi
   echo " "

fi

# go to Step [6]
if [ $step -eq 6 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "6  Project DEM to radar coordinates"
echo "Path must be located on the batch_$orb"
echo " "
   
   cd topo
   cp ../raw_orig/"$master_PRM".PRM .
   cp ../raw_orig/"$master_PRM".LED .
   mv "$master_PRM".PRM master.PRM
   
   dem2topo_ra.csh master.PRM dem.grd
   
   cd $dir
   echo " "
   echo "dem.grd has been projected to radar coordinates"
   echo " "

fi

# go to Step [7]
if [ $step -eq 7 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "7  Generate Interferogram (Real and Imaginary format) [SM | SB]"
echo "Path must be located on the batch_$orb"
echo " "

   echo " "
   echo "Working on batch_"$orb" directory"
   echo " "
   echo "--------------> Please choose an option "
   echo -n "Single Master (MS) or Small Baseline (SB) mode [type: SM or SB]? "
   read option
        
        mkdir -p stack
        cd stack
        if [ $option = "SM" ]; then
          
           echo "Interferogram is generated with SM network"
           ln -s ../intf_SM.in .
           process_intf.csh intf_SM.in $dir/raw $dir/topo

        elif [ $option = "SB" ]; then

           echo "Interferogram is generated with SB network"   
           ln -s ../intf_SB.in .
           process_intf.csh intf_SB.in $dir/raw $dir/topo

        else
           echo "--------------> Input: Option is unknown"
        fi     

   echo " "
   echo "Interferograms have been generated"
   echo " "
   cd ..

fi

# go to Step [8]
if [ $step -eq 8 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "8  Overview the sample of amplitude and phase file on Google Earth (optional)"
echo "Path must be located on the batch_$orb/stack"
echo " "

   echo " "
   echo "Working on batch_"$orb"/stack directory"
   echo " "     
   
   intf_kml.sh intf_tes.in $dir/raw $dir/topo $region_ll

   echo " "
   echo "Open kml file on Google Earth"
   echo " "
   cd ..

fi

# go to Step [9]
if [ $step -eq 9 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "9  Cut the interferograms based on ROI (optional) [SM | SB]"
echo "Path must be located on the batch_$orb/stack"
echo " "

   echo " "
   echo "Working on batch_"$orb"/stack directory"
   echo " "
   echo "--------------> Please choose an option "
   echo -n "Single Master (MS) or Small Baseline (SB) mode [type: SM or SB]? "
   read option
        
        if [ $option = "SM" ]; then
          
           echo "Interferogram is generated with SM network"
           cut_SM.bash intf_SM.in $region ../raw

        elif [ $option = "SB" ]; then

           echo "Interferogram is cropped for the SB Intf result"   
           cut_sbas.bash intf_SB.in $region ../raw

        else
           echo "--------------> Input: Option is unknown"
        fi        

   echo " "
   echo "Interferograms have been cropped"
   echo " "

fi

# go to Step [10]
if [ $step -eq 10 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "10 Create Amplitude Dispersion Index"
echo "Path must be located on the batch_$orb/stack"
echo " "

   echo " "
   echo "Working on batch_"$orb"/raw directory"
   echo " "     
   
   cd ../raw
   ls -1 *ALL_"$suffix".PRM --ignore="PRM.list*" > PRM.list
   echo " "
   echo "Compute AD for PS method"
   echo " "

   dispersion.csh PRM.list scatter_SM.grd $region

   cd $dir

fi

# go to Step [11]
if [ $step -eq 11 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "11 Convert GMTSAR result to be able processed by STAMPS PS"
echo "Path must be located on the batch_$orb/stack"
echo " "

   echo " "
   echo "Working on batch_"$orb"/stack directory"
   echo " "     
   
   mkdir -p PS
   cd PS
   cp ../intf_SM.in .
   ln -s ../../../param_dir_$orb.txt .
   sed -i -e 's/[:]/ /g' intf_SM.in
   cat intf_SM.in | sed "s/S1_//g" | sed "s/_ALL_$suffix//g" > intf_SM_list.in
   rm intf_SM.in
   cp ../../date_$orb.txt date_no_master.txt
   sed -i "/\b\($master_date\)\b/d" date_no_master.txt

   mt_prep_gmtsar_SM $region $R $A $ov_R $ov_A $threshold $master_date $suffix $heading

   cd $dir

fi

# go to Step [12]
if [ $step -eq 12 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "12 Fix the result of PS Candidates (PS)"
echo "Path must be located on the batch_$orb/stack/PS"
echo " "

   echo " "
   echo "Working on PS directory"
   echo " "     

   fix_pscands_SM.sh

fi

# go to Step [13]
if [ $step -eq 13 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "13 Create Amplitude Difference Dispersion Index"
echo "Path must be located on the batch_$orb/stack"
echo " "

   echo " "
   echo "Working on batch_"$orb"/raw directory"
   echo " "     
   
   cd ../raw
   ls -1 *ALL_"$suffix".PRM --ignore="PRM.list*" > PRM.list
   cp ../intf_SB.in sbas.list
   sed -i -e 's/[:]/ /g' sbas.list
   echo " "
   echo "Compute ADD for SB method"
   echo " "

   dispersion_sbas.sh PRM.list scatter_SB.grd $region sbas.list

   cd $dir

fi

# go to Step [14]
if [ $step -eq 14 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "14 Convert GMTSAR result to be able processed by STAMPS SB"
echo "Path must be located on the batch_$orb/stack"
echo " "

   echo " "
   echo "Working on batch_"$orb"/stack directory"
   echo " "     
   
   mkdir -p PS
   cd PS
   cp ../intf_SB.in .
   ln -s ../../../param_dir_$orb.txt .
   sed -i -e 's/[:]/ /g' intf_SB.in
   cat intf_SB.in | sed "s/S1_//g" | sed "s/_ALL_$suffix//g" > intf_SB_list.in
   rm intf_SB.in
   cp ../../date_$orb.txt date_no_master.txt
   sed -i "/\b\($master_date\)\b/d" date_no_master.txt

   mt_prep_gmtsar_SB $region $R $A $ov_R $ov_A $threshold $master_date $suffix $heading

   cd $dir

fi

# go to Step [15]
if [ $step -eq 15 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "15 Fix the result of PS Candidates (SB)"
echo "Path must be located on the batch_$orb/stack/PS/SMALL_BASELINES"
echo " "

   echo " "
   echo "Working on SMALL_BASELINES directory"
   echo " "     

   fix_pscands_SB.sh

fi
