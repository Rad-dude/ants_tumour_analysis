#!/bin/bash

#Michael Hart, University of Cambridge, 19 April 2016 (c)

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsTumourReg.sh

(c) Michael Hart, University of Cambridge, 2016

Registers an image with a tumour to standard space (e.g. MNI)

Uses tumour mask and inverse transforms (from MNI to anatomical)

Example:

antsTumourReg.sh -a mprage_brain.nii.gz -t MNI152_T1_2mm.nii.gz -m mask.nii.gz

Options:

-h  show this help
-a  skull stripped anatomical (fixed image)
-t  skull stripped template (moving image)
-m  mask (in anatomical space)

============================================================================

EOF
}

#initialise options

while getopts "ha:t:m:" OPTION
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
    m)
        mask=$OPTARG
        ;;
    ?)
        usage
        exit
        ;;
    esac
done

#check usage

if [[ -z $anat ]] || [[ -z $template ]] || [[-z $mask ]]
then
    usage
    exit 1
fi

echo "files and options ok"

#Create registration
#note structural is fixed (with mask) and moving is MNI

antsRegistrationSyN.sh \
-d 3 \
-f $anat \
-m $template \
-x $mask \
-o ATR_

#Apply transforms to mprage (to put in MNI)

output=`echo $anat | sed s/.nii.gz/_/g`

antsApplyTransforms \
-d 3 \
-i $anat \
-o ${output}MNI.nii.gz \
-r $template \
-t [ATR_0GenericAffine.mat,1] \
-t ATR_1InverseWarp.nii.gz \
-n NearestNeighbor \
--float 1

#Quality control output
slices ${output}MNI.nii.gz ${template} -o ANTS_TumourReg_check.gif

#Apply transforms to lesion mask (to put in MNI)

output=`echo $mask | sed s/.nii.gz/_/g`

antsApplyTransforms \
-d 3 \
-i $anat \
-o ${mask}MNI.nii.gz \
-r $template \
-t [ATR_0GenericAffine.mat,1] \
-t ATR_1InverseWarp.nii.gz \
-n NearestNeighbor \
--float 1

#do some stuff to tumour mask
fslmaths $mask -s 1 smooth_image
fslmaths smooth_image -binv neg_mask
fslmaths $template -mul neg_mask ${template}_lesioned

#make images
slices ${template}_lesioned -o ANTS_TumouReg_lesion_check.gif
