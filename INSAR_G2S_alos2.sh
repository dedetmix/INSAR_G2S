#!/bin/bash

# INSAR_G2S 1.5
# InSAR processing Sentinel-1 TOPS SAR and ALOS PALSAR-2 data to be able run by the time series InSAR processing (StaMPS software | PS and Small Baseline Method)
# A bundle script to generate the interferogram from GMTSAR software and further export to STAMPS format 
# This program is established by the scripts of gmtsar_process, gmtsar2stamps, and gmtsar2stamps_sbas.
# gmtsar2stamps is originally from :
#                                   - Xiaopeng Tong - Chinese Academy of Sciences
#                                   - David Sandwell - Scripps Institution of Oceanography

# Created by Noorlaila Hayati Isya	01.10.2019
# 	     IGP, TU Braunschweig - Germany
#            Department of Geomatics Engineering, ITS - Indonesia
#            noorlaila@its.ac.id
#
# 26.12.2025 add ALOS PALSAR-2 Data (FBR)

  dir=$(pwd)
  if [[ $# -ne 2 ]]; then
    echo ""
    echo "Usage: INSAR_G2S_new.sh [step] [parameter_with_path_directory]"
    echo ""
    echo "  Script to pre-process SAR data and export to STAMPS format"
    echo ""
    echo "  example : INSAR_G2S_alos2.sh 1 /home/isya/3d_disp/param_INSAR_G2S_alos2.txt"
    echo ""
    echo "  Step: Data Preparation --> "
    echo "        1  Prepare the directory arrangement"
    echo "        2  Prepare the POE data --> skip for ALOS2"
    echo "        3  Prepare the EAP data --> skip for ALOS2"
    echo "        4  Preprocess SAR data: Compute Baseline and Alignment"
    echo "        5  Create a configuration of master-slave for SM or SB network"
    echo ""
    echo "        Interferogram Generation --> "
    echo "        6  Project DEM to radar coordinates"
    echo "        7  Generate Interferogram (Real and Imaginary format) [SM | SB]"
    echo "        8  Overview the sample of amplitude and phase file on Google Earth (optional)"
    echo "        9  Cut the interferograms based on ROI [SM | SB] -- can be skipped but need to set up the region manually" 
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

# define parameter from param_INSAR_G2S_alos2.txt
orbit=$(grep dataorbit $path | sed 's/^.*= //')
echo $orbit
raw_path=$(grep raw_path $path | sed 's/^.*= //')
echo $raw_path
temp_bl=$(grep temp_bl $path | sed 's/^.*= //')
spatial_bl=$(grep spatial_bl $path | sed 's/^.*= //')
R=$(grep n_range $path | sed 's/^.*= //')
A=$(grep n_azimuth $path | sed 's/^.*= //')
ov_R=$(grep ov_range $path | sed 's/^.*= //')
ov_A=$(grep ov_azimuth $path | sed 's/^.*= //')
threshold=$(grep threshold $path | sed 's/^.*= //')
master_date=$(grep master_date $path | sed 's/^.*= //')
master_PRM=$(grep master_PRM $path | sed 's/^.*= //')
suffix=$(grep suffix_file $path | sed 's/^.*= //')
echo $suffix
type_data=$(grep type_data $path | sed 's/^.*= //')
echo $type_data
heading=$(grep heading $path | sed 's/^.*= //')
long_min=$(grep demlong_min $path | sed 's/^.*= //')
long_max=$(grep demlong_max $path | sed 's/^.*= //')
lat_min=$(grep demlat_min $path | sed 's/^.*= //')
lat_max=$(grep demlat_max $path | sed 's/^.*= //')
long_min_aoi=$(grep long_min_aoi $path | sed 's/^.*= //')
long_max_aoi=$(grep long_max_aoi $path | sed 's/^.*= //')
lat_min_aoi=$(grep lat_min_aoi $path | sed 's/^.*= //')
lat_max_aoi=$(grep lat_max_aoi $path | sed 's/^.*= //')

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

   prep_dir_alos2.sh $raw_path $suffix $type_data $orb

   echo "raw_data= $dir/batch_$orb/raw" > param_dir_$orb.txt
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

   echo "--------------> Prepare EAP"
   echo "--------------> Please choose an option "
   echo -n "Do you want to add EAP data [type: yes or no]? "
   read option

        if [ $option = "yes" ]; then         
           echo "apply EAP on the xml files"
           # apply EAP on the xml files
           prep.sh $orb
        elif [ $option = "no" ]; then
           
           echo "Step 3 skip, just add some parameter files"
        else
           echo "--------------> Input: Option is unknown"
        fi
   echo " "

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
echo "4  Preprocess SAR data: Download DEM, Compute Baseline and Alignment"
echo "Path must be located on the basement"
echo " "
    
   #Download DEM
   cd $dir/batch_"$orb"
   mkdir topo
   cd topo
   echo "DEM AOI $long_min"/"$long_max"/"$lat_min"/"$lat_max"
   make_dem.csh $long_min $long_max $lat_min $lat_max 1
   cd ..
   
   #Rearrange data.in to data_master.in
   cp data.in data_master.in
   sed -i "/^$master_PRM/d" data_master.in
   cp data_master.in data_no_master.in
   sed -i "1i $master_PRM" data_master.in
   
   #Calculate baseline and alignment
   #cd $dir/batch_"$orb"/raw
   ln -s ../topo/dem.grd .
   batch_processing.csh ALOS2 $master_PRM data_master.in 1
   batch_processing.csh ALOS2 $master_PRM data_master.in 2

   #check if baseline_table.dat exists
   FILE=baseline_table.dat
   if [ -f "$FILE" ]; then
      echo "$FILE exists."
   else 
      echo "$FILE does not exist, try to regenerate."
      #ls *ALL*PRM > prmlist
      #get_baseline_table.csh prmlist "$master_PRM".PRM
      #rm prmlist
   fi

   cd $dir

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
   
   cp date_"$orb".txt date_"$orb"_full.txt
   sed -i 's/^/20/' date_"$orb"_full.txt
   tmp_start=$(head -n 1 date_"$orb"_full.txt)
   start_date=$(date -I -d "$tmp_start - 15 day")
   tmp_end=$(tail -n 1 date_"$orb".txt)
   end_date=$(date -I -d "$tmp_end + 45 day")


   echo "--------------> Create Master-Slave network for PS (SM) and SB mentod"
   echo "--------------> Please choose an option "
   echo -n "Single Master (MS) or Small Baseline (SB) network [type: SM or SB]? "
   read option
        if [ $option = "SM" ]; then
          
           echo "SM network is created with date of master: $master_date"
           sm_config_alos2.sh data_no_master.in $master_PRM $dir/raw $suffix 
           baseline_alos2.sh $start_date $end_date $suffix $master_PRM SM
           mv baseline_pair.ps baseline_pair_SM.ps

        elif [ $option = "SB" ]; then
           
           echo "SB network is created"
           pair_config_alos2.sh date_"$orb"_full.txt $temp_bl $spatial_bl $dir/raw $suffix
           baseline_alos2.sh $start_date $end_date $suffix $master_PRM SB
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
   
   #cd topo
   #cp ../raw/"$master_PRM".PRM .
   #cp ../raw/"$master_PRM".LED .
   #mv "$master_PRM".PRM master.PRM
   
   batch_processing.csh ALOS2 $master_PRM data_master.in 3
   
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
   
   intf_kml.sh intf_tes.in ../raw ../topo $region_ll

   echo " "
   echo "Open kml file on Google Earth"
   echo " "
   cd ..

fi

# go to Step [9]
if [ $step -eq 9 ]; then
echo " "
echo "INSAR_G2S STEP ---->>" $step
echo "9  Cut the interferograms based on AOI (optional) [SM | SB]"
echo "Path must be located on the batch_$orb/stack"
echo " "

   echo " "
   echo "Working on batch_"$orb"/stack directory"
   echo " "
   echo "--------------> Please choose an option "
   echo -n "Single Master (MS) or Small Baseline (SB) mode [type: SM or SB]? "
   read option
   
        echo $long_min_aoi $lat_min_aoi "0" > aoi_ll.xyz
        echo $long_max_aoi $lat_max_aoi "0" >> aoi_ll.xyz
        
        #project geographic (long,lat) to radar coordinates (range, azimuth)
        proj_ll2ra_ascii.csh ../topo/trans.dat aoi_ll.xyz aoi_ra.xyz
        region=$(awk '{x[NR]=$1; y[NR]=$2} END {print int(x[1]) "/" int(x[2]) "/" int(y[1]) "/" int(y[2])}' aoi_ra.xyz)
        
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

   region=$(awk '{x[NR]=$1; y[NR]=$2} END {print int(x[1]) "/" int(x[2]) "/" int(y[1]) "/" int(y[2])}' aoi_ra.xyz)

   echo " "
   echo "Working on batch_"$orb"/raw directory"
   echo " "     
   
   cd ../raw
   ls -1 *PRM --ignore="PRM.list*" > PRM.list
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
   
   region=$(awk '{x[NR]=$1; y[NR]=$2} END {print int(x[1]) "/" int(x[2]) "/" int(y[1]) "/" int(y[2])}' aoi_ra.xyz)
   
   mkdir -p PS
   cd PS
   cp ../../intf_SM.in .
   ln -s ../../../param_dir_$orb.txt param_dir.txt
   sed -i -e 's/[:]/ /g' intf_SM.in
   #cat intf_SM.in | sed "s/S1_//g" | sed "s/_ALL_$suffix//g" > intf_SM_list.in
   #rm intf_SM.in
   cp ../../date_$orb.txt date_no_master.txt
   sed -i "/\b\($master_date\)\b/d" date_no_master.txt
   cp date_no_master.txt date_no_master_full.txt
   sed -i 's/^/20/' date_no_master_full.txt

   mt_prep_gmtsar_SM_alos2 $region $R $A $ov_R $ov_A $threshold $master_date $suffix $heading
   
   sed -i 's/^/20/' day.1.in
   sed -i 's/^/20/' master_day.1.in

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

   region=$(awk '{x[NR]=$1; y[NR]=$2} END {print int(x[1]) "/" int(x[2]) "/" int(y[1]) "/" int(y[2])}' aoi_ra.xyz)
   
   echo " "
   echo "Working on batch_"$orb"/raw directory"
   echo " "     
   
   cd ../raw
   ls -1 *PRM --ignore="PRM.list*" > PRM.list
   cp ../intf_SB.in sbas.list
   sed -i -e 's/[:]/ /g' sbas.list
   #awk '{print $1".SLC", $2".SLC"}' sbas.list > temp.txt && mv temp.txt sbas.list
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

   region=$(awk '{x[NR]=$1; y[NR]=$2} END {print int(x[1]) "/" int(x[2]) "/" int(y[1]) "/" int(y[2])}' aoi_ra.xyz)

   echo " "
   echo "Working on batch_"$orb"/stack directory"
   echo " "     
   
   mkdir -p PS
   cd PS
   cp ../../intf_SB.in .
   ln -s ../../../param_dir_$orb.txt param_dir.txt
   sed -i -e 's/[:]/ /g' intf_SB.in
   #re-arrange SB list from date to date
   	rm intf_SB_list.in
   	while read -r line; do
    		echo "$line" | grep -oP '(?<=-)\d{6}(?=-)' | sed 's/^/20/' | xargs >> intf_SB_list.in
	done < intf_SB.in
   #cat intf_SB.in | sed "s/S1_//g" | sed "s/_ALL_$suffix//g" > intf_SB_list.in
   #rm intf_SB.in
   cp ../../date_$orb.txt date_no_master.txt
   sed -i "/\b\($master_date\)\b/d" date_no_master.txt
   cp date_no_master.txt date_no_master_full.txt
   sed -i 's/^/20/' date_no_master_full.txt

   mt_prep_gmtsar_SB_alos2 $region $R $A $ov_R $ov_A $threshold $master_date $suffix $heading

   sed -i 's/^/20/' day.1.in
   sed -i 's/^/20/' master_day.1.in
   
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
