#!/bin/bash

# Amplitude difference dispersion from a stack of aligned SLCs for master-slave SB pairs

# Creator: Xiaopeng Tong, David Sandwell
# Date:    July 4th 2013  
# Modified by NI, 06.02.2018

# input: PRM.list
# input: sbas.list
# output: amplitude difference dispersion 

# The principle: first calibrate each images by a weighting
#                factor then compute the mean amplitude M_A_sb for all master-slave pairs
#                and the standard deviation of the difference amplitude sig_delta_A
#                then take the ratio of the M_A_sb and sig_delta_A 

# Reference: Lyons and Sandwell, Fault creep along the southern San Andreas from InSAR, permanent scatterers, and stacking, J. Geophys. Res., 108 (B1), 2047, doi:10.1029/ 2002JB001831 2003
# 	     Hooper, Andy, A multi-temporal InSAR method incorporating both persistent scatterer and small baseline approaches, GEOPHYSICAL RESEARCH LETTERS, VOL. 35, L16302, doi:10.1029/2008GL034654, 2008

#alias rm 'rm -f'

if [[ $# -ne 4 ]]; then
  echo ""
  echo "Usage: dispersion_sbas.sh PRM.list scatter.grd <rng0>/<rngf>/<azi0>/<azif> sbas.list"
  echo ""
  echo "    Amplitude difference dispersion from a stack of aligned SLCs between master and slave"
  echo ""
  echo "    PRM.list     --  a list of PRM files of the aligned SLC"
  echo "    sbas.list     --  a list of PRM files of the aligned SLC for master-slave pairs"
  echo "    scatter.grd  --  output scattering coeffient grid"
  echo "    <rng0>/<rngf>/<azi0>/<azif>   —  region of interests in radar coordinates"
  echo ""
  echo "    example:"
  echo "              PRM.list >> S1A20141113_ALL_F1.PRM"
  echo "                          S1A20141207_ALL_F1.PRM"
  echo "              sbas.list >> S1A20141113_ALL_F1 S1A20141207_ALL_F1"
  echo "                           S1A20141113_ALL_F1 S1A20141231_ALL_F1"
  echo ""
  exit 1
fi

if [ ! -e $1 ]; then
  echo ""
  echo "no input file found: $1"
  echo ""
  exit 1
fi

list=$1
outgrd=$2
region=$3
sbas_list=$4
#filter = $GMT5SAR/gmtsar/filters/gauss1x1
filter=$GMTSAR/gmtsar/filters/gauss5x5
namearray= 
weightarray= 


echo ""
echo "Start -- compute amplitude difference dispersion"
echo ""

#
# conv to get amplitude of the SLCs and compute their sum and average  
#

echo "compute amplitude from SLCs ..."
num=1
rm -f namearray.txt weightarray.txt
while read prm
do
  name=$(grep input_file $prm | awk '{print $3}' | sed 's/\.raw//' | sed 's/\.SLC//')  #add to remove .SLC -- 27.12.2025
  #namearray=(${namearray[*]}  $name".grd")
  #echo "${namearray[*]}" >> namearray.txt
  echo $name >> namearray.txt
  if [ -e $prm ]; then 
    if [ ! -e $name".grd" ]; then
      echo "running conv on file $name"
      conv 1 1 $filter $prm $name".grd"  #2-D image convolution, makes and filters amplitude file from an SLC-file
      gmt grdmath $name".grd" FLIPUD = $name".grd"
    fi
    #gmt grd2cpt $name".grd" -Cgray -Z -D > b.cpt
    gmt makecpt -Cgray -T1e-8/1e-7/1e-8 -Z > a.cpt
    gmt grdimage $name".grd" -Ca.cpt -JX6i -P -Xc -Yc -V -R$region -Bf250a500WSen > $name".ps"
  else 
      echo ""
      echo "no PRM file found: $prm"
      echo ""
      exit 1
  fi
  gmt grdcut $name".grd" -R$region -Gtmp.grd
  mv tmp.grd $name".grd"
  if [ $num == 1 ]; then
    gmt grdmath $name".grd" = sum.grd  
  else
    gmt grdmath sum.grd $name".grd" ADD = sumtmp.grd 
    mv sumtmp.grd sum.grd 
  fi
(( num++ ))

done < $list

(( num-- )) 
gmt grdmath sum.grd $num DIV = ave.grd 
avemean=$(gmt grdinfo ave.grd -L2 -C | cut -f 12)
echo $avemean
#


#
# compute the M_A_sb term 
#

echo ""
echo "compute the M_A term for SB and calibration factor..."
shopt -s extglob
IFS=" "
num=1
while read master slave
do
  ampmean_m=$(gmt grdinfo $master".grd" -L2 -C | cut -f 12)
  weight_m=$(echo $ampmean_m $avemean | awk '{print $1/$2}')
  ampmean_s=$(gmt grdinfo $slave".grd" -L2 -C | cut -f 12)
  weight_s=$(echo $ampmean_s $avemean | awk '{print $1/$2}')
  #echo "calib factor for master: "$weight_m "  ... and for slave: "$weight_s
  echo $weight_m $weight_s >> weightarray.txt
  #weightarray=(${weightarray[*]} $weight)
  #echo "${weightarray[*]}" >> weightarraySB.txt
  #gmt grdmath $name".grd" $weight DIV = tmp.grd 
  if [ $num == 1 ]; then
    gmt grdmath $master".grd" $weight_m DIV = sum.grd
    gmt grdmath $slave".grd" $weight_s DIV sum.grd ADD = sumtmp1.grd
    mv sumtmp1.grd sum.grd
  else
    gmt grdmath $master".grd" $weight_m DIV sum.grd ADD = sumtmp2.grd
    mv sumtmp2.grd sum.grd
    gmt grdmath $slave".grd" $weight_s DIV sum.grd ADD = sumtmp3.grd
    mv sumtmp3.grd sum.grd  
  fi
  (( num++ ))
done < $sbas_list
(( num-- ))
num=$(( $num*2 ))
gmt grdmath sum.grd $num DIV = M_A_sb.grd  
#rm tmp.grd
#


#
# compute the sig_delta_A term : the standard deviation of the difference in amplitude between master and slave
#  
echo ""
echo "compute the sig_delta_A term"  
echo "Step 1, compute sum of square diff A = (Amp1-Amp2)*(Amp1-Amp2) ..."
paste -d\  $sbas_list weightarray.txt > sigA_variable.txt
num=1
while read master slave weight_m weight_s
do
  name_m=$(grep input_file $master".PRM" | awk '{print $3}' | sed 's/\.raw//' | sed 's/\.SLC//')
  name_s=$(grep input_file $slave".PRM" | awk '{print $3}' | sed 's/\.raw//' | sed 's/\.SLC//')
  gmt grdmath $name_m".grd" $weight_m DIV = amp_m_calib.grd
  gmt grdmath $name_s".grd" $weight_s DIV = amp_s_calib.grd
  if [ $num == 1 ]; then
    gmt grdmath amp_m_calib.grd amp_s_calib.grd SUB SQR = sum_diff.grd
  else
    gmt grdmath amp_m_calib.grd amp_s_calib.grd SUB SQR sum_diff.grd ADD = sum_difftmp.grd
    mv sum_difftmp.grd sum_diff.grd
  fi
  (( num++ ))
  rm -f amp_m_calib.grd amp_s_calib.grd
done < sigA_variable.txt
(( num-- ))
echo "Step 2, compute sigma delta A ..."
gmt grdmath sum_diff.grd $num DIV = var_MS.grd
gmt grdmath var_MS.grd SQRT = sig_delta_A.grd

#
# compute the amplitude difference dispersion
#
echo ""
echo "compute the scattering difference amplitude ... "
gmt grdmath sig_delta_A.grd M_A_sb.grd DIV = $outgrd

#find the max of ADD value
v_max_value=$(gmt grdinfo $outgrd | awk -F'v_max: ' '{print $2}' | awk '{print $1}')
even_v_max=$(printf "%.1f" $v_max_value)
echo $v_max_value
echo $even_v_max

  if [ "$(echo "$even_v_max >= 0.6" | bc -l)" -eq 1 ]; then
    gmt makecpt -Cgray -T0.1/1/0.1 -Z -D > scatter.cpt
  else
    gmt makecpt -Cgray -T-0.1/$even_v_max/0.01 -Z -D > scatter.cpt
  fi

gmt grdimage $outgrd -Cscatter.cpt -JX6i -P -X1i -Y3i -V -Bf500a2000WSen -K > scatter_SB.ps
gmt psscale -D3/-0.8/5/0.5h -Cscatter.cpt -Ba0.2f0.1:"amplitude difference dispersion": -O >> scatter_SB.ps

echo ""
echo "Finish -- compute amplitude difference dispersion"
echo ""


#
# clean up
#
# 
rm -f sum.grd sumtmp.grd sum2.grd sum2tmp.grd ave.grd sum_MS.grd sum_delta_MS.grd ave_sum_ms.grd sum_MS_sqrt.grd sum_MS.grd var_MS.grd namearray.txt weightarray.txt sum_diff.grd scatter.cpt
#rm -f M_A_sb.grd sig_delta_A.grd sigA_variable.txt
