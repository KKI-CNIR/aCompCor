%% Steps to perform and Options for each

%Computer capability
low_ram = 0;
prefix = '';

%Create brain mask file
create_brain_mask_file = 1; %This has to be done if hp_filter, nuisance_remove or bp_filter is set
brain_mask_file=fullfile(fileparts(anat_file),'brain_mask.nii');

%time domain filtering
hp_filter = 0; %use detrend function instead of creating high pass filter for simplicity
hp = 0.005; %Cutoff frequency 200s (ignored because band=5)
band = 5; %linear detrend

%% Nuisance removal - typically performed only for seed based analysis
nuisance_estimate = 1;
nuisance_regress = 1;
nuisance_file_postfix='nuisance_fdm_noGSR_pwm50_pcsf50';
nr_options.motion_params=1; %1;
nr_options.detrend_motion_params=1; %if whole brain data has been detrended, detrend rp 
nr_options.filter_motion_params=0; %if whole brain data has been high pass filtered, high pass filter rp
%next two options will be ignored because detrend_motion_params=1
nr_options.filter_motion_params_cutoff=0.005;
nr_options.filter_motion_params_band='high';
nr_options.diff_motion_params=1; %Use motion params differential? 1=Yes
nr_options.square_motion_params=0; %Use motion params square? 0=No
nr_options.global_signal=0;
nr_options.wm_signal=2; %1=mean, 2=pca, 0=not included
nr_options.wm_pca_percent=.50; %include top pricipal components that explain 50% of the variance in white matter signals
nr_options.csf_signal=2; %1=mean, 2=pca, 0=not included
nr_options.csf_pca_percent=.50; %include top pricipal components that explain 50% of the variance in csf signals
nr_options.csf_mask=1; %1=use bwperim; 2=use imerode
nr_options.ALVIN_HOME = fullfile(toolbox_dir, 'ALVIN_v1');

