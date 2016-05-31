# ants_tumour_scripts
wrappers for using ANTs with tumour data

Structural
- brain extraction: antsBrains.sh 
- registration from structural to standard space (with SyN warp & masks): antsTumourReg.sh

FMRI
- registration from functional to structural space (affine): antsEpiReg.sh
- warps EPI data to MNI space: antsRegister4D.sh

Cortical thickness
- with custom MNI space template & priors (including tumour masks): antsTumourCT.sh

Parcellation
- in native space: antsParcellates.sh

All-In-One

runs all of above with default options (script): uberAnts.sh
