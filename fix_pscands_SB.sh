#!/bin/bash 

# bugs; fix matrix on pscands1.ll and pscands.hgt
# go to PS dir

echo -n "How many patches do you have?  "
read n

for (( c=1; c<=$n; c++ ))
do
cd ../cands_$c

# Get the difference dispersion index for PS candidates
gmt grd2xyz cands.grd -s > cands.dat 
gmt gmtconvert cands.dat -o2 > pscands.1.da
awk '{printf("%d %d %d\n", NR,$2,$1)}' cands.dat > pscands.1.ij

# Retrieve lon/lat for PS candidates
ln -s ../trans.dat .
ln -s ../dem.grd .
gmt grd2xyz cands_old.grd -s > cands_old.dat 
proj_ra2ll_ascii.csh trans.dat cands_old.dat cands.ll.dat
rm -f ralt.grd raln.grd 
gmt gmtconvert cands.ll.dat -o0,1 -bos > pscands.1.ll
gmt grdtrack cands.ll.dat -Gdem.grd -Z -nb -bos > pscands.1.hgt 
cp -f pscands.1.ij ../SMALL_BASELINES/PATCH_$c/.
cp -f pscands.1.ll ../SMALL_BASELINES/PATCH_$c/.
cp -f pscands.1.hgt ../SMALL_BASELINES/PATCH_$c/.
rm -f cands.ll.dat cands.dat cands_old.dat pscands* ralt raln
cd ..
cd SMALL_BASELINES

done

echo " "
echo "$n PATCHES have been fixed"
