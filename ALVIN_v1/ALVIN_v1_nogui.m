function [lvvol] = ALVIN_v1_nogui(segmented_images, prvseg, mask, savef, txtfile)
%ALVIN script to apply lateral ventricle mask to modulated CSF images
%see http://sites.google.com/site/mrilateralventricle/
%Matthew Kempton (matthew.kempton@kcl.ac.uk) December 2011 
%
%Note currently ALVIN works with SPM8 but not earlier versions.
%
%To use ALVIN in SPM8, In the SPM window click Utils.., Run mFile and choose the file ALVIN_v1.m
%If you have already segmented your structural MRI images and have produced modulated normalised CSF images, 
%say yes to the first question and select these files (note only files with the prefix mwc3 will be shown). 
%If you have not segmented your images say no and ALVIN will segment these first.
%Later you will be asked to select the ALVIN mask file which is included in this download.
%
%See validation paper at http://www.ncbi.nlm.nih.gov/pubmed/21835253
%Full Instructions at
%
%Versions
%ALVIN 1.0: Improved instructions and provided example test data
%AVLVIN 0.95 :Fixed bug which caused problems if images needed to be segmented and filenames were different lengths, warn user if lateral ventricles are smaller or larger than expected, other minor improvements in code
%AVLVIN 0.91 :Fixed bug which crashed when different length filenames were chosen
%ALVIN 0.9 Initial version released on internet
%
%Script asks if modulated normalised CSF images are available if they are not the program produces
%them using SPM segment. The ventricle mask is used to mask the modulated images and the ventricle
%volume is calculated
% 10 Sept 2012 - Modified by MB Nebel to be a function that runs without a
% gui

ALVIN_HOME=getenv('ALVIN_TOOLBOX_HOME');

if(nargin < 2)
    [ipath ifile iext] = fileparts(segmented_images);
    txtfile = fullfile(ipath, strcat('ALVIN_', ifile, '.txt'));
    %don't save .txt (0 = save)
    savef = 1;
    mask = fullfile(ALVIN_HOME, 'ALVIN_mask_v1.img');
    prvseg = 0;
elseif(nargin < 3)
    [ipath ifile iext] = fileparts(segmented_images);
    txtfile = fullfile(ipath, strcat('ALVIN_', ifile, '.txt'));
    %don't save .txt (0 = save)
    savef = 1;
    mask = fullfile(ALVIN_HOME, 'ALVIN_mask_v1.img');
elseif(nargin < 4)
    [ipath ifile iext] = fileparts(segmented_images);
    txtfile = fullfile(ipath, strcat('ALVIN_', ifile, '.txt'));
    %don't save .txt (0 = save)
    savef = 1;
elseif(nargin < 5)
    [ipath ifile iext] = fileparts(segmented_images);
    txtfile = fullfile(ipath, strcat('ALVIN_', ifile, '.txt')); 
end

% lvvol = zeros(length(segmented_images), 4);

%Clear selected variables
matlabbatch='';  
native_images='';
maskedarray='';
V='';
img='';


% spm_input('ALVIN ventricle segmentation v1.0',1,'d');
% spm_input('Determines lateral ventricle volume from structural',2,'d');
% spm_input('MRI data.',3,'d');
% spm_input('Have you already segmented your images and',5,'d');
% prvseg= spm_input('produced mwc3 CSF files?','+1','b',{'yes','no','not sure'},[0 1 2],2);

if (prvseg==0) %User has already segmented images so for these
% 	spm_input('Choose modulated CSF images','+1','d');
% 	segmented_images = spm_select(Inf,'^mwc3.*\.(img|nii)$','Select modulated CSF images (mwc3 files)');
	[number_images, longestpath]= size(segmented_images); %Determine number of files (longest path variable ignored)	
end

if (prvseg==2) %User not sure so assume images are not segmented and set answer to no 
	spm_input('OK, I will segment to be sure','+1','d');
	prvseg=1;
end


if (prvseg==1) %User has not segmented images so ask for native images
% 	spm_input('Choose correctly oriented images to segment','+1','d');
% 	native_images = spm_select(Inf,'image','Select MRI images');
	[number_images, longestpath]= size(native_images); %Determine number of files (longest path variable ignored)	
end



% savef= spm_input('Save volumes to text file?','+1','b',{'yes','no'},[0 1],1);
% if (savef==0) 
% 	txtname  = spm_input('Enter filename','+1','s','ALVIN_Vols.txt');
% 	txtfile = [pwd '/' txtname];
% end

%If images have not been segmented yet, segment with CSF modulation only
if (prvseg==1)
	spm_input('Segmenting images...','+1','d');
	for k=1:number_images;
		matlabbatch{k}.spm.spatial.preproc.data = {deblank(native_images(k,:))};	%cell array containing list of paths and file names
		matlabbatch{k}.spm.spatial.preproc.output.GM = [0 0 0];
		matlabbatch{k}.spm.spatial.preproc.output.WM = [0 0 0];
		matlabbatch{k}.spm.spatial.preproc.output.CSF = [1 0 0]; %Modulated segmented CSF
		matlabbatch{k}.spm.spatial.preproc.output.biascor = 0; %don't save bias corrected images
		matlabbatch{k}.spm.spatial.preproc.output.cleanup = 2; %thorough clean
	end	
	%Execute the batch process
	spm_jobman('run',matlabbatch);
	matlabbatch='';
end

% Run through each subject for Imcalc
spm_input('Calculating ventricular volumes...','+1','d');
maskedarray = cell(number_images, 1);	%Declare as an nx1 cell array to hold
for k=1:number_images;
	%work out filenames
	if (prvseg==1) %if native files were selected we need to work out segmented image names produced by the loop above
		[pathstr, name, ext] = fileparts(deblank(native_images(k,:)));
		segmented_name = ['mwc3' name];	%add expected mwc3 prefix to filename
		segmented_filename = fullfile(pathstr,[segmented_name ext]);
		segmented_images(k,1:(length(segmented_filename)))=segmented_filename;
	end
	[pathstr, name, ext] = fileparts(deblank(segmented_images(k,:)));
	maskedname= ['ALVIN_' name];	%prefix ventricle images with ALVIN
	maskedoutput=fullfile(pathstr,[maskedname ext]); %Determine output name for each ventricle image
	maskedarray(k)={maskedoutput}; %Store list of output names in masked array so these can be loaded again to determine volumes

	%set parameters for Imcalc
	matlabbatch{k}.spm.util.imcalc.input = {deblank(segmented_images(k,:)),(mask)}; %Input image names        
	matlabbatch{k}.spm.util.imcalc.output = maskedoutput;	%Output name for ventricle images
	matlabbatch{k}.spm.util.imcalc.expression = 'i1.*(i2>50)'; %Mask modulated csf image (i1) with ALVIN ventricle mask (i2) 
end
eval(['save ALVIN_imcalc_bit_jobfile.mat matlabbatch'])

%Execute the batch process
spm_jobman('run',matlabbatch);



% Output volume of the masked region from John Ashburners script for determining volume
fprintf('Lateral Ventricle Volumes in millilitres\n');
fprintf('Name \t \t \t Volume\n');
if (savef==0) %If user opted to save files set up column titles
	fid = fopen(txtfile, 'w');
	fprintf(fid,'ALVIN v1.0 Lateral Ventricle Volumes\n');
	fprintf(fid,'File produced on %s\n',datestr(now));
	fprintf(fid,'Volumes in millilitres\n');
	fprintf(fid,'Name \t Volume\n');
end	
for k=1:number_images;	
	Q = char(maskedarray(k));
	V = spm_vol(deblank(Q));
	vol = 0;
    	for islice=1:V.dim(3),
        img = spm_slice_vol(V,spm_matrix([0 0 islice]),V.dim(1:2),0);
        img = img(isfinite(img));

        vol = vol + sum(img(:));
    	end;
    	voxvol = abs(det(V.mat(1:3,1:3)))*1e-3;

	if (prvseg==1) %If user has not segmented images, display native image name
	display_filename=deblank(native_images(k,:));
	end
	if (prvseg==0) %If user has segmented images, display segmented image name
	display_filename=deblank(segmented_images(k,:));
	end
	
	warning_flag=''; %Warn user if lateral ventricles are more than 150ml or less than 1ml 
	if (vol*voxvol > 150)
 		warning_flag='ventricle volume unusually high check segmented image';
	end
	if (vol*voxvol < 1) 
		warning_flag='ventricle volume unusually small check segmented image';
	end

	[pathstr, name, ext] = fileparts(display_filename);
	fprintf('%s \t %g ml \t %s\n', name, vol*voxvol, warning_flag);
	if (savef==0)
		fprintf(fid, '%s \t %g \t ml \t %s\n', display_filename, vol*voxvol, warning_flag); %List the filename including the path followed by the lateral ventricle volume in ml
    end
    
end

if (savef==0) %If user opted to save files state the location of the text file produced
	fprintf('\nValues also saved to text file %s',txtfile);
	fclose(fid);
end

spm_input('ALVIN finished -please see command line ',1,'d');
spm_input('window for the results ',2,'d');

fprintf('\n\nALVIN Finished\n');

lvvol = vol*voxvol;

close all



	
