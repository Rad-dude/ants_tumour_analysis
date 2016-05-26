#!/bin/bash

#Michael Hart, University of Cambridge, 19 April 2016 (c)

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsTumourCT.sh

(c) Michael Hart, University of Cambridge, 2016

Performs cortical thickness algorithm but with a new tumour mask prior

Algorithm:
- turns the tumour_mask into a tumour_prior
- uses this tumour prior as an exclusion on other priors
- replaces the brainstem prior with this tumour_prior (number5)
- also includes brain extraction & registration to standard space (usually MNI)

NB: tumour mask must be standard space (e.g. MNI) - see antsTumourReg.sh

Example:

antsTumourCT.sh -a mprage.nii.gz -m tumour_mask_MNI.nii.gz -s ~/template

Options:

-h  show this help
-a  anatomical image
-m  standard space tumour mask (tumour is 1)
-s  path to standard space template
-o  overwrite output
-v  verbose

NB: standard space template requires images of full head, brain, brain mask, and priors
(see github for MNI example)

============================================================================

EOF
}

###################
# Standard checks #
###################


#initialise options

while getopts "ha:m:s:ov" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    a)
        anat=$OPTARG
        ;;
    m)
        mask=$OPTARG
        ;;
    s)
        template=$OPTARG
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

if [[ -z $anat ]] || [[-z $mask ]] 
    then
        echo "usage incorrect"
        usage
    exit 1
fi

echo "options ok"

#define directories

basedir=`pwd`

if [ ! -d ${basedir}/ACT ];
then
    echo "making output director"
    mkdir ${basedir}/ACT
else
    echo "output directory already exists"
    if [ "$overwrite" == 1 ]
    then
        mk -p ${basedir}/ACT
    else
        echo "no overwrite permission to make new output directory"
        exit 1
    fi
fi

outdir=${basedir}/ACT/

#start logfile

touch ${outdir}/antsTumourCT_logfile.txt
log=${outdir}/antsTumourCT_logfile.txt

echo $(date) >> ${log}
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

if [ -f $mask ];
then
    echo "Tumour mask ok"
else
    echo "Cannot locate file $mask. Please ensure the $mask dataset is in this directory"
    exit 1
fi


##################
# Main programme #
##################


#subtract out priors
fslmaths $mask -kernel sphere 2 -fmean $mask #smooth

cp -R ${template}/Priors .

for i in {1..6}; do
    fslmaths Priors/prior{i}.nii.gz -sub $mask Priors/prior{i}.nii.gz
done

#make new prior5 from tumour mask (in place of brainstem)
cp $mask Priors/prior5.nii.gz

#run antsCorticalThickness.sh

echo "now running antsCorticalThickness.sh"

antsCorticalThickness.sh \
-d 3 \
-a $anat \
-e ${template}/MNI152_T1_2mm.nii.gz \
-m ${template}/MNI152_T1_2mm_brain_mask.nii.gz \
-p Priors/prior%d.nii.gz \
-t ${template}/MNI152_T1_2mm_brain.nii.gz \
-o $outdir

#perform cleanup

rm -r Priors/

#complete log

echo "all done with antsTumourCT.sh" >> ${log}
echo $(date) >> ${log}


