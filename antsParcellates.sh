#!/bin/sh
set -e

#Michael Hart, University of Cambridge, 13 April 2016 (c)

#define directories

codedir=${HOME}/bin
basedir="$(pwd -P)"

#make usage function

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

antsParcellates.sh

(c) Michael Hart, University of Cambridge, April 2016

Registers a parcellation template to functional space & extracts data for connectomics

Example:

antsParcellates.sh -f epi.nii.gz -w warp.nii.gz -r affine.mat

Options:

-f  functional (epi)
-w  warp (concatenated transform) from standard-to-structural e.g. antsTumourReg.sh output
-r  rigid transform (6 DOF) from epi-to-structural e.g. antsEpiReg.sh output
-p  parcellation template (optional: default=AAL_random256)
-o  overwrite
-v  verbose

Outputs:

ants_ts.txt:    time series per parcel
ants_n.txt:     number of voxcels per parcel
ants_xyz.txt:   epi co-ordinates of parcel centre of gravity (mm)

Version:    1.1

History:    added output directory naming	10 October 2016

============================================================================

EOF
}


###################
# Standard checks #
###################

functional=
warp=
rigid=


#initialise options

while getopts "hf:w:r:p:ov" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    f)
        functional=$OPTARG
        ;;
    w)
        warp=$OPTARG
        ;;
    r)
        affine=$OPTARG
        ;;
    p)
        parcellation=$OPTARG
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

echo "${parcellation}"

#set verbose option

if [ "${verbose}" == 1 ]
then
    set -x verbose
fi

#check usage

if [[ -z "${functional}" ]] || [[ -z "${warp}" ]] || [[ -z "${affine}" ]]; then
    usage
    exit 1
fi

echo "options ok"

# final check of files

echo "Checking functional data"

functional=${basedir}/${functional}

if [ $(imtest "${functional}") == 1 ];
then
    echo "$functional is ok"
else
    echo "Cannot locate file $functional. Please ensure the $functional dataset is in this directory"
    exit 1
fi

warp=${basedir}/${warp}

if [ $(imtest "${warp}") == 1 ];
then
    echo "$warp is ok"
else
    echo "Cannot locate file $warp. Please ensure the $warp dataset is in this directory"
    exit 1
fi

affine=${basedir}/${affine}

if [ -f "${affine}" ];
then
    echo "$affine is ok"
else
    echo "Cannot locate file $affine. Please ensure the $affine dataset is in this directory"
    exit 1
fi

if [ -f "${parcellation}" ];
then
    echo "$parcellation dataset ok"
    template=${parcellation}
else
    echo "$parcellation is ok"
    template="${HOME}/templates/AAL/AAL256.nii.gz"
    echo "No template supplied - using AAL_random256"
fi

echo "files ok"

#make output directory

outname=`basename ${template} .nii.gz`

if [ ! -d ${basedir}/${outname} ];
then
    echo "making output directory"
    mkdir ${basedir}/${outname}
else
    echo "output directory already exists"
    if [ "$overwrite" == 1 ]
    then
        mkdir -p ${basedir}/${outname}
    else
        echo "no overwrite permission to make new output directory"
        exit 1
    fi
fi

outdir=${basedir}/${outname}

#make temporary directory

tempdir="$(mktemp -t -d temp.XXXXXXXX)"
cd "${tempdir}"

#start logfile

touch antsParcellation_logfile.txt
log=antsParcellation_logfile.txt

echo $(date) >> "${log}"
echo "${@}" >> "${log}"


##################
# Main programme #
##################


function antsParcels() {

    #1. create a single EPI 3D volume for registration of template to functional space
    ref=epi_avg.nii.gz
    antsMotionCorr -d 3 -a "${functional}" -o "${ref}" 

    #2. move parcellation template to functional space

    echo "moving template from MNI to functional space"

    antsApplyTransforms \
    -d 3 \
    -o native_template.nii.gz \
    -t "${warp}" \
    -t ["${affine}", 1] \
    -r "${ref}" \
    -i "${template}" \
    -n NearestNeighbor \
    --float

    #3. extract time series

    echo "now extracting timeseries for each parcels"

    fslmeants -i "${functional}" --label=native_template.nii.gz -o ants_ts.txt

    #4. calculate co-ordinates and numbers of voxels

    echo "finally checking numbers of voxels and co-ordinates of each parcel"

    fslstats -K native_template.nii.gz "${functional}" -V >> ants_n.txt #voxels & volume in epi space
    fslstats -K native_template.nii.gz "${functional}" -c >> ants_xyz.txt #mm co-ordinates in epi space

}

# call function

antsParcels

# perform cleanup
cp -fpR . "${outdir}"
cd "${outdir}"
rm -Rf "${tempdir}" "${ref}"

# complete log

echo "all done with antsParcellates.sh" >> ${log}
echo $(date) >> ${log}

