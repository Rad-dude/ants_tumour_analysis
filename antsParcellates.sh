#!/bin/sh

#Michael Hart, University of Cambridge, 13 April 2016 (c)

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsParcellates.sh

(c) Michael Hart, University of Cambridge, April 2016

Registers a parcellation template to functional space & extracts data for connectomics

Example:

antsParcellates.sh -f epi.nii.gz -w warp.nii.gz -r affine.mat -p parcellation.nii.gz

Options:

-f  functional (epi)
-w  warp (concatenated transform) from standard-to-structural e.g. antsTumourReg.sh output
-r  rigid transform (affine) from epi-to-structural e.g. antsEpiReg.sh output
-p  parcellation template (MNI space, 3D)

============================================================================

EOF
}

#initialise options

while getopts "hf:w:r:p:" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    f)
        epi=$OPTARG
        ;;
    w)
        warp=$OPTARG
        ;;
    r)
        affine=$optarg
        ;;
    p)
        parcels=$OPTARG
        ;;
    ?)
        usage
        exit
        ;;
    esac
done

#check usage

if [[ -z $epi ]] || [[ -z $warp ]] || [[ -z $affine ]] || [[ -z $parcels ]]; then
    usage
    exit 1
fi

echo "files and options ok"

#1. create a single EPI 3D volume for registration
ref=epi_avg.nii.gz
antsMotionCorr -d 3 -a $epi -o $ref #now we have a single reference EPI image

#2. reverse & apply tranforms

echo "moving template from MNI to EPI space"

antsApplyTransforms -d 3 \
-o native_template.nii.gz \
-t $warp \
-t [$affine, 1] \
-r $ref

#extract time series

echo "now extracting timeseries for each parcels"

touch ants_ts.txt

fslmeants -i $fmri --label=native_template.nii.gz --transpose -o ants_ts.txt

#calculate co-ordinates and numbers of voxels

echo "now calculating co-ordinates and numbers of voxels"

touch ants_xyz.txt
touch ants_nv.txt

sys=`uname`
if [[ "$sys" == 'Darwin' ]]; then
    for i in $(jot ${np} 1); do
        fslstats -c -k $i >> ants_xyz.txt
        fslstats -V -k $i >> ants_nv.txt
    done

elif [[ "$sys" == 'Linux' || "$sys" == 'FreeBSD' ]]; then
    for i in $(seq 1 ${np}); do
        fslstats -c -k $i >> ants_xyz.txt
        fslstats -V -k $i >> ants_nv.txt
    done
fi
