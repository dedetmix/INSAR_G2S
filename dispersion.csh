#!/bin/csh -f 

# Amplitude dispersion from a stack of aligned SLCs 

# Creator: Xiaopeng Tong, David Sandwell
# Date:    July 4th 2013  

# input: PRM.list
# output: amplitude dispersion 

# The principle: first calibrate each images by a weighting
#                factor then compute the mean amplitude M_A
#                and the standard deviation of the amplitude sig_A
#                then take the ratio of the M_A and sig_A 

# Reference: Lyons and Sandwell, Fault creep along the southern San Andreas from InSAR, permanent scatterers, and stacking, J. Geophys. Res., 108 (B1), 2047, doi:10.1029/ 2002JB001831 2003 

alias rm 'rm -f'

if ($#argv != 3) then
  echo ""
  echo "Usage: dispersion.csh  PRM.list  scatter.grd  <rng0>/<rngf>/<azi0>/<azif>"
  echo ""
  echo "    Amplitude dispersion from a stack of aligned SLCs"
  echo ""
  echo "    PRM.list     --  a list of PRM files of the aligned SLC"
  echo "    scatter.grd  --  output scattering coeffient grid"
  echo "    <rng0>/<rngf>/<azi0>/<azif>   —  region of interests in radar coordinates"
  echo ""
  exit 1
endif 

if (! -e $1) then
  echo ""
  echo "no input file found: $1"
  echo ""
  exit 1
endif

set list = $1 
set outgrd = $2
set region = $3
set filter = $GMTSAR/gmtsar/filters/gauss_alos_100m #gauss5x5 has better result for Sentinel-1
#set filter = gauss5x3
set namearray =
set weightarray = 


echo ""
echo "Start -- compute amplitude dispersion"
echo ""

#
# conv to get amplitude of the SLCs and compute their sum and average  
#

echo "compute amplitude from SLCs ..."
@ num = 1
foreach prm (`cat $list`) 
  set name = `grep input_file $prm | awk '{print $3}' | sed 's/\.raw//' | sed 's/\.SLC//'` #add to remove .SLC -- 27.12.2025
  set namearray = ($namearray $name)
  if (-e $prm) then 
    if (! -e $name".grd") then
      echo "running conv on file $name"
      conv 1 1 $filter $prm $name".grd"
      gmt grdmath $name".grd" FLIPUD = $name".grd"
    endif
#    gmt grd2cpt $name".grd" -Cgray -Z -D > cpt
    gmt makecpt -Cgray -T1e-8/1e-7/1e-8 -Z > a.cpt
    gmt grdimage $name".grd" -Ca.cpt -JX6i -P -Xc -Yc -V -R0/6144/0/25200 -Bf2500a5000WSen > $name".ps"
  else 
      echo ""
      echo "no PRM file found: $prm"
      echo ""
      exit 1
  endif
  gmt grdcut $name".grd" -R$region -Gtmp.grd
  mv tmp.grd $name".grd"
  if ($num == 1) then
    gmt grdmath $name".grd" = sum.grd  
  else
    gmt grdmath sum.grd $name".grd" ADD = sumtmp.grd 
    mv sumtmp.grd sum.grd 
  endif
  @ num ++
end
@ num -- 
gmt grdmath sum.grd $num DIV = ave.grd 
set avemean = `gmt grdinfo ave.grd -L2 -C | cut -f 12`
echo $avemean
#


#
# compute the M_A term 
#

rm -f weightarray.txt
echo ""
echo "compute the M_A term ..."
@ num = 1
foreach name ($namearray)
  echo $name
  set ampmean = `gmt grdinfo $name".grd" -L2 -C | cut -f 12` 
  set weight = `echo $ampmean $avemean | awk '{print $1/$2}'`
  echo $weight
  set weightarray = ($weightarray $weight)
  echo $weightarray >> weightarray.txt
  gmt grdmath $name".grd" $weight DIV = tmp.grd 
  if ($num == 1) then
    gmt grdmath $name".grd" $weight DIV = sum.grd
  else
    gmt grdmath $name".grd" $weight DIV sum.grd ADD = sumtmp.grd
    mv sumtmp.grd sum.grd 
  endif
  @ num ++ 
end
@ num --
gmt grdmath sum.grd $num DIV = M_A.grd  
#rm tmp.grd
#


#
# compute the sig_A term 
#  

echo "compute the sig_A term ..."
@ num = 1
foreach name ($namearray)
  if ($num == 1) then
    gmt grdmath $name".grd" $weightarray[$num] DIV M_A.grd SUB SQR = sum2.grd
  else
    gmt grdmath $name".grd" $weightarray[$num] DIV M_A.grd SUB SQR sum2.grd ADD = sum2tmp.grd
    mv sum2tmp.grd sum2.grd
  endif
  @ num ++
end
@ num --
gmt grdmath sum2.grd $num DIV SQRT = sig_A.grd  
#


#
# compute the amplitude dispersion
#

echo ""
echo "compute the scattering amplitude ... "
gmt grdmath sig_A.grd M_A.grd DIV = $outgrd

#find the max of AD value
set v_max_value=`gmt grdinfo $outgrd | awk -F'v_max: ' '{print $2}' | awk '{print $1}'`
set even_v_max=`echo $v_max_value | awk '{printf "%.1f", $1}'`
echo $v_max_value
echo $even_v_max

  if ( `echo "$even_v_max >= 0.5" | bc -l` ) then
    gmt makecpt -Cgray -T0.1/1/0.1 -Z -D > scatter.cpt
  else
    gmt makecpt -Cgray -T-0.1/$even_v_max/0.01 -Z -D > scatter.cpt
  endif

gmt grdimage $outgrd -Cscatter.cpt -JX6i -P -X1i -Y3i -V -R$region -Bf500a2000WSen -K > scatter_AD.ps
gmt psscale -D3/-0.8/5/0.5h -Cscatter.cpt -Ba0.2f0.1:"amplitude dispersion": -O >> scatter_AD.ps

echo ""
echo "Finish -- compute amplitude dispersion"
echo ""


#
# clean up
#
foreach name ($namearray)
#  rm $name".grd"
end
rm sum.grd sumtmp.grd sum2.grd sum2tmp.grd ave.grd
#rm scatter.cpt M_A.grd sig_A.grd
