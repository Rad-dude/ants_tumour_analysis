#!/bin/bash

#Michael Hart, University of Cambridge, 13 April 2016 (c)

#define directories

codedir=${HOME}/bin
basedir=$(pwd)

#make usage function

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsEpiReg.sh

(c) Michael Hart, University of Cambridge, 2016

Creates an rigid affine transform from functional to structural space

Example:

antsEpiReg.sh -f functional.nii.gz -s mprage.nii.gz

Options:

-h  show this help
-f  functional (epi)
-s  structural
-o  overwrite
-v  verbose

Version:    1.1

History:    modified 25 May 2016 - new directory handling and slicer file

============================================================================

EOF
}

#initialise options

functional=
structural=

while getopts "hf:s:ov" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    f)
        functional=$OPTARG
        ;;
    s)
        structural=$OPTARG
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

#check usage

if [[ -z $functional ]] || [[ -z $structural ]]

then
    usage
    exit 1
fi

echo "files and options ok"

# final check of files
# do they exist, can they be read, by me, and are the correct format

echo "Checking functional and structural data"

functional=${basedir}/${functional}

if [ -f $functional ];
then
    echo "$functional dataset ok"
else
    echo "Cannot locate file $functional. Please ensure the $functional dataset is in this directory"
    exit 1
fi

structural=${basedir}/${structural}

if [ -f $structural ];
then
    echo "$functional dataset ok"
else
    echo "Cannot locate file $functional. Please ensure the $functional dataset is in this directory"
    exit 1
fi

echo "files ok"

#make output directory

if [ ! -d ${basedir}/AER ];
then
    echo "making output directory"
    mkdir ${basedir}/AER
else
    echo "output directory already exists"
    if [ "$overwrite" == 1 ]
    then
        echo "overwriting output directory"
        mkdir -p ${basedir}/AER
    else
        echo "no overwrite permission to make new output directory"
        exit 1
    fi
fi

outdir=${basedir}/AER

cd $outdir

#start logfile

touch AER_logfile.txt
log=AER_logfile.txt

echo date >> ${log}
echo "${@}" >> ${log}


##################
# Main programme #
##################


function AER() {

    #1. create a single EPI 3D volume

    ref=epi_avg.nii.gz
    antsMotionCorr -d 3 -a $functional -o $ref #now we have a single reference EPI image

    #2. generate a 3D affine transformation to a template

    antsRegistrationSyN.sh \
    -d 3 \
    -o affine \
    -f $structural \
    -m $ref \
    -t a

    #3. warp the single epi image

    antsApplyTransforms \
    -d 3 \
    -o epi2struct.nii.gz \
    -i $ref \
    -t affine0GenericAffine.mat \
    -r $structural

    #4. quality check the result

    slices epi2struct.nii.gz $structural -o antsEpiCheck.gif

}

#call function

AER

#perform cleanup

rm epi_avg.nii.gz affineWarped.nii.gz affineInverseWarped.nii.gz
