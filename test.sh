#(c) 2012, Ameera X. Patel, University of Cambridge

tempdir=$HOME/fmri_spt/templates/standard
parcdir=$HOME/fmri_spt/templates/parcel_temps
codedir=$HOME/fmri_spt/code_bin
maskdir=$HOME/fmri_spt/templates/mask
basedir=`pwd`

usage()
{
cat<<EOF
usage: $0 options

===========================================================================

test.sh

Test


OPTIONS:

-h  Show this message (Flag)
-i  Pre-processed functional dataset (in native space) [REQUIRED]
-a  Pre-processed anatomical dataset (in native space) [REQUIRED]
-t  Stanard space template, in talairach space. THIS MUST BE ONE OF
THE FOLLOWING 4 OPTIONS (MNI,N27, ICBM, EPI). [DEFAULT="MNI"]
Please see below for more information on templates.
-p  Parcellation template. Please select one template from the
/templates/atlas folder in this package. [DEFAULT="AT116.nii"]
More information on parcellation templates below.
-o  Output prefix for parcellated data. Note, this program will
append extensions onto this name [DEFAULT="ppp"]
-v  Verbose (Flag)




============================================================================

EOF
}

input=
anat=
temp=
parcel=
output=
verbose=

while getopts "hi:a:t:p:o:v" OPTION
do
case $OPTION in
h)
usage
exit 1
;;
i)
input=$OPTARG
;;
a)
anat=$OPTARG
;;
t)
temp=$OPTARG
;;
p)
parcel=$OPTARG
;;
o)
output=$OPTARG
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

# Verbose option

if [ "$verbose" == 1 ]
then
set -x verbose
fi

if [[ -z $input ]] || [[ -z $anat ]]
then
usage
exit 1
fi


# Fail safe to prevent script execution with non-existent files.

echo ""
echo "Checking functional and anatomical datasets ..."
echo ""

if [ -f $input ];
then
echo "Functional dataset ok"
else
echo "Cannot locate file $input. Please ensure the $input dataset is in this directory"
exit 1
fi

if [ -f $anat ];
then
echo "Anatomical dataset ok"
echo ""
else
echo "Cannot locate file $anat. Please ensure the file $anat is in the working directory"
exit 1
fi

