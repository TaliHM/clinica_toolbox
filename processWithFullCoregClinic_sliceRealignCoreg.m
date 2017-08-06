function [subInfo, status_flag] = processWithFullCoregClinic_sliceRealignCoreg(subInfo, pTable, sliceTiming, realign, coreg)

% Batch script for preprocessing the fMRI tests of the clinic
% (used to be the function process_withFullCoregistration.mat)

% fclose all; clear; clc;
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
maxTranslation = subInfo.parameters.maxTranslation;   % max allowed motion correction (mm)
maxRotation = subInfo.parameters.maxRotation;    % max allowed rotation (degrees)
acquisitionOrder = subInfo.parameters.acquisitionOrder; % set the series acquisition order : bottom-up (1) or top-down (0)
%-------------------------------------------------------------------------------

% setting subject's initials
subInit = createSubInitials(subInfo);

% setting up the log folder
if ~exist( fullfile( subPath, 'Logs' ) ,'file'),
    mkdir( fullfile( subPath, 'Logs' ) );
end

dateStr = [num2str(startTime(3),'%0.2d') '-' num2str(startTime(2),'%0.2d') '-' num2str(startTime(1)) ];

% updating log file
logFID = fopen( fullfile( subPath, 'Logs', [ subInit '_processWithFullCoregClinic_' dateStr '.log' ] ), 'at' ); %used to be wt
fprintf( logFID, '%s (%s) - Processing with full coregistration - part I \n', subInfo.name, subInit);
fprintf( logFID, '-------------------------------------------------------------------\n' );
fprintf( logFID, [ 'processed with: processWithFullCoregClinic_sliceRealignCoreg.m (version ' FileVersion ')\n' ] );
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
    
    % let's see if fMRIsession field exist - and if it does we'll go over it
    % and coregister them one by one
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
        SLICE_TIMING = sliceTiming;
        REALIGN = realign;
        COREGISTRATION = coreg;
        
        sliceTimingPrefix = ['a' fileTemplate];
        realignPrefix = ['r' sliceTimingPrefix];
        coregPrefix = ['r' realignPrefix];
        
        fprintf('\nProcessing %s \nSlice timing: %d\nRealign: %d\nCoregistration: %d\n\n',...
            [subInit '_' fullSeriesName], sliceTiming, realign, coreg);
        % --------------------------------------------------------------------------
        
        if (sum([sliceTiming, realign, coreg]) == 0)
            str = sprintf('%s - already underwent first processing stage.', fullSeriesName);
            disp( str );
            % fprintf( logFID, '%s\n', str );
        else
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
            
            % check if there is SPGR file - if not - copying the existing file.
            if isempty(dir(fullfile( subPath, 'viewer', 'SPGR*.nii' )))
                source = fullfile( anatomyPath, anatomyfile );
                destination = fullfile( subPath, 'viewer');
                copyfile( source, destination );
            end
            
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
            str = sprintf('TR of is %s seconds.\n', num2str(seriesTR));
            fprintf( logFID, str );
            
            % Check if files are in 3D (taken from vol_*.nii file)
            vol_niftiFiles = dir( fullfile( fullSeriesFuncPath, [ fileTemplate, '*.' volumesFormat ] ) );
            hdr = load_nii_hdr( fullfile( fullSeriesFuncPath, vol_niftiFiles(1).name ) );
            
            if( hdr.dime.dim(1) ~= 3),
                errorStr = sprintf('Files for series %s are not 3D!', fullSeriesName);
                fprintf( logFID, '\n\nError: %s\n', errorStr );
                error( errorStr );
            end
            
            % Get number of slices in each volume (taken from vol_*.nii file)
            nSlices = hdr.dime.dim(4);
            str = sprintf('Number of slices is %s.\n\n', num2str( nSlices )) ;
            fprintf( logFID, str);
            
            cd(fullSeriesFuncPath);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Slice-timing correction %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Correct differences in image acquisition time between slices.
            % Slice-time corrected files are prepended with an ’a’.
            % Note: The sliceorder arg that specifies slice acquisition order is a
            % vector of N numbers, where N is the number of slices per volume.
            % Each number refers to the position of a slice within the image file.
            % The order of numbers within the vector is the temporal order in which
            % those slices were acquired.
            
            if( SLICE_TIMING )
                disp( 'SLICE TIMING' );
                
                % updating waitbar
                step = 10;
                curProcess = 'Applying slice timing correction';
                str = sprintf('%s  (%d/%d sessions)\n%s..',...
                    [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                waitbar(step/100, h, str,...
                    'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                
                % update log file with start time of slice timing
                t = clock;
                sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                str = sprintf('%s - Start Slice timing..', sTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
                
                matlabbatch{1}.spm.temporal.st.tr = seriesTR;
                matlabbatch{1}.spm.temporal.st.nslices = nSlices;
                matlabbatch{1}.spm.temporal.st.ta = seriesTR - (seriesTR / nSlices); % TR-(TR/nSlices)
                
                if ~isempty(isEEG)
                    matlabbatch = updateMatlabatch4eegProcess(subInfo, pTable, matlabbatch, 'sliceTiming', logFID);
                else
                    % first let's look for the original files (strating with
                    % 'vol_*.nii)
                    % Skipping the first few fMRI volumes..
                    files = { vol_niftiFiles(nFirstVolumesToSkip+1:end).name }';
                    
                    % making sure that the dir function does not mess with the file
                    % order.
                    str  = sprintf('%s#', files{:});
                    s = [fileTemplate '%d.nii#'];
                    num  = sscanf(str, s);
                    [dummy, index] = sort(num);
                    files = files(index);
                    
                    % set the session folder of the current subject, the TR, number
                    % of slices and TA
                    matlabbatch{1}.spm.temporal.st.scans{1} = cellstr( strcat( [fullSeriesFuncPath '\'] , files, ',1' ) );
                end
                
                % set the series acquisition order : bottom-up or reversed
                if acquisitionOrder,
                    %interleaved (bottom --> up)
                    matlabbatch{1}.spm.temporal.st.so = [ nSlices:-2:1 nSlices-1:-2:1 ];
                else
                    %interleaved (top --> down)
                    matlabbatch{1}.spm.temporal.st.so = [ 1:2:nSlices 2:2:nSlices ];
                end
                
                % set the reference slice - slice index of the reference slice
                matlabbatch{1}.spm.temporal.st.refslice = 1;
                
                
                % make slice timing correction
                spm_jobman( 'run', matlabbatch );
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Realignment (estimate and reslice) %
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % This routine realigns a time-series of images acquired from the same
            % subject using a least squares approach and a 6 parameter (rigid body)
            % spatial transformation. The first image in the list specified by
            % the user is used as a reference to which all subsequent scans are realigned.
            % A set of realignment parameters are saved for each session, named rp_*.txt
            % After realignment, the images are resliced such that they match the
            % first image selected voxel-for-voxel.
            % in addition to reslicing the images, it also creates a mean of the
            % resliced image (e.g. mean*.nii).
            % The resliced images are named the same as the originals, except that
            % they are prefixed by ’r’.
            
            if( REALIGN )
                disp( 'REALIGNING' );
                
                % updating waitbar
                step = step + 30;
                curProcess = 'Applying realignment';
                str = sprintf('%s  (%d/%d sessions)\n%s..',...
                    [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                waitbar(step/100, h, str,...
                    'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                
                % update log file with start time of realignment
                t = clock;
                sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                str = sprintf('%s - Start Realignment..', sTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
                
                % clear matlabbatch variable
                clear matlabbatch;
                
                % loading the matlabbatch template file
                load( fullfile(  templatePath, 'Realign_Estimate&Reslice_template.mat' ) );
                
                if ~isempty(isEEG)
                    matlabbatch = updateMatlabatch4eegProcess(subInfo, pTable, matlabbatch, 'realign', logFID);
                else
                    % searching for the files that underwent slice timing (these
                    % are the files with the 'a' prefix, e.g.: 'avol_*.nii))
                    d = dir( fullfile( fullSeriesFuncPath, [ sliceTimingPrefix '*.' volumesFormat ] ) );
                    files = { d.name }';
                    
                    % making sure that the dir function does not mess with the file
                    % order
                    str  = sprintf('%s#', files{:});
                    s = [sliceTimingPrefix '%d.nii#'];
                    num  = sscanf(str, s);
                    [dummy, index] = sort(num);
                    files = files(index);
                    
                    % save these files to the template
                    matlabbatch{1}.spm.spatial.realign.estwrite.data{1} = cellstr( strcat( [ fullSeriesFuncPath '\' ], files, ',1' ) );
                end
                
                % This will run the realign job which will write realigned images
                % into the directory where the functional images are.
                % These new images will be prefixed with the letter “r”.
                % SPM will then plot the estimated time series of translations and rotations.
                % SPM will also create a mean image eg. meansM03953_0005_0006.{hdr,img} which will be
                % used in the next step of spatial processing - coregistration.
                spm_jobman( 'run', matlabbatch );
                
                % Checking the realignment report
                reportFile = dir( fullfile( fullSeriesFuncPath, 'rp_*.txt' ) );
                if( length( reportFile ) > 1 ),
                    errorStr = sprintf('Two realign parameters files were found!');
                    fprintf( logFID, '\n\nError: %s\n', errorStr );
                    error( errorStr );
                end
                
                % Taking the translation (t1 - t3) and rotation (r1 - r3) parameters from
                % the report file
                [ t1, t2, t3, r1, r2, r3, ] = textread( fullfile( fullSeriesFuncPath, reportFile.name ), '%f %f %f %f %f %f' );
                
                % Checking if the translation (t1 - t3) was within allowed range
                translationParameters =  [ t1 t2 t3 ];
                max_translationValue = max( abs( translationParameters(:) ) );
                if( max_translationValue > maxTranslation )
                    errorStr = sprintf('Max value for translation is %s, should be less than %s mm.',...
                        num2str(max_translationValue), num2str(maxTranslation));
                    warning( errorStr );
                    fprintf( logFID, '\nwarning !!! %s\n\n', errorStr );
                else
                    str = sprintf('- Max translation is %s mm.',  num2str(max_translationValue));
                    fprintf( logFID, '%s\n', str );
                end
                
                % checking if the rotation (r1 - r3) was within allowed range
                rotationParameters =  [ r1 r2 r3 ];
                max_rotationValue = max( abs( rotationParameters(:) ) );
                if ( max_rotationValue > maxRotation )
                    errorStr = sprintf('Max value for rotation is %s, should be less than %s dgrees.',...
                        num2str(max_rotationValue), num2str(maxTranslation));
                    warning( errorStr );
                    fprintf( logFID, '\nwarning !!! %s\n\n', errorStr );
                else
                    str = sprintf('- Max rotation is %s degrees.',  num2str(max_rotationValue));
                    fprintf( logFID, '%s\n\n', str );
                end
                
                % plotting realignment graphs of translation and rotation
                fontsize = 7;
                nVolumes = 1:length(t1);
                xmax = length(nVolumes);
                f = figure('Position', [100, 100, 900, 700]);
                
                % top subplot - for translation
                ax1 = subplot(2,1,1);
                hold on;
                plot(ax1, nVolumes, t1, 'Color', rgb('FireBrick'), 'LineWidth', 1);
                plot(ax1, nVolumes, t2, 'Color', rgb('ForestGreen'), 'LineWidth', 1);
                plot(ax1, nVolumes, t3, 'Color', rgb('RoyalBlue'), 'LineWidth', 1);
                set(gca, 'XLim', [0 xmax]);
                set(gca, 'XTick', [0:5:xmax]);
                
                ylabel( 'mm' );
                xlabel('Volumes');
                title( sprintf('Translation for: %s', fullSeriesName ), 'interpreter', 'none');
                legend(ax1, {'t1', 't2', 't3'}, 'FontSize', fontsize );
                
                % bottom subplot - for rotation
                ax2 = subplot(2,1,2);
                hold on
                plot(ax2, nVolumes, r1, 'Color', rgb('FireBrick'), 'LineWidth', 1);
                plot(ax2, nVolumes, r2, 'Color', rgb('ForestGreen'), 'LineWidth', 1);
                plot(ax2, nVolumes, r3, 'Color', rgb('RoyalBlue'), 'LineWidth', 1);
                set(gca, 'XLim', [0 xmax])
                set(gca, 'XTick', [0:5:xmax])
                
                ylabel( 'Degree' );
                xlabel('Volumes');
                title( sprintf('Rotation for: %s', fullSeriesName ), 'interpreter', 'none');
                legend(ax2, {'r1', 'r2', 'r3'}, 'FontSize', fontsize );
                
                % save the graph in the session folder
                saveas(f, fullfile(fullSeriesFuncPath, [reportFile.name(1:end-4) '_graph' ]), 'png')
                saveas(f, fullfile(fullSeriesFuncPath, [reportFile.name(1:end-4) '_graph' ]), 'fig')
                close(gcf);
            end
            
            %%%%%%%%%%%%%%%%%%%
            % Corregistration %
            %%%%%%%%%%%%%%%%%%%
            % Within-subject registration using a rigid-body model.
            % The images are also smoothed slightly, as is the histogram.
            % This is all in order to make the cost function as smooth as possible,
            % to give faster convergence and less chance of local minima.
            % At the end of coregistration, the voxel-to-voxel affine transformation
            % matrix is displayed, along with the histograms for the images in the
            % original orientations, and the final orientations.
            % Registration parameters are stored in the headers of the "source"
            % and the "other" images.
            % These images are also resliced to match the source image voxel-for-voxel.
            % The resliced images are named the same as the originals except that
            % they are prefixed by ’r’.
            
            if (COREGISTRATION)
                % we coregisterthe patient's data to the his \ her SPGR.
                disp( 'COREGISTRATION' );
                
                % updating waitbar
                step = step + 30;
                curProcess = 'Applying coregistration';
                str = sprintf('%s  (%d/%d sessions)\n%s..',...
                    [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
                waitbar(step/100, h, str,...
                    'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                
                % update log file with start time of coregistration
                t = clock;
                sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                str = sprintf('%s - Start Coregistration..', sTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
                
                % clear matlabbatch variable
                clear matlabbatch;
                
                % remember that in the realignment stage, in addition to reslicing
                % the images, it also creates a mean of the resliced image.
                % so we need it.
                meanfile = dir( fullfile( fullSeriesFuncPath, [ 'mean*.' volumesFormat ] ) );
                if isempty( meanfile )
                    errorStr = sprintf('Cant find file mean*.%s', volumesFormat );
                    fprintf( logFID, '\n\nError: %s\n', errorStr );
                    error( errorStr );
                elseif length( meanfile ) > 1,
                    errorStr = sprintf('More than one mean*.%s files!', volumesFormat);
                    fprintf( logFID, '\n\nError: %s\n', errorStr );
                    error( errorStr );
                end
                
                
                if ~isempty(isEEG)
                    % update log file
                    str = sprintf('Coregistration is done only with estimate (reslice will be done later, if required)');
                    disp( str );
                    fprintf( logFID, '%s\n', str );
                    
                    % loading the matlabbatch template file
                    load( fullfile(  templatePath, 'Coregister_Estimate_template.mat' ) );
                    
                    % set the image that is assumed to remain stationary (SPGR)
                    matlabbatch{1}.spm.spatial.coreg.estimate.ref = ...
                        cellstr( strcat( [ anatomyPath '\'  anatomyfile ], ',1' ) );
                    
                    % now we enter the mean file that will be jiggled about to best
                    % match the reference image (SPGR).
                    matlabbatch{1}.spm.spatial.coreg.estimate.source = ...
                        cellstr( strcat( [ fullSeriesFuncPath '\' meanfile.name ], ',1' ) );
                    
                    matlabbatch = updateMatlabatch4eegProcess(subInfo, pTable, matlabbatch, 'coreg', logFID);
                    
                else
                    load( fullfile(  templatePath, 'Coregister_Estimate&Reslice_template.mat' ) );
                    
                    % set the image that is assumed to remain stationary (SPGR)
                    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = ...
                        cellstr( strcat( [ anatomyPath '\'  anatomyfile ], ',1' ) );
                    
                    % now we enter the mean file that will be jiggled about to best
                    % match the reference image (SPGR).
                    matlabbatch{1}.spm.spatial.coreg.estwrite.source = ...
                        cellstr( strcat( [ fullSeriesFuncPath '\' meanfile.name ], ',1' ) );
                    
                    % searching for the files that underwent realignment (these
                    % are the files with the 'ra' prefix, e.g.: 'ravol_*.nii)
                    d = dir( fullfile( fullSeriesFuncPath, [ realignPrefix, '*.' volumesFormat ] ) );
                    files = { d.name }';
                    
                    % making sure that the dir function does not mess with the file
                    % order
                    str  = sprintf('%s#', files{:});
                    s = [realignPrefix '%d.nii#'];
                    num  = sscanf(str, s);
                    [dummy, index] = sort(num);
                    files = files(index);
                    
                    % now we enter the images that need to remain in alignment with the source image (the mean file)
                    % these are the ravol_*.nii files of the patient)
                    matlabbatch{1}.spm.spatial.coreg.estwrite.other = cellstr( strcat( [ fullSeriesFuncPath '\' ], files, ',1' ) );
                end
                
                % SPM will then implement a coregistration between the structural and functional data that
                % maximises the mutual information. SPM will have changed the header
                % of the source file which in this case is the structural image
                spm_jobman( 'run', matlabbatch );
                
                % Generating batch file for visualizing the coregistration with Mricron
                % mricronPath =  fullfile( subPath, 'viewer', 'mricron');
                meanFilePath = fullfile(fullSeriesFuncPath, meanfile.name );
                
                if ~isempty(isEEG)
                    s = {};
                    name = strtrim(pTable(:,2))';
                    name = cellfun(@str2num, name);
                    for n = 1:size(name, 2)
                        s{n} = num2str(name(n), '%0.2d');
                    end
                    
                    str = ['Se' strjoin(s, '_')];
                    cmdFile = fullfile( subPath, 'viewer', [ 'checkRegistration_EEG_fMRI_' str '.bat' ] );
                else
                    cmdFile = fullfile( subPath, 'viewer', [ 'checkRegistration_' fullSeriesName '.bat' ] );
                end
                
                batchFID = fopen( cmdFile , 'wt' );
                fprintf( batchFID,...
                    'start /MAX mricron .\\%s -o %s -l 300 -h 9999 -c -40',...
                    anatomyfile, meanFilePath);
                fclose( batchFID );
            end
            
            % clear matlabbatch variable
            clear matlabbatch;
            
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
            fprintf('\n');
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
    fprintf( logFID, '\nYAY!, Part I of preprocessing ended successfully! :) \n\n' );
end

fclose( logFID );
% % let's open the log file and make sure everything is ok..
% filename = fullfile( subPath, 'Logs', [ subInit '_processWithFullCoregClinic' dateStr '.log' ] );
% winopen(filename)

step = 100/100;
waitbar(step, h, sprintf('Finished!'))
pause(0.1)
close(h);
end