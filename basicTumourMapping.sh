#!/bin/bash

#basic parameters
dim=3 # image dimensionality
AP="/usr/rt337/public_html/mgh40/bin/" # /home/yourself/code/ANTS/bin/bin/  # path to ANTs binaries
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4  # controls multi-threading
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

#images
f=$1 ;
m=$2 ;
mask=$3   # fixed and moving image file names

#some other imaging parameters
reg=${AP}antsRegistration           # path to antsRegistration
its=10000x1111x5
percentage=0.25
syn="20x20x0,0,5"
nm=BBM

#1. warp MNI to mprage with tumour mask

#do registration (with mask in fixed space)

antsRegistrationSyN.sh \
-d $dim \
-m $m \
-f $f \
-o ${nm} #gives BBM, BBM_diff, BBM_inv

#apply warps: moving to rigid (fixed) space - uses 1Warp then 0GenericAffine and gives BBM_warped.nii.gz
${AP}antsApplyTransforms -d $dim -i $m -r $f -n linear -t ${nm}1Warp.nii.gz -t ${nm}0GenericAffine.mat -o ${nm}_warped.nii.gz --float 1

#2. do with lesioning
echo Lesion study uses the affine mapping from the previous result.
echo One could also "revise" the template mask by the lesion mask but
echo here we assume the affine map is not corrupted by the lesion (therefore template not adapted)
echo We do, however, mask the deformation estimation with a lesion mask.

#use original affine.mat
origmat=${nm}0GenericAffine.mat

nm=BBM_Lesion #new name

#do some stuff to tumour mask
SmoothImage 3 data/lesion.nii.gz 2 data/neg_lesion.nii.gz #smooth
ImageMath 3 data/neg_lesion.nii.gz CorruptImage  data/neg_lesion.nii.gz #add some corruption
ImageMath 3 data/neg_lesion.nii.gz Neg data/neg_lesion.nii.gz #make at exclusive (0's)
MultiplyImages 3 data/neg_lesion.nii.gz $m data/T1_lesioned.nii.gz #multiply by $2 i.e. moving image
m=data/T1_lesioned.nii.gz #define this as moving image (has the lesion zeroed out)

***they should be different spaces??? apparently not - lesion on fixed is similar to that of moving

#some definitions
imgs=" $m, $f " #opposite order plus new moving image with lesion
myit=1000

#now register new lesioned image to fixed (or vice versa?)
$reg -d $dim -r [${origmat},1] \ #initialises registration with current affine (in reverse)
-m mattes[  $imgs , 1 , 32 ] \ #uses fixed / moving (so above is reversed???)
-t SyN[ .20, 3, 0.1 ] \
-c [ 30x20x0 ]  \
-s 1x0.5x0vox  \
-f 4x2x1 -l 1 -u 1 -z 1 -x data/neg_lesion.nii.gz   \ #now uses negative lesion
-o [${nm},${nm}_diff.nii.gz,${nm}_inv.nii.gz] #makes BBM_lesion, BBM_lesion_diff, BBM_lesion_inv

#make images
ExtractSliceFromImage 3 data/T1_lesioned.nii.gz temp.nii.gz 1 120
ConvertImagePixelType temp.nii.gz T1_lesioned.jpg 1 #original unregistered T1
ExtractSliceFromImage 3 ${nm}_diff.nii.gz temp.nii.gz 1 120 #image is BBM_lesion_diff
ConvertImagePixelType temp.nii.gz Template2T1_lesioned.jpg 1

#so in summary, uses original affine from MNI-to-mprage (with mprage-mask) to do another SyN registration from MNI to lesioned-T1 using negative-lesion mask
