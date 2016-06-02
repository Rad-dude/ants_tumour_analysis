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

antsTumourCT.sh -s mprage.nii.gz -m tumour_mask_MNI.nii.gz

Options:

-h  show this help
-s  anatomical image
-m  standard space tumour mask (tumour is 1)
-t  path to standard space template
-o  overwrite output
-v  verbose

NB: standard space template requires images of full head, brain, brain mask, and priors
(see github for MNI example)

Version:    1.1

History:    no amendments

============================================================================

EOF
}


###################
# Standard checks #
###################


structural=
tumour_mask=
template=

#initialise options

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

if [[ -z "${structural}" ]] || [[ -z "${tumour_mask}" ]]
then
    echo "usage incorrect"
    usage
    exit 1
fi

echo "options ok"

# final check of files

echo "Checking structural and tumour_mask data"

if [ $(imtest "${structural") == 1 ];
then
    echo "Structural dataset ok"
    structural=${basedir}/${structural}
else
    echo "Cannot locate file $structural. Please ensure the $structural dataset is in this directory"
    exit 1
fi

if [ $(imtest "${tumour_mask}") == 1 ];
then
    echo "Tumour mask ok"
    tumour_mask=${basedir}/${tumour_mask}
else
    echo "Cannot locate file ${tumour_mask}. Please ensure the "${tumour_mask}" dataset is in this directory"
    exit 1
fi

if [ -d $template ];
then
    echo "$template dataset ok"
    template=${basedir}/${template}
else
    template="${HOME}/ANTS/ANTS_templates/MNI"
    echo "No template supplied - using MNI"
    exit 1
fi

#make output directory

if [ ! -d ${basedir}/ACT ];
then
    echo "making output directory"
    mkdir ${basedir}/ACT
else
    echo "output directory already exists"
    if [ "$overwrite" == 1 ]
    then
        echo "overwriting output directory"
        mkdir -p ${basedir}/ACT
    else
        echo "no overwrite permission to make new output directory"
        exit 1
    fi
fi

outdir=${basedir}/ACT

#make temporary directory

tempdir="$(mktemp -t -d temp.XXXXXXXX)"

cd "${tempdir}"

mkdir ACT #duplicate

#start logfile

touch ${outdir}/antsTumourCT_logfile.txt
log=${outdir}/antsTumourCT_logfile.txt

echo $(date) >> ${log}
echo "${@}" >> ${log}


##################
# Main programme #
##################


#define function

function antsTCT() {

    #subtract out priors
    fslmaths "${tumour_mask}" -kernel sphere 2 -fmean "${tumour_mask}" #smooth

    cp -R ${template}/Priors .

    for i in {1..6};
    do
        fslmaths Priors/prior{i}.nii.gz -sub "${tumour_mask}" Priors/prior{i}.nii.gz
    done

    #make new prior5 from tumour mask (in place of brainstem)
    cp "${tumour_mask}" Priors/prior5.nii.gz

    #run antsCorticalThickness.sh

    echo "now running antsCorticalThickness.sh"

    antsCorticalThickness.sh \
    -d 3 \
    -a $structural \
    -e ${template}/MNI152_T1_2mm.nii.gz \
    -m ${template}/MNI152_T1_2mm_brain_mask.nii.gz \
    -p Priors/prior%d.nii.gz \
    -t ${template}/MNI152_T1_2mm_brain.nii.gz \
    -o ACT/

}

#call function

antsTCT

#cleanup

cp -fpR . "${outdir}"
cd "${outdir}"
rm -Rf "${outdir}" Priors/

#close up

echo "all done with antsTumourCT.sh" >> ${log}
echo $(date) >> ${log}


