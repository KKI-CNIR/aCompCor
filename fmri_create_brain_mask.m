function fmri_create_brain_mask(anat_file,out_filename)
%Function to create a brain mask in the normalized space (can be done only
%after segmentation)
%Usage
%   fmri_create_brain_mask(anat_file,out_filename)
%Inputs
%   anat_file - is the filename of the T1-weighted image (the one that was segmented)
%   out_filename - is the filename of the output (typically 'brain_mask.nii')

%Suresh E Joel, Mar 2011

[anat_dir,anat_filename,ext]=fileparts(anat_file);

v=spm_vol(fullfile(anat_dir,['wc1',anat_filename,ext]));
gm=spm_read_vols(v);

v=spm_vol(fullfile(anat_dir,['wc2',anat_filename,ext]));
wm=spm_read_vols(v);

v=spm_vol(fullfile(anat_dir,['wc3',anat_filename,ext]));
csf=spm_read_vols(v);

i=double(gm+wm+csf) > 0.25;

v.fname=out_filename;
v.private.dat.fname=v.fname;

spm_write_vol(v,i);
