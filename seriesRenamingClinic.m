function [subInfo, status_flag] = seriesRenamingClinic(subInfo, pTable)
% the new and improved seriesRenamingClinic_new!!

% This script changes the name of MRI scans foldres.
% SeriesIndices - 2D array, where each row represent an fMRI series, and first column is the
% series number as designated by the MRI scanner (mri_idx), and second column is the
% series number according the clinical fMRI table (pTable_idx).
% NumberOfDirectionForDTI - Just for creating a folder name with the correct number of direction.
viewerPath = 'M:\clinica\pre-processing scripts\viewer_dir_template'; % the path to mricron program
FileVersion = 'v1'; %19.01.2016 - THM
status_flag = 0;

subPath = subInfo.path;
% creating seriesIndices array
% first column is the series number as designated by the MRI scanner (mri_idx)
% second column is the series number according the clinical fMRI table (pTable_idx).
logicals = cell2mat(pTable(:,1));
pTable(logicals == 0,:) = [];
mri_idx = pTable(:,2);
pTable_idx = pTable(:,5);
seriesIndices = str2double([mri_idx, pTable_idx]);
% seriesIndices = cellfun(@str2num, seriesIndices, 'UniformOutput', false);

% inserting [0,1] for DTI ?
%SeriesIndices = [0, 1; SeriesIndices];

% creating series names array
seriesNames = pTable(:,4);

% creating subject name and initials
subName = subInfo.name;
subInit = createSubInitials(subInfo);
fprintf('Current subject: %s (%s)\n', subName, subInit);
fprintf('seriesRenamingClinic.mat version: %s\n\n', FileVersion);

sTime = clock;
dateStr = [num2str(sTime(3),'%0.2d') '-' num2str(sTime(2),'%0.2d') '-' num2str(sTime(1)) ];
timeStr =  [num2str(sTime(4),'%0.2d') ':' num2str(sTime(5),'%0.2d')];

% creating Logs folder
if ~exist( fullfile( subPath, 'Logs' ) ,'file'), % create folder: Logs
    mkdir( fullfile( subPath, 'Logs' ) );
end


% updating log file
logFID = fopen( fullfile( subPath, 'Logs', [ subInit '_SeriesRenamingClinic_' dateStr '.log' ] ), 'at' ); %used to be wt
fprintf( logFID, '%s (%s) - Series renaming log file \n', subName, subInit);
fprintf( logFID, '-------------------------------------------------------------------\n' );
fprintf( logFID, [ 'processed with: seriesRenamingClinic.m (version ' FileVersion ')\n' ] );
fprintf( logFID, '\n%s\n', dateStr );
fprintf( logFID, '--------------\n' );
fprintf( logFID, 'Subject''s folder: %s\n\n', subPath );

try
    % checking if we have access to the protocolTable.xlsx file
    fprintf('uploading protocoleTable.xlsx file..\n\n')
    protocolPath = 'M:\protocols-new';
    protocolFile = 'ProtocolsTable.xls';
    pfile = fullfile(protocolPath, protocolFile);
    if ((exist(pfile, 'file')) == 2)
        [data, txt, protocolFile_raw]= xlsread(pfile);
        % [data, txt, protocolFile_raw]= xlsread(pfile, '', '', 'basic'); % basic for quicker reading
    else
        errorStr = 'Don''t have access to server fmri-t2. Please check network connection.';
        fprintf( logFID, '\n\nError: %s\n', errorStr );
        error( errorStr );
    end
    
    % creating Analysis, DTI and viewer folders in the subject's dir
    if ~exist( fullfile( subPath, 'Analysis' ),'dir' ), % create folder: Analysis
        mkdir( fullfile( subPath, 'Analysis' ) );
    end
    
    LIpath = fullfile( subPath, 'Analysis', 'LI');
    if ~exist(LIpath, 'dir')
        mkdir(LIpath);
    end
    
    dti_nDirections = subInfo.parameters.dti_nDirections;
    dtiFolder = ['DTI_' num2str( dti_nDirections )];

    if ~exist( fullfile( subPath, 'Analysis', dtiFolder, 'Fibers' ),'dir' ), % create folder: Fibers inside Analysis
        mkdir( fullfile( subPath, 'Analysis', dtiFolder, 'Fibers' ) );
    end
    
    if ~exist( fullfile( subPath, 'viewer' ) ,'dir'), % create folder: viewer
        mkdir( fullfile( subPath, 'viewer' ) );
        copyfile( viewerPath, fullfile( subPath, 'viewer' ) ); %copy "mricron" into it
    end
    
    % creating Analysis, DTI and viewer folders in the subject's dir
    if ~exist( fullfile( subPath, 'Raw_Data' ),'dir' ), 
        mkdir( fullfile( subPath, 'Raw_Data' ) );
    end
    
    % creating Analysis, DTI and viewer folders in the subject's dir
    if ~exist( fullfile( subPath, 'viewer', 'figures' ),'dir' ), 
        mkdir( fullfile( subPath, 'viewer', 'figures' ) );
    end
    
    if ~exist( fullfile( subPath, 'viewer', 'figures', 'multislice' ),'dir' ), 
        mkdir( fullfile( subPath, 'viewer', 'figures', 'multislice' ) );
    end
    
    
    isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
    if ~isempty(isEEG)
        if ~exist( fullfile( subPath, 'Spikes_xls' ),'dir' ),
            mkdir( fullfile( subPath, 'Spikes_xls' ) );
        end
        
        if ~exist( fullfile( subPath, 'EEG_Data' ),'dir' ),
            mkdir( fullfile( subPath, 'EEG_Data' ) );
        end
    end
    
    
    %     studyDir = dir(fullfile(subPath, 'Study*'));
    %
    %     if (length(studyDir) == 1)
    %         % enter to the study dir and show all series numbers
    %         studyDirName = studyDir.name;
    %         cd(fullfile(subPath, studyDirName))
    %     else
    %         studyDirName = '';
    %     end
    %
    %     studyPath = fullfile(subPath, studyDirName);
    %
    %     % creating a list with directories that start with: Series
    %     seriesDir = dir(fullfile(studyPath, 'Series*'));
    
    [studyPath, seriesDir] = getRawDataPath(subPath);
    
    if ~isempty(seriesDir)
        seriesDirName = {seriesDir.name}';
        
        % going over each Series..
        for ii = 1:size(seriesDirName,1),
            % curSeriesName_oldFormat - the name we recieve from the MRI scanner
            curSeriesName_oldFormat = seriesDirName{ii};
            
            % let's check how many dicom files in this directory
            dicomFiles = dir( fullfile( studyPath, curSeriesName_oldFormat, '*.dcm' ) );
            if( size( dicomFiles, 1 ) == 0 )
                errorStr = sprintf('Can''t find dicom files in folder: \n  %s', fullfile( studyPath, curSeriesName_oldFormat )) ;
                warning( errorStr );
                fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
                continue;
            end
            
            % let's get the info from the dcm file of the current series
            dcm = dicominfo( fullfile( studyPath, curSeriesName_oldFormat, dicomFiles(1).name ) );
            
            % now we need to make sure that we process only those
            % series that were checked in the gui.
            curSeries_pTableIndex = find( seriesIndices(:,1) == dcm.SeriesNumber );
            
            if (~isempty(curSeries_pTableIndex))
                %                     d.SeriesNumber = dcm.SeriesNumber;
                %                     d.SeriesDescription = dcm.SeriesDescription;
                
                % we analyze according to the scan type (either fMRI, DTI, mprage or flair)
                scanType = regexpi(lower(dcm.SeriesDescription), '(fmri|dti|mprage|flair|rest|spgr|fspgr)+[^(_| |-)]*', 'match');
                
                % if it is still empty, but maybe(maybe) its an fmri
                % session.., let's search the name in the protocol table...
                if isempty(scanType)
                    tasksList = lower(protocolFile_raw(:,3));
                    logicalArray = ~cellfun('isempty', strfind(tasksList, lower(dcm.SeriesDescription)));
                    
                    if (sum(logicalArray) > 0)
                        scanType = {'fmri'};
                    end
                end
                
                % if it is still(!) empty, let's try our luck and maybe
                % it's an eeg-fmri session - we'll check the path
                if isempty(scanType)
                    %isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
                    
                    if ~isempty(isEEG)
                        scanType = {'fmri'};
                    end
                end
                
                % one last chance - checking the 4th column to see if its
                % empty or not..
                if isempty(scanType)
                    taskColpTable = lower(pTable(:,4));
                    
                    if ~isempty(taskColpTable{curSeries_pTableIndex})
                        scanType = {'fmri'};
                    end
                end
                
                
                if ~isempty(scanType)
                    scanType = lower(scanType{1});
                end
                
                % if it is an fMRI series we need to do some additional
                % things before convering to nifti files..
                if (isequal(scanType, 'fmri') || isequal(lower(scanType), 'rest'))
                    
                    %%% Processing fMRI sessions!
                    subInfo = seriesRenamingClinic_fmri(subInfo, dcm, protocolFile_raw, pTable, curSeriesName_oldFormat, logFID);
                    
                    isRest = char(regexp(lower(dcm.SeriesDescription), 'rest', 'match'));
                    % if we are in the rest session - we do not have
                    % any number in col 2 - so we need to fill in the
                    % fields..
                    if isnan((seriesIndices(curSeries_pTableIndex,2)))
                        if ~isempty(isRest)
                            curSeriesName_newFormat = 'Rest';
                        else
                            %                             curSeriesName_newFormat = char(pTable(curSeries_pTableIndex,3));
                            %                             curSeriesName_newFormat = strrep(lower(curSeriesName_newFormat), 'fmri_', '');
                            curSeriesName_newFormat = strsplit(dcm.SeriesDescription, {'_', ' ', '-', '|'});
                            curSeriesName_newFormat = curSeriesName_newFormat(~cellfun('isempty',deblank(curSeriesName_newFormat)));
                            
                            %maybe it's an eeg-fmri session? we will know by checking the
                            %path
                            % searching for the Analysis in the path string and
                            % extracting the name before it
                            %isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
                            
                            if ~isempty(isEEG)
                                % checking the number of dicom files = number or repititons
                                d = dir(fullfile( studyPath, curSeriesName_oldFormat, '*.dcm' ));
                                curSeriesName_newFormat = sprintf('EEG_fMRI(%drep)', size(d, 1));
                            elseif size(curSeriesName_newFormat,2) == 1
                                a = strfind(lower(curSeriesName_newFormat), 'ft');
                                if ~isempty(a{:})
                                    sName = regexpi(curSeriesName_newFormat, '\w*[^(\d*rep)]*', 'match');
                                    sName = [sName{:}];
                                    curSeriesName_newFormat = [upper(sName{1}) '(' sName{2} ')' ];
                                else
                                    curSeriesName_newFormat = [curSeriesName_newFormat{:}];
                                end
                            else
                                curSeriesName_newFormat = regexprep(curSeriesName_newFormat,'(\<[a-z])','${upper($1)}');
                                curSeriesName_newFormat = strjoin(curSeriesName_newFormat, '_');
                            end
                            
                            
                        end
                        
                        fullSeriesName = ['Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat ];
                        curSeriesName_newFormat_path = fullfile( subPath, [ subInit '_' fullSeriesName]);
                        
                    else
                        % if we have two same series numbers - but they are related to
                        % different scans (like, e.g., one series was added from a previous
                        % scan).
                        % we need the fmri session - so if its a dti or spgr - nothing will be
                        % in the second column (that shows the number of protocol table index)
                        if (size(curSeries_pTableIndex, 1) > 1)
                            for k = 1:size(curSeries_pTableIndex,1)
                                if ~isnan(seriesIndices(curSeries_pTableIndex(k), 2))
                                    curSeriesName_newFormat = char(seriesNames(curSeries_pTableIndex(k)));
                                    curSeries_pTableIndex = curSeries_pTableIndex(k);
                                    break
                                end
                            end
                        else
                            curSeriesName_newFormat = char(seriesNames(curSeries_pTableIndex));
                        end
                        
                        curSeriesName_newFormat = char(seriesNames(curSeries_pTableIndex));
                        %                             curSeriesName_newFormat = strsplit(dcm.SeriesDescription, {'_', ' ', '-', '|'});
                        %                             curSeriesName_newFormat = curSeriesName_newFormat(~cellfun('isempty',deblank(curSeriesName_newFormat)));
                        %
                        %                             if size(curSeriesName_newFormat,2) == 1
                        %                                 a = strfind(lower(curSeriesName_newFormat), 'ft');
                        %                                 if ~isempty(a{:})
                        %                                     sName = regexpi(curSeriesName_newFormat, '\w*[^(\d*rep)]*', 'match');
                        %                                     sName = [sName{:}];
                        %                                     curSeriesName_newFormat = [upper(sName{1}) '(' sName{2} ')' ];
                        %                                 else
                        %                                     curSeriesName_newFormat = [curSeriesName_newFormat{:}];
                        %                                 end
                        %                             else
                        curSeriesName_newFormat = regexprep(curSeriesName_newFormat,'(\<[a-z])','${upper($1)}');
                        %                                 curSeriesName_newFormat = strjoin(curSeriesName_newFormat, '_');
                        %                             end
                        
                        fullSeriesName = ['Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat ];
                        curSeriesName_newFormat_path = fullfile( subPath, [ subInit '_' fullSeriesName]);
                    end
                    
                else %its another series type...
                    str = sprintf('Series no. %s', num2str( dcm.SeriesNumber ));
                    disp( str );
                    fprintf( logFID, '\n%s', str );
                    fprintf( logFID, '\n--------------' );
                    
                    curSeriesName_newFormat = strsplit(dcm.SeriesDescription, {'_', ' ', '-', '|'});
                    curSeriesName_newFormat = curSeriesName_newFormat(~cellfun('isempty',deblank(curSeriesName_newFormat)));
                    curSeriesName_newFormat = strjoin(curSeriesName_newFormat, '_');
                    
                    %curSeriesName_newFormat = strrep(dcm.SeriesDescription, ' ', '_');
                    fullSeriesName = ['Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat ];
                    curSeriesName_newFormat_path = fullfile( subPath, [ subInit '_' fullSeriesName]);
                    
                    % moving the files of the current series to a new folder with the proper series name
                    t = clock;
                    startTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                    
                    source =  fullfile( studyPath, curSeriesName_oldFormat);
                    destination = curSeriesName_newFormat_path;
                    [status,msg,msgid] = copyfile(source, destination);
                    
                    % If all is good - we update the log file and rename folder to the series name
                    if (status == 1)
                        % str = sprintf('%s - Successfully converted Series no. %s to %s', startTime, num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
                        str = sprintf('%s - Successfully converted to %s', startTime, curSeriesName_newFormat );
                        disp( str );
                        fprintf( logFID, '\n%s\n', str );
                    else
                        errorStr = sprintf('Failed to convert Series no. %s to %s', num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
                        warning( errorStr );
                        fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
                    end
                    
                end
                
                % now we can convert the dicoms into nifti files and move them to
                % their proper (new) folder
                t = clock;
                startTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                % str = sprintf('%s - Start dicom2nifti of series %s', startTime, curSeriesName_newFormat );
                str = sprintf('%s - Start dicom2nifti..', startTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
                
                % going to mriCron folder in order to initiate conversion
                mricronPath = 'M:\mricron2014';
                cd(mricronPath);
                dcm2niiFile = 'M:\mricron2014\dcm2nii';
                
                % creating the batch file for MRIcorN (for future use)
                cmdFile = fullfile( curSeriesName_newFormat_path, [ 'dcm2nii_' curSeriesName_newFormat '.bat']);
                batchFID = fopen( cmdFile , 'wt' );
                
                % mricron 2014
                % -b load settings from specified ini file, e.g. '-b C:\set\t1.ini'
                fprintf( batchFID, '"%s" -b %s %s\n', dcm2niiFile, [dcm2niiFile '.ini'], curSeriesName_newFormat_path);
                fclose( batchFID );
                system(['"' cmdFile '"']);
                
                % let's announce that we have finished with dcm2nii
                % t = clock;
                % startTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                % str = sprintf('%s - Finished dicom2nifti of series %s\n', startTime, curSeriesName_newFormat );
                % disp( str );
                % fprintf( logFID, '%s\n', str );
                
                cd(subPath);
                
                % now we want to move the nifti files we created to
                % their proper folder in the analysis dir
                if (isequal(scanType, 'fmri') || isequal(lower(scanType), 'rest'))
                    dest = ['func\' fullSeriesName];
                    prefix = 'vol_';
                    % prefix = ['vol_Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat];
                elseif (isequal(scanType, 'dti'))
                    dest = dtiFolder;
                    prefix = 'dti_';
                    % prefix = ['dti_Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat];
                elseif (isequal(scanType, 'mprage')) || (isequal(scanType, 'flair')) ||...
                        (isequal(scanType, 'spgr')) || (isequal(scanType, 'fspgr'))
                    dest = 'anat' ;
                    prefix = ['SPGR_' fullSeriesName];
                else
                    dest = 'anat';
                    prefix =  [ 'overlay_' fullSeriesName];
                end
                
                % and renaming the files, so it would look nice
                fprintf('Renaming NIFTI files...\n');
                niifiles = dir(fullfile( curSeriesName_newFormat_path, '*.nii'));
                nfiles = { niifiles.name }';
                
                if (size(nfiles, 1) == 1)
                    source = fullfile(curSeriesName_newFormat_path, char(nfiles));
                    destination = fullfile(curSeriesName_newFormat_path, [prefix '.nii']);
                    movefile(source, destination)
                else
                    for ind = 1:length(nfiles)
                        source = fullfile(curSeriesName_newFormat_path, nfiles{ind});
                        destination = fullfile(curSeriesName_newFormat_path, [prefix num2str(ind, '%0.3d') '.nii']);
                        movefile(source, destination)
                    end
                end
                
                % the folder name of the DTI should contain the number of
                % directions (i.e. number of files)
                if isequal(prefix, 'dti_')
                    dti_nDirections = size(nfiles, 1);
                    dtiFolder = ['DTI_' num2str( dti_nDirections )];
                    subInfo.parameters.dti_nDirections = dti_nDirections;
                    dest = dtiFolder;
                end
                
                % now that we know where we want to put the files -
                % let's move them to their new home..
                destPath = fullfile( subPath, 'Analysis' ,dest);
                if (~exist(destPath, 'dir'))
                    mkdir(destPath);
                end
                
                % moving the nifti files to their proper folder
                fprintf('Moving NIFTI files to %s...\n\n', destPath);
                source = fullfile(curSeriesName_newFormat_path, '*.nii');
                destination = destPath;
                movefile(source, destination)

                % let's add this renaming stage to the batch file, so
                % it will be possible in the future to do so manually
                % without opening seriesrenaming
                % accessing the batch file
                cmdFile = fullfile( curSeriesName_newFormat_path, [ 'dcm2nii_' curSeriesName_newFormat '.bat']);
                batchFID = fopen( cmdFile , 'at' );
                
                % now we are setting the batch file that will
                % automatically convert the dicom files and rename them
                % without opening the seriesRenaming GUI (for future
                % work if needed)
                % this string will rename the nifti files into prefix
                renameStr = ['@SETLOCAL ENABLEDELAYEDEXPANSION' char(10),...
                    '@set /a counter=1' char(10) ,...
                    '@set counterFormatted="1"' char(10) ,...
                    '@for /f "tokens=*" %%f in (''dir /b /od *.nii'') do @(' char(10) ,...
                    '@set counterFormatted=00!counter!' char(10) ,...
                    '@rename %%f ' prefix '!counterFormatted:~-3!.nii' char(10) ,...
                    '@set /a counter = !counter! + 1)'];
                
                % this string will create a new folder to which the nii
                % files will eventually move
                createDirStr = ['MD "' fullfile(curSeriesName_newFormat_path, fullSeriesName) '"'];
                % this string moves the new nii files into the new folder
                moveFilesStr = ['for /f %%a IN (''dir /b *.nii'') do move %%a ' fullfile(curSeriesName_newFormat_path, fullSeriesName)];
                
                str = sprintf('\n%s\n\n%s\n\n%s', renameStr, createDirStr, moveFilesStr);
                fprintf( batchFID, '%s', str);
                fclose( batchFID );
                
                % used in the old code - need to figure out if we still
                % need it
                %   dicom2nifti(    'dicom_dir', fullfile( rootFolder{jj}, FoldersToRename{ii} ), ...
                %  'subject_dir', fullfile( rootFolder{jj}, 'Analysis' ), ...
                %  'run_dir_naming', 'series_number', ...
                %  'func_imgs_threshold', '30', ...
                %  'dti_dir', [ 'DTI' num2str( NumberOfDirectionForDTI ) ], ...
                %  'anat_fn', [ 'SPGR' seriesNumberSTR ], ...
                %  'overlay_fn', [ 'overlay' seriesNumberSTR ] ...
                %  );
                
                % let's announce that we have finished preprocessing
                % the subject's current scanning session
                t = clock;
                startTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
                % str = sprintf('%s - Finished preprocessing %s\n', startTime, [ subInit '_' fullSeriesName] );
                str = sprintf('%s - Finished series renaming\n', startTime );
                disp( str );
                fprintf( logFID, '%s\n', str );
            end
        end
        
        %Verifying we have only one anatomy file (SPGR)
        SPGRpath = fullfile( subPath, 'Analysis', 'anat');
        SPGRfile = dir( fullfile(SPGRpath, 'SPGR*.nii' ) );
        if length( SPGRfile ) == 1, % change anatomical filename to SPGR.nii anyway
            subInfo.SPGR = SPGRfile.name;
        else
            % let's prompt our user to select a file that would be the SPGR
            % file
            SPGRfile = uigetfile(fullfile(SPGRpath, '*.nii'), 'Select anatomy file') ;
            subInfo.SPGR = SPGRfile;
            %movefile( fullfile( spgrDir, spgrFile ), fullfile( spgrDir, 'SPGR.nii' ) );
        end
        
        % checking that the anatomy file is not too big (> 50 MB) if it
        % does - we alert the subject.
        chooseAnat = 0;
        while chooseAnat == 0
            s = dir(fullfile(SPGRpath, subInfo.SPGR));
            if (s.bytes > 52428800)
                str = sprintf('HEADS UP! the anatomy file you have chosen is bigger than %.0f MB!\nThis may mean that fMRI processing might take a long while\nDo you wish to choose another one?', ceil(52428800/(1024^2)));
                choice = questdlg(str, ...
                    '', ...
                    'Yes','No', 'No');
                if isequal(choice, 'No')
                    % do not apply series renaming again, wo we're moving to the next step
                    subInfo.SPGR = SPGRfile;
                    chooseAnat = 1;
                else
                    % let's prompt our user to select a file that would be the SPGR
                    % file
                    SPGRfile = uigetfile(fullfile(SPGRpath, '*.nii'), 'Select anatomy file') ;
                    chooseAnat = 0;
                end
            else
                chooseAnat = 1;
            end
        end
        
        save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
    end
    
    % ----------------------------------------------------------------------------------------
    endTime = clock;
    totalTime = etime( endTime, sTime );
    startTime = [ num2str( sTime(4), '%0.2d' ) ':' num2str( sTime(5), '%0.2d' ) ':' num2str( round (sTime(6) ), '%0.2d' ) ];
    endTime = [ num2str( endTime(4), '%0.2d' ) ':' num2str( endTime(5), '%0.2d' ) ':' num2str( round (endTime(6) ), '%0.2d' ) ];
    totalTime = [ num2str( floor( totalTime/3600 ), '%0.2d' ) ':' num2str( floor( mod(totalTime,3600)/60 ), '%0.2d' ) ':' num2str( round ( mod(totalTime,60) ), '%0.2d' ) ];
    disp( '------------------------- Quick Summary ---------------------' );
    disp( [ 'Start time - ' startTime ] );
    disp( [ 'End   time - ' endTime ] );
    fprintf( logFID, '\n%s\n', [ 'Start time - ' startTime ] );
    fprintf( logFID, '%s\n', [ 'End   time - ' endTime ] );
    disp( [ 'Total time - ' totalTime ] );
    fprintf( logFID, '%s\n', [ 'Total time - ' totalTime ] );
    status_flag = 1;
    
catch me
    endTime = clock;
    totalTime = etime( endTime, sTime );
    startTime = [ num2str( sTime(4), '%0.2d' ) ':' num2str( sTime(5), '%0.2d' ) ':' num2str( round (sTime(6) ), '%0.2d' ) ];
    endTime = [ num2str( endTime(4), '%0.2d' ) ':' num2str( endTime(5), '%0.2d' ) ':' num2str( round (endTime(6) ), '%0.2d' ) ];
    totalTime = [ num2str( floor( totalTime/3600 ), '%0.2d' ) ':' num2str( floor( mod(totalTime,3600)/60 ), '%0.2d' ) ':' num2str( round ( mod(totalTime,60) ), '%0.2d' ) ];
    disp( '------------------------- Quick Summary ---------------------' );
    disp( [ 'Start time - ' startTime ] );
    disp( [ 'End   time - ' endTime ] );
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
    fprintf( logFID, '\nYAY!, Series renaming ended successfully! :) \n\n' );
end

fclose( logFID );
% let's open the log file and make sure everything is ok..
filename = fullfile( subPath, 'Logs', [ subInit '_SeriesRenamingClinic_' dateStr '.log' ] );
winopen(filename)
end