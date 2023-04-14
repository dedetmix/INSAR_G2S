#!/bin/bash

inputfile=$1
raw=$2
topo=$3
region=$4

shopt -s extglob
IFS=":"
while read master slave
do

mkdir view

master_id=$(grep SC_clock_start $raw/$master.PRM | awk '{printf("%d",int($3))}')
slave_id=$(grep SC_clock_start $raw/$slave.PRM | awk '{printf("%d",int($3))}')
ln -s $raw/"$master".SLC .
ln -s $raw/"$master".LED .
ln -s $raw/"$slave".SLC .
ln -s $raw/"$slave".LED .
rm -f imag.grd real.grd
ln -s real_$master_id"_"$slave_id.grd real.grd
ln -s imag_$master_id"_"$slave_id.grd imag.grd

# do filter and create phase & amplitude
# recommended range decimation to be 8, azimuth decimation to be 2 for S1A
filter.csh $raw/"$master".PRM $raw/"$slave".PRM 200 1 8 2
# project to global coordinate
proj_ra2ll.csh trans.dat phase.grd phase_ll.grd
proj_ra2ll.csh trans.dat display_amp.grd amp_ll.grd
proj_ra2ll.csh trans.dat corr.grd corr_ll.grd

# convert to kml data (Google Earth)
grd2kml.csh amp_ll display_amp.cpt
grd2kml.csh corr_ll corr.cpt

gmt grdimage phase_ll.grd -JX6 -Cphase.cpt -B0.5WesN -P -Y3 -R$region --MAP_FRAME_TYPE=inside > phase_ll.ps
gmt psconvert phase_ll.ps -TG -W+k+t"phase_$master"_"$slave"+l256/-1 -V -E526
gmt grdimage amp_ll.grd -JX6 -Cdisplay_amp.cpt -B0.5WesN -P -Y3 -R$region --MAP_FRAME_TYPE=inside > amp_ll.ps
gmt psconvert amp_ll.ps -TG -W+k+t"amp_$master"_"$slave"+l256/-1 -V -E526

mkdir view/view_"$master"_"$slave"
mv display_amp.grd view/view_"$master"_"$slave"/.
mv phase_ll.grd view/view_"$master"_"$slave"/.
mv amp_ll.grd view/view_"$master"_"$slave"/.
mv amp_ll.png view/view_"$master"_"$slave"/.
mv amp_ll.kml view/view_"$master"_"$slave"/.
mv phase_ll.png view/view_"$master"_"$slave"/.
mv phase_ll.kml view/view_"$master"_"$slave"/.
mv corr.grd view/view_"$master"_"$slave"/.
mv corr.pdf view/view_"$master"_"$slave"/.
mv corr_ll.kml view/view_"$master"_"$slave"/.
mv phase_ll.ps view/view_"$master"_"$slave"/.
mv amp_ll.ps view/view_"$master"_"$slave"/.

#rm -f phase_ll.grd amp_ll.grd
rm -f amp1.grd amp2.grd filtcorr.grd mask.grd phasefilt.grd phasefilt.pdf phase.grd phase_ll.ps phase.pdf raln.grd ralt.grd realfilt.grd amp.grd imagfilt.grd ijdec
rm -f "$master".SLC "$master".LED "$slaver".SLC "$slave".LED
done < $inputfile  
