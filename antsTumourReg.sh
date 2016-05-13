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

antsTumourReg.sh -a mprage_brain.nii.gz -t MNI152_T1_2mm_brain.nii.gz -m mask.nii.gz

Options:

-h  show this help
-a  skull stripped anatomical (fixed image)
-t  skull stripped template (moving image)
-m  tumour mask (anatomical space - tumour is 1)
-o  overwrite
-v  verbose

============================================================================

EOF
}


###################
# Standard checks #
###################


#initialise options

while getopts "ha:t:m:ov" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    a)
        anat=$OPTARG
        ;;
    t)
        template=$OPTARG
        ;;
    m)
        mask=$OPTARG
        ;;
    o)
        overwrite=1
        ;;
    v)
        verbose=1
        ;;
    ?)
        usage
        exit
        ;;
    esac
done

#set verbose option

if [ "$verbose" == 1 ]
then
    set -x verbose
fi

#check usage

if [[ -z $anat ]] || [[ -z $template ]] || [[ -z $mask ]]
then
    echo "usage incorrect"
    usage
    exit 1
fi

echo "options ok"


#define directories
#need check if exists and if can overwrite

basedir=`pwd`

if [ ! -d ${basedir}/ATR ];
then
    echo "making output directory"
    mkdir ${basedir}/ATR
else
    echo "output directory already exists"
    if [ "$overwrite" == 1 ]
    then
        mkdir -p ${basedir}/ATR
    else
        echo "no overwrite permission to make new output directory"
    exit 1
    fi
fi

outdir=${basedir}/ATR/

#start logfile

touch ${outdir}antsTumourRegistration_logfile.txt
log=${outdir}antsTumourRegistration_logfile.txt

echo $(date) >> ${log}
echo "${@}" >> ${log}

# final check of files
# do they exist, can they be read, by me, and are the correct format

echo "Checking functional and template data"

if [ -f $anat ];
then
    echo "$anat ok"
else
    echo "Cannot locate file $anat. Please ensure the $anat dataset is in this directory"
    exit 1
fi

if [ -f $template ];
then
    echo "$template ok"
else
    echo "Cannot locate file $template. Please ensure the $anat dataset is in   this directory"
    exit 1
fi

if [ -f $mask ];
then
    echo "$mask ok"
else
    echo "Cannot locate file $mask. Please ensure the $anat dataset is in this directory"
    exit 1
fi

echo "files ok"


##################
# Main programme #
##################


#1. Make mask negative first (exclusion mask)
inv_mask=inv_mask.nii.gz
fslmaths $mask -binv $inv_mask #tumour is 0 / rest is 1

#2. Create registration
#note structural is fixed (with mask) and moving is MNI

antsRegistrationSyN.sh \
-d 3 \
-f $anat \
-m $template \
-x $inv_mask \
-o ATR_

#3. Apply transforms to mprage (to put in MNI)

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

#4. Quality control registration output
slices ${output}MNI.nii.gz ${template} -o ANTS_TumourReg_check.gif

#5. Apply transforms to lesion mask (to put in MNI)

output=`echo $mask | sed s/.nii.gz/_/g`

antsApplyTransforms \
-d 3 \
-i $mask \
-o ${output}MNI.nii.gz \
-r $template \
-t [ATR_0GenericAffine.mat,1] \
-t ATR_1InverseWarp.nii.gz \
-n NearestNeighbor \
--float 1

#6. Do some stuff to tumour mask 
fslmaths ${output}MNI.nii.gz -binv neg_mask_MNI
fslmaths neg_mask_MNI -s 2 neg_mask_MNI_s2
fslmaths $template -mul neg_mask_MNI_s2 template_lesioned

#7. Quality control lesion output
slices template_lesioned -o ANTS_TumourReg_lesion_check.gif

#8. Concatenate transforms

antsApplyTransforms \
-d 3 \
-o [structural2standard.nii.gz,1] \
-t [ATR_0GenericAffine.mat, 1] \
-t ATR_1InverseWarp.nii.gz \
-r $template

antsApplyTransforms \
-d 3 \
-o [standard2structural.nii.gz,1] \
-t ATR_1Warp.nii.gz \
-t ATR_0GenericAffine.mat \
-r $anat

#perform cleanup

rm neg_mask_MNI net_mask_MNI_s2

#complete log

echo "all done with antsTumourReg.sh" >> ${log}
echo $(date) >> ${log}
