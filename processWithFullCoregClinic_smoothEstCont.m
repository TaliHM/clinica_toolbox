function [subInfo, status_flag] = processWithFullCoregClinic_smoothEstCont(subInfo, pTable, smooth, est, contrast, create4D)

% Batch script for preprocessing the fMRI tests of the clinic
% (used to be the function process_withFullCoregistration.mat)

startTime = clock;
FileVersion = 'v1.0';  %07.02.2016 - THM
status_flag = 0;

% updating waitbar
step = 1;
str = sprintf('Initializing SPM12\n');
h = waitbar(step/100, str,...
    'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');

fprintf('\n\nInitializing SPM12...\n');
spm_jobman('initcfg');
spm('defaults','FMRI');

%------------------------ Setting initial parameters %--------------------------
subPath = subInfo.path;
templatePath = subInfo.parameters.templatePath;
fileTemplate = [subInfo.parameters.fileTemplate '_']; % e.g. 'vol_'
volumesFormat = subInfo.parameters.volumesFormat; % 'nii' or 'img'
%-------------------------------------------------------------------------------

% setting up the log folder
if ~exist( fullfile( subPath, 'Logs' ) ,'file'),
    mkdir( fullfile( subPath, 'Logs' ) );
end

dateStr = [num2str(startTime(3),'%0.2d') '-' num2str(startTime(2),'%0.2d') '-' num2str(startTime(1)) ];

% create subject initials
subInit = createSubInitials(subInfo);

% updating log file
logFID = fopen( fullfile( subPath, 'Logs', [ subInit '_processWithFullCoregClinic_' dateStr '.log' ] ), 'at' ); %used to be wt
fprintf( logFID, '\n\n%s (%s) - Processing with full coregistration - part II \n', subInfo.name, subInit);
fprintf( logFID, '-------------------------------------------------------------------\n' );
fprintf( logFID, [ 'processed with: processWithFullCoregClinic_smoothEstCont.m (version ' FileVersion ')\n' ] );
fprintf( logFID, '\n%s\n', dateStr );
fprintf( logFID, '--------------\n' );

fprintf( logFID, 'Subject''s folder: %s\n\n', subPath );

try
    disp( [ 'Process script version: ' FileVersion  ] );
    
    % setting the path to the anat folder and the func folder
    analysisPath = fullfile( subPath, 'Analysis' );
    anatomyPath = fullfile( analysisPath, 'anat' );
    funcPath = fullfile( analysisPath, 'func' );
    
    % we take only what is marked!
    logicals = cell2mat(pTable(:,1));
    pTable(logicals == 0,:) = [];
    
    %     % let's see if fMRIsession field exist - and if it does we'll go over it
    %     % and coregister them one by one
    fields = subInfo.fMRIsession;
    fieldnameToAccess = sort(fieldnames(fields));
    
    for i = 1:size(pTable, 1)
        
        % find the corresponding field in subInfo
        for k = 1:size(fieldnameToAccess)
            if str2double(pTable{i,2}) == fields.(fieldnameToAccess{k}).seriesNumber
                break
            end
        end
        
        seriesNumber= fields.(fieldnameToAccess{k}).seriesNumber;
        seriesDescription = fields.(fieldnameToAccess{k}).seriesDescription;
        fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
        
        % setting the path to the current series func folder
        fullSeriesFuncPath = fullfile(funcPath, fullSeriesName);
        
        % --------------------------------------------------------------------------
        % now we set the processing status straight from the subject's current
        % scanning session
        SMOOTH = smooth;
        ESTIMATE = est;
        CONTRAST = contrast;
        
        sliceTimingPrefix = ['a' fileTemplate];
        realignPrefix = ['r' sliceTimingPrefix];
        coregPrefix = ['r' realignPrefix];
        SmoothPrefix = ['s' coregPrefix];
        
        if isempty(~strfind(fullSeriesName, 'Rest'))
            fprintf('\nProcessing %s \nSmooth: %d\nEstimate: %d\nContrast: %d\n\n',...
                [subInit '_' fullSeriesName], smooth, est, contrast);
        else
            fprintf('\nProcessing %s \nSmooth: %d\n\n',...
                [subInit '_' fullSeriesName], smooth);
        end
        
        % --------------------------------------------------------------------------
        
        if (sum([smooth, est, contrast]) == 0)
            str = sprintf('\n%s - already underwent second processing stage.', fullSeriesName);
            disp( str );
            % fprintf( logFID, '%s\n', str );
        else
            
            % updating log file
            fprintf( logFID, '%s\n', fullSeriesName);
            fprintf( logFID, '---------------------------------\n' );
            
            % Extracting Series parameters
            % the current series name is saed in the structure in lowercase letters
            % and no brackets. we need to change the curernt series name (which is
            % with uppercases and brackets) so we can find it in the structure.
            sName = regexp(lower(fullSeriesName), '\w*[^(\d*rep)]*', 'match');
            fieldname = strjoin(sName,'_');
            
            % if its an EEG-fMRI session we are processing it differently - all
            % sessions at one (and not one by one as we used to in the ordinary fmri
            % scans
            isEEG = regexp(lower(fieldname), 'eeg_fmri', 'match');
            
            if ~isempty(isEEG)
                fprintf( logFID, 'IMPROTANT!! This is an EEG_fMEI Analysis (all sessions are processed at once at all stages)\n\n');
                
                % first we check if there is relevant field in the relevant
                % session in subInfo.fMRIsession, or else we take if from
                % the general parameters
                if isfield(subInfo.fMRIsession.(fieldname), 'nFirstVolumesToSkip')
                    nFirstVolumesToSkip = subInfo.fMRIsession.(fieldname).nFirstVolumesToSkip;
                elseif isfield(subInfo.fMRIsession.parameters, 'nFirstVolumesToSkip_eeg')
                    nFirstVolumesToSkip = subInfo.parameters.nFirstVolumesToSkip_eeg;
                else
                    nFirstVolumesToSkip = subInfo.parameters.nFirstVolumesToSkip;
                end
                
                % smooth size
                if isfield(subInfo.fMRIsession.(fieldname), 'smoothSize')
                    smoothSize = subInfo.fMRIsession.(fieldname).smoothSize;
                elseif isfield(subInfo.fMRIsession.parameters, 'smoothSize_eeg')
                    smoothSize = subInfo.parameters.smoothSize_eeg;
                else
                    smoothSize = subInfo.parameters.smoothSize;
                end
                
                % lag
                if isfield(subInfo.fMRIsession.(fieldname), 'lag')
                    lag = subInfo.fMRIsession.(fieldname).lag;
                elseif isfield(subInfo.fMRIsession.parameters, 'lag_eeg')
                    lag = subInfo.parameters.lag_eeg;
                else
                    lag = subInfo.parameters.lag;
                end
                
            else
                % first we check if there is relevant field in the relevant
                % session in subInfo.fMRIsession, or else we take if from
                % the general parameters
                if isfield(subInfo.fMRIsession.(fieldname), 'nFirstVolumesToSkip')
                    nFirstVolumesToSkip = subInfo.fMRIsession.(fieldname).nFirstVolumesToSkip;
                elseif isfield(subInfo.fMRIsession.parameters, 'nFirstVolumesToSkip_fmri')
                    nFirstVolumesToSkip = subInfo.parameters.nFirstVolumesToSkip_fmri;
                else
                    nFirstVolumesToSkip = subInfo.parameters.nFirstVolumesToSkip;
                end
                
                % smooth size
                if isfield(subInfo.fMRIsession.(fieldname), 'smoothSize')
                    smoothSize = subInfo.fMRIsession.(fieldname).smoothSize;
                elseif isfield(subInfo.fMRIsession.parameters, 'smoothSize_fmri')
                    smoothSize = subInfo.parameters.smoothSize_fmri;
                else
                    smoothSize = subInfo.parameters.smoothSize;
                end
                
                % lag
                if isfield(subInfo.fMRIsession.(fieldname), 'lag')
                    lag = subInfo.fMRIsession.(fieldname).lag;
                elseif isfield(subInfo.fMRIsession.parameters, 'lag_fmri')
                    lag = subInfo.parameters.lag_fmri;
                else
                    lag = subInfo.parameters.lag;
                end
            end
            
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
            % Smoothing %
            %%%%%%%%%%%%%
            % This is for smoothing (or convolving) image volumes with a Gaussian
            % kernel of a specified width. It is used as a preprocessing step to
            % suppress noise and effects due to residual differences in functional
            % and gyral anatomy during inter-subject averaging.
            % The smoothed images are written to the same subdirectories as
            % the original images and are prefixed with a ’s’.
            
            if( SMOOTH )
                disp( 'Smoothing' );
                
                % updating waitbar
                step = 10;
                curProcess = 'Applying smoothing';
                str = sprintf('%s  (%d/%d sessions)\n%s..',...
                    [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                waitbar(step/100, h, str,...
                    'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                
                % update log file with start time of smoothing
                t = clock;
                sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                str = sprintf('%s - Start Smoothing..', sTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
                
                % clear matlabbatch variable
                clear matlabbatch;
                
                % loading the matlabbatch template file
                load( fullfile(  templatePath, 'Smooth_template.mat' ) );
                
                if ~isempty(isEEG)
                    matlabbatch = updateMatlabatch4eegProcess(subInfo, pTable, matlabbatch, 'smooth', logFID);
                else
                    % searching for the files that underwent coregistration (these
                    % are the files with the 'rra' e.g.: 'rravol_*.nii)
                    d = dir( fullfile( fullSeriesFuncPath, [ coregPrefix '*.' volumesFormat ] ) );
                    files = { d.name }';
                    
                    % making sure that the dir function does not mess with the file
                    % order
                    str  = sprintf('%s#', files{:});
                    s = [coregPrefix '%d.nii#'];
                    num  = sscanf(str, s);
                    [dummy, index] = sort(num);
                    files = files(index);
                    
                    % now we enter the images that need to be smoothed
                    matlabbatch{1}.spm.spatial.smooth.data = cellstr( strcat( [ fullSeriesFuncPath '\' ], files, ',1' ) );
                    %matlabbatch{1}.spm.spatial{jj}.smooth.data = cellstr( strcat( [ funcPath '\' fullSeriesName '\' ], files, ',1' ) );
                end
                
                % if we specified the full-width at half maximum (FWHM) of the
                % Gaussiam smoothing kernel in mm
                fwhm(1:3) = smoothSize;
                matlabbatch{1}.spm.spatial.smooth.fwhm = fwhm;
                
                % This will smooth the data by (the default) smoothSize variable (=4)
                % in each direction, the default smoothing kernel width.
                spm_jobman( 'run', matlabbatch );
            end
            
            
            % files without PRT files will not undergo estimation and
            % contrast preprocessing.
            % we are not doing any estimation or contrast definition for rest
            % series or er-fmri series
            if isfield(subInfo.fMRIsession.(fieldname), 'prtFile')
                %~isequal(subInfo.fMRIsession.(fieldname).seriesDescription, 'Rest')
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Estimation and Model specification %
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if( ESTIMATE )
                    disp( 'Specify 1st Level ' );
                    
                    if create4D
                        create4DperSlice(subInfo, pTable(i,:), logFID, h)
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%
                    % MODEL SPECIFICATION %
                    %%%%%%%%%%%%%%%%%%%%%%%
                    
                    % updating waitbar
                    step = step + 10;
                    curProcess = 'Applying model specification';
                    str = sprintf('%s  (%d/%d sessions)\n%s..',...
                        [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                    waitbar(step/100, h, str,...
                        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                    
                    % update log file with start time of model specification
                    t = clock;
                    sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                    str = sprintf('%s -  Start Specifying 1st Level Model..', sTime );
                    disp( str );
                    fprintf( logFID, '%s\n', str );
                    
                    clear matlabbatch;
                    
                    % loading the matlabbatch template file and 2 mat files needed for
                    % moder specification
                    load( fullfile(  templatePath, 'SpecifyModel_template.mat' ) );
                    
                    % searching for the files that underwent coregistration (these
                    % are the files with the 'rra' e.g.: 'rravol_*.nii)
                    d = dir( fullfile( fullSeriesFuncPath, [ SmoothPrefix '*.' volumesFormat ] ) );
                    files = { d.name }';
                    
                    % making sure that the dir function does not mess with the file
                    % order
                    str  = sprintf('%s#', files{:});
                    s = [SmoothPrefix '%d.nii#'];
                    num  = sscanf(str, s);
                    [dummy, index] = sort(num);
                    files = files(index);
                    
                    % let's make sure we have the right number of volumes to process
                    nRep = regexp(subInfo.fMRIsession.(fieldname).seriesDescription, '(\d)+[^rep]', 'match');
                    nRep = str2num(nRep{:});
                    numberOfVolumesToProcess = nRep - nFirstVolumesToSkip;
                    
                    if( numberOfVolumesToProcess ~= length( files ) ),
                        errorStr = sprintf('Wrong number of volume files - should be %s, found %s',  num2str(nRep),  num2str(length( files )));
                        warning( errorStr );
                        fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
                    end
                    
                    matlabbatch{1}.spm.stats.fmri_spec.dir = cellstr( fullSeriesFuncPath );
                    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = seriesTR;
                    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = cellstr( strcat( [ fullSeriesFuncPath '/' ], files, ',1' ) );
                    
                    % entering the condition names, onsets, and durations
                    condNames = subInfo.fMRIsession.(fieldname).condNames;
                    condOnsets = subInfo.fMRIsession.(fieldname).condOnsets;
                    condDurations = subInfo.fMRIsession.(fieldname).condDurations;
                    
                    for curCond = 1:size(condNames,2),
                        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(curCond).name = condNames{curCond};
                        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(curCond).onset = condOnsets(:,curCond) + lag * seriesTR;
                        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(curCond).duration = condDurations(1:size(condOnsets,1),curCond);
                    end
                    
                    % high pass filter (in seconds):
                    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 3 * ( (condOnsets(2,1) - condOnsets(1,1) ) * seriesTR );
                    
                    % if there is old SPM we will delete it (soon we'll create a new
                    % SPM file with the next section of estimation..)
                    if exist(fullfile( fullSeriesFuncPath, 'SPM.mat' ) , 'file')
                        delete( fullfile( fullSeriesFuncPath, 'SPM.mat' )  );
                    end
                    
                    spm_jobman( 'run', matlabbatch );
                    
                    
                    %%%%%%%%%%%%%%
                    % ESTIMATION %
                    %%%%%%%%%%%%%%
                    disp( 'Estimating' );
                    
                    
                    % updating waitbar
                    step = step + 10;
                    curProcess = 'Applying estimation';
                    str = sprintf('%s  (%d/%d sessions)\n%s..',...
                        [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                    waitbar(step/100, h, str,...
                        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                    
                    % update log file with start time of estimation
                    t = clock;
                    sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                    str = sprintf('%s -  Start Estimation..', sTime );
                    disp( str );
                    fprintf( logFID, '%s\n', str );
                    
                    clear matlabbatch;
                    
                    % loading the matlabbatch template file
                    load( fullfile(  templatePath, 'EstimateModel_template.mat' ) );
                    
                    % specifying the location of the SPM.mat file
                    matlabbatch{1}.spm.stats.fmri_est.spmmat = {fullfile( fullSeriesFuncPath, 'SPM.mat' )};
                    
                    spm_jobman( 'run', matlabbatch );
                end
                
                
                %%%%%%%%%%%%
                % Contrast %
                %%%%%%%%%%%%
                if( CONTRAST )
                    disp( 'Contrast definitions..' );
                    
                    % updating waitbar
                    step = step + 30;
                    curProcess = 'Applying contrast definitions';
                    str = sprintf('%s  (%d/%d sessions)\n%s..',...
                        [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                    waitbar(step/100, h, str,...
                        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                    
                    % update log file with start time of contrast definitions
                    t = clock;
                    sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                    str = sprintf('%s -  Start Contrast definitions..', sTime );
                    disp( str );
                    fprintf( logFID, '%s\n', str );
                    
                    clear matlabbatch;
                    
                    % loading the matlabbatch template file
                    load( fullfile(  templatePath, 'Contrasts_template.mat' ) );
                    
                    % Reading the relevant volumes for contrast
                    % searching for the files that underwent smoothing (these
                    % are the files with the 'srra' prefix or 'swra', e.g.: 'sravol_*.nii or swravol_*.nii, respectively)
                    d = dir( fullfile( fullSeriesFuncPath, [ SmoothPrefix '*.' volumesFormat ] ) );
                    files = { d.name }';
                    
                    % making sure that the dir function does not mess with the file
                    % order
                    str  = sprintf('%s#', files{:});
                    s = [SmoothPrefix '%d.nii#'];
                    num  = sscanf(str, s);
                    [dummy, index] = sort(num);
                    files = files(index);
                    
                    % specifying the location of the SPM.mat file
                    matlabbatch{1}.spm.stats.con.spmmat = cellstr( fullfile( fullSeriesFuncPath, 'SPM.mat' ) );
                    
                    if isfield(subInfo.fMRIsession.(fieldname), 'contrasts')
                        contrastList = subInfo.fMRIsession.(fieldname).contrasts;
                        
                        % doing (2+mm) because there is 2 default contrast (positive effect and negative effect)
                        % that it does so we begin from 3.
                        % we copy the name of the contrast and its wieghts
                        for curContrast = 1:size( contrastList, 1 ),
                            matlabbatch{1}.spm.stats.con.consess{2+curContrast}.tcon.name = contrastList{ curContrast, 1 };
                            matlabbatch{1}.spm.stats.con.consess{2+curContrast}.tcon.convec = contrastList{ curContrast, 2 };
                            matlabbatch{1}.spm.stats.con.consess{2+curContrast}.tcon.sessrep = 'none';
                        end
                    end
                    
                    % make statistics
                    spm_jobman( 'run', matlabbatch );
                    
                    %%%%%%%%%%%%%%%%%%%%%%
                    % Organize SPM files %
                    %%%%%%%%%%%%%%%%%%%%%%
                    disp( 'Organizing spmT files...' );
                    
                    % updating waitbar
                    step = step + 10;
                    curProcess = 'Organizing spmT files';
                    str = sprintf('%s  (%d/%d sessions)\n%s..',...
                        [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                    waitbar(step/100, h, str,...
                        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                    
                    
                    % update log file with start time of SPM renaming
                    t = clock;
                    sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                    str = sprintf('%s -  Start SPM renaming..', sTime );
                    disp( str );
                    fprintf( logFID, '%s\n', str );
                    
                    % organizing spmT files into something more readable..
                    fprintf('\nRenaming spmT files for: %s\n', subInfo.name);
                    copySPMfiles(subInfo, fullSeriesName, 'nii');
                    copySPMfiles(subInfo, fullSeriesName, 'img');
                    copySPMfiles(subInfo, fullSeriesName, 'hdr');
                end
            end
            
            % ----------------------------------------------------------------------------------------
            
            % updating waitbar
            step = 90;
            curProcess = 'Updaing log file';
            str = sprintf('%s  (%d/%d sessions)\n%s..',...
                [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
            waitbar(step/100, h, str,...
                'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
            
            endTime = clock;
            totalTime = etime( endTime, startTime );
            sTime = [ num2str( startTime(4), '%0.2d' ) ':' num2str( startTime(5), '%0.2d' ) ':' num2str( round (startTime(6) ), '%0.2d' ) ];
            endTime = [ num2str( endTime(4), '%0.2d' ) ':' num2str( endTime(5), '%0.2d' ) ':' num2str( round (endTime(6) ), '%0.2d' ) ];
            totalTime = [ num2str( floor( totalTime/3600 ), '%0.2d' ) ':' num2str( floor( mod(totalTime,3600)/60 ), '%0.2d' ) ':' num2str( round ( mod(totalTime,60) ), '%0.2d' ) ];
            fprintf( '------------------------- %s - Quick Summary ---------------------\n', subInfo.name );
            disp( [ 'Start time - ' sTime ] );
            disp( [ 'End   time - ' endTime ] );
            fprintf( logFID, '\n%s\n', [ 'End   time - ' endTime ] );
            disp( [ 'Total time - ' totalTime ] );
            fprintf( logFID, '%s\n', [ 'Total time - ' totalTime ] );
            status_flag = 1;
            fprintf('\n\n');
        end
        
        % if it's an eeg-fmri session - we analyse all sessions at once, so
        % one we've done with that - we can stop the process
        if ~isempty(isEEG)
            break
        end
        
    end
    
catch me
    endTime = clock;
    totalTime = etime( endTime, startTime );
    sTime = [ num2str( startTime(4), '%0.2d' ) ':' num2str( startTime(5), '%0.2d' ) ':' num2str( round (startTime(6) ), '%0.2d' ) ];
    endTime = [ num2str( endTime(4), '%0.2d' ) ':' num2str( endTime(5), '%0.2d' ) ':' num2str( round (endTime(6) ), '%0.2d' ) ];
    totalTime = [ num2str( floor( totalTime/3600 ), '%0.2d' ) ':' num2str( floor( mod(totalTime,3600)/60 ), '%0.2d' ) ':' num2str( round ( mod(totalTime,60) ), '%0.2d' ) ];
    fprintf( '------------------------- %s - Quick Summary ---------------------\n', subInfo.name );
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
    fprintf( logFID, '\nYAY!, Part II of preprocessing ended successfully! :) \n\n' );
end

fclose( logFID );

step = 100/100;
waitbar(step, h, sprintf('Finished!'))
pause(0.1)
close(h);

% let's open the log file and make sure everything is ok..
filename = fullfile( subPath, 'Logs', [ subInit '_processWithFullCoregClinic_' dateStr '.log' ] );

if exist(filename, 'file')
    winopen(filename)
end

end