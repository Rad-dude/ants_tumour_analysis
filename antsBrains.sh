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

antsBrains.sh -a mprage.nii.gz -t MNI152_T1_2mm.nii.gz -m MNI152_T1_2mm_brain_mask.nii.gz

Options:

-h  show this help
-a  anatomical
-t  template (with skull)
-m  template brain mask
-o  overwrite output directory
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

if [ ! -d ${basedir}/ABE ];
then
    echo "making output director"
    makedir ${basedir}/ABE
else
    echo "output directory already exists"
    if [ "$overwrite" == 1 ]
    then
        makedir -p ${basedir}/ABE
    else
        echo "no overwrite permission to make new output directory"
    exit 1
    fi
fi

outdir=${basedir}/antsBrains

#start logfile

touch ${outdir}/antsBrainExtraction_logfile.txt
log=${outdir}/antsBrainExtraction_logfile.txt

echo date >> ${log}
echo "${@}" >> ${log}

# final check of files
# do they exist, can they be read, by me, and are the correct format

echo "Checking functional and template data"

if [ -f $anat ];
then
    echo "Structural dataset ok"
else
    echo "Cannot locate file $anat. Please ensure the $anat dataset is in this directory"
    exit 1
fi

echo "structural image ok"

##################
# Main programme #
##################

bash antsBrainExtraction.sh \
-d 3 \
-a $anat \
-e $template \
-m $mask \
-o $outdir

echo "antsBrains done: brain extracted"

echo "now viewing results"

slices $anat ABEBrainExtractionBrain.nii.gz ${outdir}/ABE_check.gif

#perform cleanup

#complete log

echo "all done with antsBrains.sh" >> ${log}
echo date >> ${log}
