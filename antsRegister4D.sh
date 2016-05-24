#!/bin/sh

#Michael Hart, University of Cambridge, 13 April 2016 (c)

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsRegister4D.sh

(c) Michael Hart, University of Cambridge, 2016

Warps a 4D epi to standard space

Example:

antsRegister4D.sh -f epi.nii.gz -w warp.nii.gz -r affine.mat -t MNI.nii.gz

Options:

    -h  show this help
    -f  functional / epi
    -w  warp (contactenated transform) from structural-to-standard
    -r  rigid transform from epi-to-structural
    -t  standard space template e.g. MNI

============================================================================

EOF
}

#initialise options

while getopts "hf:w:r:t:" OPTION
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
        affine=$OPTARG
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

if [[ -z $epi ]] || [[ -z $warp ]] || [[ -z $affine ]] || [[ -z $template ]]
then
    usage
    exit 1
fi

echo "files and options ok"

#1. generate number of volumes and time between them (aka TR)
hislice=`PrintHeader $epi | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1`
tr=`PrintHeader $epi | grep "Voxel Spac" | cut -d ',' -f 4 | cut -d ']' -f 1` 

#2. concatentate transforms
#start farthest away from image
#use inverse transforms for mprage-to-MNI (opposite of ATR) and in opposite order
#finally add epi-to-mprage affine.mat

antsApplyTransforms \
-d 3 \
-t $warp \
-t $affine \
-o [diffCollapsedWarp.nii.gz, 1] \
-r $template

#3. multiply transforms

echo "replicating concatenated transforms"

ImageMath 3 \
diff4DCollapsedWarp.nii.gz \
ReplicateDisplacement \
diffCollapsedWarp.nii.gz \
$hislice $tr 0 #

#4. multiply template

echo "replicating template"

ImageMath 3 \
MNI_replicated.nii.gz \
ReplicateImage \
$template \
$hislice $tr 0

#5. apply tranforms

echo "applying transforms: epi-to-MNI"

antsApplyTransforms -d 4 \
-o epi2template.nii.gz \
-t diff4DCollapsedWarp.nii.gz \
-r MNI_replicated.nii.gz \
-i $epi

#6. check result in fslview
