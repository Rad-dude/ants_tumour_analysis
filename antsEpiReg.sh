#!/bin/bash

#Michael Hart, University of Cambridge, 13 April 2016 (c)

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsEpiReg.sh

(c) Michael Hart, University of Cambridge, 2016

Creates an affine transform from epi to structural

Example:

antsEpiReg.sh -f epi.nii.gz -s mprage.nii.gz

Options:

-h  show this help
-f  functional (epi)
-s  structural

============================================================================

EOF
}

#initialise options

while getopts "hf:t:w:" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    f)
        usage
        epi=$OPTARG
        ;;
    s)
        structural=$OPTARG
        ;;
    ?)
        usage
        exit
        ;;
    esac
done

#check usage

if [[ -z $epi ]] || [[ -z $structural ]]

then
    usage
    exit 1
fi

echo "files and options ok"

#1. create a single EPI 3D volume
ref=epi_avg.nii.gz
antsMotionCorr -d 3 -a $epi -o $ref #now we have a single reference EPI image

#2. generate a 3D affine transformation to a template

antsRegistrationSyN.sh
-d 3 \
-o affine \
-f $structural \
-m $ref \
-t a

#3. warp the single epi image

antsApplyTransforms \
-d 3 \
-o epi2struct.nii.gz \
-i $ref \
-t affine0GenericAffine.mat \
-r $structural

#4. quality check the result

slices $structural epi2struct -o antsEpiCheck.gif
