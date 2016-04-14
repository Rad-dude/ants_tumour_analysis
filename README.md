# ants_tumour_scripts
wrappers for using ANTs with tumour data

Structural
- brain extraction 
- SyN warp for mprage-to-MNI space

FMRI
- creates a merged affine & SyN warp for EPI-to-MNI space
- warps EPI data to MNI space 
- parcellates EPI data 

Cortical thickness
- uses custom MNI space template & custom priors
