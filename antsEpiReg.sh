#!/bin/bash
set -e

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

History:    no amendments

============================================================================

EOF
}

###################
# Standard checks #
###################


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

#set verbose option

if [ "$verbose" == 1 ]
then
    set -x verbose
fi

#check usage

if [[ -z $functional ]] || [[ -z $structural ]]

then
    echo "usage incorrect" >&2
    usage
    exit 1
fi

echo "options ok"

# final check of files

echo "Checking functional and structural data"

functional=${basedir}/${functional}

if [ $(imtest $functional) == 1 ];
then
    echo "$functional dataset ok"
else
    echo "Cannot locate file $functional. Please ensure the $functional dataset is in this directory"
    exit 1
fi

structural=${basedir}/${structural}

if [ $(imtest $structural) == 1 ];
then
    echo "$structural dataset ok"
else
    echo "Cannot locate file $structural. Please ensure the $structural dataset is in this directory"
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

#make temporary directory

tempdir="$(mktemp -t -d temp.XXXXXXXX)"

cd $tempdir

#start logfile

touch AER_logfile.txt
log=AER_logfile.txt

echo $(date) >> ${log}
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

    Return 0

}

#call function

AER

echo "antsEpiReg done: functional registered to structural"

#check results

slices epi2struct.nii.gz $structural -o antsEpiCheck.gif

#perform cleanup

cp -fpR . "${outdir}"
cd $outdir
rm -Rf ${tempdir} epi_avg.nii.gz affineWarped.nii.gz affineInverseWarped.nii.gz

#complete log

echo "all done with antsEpiReg.sh" >> ${log}
echo $(date) >> ${log}

