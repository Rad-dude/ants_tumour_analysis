#!/bin/bash

#Michael Hart, University of Cambridge, 19 April 2016 (c)

#define directories

codedir=${HOME}/bin
basedir="$(pwd -P)"

#make usage function

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

antsTumourReg.sh -s mprage_brain.nii.gz -m mask.nii.gz

Options:

-h  show this help
-s  skull stripped anatomical (fixed image)
-m  tumour mask (anatomical space - tumour is 1)
-t  skull stripped template (moving image - optional: default=MNI)
-o  overwrite
-v  verbose

Version:    1.1

History:    no amendments

============================================================================

EOF
}


###################
# Standard checks #
###################


#initialise options

structural=
tumour_mask=
template=

while getopts "hs:m:tov" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    s)
        structural=$OPTARG
        ;;
    m)
        tumour_mask=$OPTARG
        ;;
    t)
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

if [[ -z $structural ]] || [[ -z $tumour_mask ]]
then
    echo "usage incorrect"
    usage
    exit 1
fi

echo "options ok"

# final check of files

echo "Checking structural data"

structural_path=${basedir}/${structural}
structural_name=`basename ${structural} .nii.gz`

if [ $(imtest $structural_path) == 1 ];
then
    echo "$structural dataset ok"
else
    echo "Cannot locate file $structural. Please ensure the $structural dataset is in this directory"
    exit 1
fi

tumour_mask_path=${basedir}/${tumour_mask}
tumour_mask_name=`basename ${tumour_mask} .nii.gz`

if [ $(imtest $tumour_mask_path) == 1 ];
then
    echo "$tumour_mask ok"
else
    echo "Cannot locate file $tumour_mask. Please ensure the $tumour_mask dataset is in this directory"
    exit 1
fi 

if [ $(imtest $template) == 1 ];
then
    echo "$template dataset ok"
    template=${basedir}/${template}
else
    template="${HOME}/ANTS/ANTS_templates/MNI/MNI152_T1_2mm_brain.nii.gz"
    echo "No template supplied - using MNI brain"
fi

template_name=`basename ${template} .nii.gz`

echo "files ok"

#make output director

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

outdir="${basedir}/ATR"

#make temporary directory

tempdir="$(mktemp -t -d temp.XXXXXXXX)"
cd "${tempdir}"

#start logfile

touch antsTumourRegistration_logfile.txt
log=antsTumourRegistration_logfile.txt

echo $(date) >> ${log}
echo "${@}" >> ${log}


##################
# Main programme #
##################


function antsTR() {


    #1. Make mask negative first (exclusion mask)
    inv_mask=inv_mask.nii.gz
    fslmaths $tumour_mask_path -binv $inv_mask #tumour is 0 / rest is 1

    #2. Create registration
    #note structural is fixed (with mask) and moving is MNI

    antsRegistrationSyN.sh \
    -d 3 \
    -f $structural_path \
    -m $template \
    -x $inv_mask \
    -o ATR

    #3. Apply transforms to mprage (to put in MNI)

    antsApplyTransforms \
    -d 3 \
    -i $structural_path \
    -o ${structural_name}_MNI.nii.gz \
    -r $template \
    -t [ATR0GenericAffine.mat,1] \
    -t ATR1InverseWarp.nii.gz \
    -n NearestNeighbor \
    --float 1

    #4. Quality control registration output
    slices ${structural_name}_MNI.nii.gz ${template} -o ATR_structural_check.gif

    #5. Apply transforms to lesion mask (to put in MNI)

    antsApplyTransforms \
    -d 3 \
    -i $tumour_mask_path \
    -o ${tumour_mask_name}_MNI.nii.gz \
    -r $template \
    -t [ATR0GenericAffine.mat,1] \
    -t ATR1InverseWarp.nii.gz \
    -n NearestNeighbor \
    --float 1

    #6. Do some stuff to tumour mask
    fslmaths ${tumour_mask_name}_MNI.nii.gz -binv neg_mask_MNI
    fslmaths neg_mask_MNI -s 2 neg_mask_MNI_s2
    fslmaths ${template} -mul neg_mask_MNI_s2 ${template_name}_lesioned

    #7. Quality control lesion output
    slices ${template_name}_lesioned -o ATR_lesion_check.gif

    #8. Concatenate transforms

    antsApplyTransforms \
    -d 3 \
    -o [structural2standard.nii.gz,1] \
    -t [ATR0GenericAffine.mat, 1] \
    -t ATR1InverseWarp.nii.gz \
    -r $template

    antsApplyTransforms \
    -d 3 \
    -o [standard2structural.nii.gz,1] \
    -t ATR1Warp.nii.gz \
    -t ATR0GenericAffine.mat \
    -r $structural_path

}

# call function

antsTR

# perform cleanup
cp -fpR . "${outdir}"
cd "${outdir}"
rm -Rf "${tempdir}" neg_mask_MNI.nii.gz neg_mask_MNI_s2.nii.gz

# complete log

echo "all done with antsTumourReg.sh" >> ${log}
echo $(date) >> ${log}
