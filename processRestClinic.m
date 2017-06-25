function [subInfo, status_flag] = processRestClinic(subInfo, roiTable)

% Batch script for preprocessing the rest session of the clinic
% (used to be processRest.mat)

startTime = clock;
FileVersion = 'v1.0';  %30.03.2016 - THM
status_flag = 0;

% genpath(addpath('M:\spm12'))
fprintf('\n\nInitializing SPM12...\n');
spm_jobman('initcfg');
spm('defaults','FMRI');

%------------------------ Setting initial parameters %--------------------------
subPath = subInfo.path;
templatePath = subInfo.parameters.templatePath;
fileTemplate = [subInfo.parameters.fileTemplate '_']; % e.g. 'vol_'
volumesFormat = subInfo.parameters.volumesFormat; % 'nii' or 'img'
roiRadius = subInfo.parameters.roiRadius;
cutoff = subInfo.parameters.cutoff;
wmCenter = subInfo.parameters.wmCenter; % center coordinates of white matter
csfCenter = subInfo.parameters.csfCenter; % center coordinates of CSF

logicals = cell2mat(roiTable(:,1));
roiTable(logicals == 0,:) = [];

% setting the path to the anat folder and the func folder
analysisPath = fullfile( subPath, 'Analysis' );
anatomyPath = fullfile( analysisPath, 'anat' );
funcPath = fullfile( analysisPath, 'func' );
%-------------------------------------------------------------------------------

% setting up the log folder
if ~exist( fullfile( subPath, 'Logs' ) ,'file'),
    mkdir( fullfile( subPath, 'Logs' ) );
end

dateStr = [num2str(startTime(3),'%0.2d') '-' num2str(startTime(2),'%0.2d') '-' num2str(startTime(1)) ];

% setting subject's initials
subInit = createSubInitials(subInfo);

% updating log file
logFID = fopen( fullfile( subPath, 'Logs', [ subInit '_processRestClinic_' dateStr '.log' ] ), 'at' ); %used to be wt
fprintf( logFID, '%s (%s) - Processing rest session\n', subInfo.name, subInit);
fprintf( logFID, '-------------------------------------------------------------------\n' );
fprintf( logFID, [ 'processed with: processRestClinic.m (version ' FileVersion ')\n' ] );
fprintf( logFID, '\n%s\n', dateStr );
fprintf( logFID, '--------------\n' );
fprintf( logFID, 'Subject''s folder: %s\n\n', subPath );

try
    disp( [ 'Process script version: ' FileVersion  ] );
    
    % let's see if fMRIsession field exist - and if it does we'll find
    % our rest session
    fields = subInfo.fMRIsession;
    fld = fieldnames(fields);
    
    % we analyze according to the scan type (either fMRI, DTI, mprage or flair)
    f = regexpi(fld, '(rest)+[^(_| )]*', 'match');
    loc = find(~cellfun(@isempty, f));
    
    % if it is an fMRI series we need to do some additional
    % things before convering to nifti files..
    if ~isempty(loc)
        restSession = fld{loc};
        
        for row = 1:size(roiTable,1)
            
            roiCenter_coords = strsplit(roiTable{row, 3}, {'[', ',', ' ', ']'});
            roiCenter_coords = roiCenter_coords(~cellfun('isempty',deblank(roiCenter_coords)));
            
            roiCenter = str2double(roiCenter_coords);
            roiName = strjoin([roiTable(row, 2), roiCenter_coords], '_');
            
            FILTER = roiTable{row, 4};
            ESTIMATE = roiTable{row, 5};
            
            seriesNumber = fields.(restSession).seriesNumber;
            seriesDescription = fields.(restSession).seriesDescription;
            fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
            
            % setting the path to the current series func folder
            fullSeriesFuncPath = fullfile(funcPath, fullSeriesName);
            restFilteredPath = fullfile(fullSeriesFuncPath, [fullSeriesName '_filtered']);
            
            % --------------------------------------------------------------------------
            % now we set the processing status straight from the subject's current
            % scanning session
            
            sliceTimingPrefix = ['a' fileTemplate];
            realignPrefix = ['r' sliceTimingPrefix];
            coregPrefix = ['r' realignPrefix];
            SmoothPrefix = ['s' coregPrefix];
            
            fprintf('\nProcessing %s \nFilter: %d\nEstimate: %d\n\n',...
                [subInit '_' fullSeriesName], FILTER, ESTIMATE);
            % --------------------------------------------------------------------------
            
            % updating log file
            fprintf( logFID, '%s\n', fullSeriesName);
            fprintf( logFID, '---------------------------------\n' );
            
            % Setting anatomy file from subInfo
            if ~isfield(subInfo, 'SPGR')
                % let's prompt our user to select a file that would be the SPGR
                % file
                SPGRfile = uigetfile(fullfile(anatomyPath, '*.nii'), 'Select anatomy file') ;
                subInfo.SPGR = SPGRfile;
                save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
            end
            
            anatomyfile = subInfo.SPGR;
            
            % Extracting Series parameters
            % the current series name is saed in the structure in lowercase letters
            % and no brackets. we need to change the curernt series name (which is
            % with uppercases and brackets) so we can find it in the structure.
            sName = regexp(lower(fullSeriesName), '\w*[^(\d*rep)]*', 'match');
            fieldname = strjoin(sName,'_');
            
            % Taking TR from dicom
            if isfield(subInfo.fMRIsession.(fieldname).dcmInfo_org, 'RepetitionTime')
                tr = subInfo.fMRIsession.(fieldname).dcmInfo_org.RepetitionTime;
            else
                errorStr = sprintf('Can''t find TR in (ms) in series: %s!', fullSeriesName);
                fprintf( logFID, '\n\nError: %s\n', errorStr );
                error( errorStr );
            end
            
            seriesTR =  tr  / 1000; % in seconds
            cd(fullSeriesFuncPath);
            
            
            %%%%%%%%%%%%%
            % Filtering %
            %%%%%%%%%%%%%
            % we are using a cutoff filter of low and high frequencies
            % fluctations. for this, we are using several function from
            % REST 1.8 toolbox (taken from: http://restfmri.net/forum/index.php
            if ~exist(restFilteredPath, 'dir')
                d = dir(fullfile(restFilteredPath, '*4D*.nii'));
                if isempty(d)
                    disp( 'Filtering' );
                    
                    % update log file with start time of smoothing
                    t = clock;
                    sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                    str = sprintf('%s - Start Filtering..', sTime );
                    disp( str );
                    fprintf( logFID, '%s\n', str );
                    
                    % Reading the relevant volumes for estimation
                    % searching for the files that underwent smoothing (these
                    % are the files with the 'srra' prefix, e.g.: 'sravol_*.nii)
                    d = dir( fullfile( fullSeriesFuncPath, [ SmoothPrefix '*.' volumesFormat ] ) );
                    files = { d.name }';
                    
                    % making sure that the dir function does not mess with the file
                    % order
                    str  = sprintf('%s#', files{:});
                    s = [SmoothPrefix '%d.nii#'];
                    num  = sscanf(str, s);
                    [dummy, index] = sort(num);
                    files = files(index);
                    
                    % we copy the hdr of our 3D data
                    [ hdr3D, filetype, fileprefix, machine ] = load_nii_hdr( fullfile( fullSeriesFuncPath, d(1).name ) );
                    nii3D.hdr = hdr3D;
                    nii3D.hdr.dime.dim(5) = length( files );
                    nii3D.img = zeros( hdr3D.dime.dim(2), hdr3D.dime.dim(3), hdr3D.dime.dim(4));
                    
                    % we create a temporary folder
                    tmpImgFolder = fullfile(fullSeriesFuncPath, 'tmpImg');
                    mkdir(tmpImgFolder);
                    
                    % creating img, hdr, and mat files in the temporary folder from each smoothed vol
                    % file
                    fprintf('creating img, hdr, and mat files...\n')
                    for nn = 1:length( files ),
                        nii3D.img(:,:,:) = load_nii_img( hdr3D, filetype, fullfile( fullSeriesFuncPath, d(nn).name(1:end-4) ), machine );
                        save_nii( nii3D, fullfile( tmpImgFolder, [d(nn).name(1:end-4) '.img'] ) );
                    end
                    fprintf('\n')
                    clear nii3D;
                    
                    % using this temporary folder to insert the 4th
                    % dimention ( - time)
                    rp_bandpass(tmpImgFolder, seriesTR, cutoff(2), cutoff(1), 'Yes', 0);
                    rmdir(tmpImgFolder,'s');
                    
                    % change the name of the filtered folder
                    source = [tmpImgFolder '_filtered'];
                    destination = restFilteredPath;
                    movefile(source, destination)
                end
            end
            
            %%%%%%%%%%%%%%
            % ESTIMATION %
            %%%%%%%%%%%%%%
            if( ESTIMATE )
                disp( 'Estimating' );
                
                % update log file with start time of estimation
                t = clock;
                sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                str = sprintf('%s -  Start Estimation..', sTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
                
                if exist(restFilteredPath , 'dir')
                    
                    % moving the motion txt file into the new filtered folder
                    d = dir(fullfile(fullSeriesFuncPath, 'rp*.txt'));
                    source = fullfile(fullSeriesFuncPath, d.name);
                    destination = fullfile(restFilteredPath, d.name );
                    copyfile(source, destination);
                    
                    % moving the meanavol *.nii file to the new filtered folder
                    d = dir(fullfile(fullSeriesFuncPath, 'mean*.nii'));
                    source = fullfile(fullSeriesFuncPath, d.name);
                    destination = fullfile( restFilteredPath, d.name );
                    copyfile(source, destination);
                    
                    %                     % checking if a 4D file exists in the rest folder
                    %                     d = dir(fullfile( fullSeriesFuncPath, '4D*.nii'));
                    %                     if ~isempty(d)
                    %                         source = fullfile(fullSeriesFuncPath, d.name);
                    %                         destination = fullfile( restFilteredPath, d.name );
                    %                         copyfile(source, destination);
                    %                     end
                    
                    %                 volumesFormat = 'img';
                    %                 EstimatePrefix = '000';
                    roiResultsPath = fullfile(restFilteredPath, roiName);
                    
                    if~exist(roiResultsPath, 'dir')
                        mkdir(roiResultsPath);
                    end
                end
                
                clear matlabbatch;
                
                % loading the matlabbatch template file
                load( fullfile(  templatePath, 'Functional_connectivity_template.mat' ) );
                
                % Reading the relevant volumes for estimation
                % searching for the files that underwent smoothing (these
                % are the files with the 'srra' prefix, e.g.: 'sravol_*.nii)
                d = dir( fullfile( fullSeriesFuncPath, [ SmoothPrefix '*.' volumesFormat ] ) );
                files = { d.name }';
                
                % making sure that the dir function does not mess with the file
                % order
                str  = sprintf('%s#', files{:});
                s = [SmoothPrefix '%d.nii#'];
                num  = sscanf(str, s);
                [dummy, index] = sort(num);
                files = files(index);
                
                % unlike the processWithFullCoregClinic functions, we are
                % using one matlabbatch file in order to process the model
                % specification, estimation and contrast definitions.
                
                % model specification parameters
                matlabbatch{1}.spm.stats.fmri_spec.dir = cellstr( roiResultsPath );
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT = seriesTR;
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans = cellstr( strcat( [ fullSeriesFuncPath '\' ], files, ',1' ) );
                
                % add roi regressor
                % use MarsBar toolbox
                %             nii_dir = [fullfile(fullSeriesFuncPath) '\'];
                roi = maroi_sphere(struct('centre',roiCenter,'radius',roiRadius));
                file_type = [SmoothPrefix '*.' volumesFormat];
                roiTc = extract_ROI_TC({roi} , fullSeriesFuncPath, file_type);
                
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress.name = roiName;
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress.val = roiTc;
                
                % create covariates if needed
                if ~exist(fullfile(restFilteredPath, 'covariates.mat'), 'file')
                    % if ~isfield(subInfo.fMRIsession.(fieldname), 'covariates')
                    
                    % add movement whole brain, csf, and white matter covariates
                    d = dir(fullfile(fullSeriesFuncPath, 'rp*.txt'));
                    mov = load(fullfile(fullSeriesFuncPath, d.name));
                    subInfo.fMRIsession.(fieldname).covariates.mov = mov;
                    
                    
                    % create whole brain mask
                    wholeBrain_roi = create_whole_brain_mask( fullfile( anatomyPath, anatomyfile ), anatomyPath, 'wholeBrainMask.nii');
                    
                    % create white matter mask
                    wm = maroi_sphere(struct('centre',wmCenter,'radius',6));
                    wm = label(wm, 'wm_roi.nii');%set roi label
                    wm = descrip(wm, 'wm_roi.nii');%set roi description
                    wm_roi = saveroi(wm, fullfile(anatomyPath, 'wm_roi.nii'));
                    
                    % create csf mask
                    csf = maroi_sphere(struct('centre',csfCenter,'radius',6));
                    csf = label(csf, 'csf_roi.nii');%set roi label
                    csf = descrip(csf, 'csf_roi.nii');%set roi description
                    csf_roi = saveroi(csf, fullfile(anatomyPath, 'csf_roi.nii'));
                    
                    % extract time cource of rois
                    tc = extract_ROI_TC({wholeBrain_roi, wm_roi, csf_roi} , fullSeriesFuncPath, file_type);
                    
                    % updating subInfo file
                    subInfo.fMRIsession.(fieldname).covariates.wholeBrainTc = tc(:,1);
                    subInfo.fMRIsession.(fieldname).covariates.wmTc = tc(:,2);
                    subInfo.fMRIsession.(fieldname).covariates.csfTc = tc(:,3);
                    
                    % orthogonalize time cources
                    R = [mov tc];
                    R = (R-repmat(mean(R), size(R,1), 1))./repmat(std(R),size(R,1), 1); %Z transform
                    orth_tc = spm_orth(R); %orthogonalize covariates
                    R = orth_tc;
                    save(fullfile(restFilteredPath, 'covariates.mat'), 'R', 'tc');
                    
                    % updating subInfo file
                    subInfo.fMRIsession.(fieldname).covariates.R = R;
                    
                    % and saving it to the subInfo file..
                    save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
                    
                end
                
                % add covariates
                matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = fullfile(restFilteredPath, 'covariates.mat');
                
                spmFile = fullfile( roiResultsPath, 'SPM.mat' );
                if exist(spmFile, 'file')
                    delete( fullfile( roiResultsPath, 'SPM.mat' )  );
                end
                
                % estimation parameters
                matlabbatch{2}.spm.stats.fmri_est.spmmat = cellstr( fullfile( roiResultsPath, 'SPM.mat' ) );
                %           matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
                
                % add contrasts
                matlabbatch{3}.spm.stats.con.spmmat = cellstr(fullfile( roiResultsPath, 'SPM.mat' ));
                matlabbatch{3}.spm.stats.con.consess{1,1}.tcon.name = 'Positive_Effect';
                matlabbatch{3}.spm.stats.con.consess{1,1}.tcon.convec = 1;
                matlabbatch{3}.spm.stats.con.consess{1,2}.tcon.name = 'Negative_Effect';
                matlabbatch{3}.spm.stats.con.consess{1,2}.tcon.convec = -1;
                
                % make estimation
                spm_jobman( 'run', matlabbatch );
                clear matlabbatch;
                
                %%%%%%%%%%%%%%%%%%%%%%
                % Organize SPM files %
                %%%%%%%%%%%%%%%%%%%%%%
                disp( 'Organizing spmT files...' );
                
                % update log file with start time of SPM renaming
                t = clock;
                sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                str = sprintf('%s -  Start SPM renaming..', sTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
                
                % organizing spmT files into something more readable..
                fprintf('Renaming spmT files for: %s\n', subInfo.name);
                rest_copySPMfiles(subInfo, roiResultsPath, 'nii');
                rest_copySPMfiles(subInfo, fullSeriesName, 'img');
                rest_copySPMfiles(subInfo, fullSeriesName, 'hdr');
                
                % ----------------------------------------------------------------------------------------
                endTime = clock;
                totalTime = etime( endTime, startTime );
                sTime = [ num2str( startTime(4), '%0.2d' ) ':' num2str( startTime(5), '%0.2d' ) ':' num2str( round (startTime(6) ), '%0.2d' ) ];
                endTime = [ num2str( endTime(4), '%0.2d' ) ':' num2str( endTime(5), '%0.2d' ) ':' num2str( round (endTime(6) ), '%0.2d' ) ];
                totalTime = [ num2str( floor( totalTime/3600 ), '%0.2d' ) ':' num2str( floor( mod(totalTime,3600)/60 ), '%0.2d' ) ':' num2str( round ( mod(totalTime,60) ), '%0.2d' ) ];
                disp( '------------------------- Quick Summary ---------------------' );
                disp( [ 'Start time - ' sTime ] );
                disp( [ 'End   time - ' endTime ] );
                fprintf( logFID, '\n%s\n', [ 'End   time - ' endTime ] );
                disp( [ 'Total time - ' totalTime ] );
                fprintf( logFID, '%s\n', [ 'Total time - ' totalTime ] );
                status_flag = 1;
                fprintf('\n\n');
                
            end
        end
    else
        errorStr = sprintf('Failed to find the rest session');
        warning( errorStr );
        fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
    end
    
catch me
    endTime = clock;
    totalTime = etime( endTime, startTime );
    sTime = [ num2str( startTime(4), '%0.2d' ) ':' num2str( startTime(5), '%0.2d' ) ':' num2str( round (startTime(6) ), '%0.2d' ) ];
    endTime = [ num2str( endTime(4), '%0.2d' ) ':' num2str( endTime(5), '%0.2d' ) ':' num2str( round (endTime(6) ), '%0.2d' ) ];
    totalTime = [ num2str( floor( totalTime/3600 ), '%0.2d' ) ':' num2str( floor( mod(totalTime,3600)/60 ), '%0.2d' ) ':' num2str( round ( mod(totalTime,60) ), '%0.2d' ) ];
    disp( '------------------------- Quick Summary ---------------------' );
    disp( [ 'Start time - ' sTime ] );
    disp( [ 'Error time - ' endTime ] );
    fprintf( logFID, '\n%s\n', [ 'Error time - ' endTime ] );
    fprintf( logFID, 'Error msg - %s (line: %d)\n', me.message, me.stack(1).line);
    disp( [ 'Total time - ' totalTime ] );
    fprintf( logFID, '%s\n', [ 'Total time - ' totalTime ] );
    fclose( logFID );
    tempErrStr = lasterr;
    tempIndex = strfind( tempErrStr, '==>' );
    tempErrStr( tempIndex:tempIndex+2 ) = [];
    tempIndex = strfind( tempErrStr, 10 );
    tempErrStr( tempIndex ) = ':';
    disp( tempErrStr );
    
    % throw the error
    rethrow(me)
end

if (status_flag == 1)
    fprintf( logFID, '\nYAY!, Rest processing ended successfully! :) \n\n' );
end

fclose( logFID );
% let's open the log file and make sure everything is ok..
filename = fullfile( subPath, 'Logs', [ subInit '_processRestClinic_' dateStr '.log' ] );

if exist(filename, 'file')
    winopen(filename)
end
end