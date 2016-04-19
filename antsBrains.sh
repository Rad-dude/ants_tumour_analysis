#!/bin/bash

#Michael Hart, University of Cambridge, 13 April 2016 (c)

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsBrains.sh

(c) Michael Hart, University of Cambridge, 2016

Does brain extraction with ANTs

Example:

bash antsBrains.sh -a mprage.nii.gz -t MNI152_T1_2mm.nii.gz -m MNI152_T1_2mm_brain_mask.nii.gz

Options:

-h  show this help
-a  anatomical
-t  template (with skull)
-m  template brain mask

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

if [[ -z $anat ]] || [[ -z $template ]] || [[ -z $mask ]]
then
    usage
    exit 1
fi

echo "files and options ok"

bash antsBrainExtraction.sh \
-d 3 \
-a $anat \
-e $template \
-m $mask \
-o ABE

echo "antsBrains done: brain extracted"

echo "now viewing results"

slices $anat BrainExtractionBrain.nii.gz ABE_check.gif
eog ABE_check.gif

