function fmri_preprocess(setup_file)

%Function to preprocess a single subject with multiple fmri runs.
%The steps and specifications for what is to be done is from the set up
%file

%Suresh E Joel Dec 22, 2010, Modified Mar 2, 2011
%MB Nebel modified Feb 19, 2013: fmri_regress_nuisance returns a variable
%that indicates the file prefix for nuisance-regressed data

%% Initializing
clear rp_file;
% clear classes;
if(isunix)
    load(setup_file);
else
    load(char(setup_file));
end

if (exist('temp_path', 'var'))
    cd(temp_path);
end

%% Create brain_mask - This is possible only if we had segmented and is needed only if we run one of the following!! - FIX THIS
if(create_brain_mask_file==1)
    fmri_create_brain_mask(anat_file, brain_mask_file);
end;

disp(['Prefix ', prefix]);

for ir=1:length(func_files) %The following needs to be done session by session
    prefix_loop=prefix;
    disp(['Prefix_loop ', prefix_loop]);
    clear curr_func_files;
    %% HP filter or detrend
    if(hp_filter)
        for i=1:length(func_files{ir}),
            [func_dir,func_file,ext]=fileparts(func_files{ir}{i});
            curr_func_files{i}=fullfile(func_dir,[prefix_loop,func_file,ext, ',1']);
        end;
        disp(curr_func_files{1});
        cutoffs = hp;
        brain_mask_filename = brain_mask_file;
        drop_band = 0;
        if ~exist('band','var')
            % 			detrend is default option
            band = 5;
            drop_band = 1;
        end
        fmri_time_filt(curr_func_files,tr,hp,band,brain_mask_file,low_ram);
        if (drop_band), clear band, end
        prefix_loop=['f',prefix_loop];
        clear curr_func_files func_dir func_file;
    end;
    
    %% Estimate nuisances
    if(nuisance_estimate)
        [~,func_file,ext] = fileparts(func_files{ir}{1});
        afile = ['a',func_file];
        for i=1:length(func_files{ir}),
            [func_dir,func_file,ext]=fileparts(func_files{ir}{i});
            curr_func_files{i}=fullfile(func_dir,[prefix_loop,func_file,ext]);
        end;
        nuisance_file=[curr_func_files{1},nuisance_file_postfix,'.mat'];
        % rp file location
        if(~exist('rp_file_nm', 'var'))
            rp_file_nm=dir(fullfile(fileparts(curr_func_files{1}),['rp*' afile '.txt']));
            rp_file{ir}=fullfile(fileparts(curr_func_files{1}),tmp(1).name)
        else
            rp_file{ir}=fullfile(fileparts(curr_func_files{1}),rp_file_nm)
        end
        if ~exist('wm_file','var')
            [anat_dir,anat_file_nodir,ext]=fileparts(anat_file);
            wm_file=fullfile(anat_dir,['wc2',anat_file_nodir,ext]);
        end
        
        if nr_options.wm_signal== 0
            wm_file='';
        end
        
        if ~exist('csf_file','var')
            [anat_dir,anat_file_nodir,ext]=fileparts(anat_file);
            csf_file=fullfile(anat_dir,['wc3',anat_file_nodir,ext]);
        end
        
        if nr_options.csf_signal== 0
            csf_file='';
        end
        if ~exist('npref','var')
            npref = 'n';
        end
        fmri_estimate_nuisance(curr_func_files,tr,rp_file{ir},wm_file,csf_file,brain_mask_file,nr_options,nuisance_file);
    end %if nuisance_regress
    
    if(nuisance_regress)
        for i=1:length(func_files{ir}),
            [func_dir,func_file,ext]=fileparts(func_files{ir}{i});
            curr_func_files{i}=fullfile(func_dir,[prefix_loop,func_file,ext]);
        end;
        nuisance_file=[curr_func_files{1},nuisance_file_postfix,'.mat'];
        if(low_ram~=1),
            [npref] = fmri_regress_nuisance(curr_func_files,brain_mask_file,nuisance_file, nr_options);
            
        else
            fmri_regress_nuisance_1D(curr_func_files,brain_mask_file,nuisance_file, nr_options);
            
        end
        prefix_loop=[npref,prefix_loop];
        clear curr_func_files func_dir func_file nuisance_file;
    end; %if nuisance_regress
end %for ir

