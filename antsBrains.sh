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

anat=
template=
mask=

#initialise options

while getopts "h:a:t:m" OPTION
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

if [ -f $anat ];
then
    echo "structural ok"
else
    echo "Cannot locate file $anat. Please ensure the $anat dataset is in this directory"
    exit 1
fi

if [ -f $template ];
then
    echo "template ok"
    echo ""
else
    echo "Cannot locate file $template. Please ensure the file $template is in the working directory"
    exit 1
fi

if [ -f $mask ];
then
    echo "mask ok"
    echo ""
else
    echo "Cannot locate file $mask. Please ensure the file $mask is in the working directory"
    exit 1
fi

echo "files and options ok"

bash antsBrainExtraction.sh \
-d 3 \
-a $anat \
-e $template \
-m $mask \
-o ABE_
