# ants_tumour_scripts
wrappers for using ANTs with tumour data

Structural
- brain extraction: antsBrains.sh 
- SyN warp for mprage-to-MNI space: antsT1Reg.sh
- registration with masks: antsTumourReg.sh

FMRI
- creates a merged affine & SyN warp for EPI-to-MNI space: antsEpiReg.sh
- warps EPI data to MNI space: antsRegister4D.sh
- parcellates EPI data: antsParcellates .sh 

Cortical thickness
- uses custom MNI space template & custom priors (including tumour masks): antsTumoursCT.sh
