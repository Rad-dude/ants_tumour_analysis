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

No masks - just straight up

Example:

antsT1Reg.sh -a mprage_brain.nii.gz -t MNI152_T1_2mm_brain.nii.gz

Options:

-h  show this help
-a  skull stripped anatomical (moving image)
-t  skull stripped template (fixed image)

============================================================================

EOF
}

#initialise options

while getopts "ha:t:" OPTION
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

output=`echo $anat | sed s/.nii.gz/_/g`

antsApplyTransforms \
-d 3 \
-i $anat \
-o ${output}MNI.nii.gz \
-r $template \
-t AR_1Warp.nii.gz \
-t AR_0GenericAffine.mat \
-n NearestNeighbor \
--float 1

#Quality control output
slices ${output}MNI.nii.gz $template -s 2 -o ANTS_T1Reg_check.gif