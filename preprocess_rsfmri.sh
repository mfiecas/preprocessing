mni=/Users/markfiecas/fsl/data/standard/MNI152_T1_2mm_brain
brainmask=/Users/markfiecas/fsl/data/standard/MNI152_T1_2mm_brain_mask.nii.gz

function preprocess(){
echo "Preprocessing $1 ..."
t1dir=$1
epidir=$2
epifn=$(ls $epidir/*.nii.gz | head -n 1);

# MPRAGE to MNI
echo "MPRAGE to MNI"
flirt -in $t1dir/t1_brain -ref $mni -omat $t1dir/mprageToMNI.mat

# Motion correct
echo "Motion Correction"
mcflirt -in $epifn -stats -plots -out $epidir/rfmri

# Obtain mean image
fslmaths $epidir/rfmri -Tmean $epidir/meanfmri

# Mean to MPRAGE
echo "EPI to MPRAGE"
flirt -in $epidir/rfmri_meanvol -ref $t1dir/t1_brain -omat $epidir/epiToMprage.mat

# Combine transformations
convert_xfm -omat $epidir/epiToMNI.mat -concat $t1dir/mprageToMNI.mat $epidir/epiToMprage.mat

# Epi to MNI
flirt -in $epidir/rfmri -ref $mni -out $epidir/wrepi -applyxfm -init $epidir/epiToMNI.mat

# Spatial smoothing
# FWHM = 5mm
echo "Spatial Smoothing"
fslmaths $epidir/wrepi -kernel gauss 2.1233226 -fmean $epidir/swrepi

# Segmentation
echo "Segmentation"
fast -t 1 -g -p -o segment $t1dir/t1_brain
mkdir $t1dir/segment
mv segment*.nii.gz $t1dir/segment
cd $t1dir/segment

# Segmentation - CSF
flirt -in segment_prob_0 -ref $mni -applyxfm -init $t1dir/mprageToMNI.mat -out wcsf
fslmaths wcsf -thr .75 wcsf_thr
fslmaths wcsf_thr -bin wcsf_bin
3dmaskave -mask wcsf_bin.nii.gz -quiet $epidir/swrepi.nii.gz > $epidir/csf.1D

# Segmentation - WM
flirt -in segment_prob_2 -ref $mni -applyxfm -init $t1dir/mprageToMNI.mat -out wwm
fslmaths wwm -thr .75 wwm_thr
fslmaths wwm_thr -bin wwm_bin
3dmaskave -mask wwm_bin.nii.gz -quiet $epidir/swrepi.nii.gz > $epidir/wm.1D

# Nuisance signals
echo "Nuisance Signal Regression"
cd $epidir
1dcat csf.1D wm.1D rfmri.par > nuisance.1D
3dDetrend -prefix resid -vector nuisance.1D -polort 1 swrepi.nii.gz
3dAFNItoNIFTI resid+tlrc
fslmaths resid -mul $brainmask nswrepi
rm resid*
fslmeants -i nswrepi -m $brainmask -o nswrepi.txt --showall
}

preprocess /Users/markfiecas/data/Stroke/cases/S05-1/20170530-ST001-S05/MR-SE007-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S05-1/20170530-ST001-S05/MR-SE014-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S05-2/20170530-ST001-S05/MR-SE007-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S05-2/20170530-ST001-S05/MR-SE014-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S09-1/20170601-ST001-S09/MR-SE007-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S09-1/20170601-ST001-S09/MR-SE014-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S09-2/20170802-ST001-S09/MR-SE005-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S09-2/20170802-ST001-S09/MR-SE012-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S10-1/20170530-ST001-S10/MR-SE018-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S10-1/20170530-ST001-S10/MR-SE025-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S10-2/20170727-ST001-S10/MR-SE009-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S10-2/20170727-ST001-S10/MR-SE016-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S12-1/20170614-ST001-S12/MR-SE005-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S12-1/20170614-ST001-S12/MR-SE014-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S12-2/20170807-ST001-S12/MR-SE010-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S12-2/20170807-ST001-S12/MR-SE016-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S13-1/20170613-ST001-S13/MR-SE003-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S13-1/20170613-ST001-S13/MR-SE010-FMRI_REST_AP
preprocess /Users/markfiecas/data/Stroke/cases/S13-2/20170802-ST001-S13/MR-SE005-T1_SAG_GR2 /Users/markfiecas/data/Stroke/cases/S13-2/20170802-ST001-S13/MR-SE012-FMRI_REST_AP




