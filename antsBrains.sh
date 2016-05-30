#!/bin/bash
set -e

# antsBrains.sh
#
#
# Michael Hart, University of Cambridge, 13 April 2016 (c)

#define directories

codedir=${HOME}/bin
basedir=$(pwd)

#make usage function

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsBrains.sh

(c) Michael Hart, University of Cambridge, 2016

Does brain extraction with ANTs
As default uses MNI head & brain mask

Example:

antsBrains.sh -s mprage.nii.gz

Options:

-h  show this help
-s  anatomical
-t  template head (not skull stripped)
-m  brain mask of template
-o  overwrite output directory
-v  verbose

Version:    1.1

History:    no amendments

============================================================================

EOF
}


###################
# Standard checks #
###################

structural=
template=
mask=

#initialise options

while getopts "hs:tmov" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    s)
        structural=$OPTARG
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

if [[ -z $structural ]]
then
    echo "usage incorrect" >&2
    usage
    exit 1
fi

echo "options ok"

# Set defaults if options empty

if [ "$template" == "" ]
then
    template="${HOME}ANTS/ANTS_templates/MNI/MNI152_T1_2mm.nii.gz"
fi

if [ "$mask" == "" ]
then
    mask="${HOME}/ANTS/ANTS_templates/MNI/MNI152_T1_2mm_brain_mask.nii.gz"
fi

# final check of files

echo "Checking functional and template data"

structural=${basedir}/${structural}

if [ $(imtest $structural) == 1 ];
then
    echo "Structural dataset ok"
else
    echo "Cannot locate file $structural. Please ensure the $structural dataset is in this directory"
    exit 1
fi

if [ $(imtest $template) == 1 ];
then
    echo "Template dataset ok"
else
    echo "Cannot locate file $template. Please ensure the $template dataset is in this directory"
    exit 1
fi

if [ $(imtest $mask) == 1 ];
then
    echo "Mask dataset ok"
else
    echo "Cannot locate file $mask. Please ensure the $mask dataset is in this directory"
    exit 1
fi

echo "files ok"

#make output directory

basedir=`pwd`

if [ ! -d ${basedir}/ABE ];
then
    echo "making output director"
    mkdir ${basedir}/ABE
else
    echo "output directory already exists"
    if [ "$overwrite" == 1 ]
    then
        mkdir -p ${basedir}/ABE
    else
        echo "no overwrite permission to make new output directory"
    exit 1
    fi
fi

outdir=${basedir}/ABE

#make temporary directory

tempdir="$(mktemp -t -d temp.XXXXXXXX)"

cd "${tempdir}"

mkdir ABE #duplicate

#start logfile

touch ABE/ABE_logfile.txt
log=ABE/ABE_logfile.txt

echo $(date) >> ${log}
echo "${0}" >> ${log}
echo "${@}" >> ${log}


##################
# Main programme #
##################


function antsBE() {

    antsBrainExtraction.sh \
    -d 3 \
    -a $structural \
    -e $template \
    -m $mask \
    -o ABE/

}

#call function

antsBE

echo "antsBrains done: brain extracted"

#check results

echo "now viewing results"

slices $anat ABE/BrainExtractionBrain.nii.gz -o ABE_check.gif

#perform cleanup

cd ABE/
cp -fpR . "${outdir}"
cd $outdir
rm -Rf ${tempdir} BrainExtractionMask.nii.gz BrainExtractionPrior0GenericAffine.mat

#complete log
cd ..
echo "all done with antsBrains.sh" >> ${log}
echo $(date) >> ${log}
