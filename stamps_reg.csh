#!/bin/csh -f

# get from mt_prep (STAMPS) script

rm -f patch_all.in

set width = $1
set length = $2
set prg = $3
set paz = $4
set overlap_rg = $5
set overlap_az = $6


@ width_p = $width / $prg
echo $width_p
@ length_p = $length / $paz
echo $length_p
set irg = 0
set iaz = 0
set ip = 0
while ($irg < $prg)
    @ irg = $irg + 1
    while ($iaz < $paz)
        @ iaz = $iaz + 1
        @ ip = $ip + 1
        @ start_rg1 = $width_p * ($irg - 1) + 1
        @ start_rg = $start_rg1 - $overlap_rg
        if ($start_rg < 1) then
            set start_rg = 1
        endif
        @ end_rg1 = $width_p * $irg
        @ end_rg = $end_rg1 + $overlap_rg
        if ($end_rg > $width) then
            @ end_rg = $width
        endif
        @ start_az1 = $length_p * ($iaz - 1) + 1
        @ start_az = $start_az1 - $overlap_az
        if ($start_az < 1) then
            set start_az = 1
        endif
        @ end_az1 = $length_p * $iaz
        @ end_az = $end_az1 + $overlap_az

        if ($end_az > $length) then
            @ end_az = $length
        endif

        if (! -e PATCH_$ip) then
            mkdir PATCH_$ip
        endif
        echo $start_rg $end_rg $start_az $end_az
	echo $start_rg $end_rg $start_az $end_az >> patch_all.in
        cd PATCH_$ip
        echo $start_rg > patch.in
        echo $end_rg >> patch.in
        echo $start_az >> patch.in
        echo $end_az >> patch.in
        echo $start_rg1 > patch_noover.in
        echo $end_rg1 >> patch_noover.in
        echo $start_az1 >> patch_noover.in
        echo $end_az1 >> patch_noover.in
        cd ..
    end
    set iaz = 0
end
