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

NB: standard space template requires images of full head, brain, brain mask, and priors
(see github for MNI example)

============================================================================

EOF
}

#initialise options

while getopts "ha:m:s:" OPTION
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
    ?)
        usage
        exit
        ;;
    esac
done

#check usage

if [[ -z $anat ]] || [[-z $mask ]]
then
    usage
    exit 1
fi

echo "files and options ok"

#subtract out priors
fslmaths $mask -s 1 $mask #smooth

cp -R $template/Priors .

for nPrior in `ls Priors/`; do
    fslmaths $nPrior -sub $mask $nPrior
done

#make new prior5 from tumour mask (in place of brainstem)
mv $mask Priors/prior5.nii.gz

#run antsCorticalThickness.sh

antsCorticalThickness.sh \
-dim 3 \
-a $anat \
-e ${template}/MNI152_T1_2mm.nii.gz \
-m ${template}/MNI152_T1_2mm_brain_mask.nii.gz \
-p ${template}/Priors/prior%d.nii.gz \
-t ${template}/MNI152_T1_2mm_brain.nii.gz \
-o ATCT_
