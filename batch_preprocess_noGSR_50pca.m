%%%%%%%%%%%%%set these paths
%% directory with subject data
study_dir = 'D:\acompcorStuff';
%% directory where toolbox scripts are saved
toolbox_dir = 'D:\acompcorStuff';

addpath(toolbox_dir)

%% Subjects to be processed
file_flag=0; % 1 if inputting a textfile, 0 if creating a variable within the script
if file_flag,
    fid = fopen(fullfile(study_dir, 'subjects_postproc.txt'));
    subjects_td = textscan(fid, '%s');
    fclose(fid);
    part_ids = strtrim(char(subjects_td{1}));
else,
    % In the format: {'XXX','XXX','XXX'}
    part_ids={'data'};
end;

n_sess=1; %Number of functional runs/sessions for each participant
dimen=3; % 3 = separate image file for each functional frame
prefixes = {'wa'}; %prefix of functional files to look for
tr = 2;

istart = 1;
istop = length(part_ids);

for isub=istart:istop,
    if file_flag,
        ID = strtrim(part_ids(isub, :));
    else,
        ID = part_ids{isub};
    end;
    
    %directory of subject to be processed
    subjdir = fullfile(study_dir, ID);
    
    %directory containing subject's MPRAGE
    apath = fullfile(subjdir,  'Anatomical');
    
    %point to anatomical file coregistered to functional 
    anat_file = fullfile(apath, 'anat.nii');
    
    %directory containing subject's functional data
    fpath = fullfile(subjdir, 'Functionals');
    
    %   Find rp file for nuisance estimation & regression; script assumes
    %   it is in the same directory as the functional data
    rplist = dir(fullfile(fpath, 'rp*.txt'));
    rpf = {rplist.name};
    
    if(length(rpf) == 1)
        rp_file_nm = rpf{1};
    else
        warning('Multiple rp files')
        disp(rpf)
        which_file = input('Which rp file?');
        rp_file_nm = rpf{which_file};
    end
    
    if length(n_sess) > 1
        sessions = n_sess(isub);
    else
        sessions = n_sess;
    end
    
    func_dir = cell(sessions, 1);
    func_files = cell(sessions, 1);
    anat_dir = cell(sessions, 1);
    sess_dir = {''};
    for i_sess=1:sessions
        prefix = prefixes{i_sess};
        func_dir{i_sess} = fpath;
        anat_dir{i_sess} = apath;
        
        %get list of files with the specified prefix in func_dir
        ifiles = dir(fullfile(func_dir{i_sess}, [prefix, '*.img']));
        ifiles = {ifiles.name};
        for i_dyn=1:length(ifiles),
            func_files{i_sess}{i_dyn}=fullfile(func_dir{i_sess}, ...
                ifiles{i_dyn});
        end;
    end;
    
    %load specs into matlab memory
    fmri_preprocess_specs_noGSR_50pca;
    setup_file=fullfile(subjdir, ...
        ['preprocess_specs_noGSR_50pca', datestr(now,'yyyymmdd'), '.mat']);
    save(setup_file);
    
    cd(subjdir)
    
    %detrend functional data, estimate and extract nuisances
    fmri_preprocess(setup_file);
    
    cd(toolbox_dir)
    
end;

