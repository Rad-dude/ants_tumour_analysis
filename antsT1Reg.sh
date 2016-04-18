#!/bin/bash

#Michael Hart, University of Cambridge, 13 April 2016 (c)

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsT1Reg.sh

(c) Michael Hart, University of Cambridge, 2016

Registers a T1 image to standard space (e.g. MNI)

Example:

bash antsT1Reg.sh -a mprage_brain.nii.gz -t MNI152_T1_2mm.nii.gz

Options:

-h  show this help
-a  skull stripped anatomical (moving image)
-t  skull stripped template (fixed image)

============================================================================

EOF
}

#initialise options

while getopts "ha:t" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    a)
        usage
        anat=$OPTARG
        ;;
    t)
        template=$OPTARG
        ;;
    ?)
        usage
        exit
        ;;
    esac
done

#check usage

if [[ -z $anat ]] || [[ -z $template ]]
then
    usage
    exit 1
fi

echo "files and options ok"

#Create registration
antsRegistrationSyN.sh \
-d 3 \
-m $anat \
-f $template \
-o AR_

#Apply transforms
antsApplyTransforms \
-d 3 \
-i $anat \
-o AT_ \
-r $template \
-t AR_affine0 \
-t AR_diff1warp.nii.gz

#Quality control output
slices $template $anat ANTS_T1Reg_check.gif