function mergeActivationsClinic(subInfo, files_table)

% DTI and fMRI superimposing script for Clinic
% superimpose - an array that contains the followings:
% filename (without extension), intensityValue, and viewerColor
FileVersion = 'v1';  % 17.03.2016 THM
disp( [ 'Merge activations, version: ' FileVersion ] );

%------------------------ Setting initial parameters %--------------------------
spmViewerPath = 'M:\viewer_SPM';

subPath = subInfo.path;
anatomyfile = subInfo.SPGR;
upDownFlip = subInfo.parameters.upDownFlip;

createColorMatrix = 0;
colorScheme = {'FireBrick'; 'Teal'; 'ForestGreen'; 'DarkOrange'; 'HotPink';
    'MediumPurple'; 'Chocolate'; 'DarkMagenta'; 'RoyalBlue'; 'LightCoral';
    'PaleVioletRed'; 'SteelBlue'; 'DarkBlue'; 'Indigo'; 'Black'; 'Amethyst';
    'SeaGreen'; 'CornFlowerBlue'; 'Orange'; 'Crimson'; 'Gray'; 'LightSlateGray';
    'DarkCyan'; 'CadetBlue'; 'Gold'; 'DodgerBlue'; 'LightSalmon'; 'RosyBrown';
    'BurlyWood'; 'DarkSalmon'; 'Red';};

% (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se
SPGRseries = regexp(anatomyfile, '[^SPGR]+(\w*.*)[^nii]', 'tokens');
SPGRseries = SPGRseries{1};

% creating subject name and initials
subInit = createSubInitials(subInfo);

% setting the path to the anat folder and the func folder
analysisPath = fullfile( subPath, 'Analysis' );
funcPath = fullfile( analysisPath, 'func' );
anatomyPath = fullfile( analysisPath, 'anat' );
viewerFilesPath = fullfile( subPath, 'viewer', 'files' );
SPGRdicomPath = fullfile( subPath, [subInit '_'  SPGRseries{:}]);
isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
if ~isempty(isEEG)
    eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
end
%-------------------------------------------------------------------------------

% check if the viewer directory exists
if ~exist( fullfile( subPath, 'viewer' ) ,'dir'),
    mkdir( fullfile( subPath, 'viewer' ) );
    copyfile( spmViewerPath, fullfile( subPath, 'viewer' ) );
end

if ~exist( viewerFilesPath ,'dir'),
    mkdir( viewerFilesPath );
end

% check if there is SPGR file - if not - copying the existing file.
if isempty(dir(fullfile( subPath, 'viewer', 'SPGR*.nii' )))
    source = fullfile( anatomyPath, anatomyfile );
    destination = fullfile( subPath, 'viewer');
    copyfile( source, destination );
end
%-------------------------------------------------------------------------------

step = 1;
str = sprintf('Applying merge activations\n');
h = waitbar(step/100, str,...
    'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');

% going over the list and dealing with each pair (or triplet) of files at a
% time.
ind = find(strcmp('*', files_table(:,1)));

for curFileList_index = 1:numel(ind)
    begin = ind(curFileList_index);
    if (curFileList_index+1 > size(ind, 1))
        finish = size(files_table,1);
        finish = begin + (finish - begin);
    else
        finish = ind(curFileList_index+1);
        finish = begin + (finish - begin)-1;
    end
    
    superimpose_list = files_table((begin : finish),2:end);
    
    % updating waitbar
    step = 1;
    step = step + 4;
    str = sprintf('Applying merge activations (%d/%d)\nInitializing parameters..', curFileList_index, numel(ind));
    waitbar(step/100, h, str,...
        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
    
    newSeriesPrefix = superimpose_list{1, 6};
    newSeriesName = superimpose_list{1, 5};
    writeOutputDicoms = superimpose_list{1, 4};
    files = superimpose_list(:,1);
    
    % no series name? let's create one!
    if isempty(newSeriesName)
        % new seires name
        fname = regexp(files, '\w*^[^_]*', 'match');
        fname = [fname{:}];
        newSeriesName = {'SPGR'};
        
        isBinFile = regexp(files, 'bin', 'match');
        isRestFile = regexpi(files, 'rest', 'match');
        
        fmriFiles = find(cellfun(@isempty,isBinFile));
        if ~isempty(fmriFiles)
            if (isempty(find(~cellfun(@isempty,isRestFile)))) || numel(fmriFiles) ~= numel(isRestFile)
                tmpNewSeriesName = newSeriesName;
                
                fname = files(fmriFiles);
                for n = 1:numel(fname)
                    curFname = fname(n);
                    curFname = regexp(curFname, '^[^\d+]+(?=c)', 'match');
                    curFname = [curFname{:}];
                    if ~isempty(curFname)
                        curFname = strrep(curFname, '_', '');
                    else
                        curFname = files{n};
                    end
                    tmpNewSeriesName = [tmpNewSeriesName curFname];
                end
                if numel(fmriFiles) > 1 && isequal(fname{fmriFiles(1)}, fname{fmriFiles(1:end)})
                    newSeriesName = [newSeriesName fname{fmriFiles(1)}];
                else
                    newSeriesName = tmpNewSeriesName;
                end
            end
        end
        
        restFiles = find(~cellfun(@isempty,isRestFile));
        if ~isempty(restFiles)
            if numel(restFiles) == numel(files)
                for i = 1:numel(files)
                    file = regexpi(files{i},  '(?<=rest_)\w+', 'match');
                    newSeriesName = [newSeriesName file];
                end
            else
                newSeriesName = [newSeriesName fname{restFiles}];
            end
            
        end
        
        newSeriesName = strjoin(newSeriesName, '_');
        newSeriesName = ['Merged_Activations_' newSeriesName];
    end
    
    %     % check if there are already folders with this name
    %     counter = 0;
    %     sName = newSeriesName;
    %     ls = dir(fullfile(subPath, 'viewer'));
    %     ls = {ls.name};
    %     alreadyExist_ind = strfind(ls, sName);
    %     alreadyExist_ind = find(~cellfun(@isempty, alreadyExist_ind));
    %     if ~isempty(alreadyExist_ind)
    %         newSeriesName = [sName sprintf('_%.2d', size(alreadyExist_ind,2) + 1)] ;
    %         counter = counter + size(alreadyExist_ind,2);
    %     end
    %
    %     % check if there are already folders with this name int he
    %     % table list
    %     f = files_table(:, 6);
    %     f = cellfun(@num2str,f,'un',0);
    %     f = unique(f);
    %     alreadyExist_ind = strfind(f,sName);
    %     alreadyExist_ind = find(~cellfun(@isempty, alreadyExist_ind));
    %
    %     if size(alreadyExist_ind,1) > 1
    %         counter = counter + size(alreadyExist_ind,1);
    %         newSeriesName = [sName sprintf('_%.2d', counter + 1)] ;
    %     end
    
    if writeOutputDicoms
        dicomOutputName = ['out' newSeriesName];
        dicomOutputPath = fullfile( analysisPath, dicomOutputName );
    end
    
    %removing SPGR string from newSeriesName
    
    %filename = char(regexp(newSeriesName, '(?<=SPGR_)\w*', 'match'));
    filename = strrep(newSeriesName, 'SPGR_', '');
    filename = strrep(filename, '_Merged_Activations', '');
    filename = strrep(filename, 'Merged_Activations_', '');
    filename  = ['Merged_' filename];
    
    % extracting the names of the files to be merged
    activation1 = files{1};
    activation2 = files{2};
    
    % copying the files into the viewer\files path
    fields = subInfo.fMRIsession;
    fieldnameToAccess = fieldnames(fields);
    
    % going over the fmri fields in subInfo and checking if our file
    % matches one of them.
    
    for j = 1:size(files,1)
        
        file = lower(regexpi(char(files{j}), 'rest', 'match'));
        if isempty(file)
            file = lower(regexp(char(files{j}), '^[^\d+]+(?=c)', 'match'));
        end
        
        file = char(strrep(file, '_', ''));
        foundStr = 0;
        
        for i = 1:numel(fieldnameToAccess)
            
            % extracting the current fmri session name
            seriesDescription = fields.(fieldnameToAccess{i}).seriesDescription;
            sName = regexp(lower(seriesDescription), '^[^(]+(?=)', 'match');
            seriesName = char(strrep(sName, '_', ''));
            
            f = findTaskName(seriesName, file);
            if ~isempty(f)
                foundStr = 1;
                
                % setting the path to the current series func folder
                seriesNumber= fields.(fieldnameToAccess{i}).seriesNumber;
                fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
                fullSeriesFuncPath = fullfile(funcPath, fullSeriesName);
                
                % copying the img and hdr of the activation file into the
                % superimpose folder in the viewer (they were already
                % coregistered in previous preprocessing)
                % copying to the viewer folder a copy of the original fmri file (copy file)
                fmriFiles = fullfile( fullSeriesFuncPath, 'Results', [ files{j}  '.*'] );
                
                if ~isempty(dir(fmriFiles))
                    fprintf('Found: %s\n', fmriFiles);
                    copyfile( fmriFiles, viewerFilesPath );
                    break
                end
            end
        end
        
        if ~foundStr
            
            % now let's search in the analysis folder itself for things to show
            dirs = dir(fullfile(analysisPath));
            dirs = {dirs.name};
            dirs = dirs(3:end);
            
            % check that we have other folders than the default ones (i.e.;
            % DTI_41, func, anat, and LI)
            dirType = regexpi(lower(dirs), '(dti_41|li|anat|func|out*)+[^(_| |-)]*', 'match');
            idx = find(cellfun(@isempty,dirType));
            
            if ~isempty(idx)
                for n = 1:numel(idx)
                    if strcmpi(dirs{idx(n)}, 'eeg_lags')
                        
                        eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
                        
                        sessionDirs = dir(eegLagsPath);
                        sessionDirs = {sessionDirs.name};
                        sessionDirs = sessionDirs(3:end);
                        
                        for s = 1:size(sessionDirs, 2)
                            curSess = sessionDirs{s};
                            
                            lagDirs = dir(fullfile(eegLagsPath, curSess));
                            lagDirs = {lagDirs.name};
                            lagDirs = lagDirs(3:end);
                            
                            for lg = 1:size(lagDirs, 2)
                                curLag = lagDirs{lg};
                                
                                resultsPath = fullfile(eegLagsPath, curSess, curLag, 'Results');
                                spmFiles = dir(resultsPath);
                                spmFiles = {spmFiles.name};
                                spmFiles = spmFiles(3:end);
                                
                                if ~isempty(spmFiles)
                                    
                                    % find if the file exists
                                    if exist(fullfile(resultsPath, [files{j} '.hdr']), 'file') || ...
                                            exist(fullfile(resultsPath, [files{j} '.nii']), 'file')
                                        foundStr = 1;
                                        
                                        % copying the img and hdr of the activation file into the
                                        % superimpose folder in the viewer (they were already
                                        % coregistered in previous preprocessing)
                                        % copying to the viewer folder a copy of the original fmri file (copy file)
                                        fmriFiles = fullfile( eegLagsPath, curSess, curLag, 'Results', [ files{j}  '.*'] );
                                        fprintf('Found: %s\n', fmriFiles);
                                        copyfile( fmriFiles, viewerFilesPath );
                                        break
                                    end
                                end
                            end
                            if foundStr
                                break
                            end
                        end
                    else
                        curDir = fullfile(analysisPath, dirs{idx(n)});
                        % now lets set the fmri files..
                        % find if the file exists
                        if exist(fullfile(curDir, [files{j} '.hdr']), 'file') || ...
                                exist(fullfile(curDir, [files{j} '.nii']), 'file')
                            foundStr = 1;
                            
                            % copying the img and hdr of the activation file into the
                            % superimpose folder in the viewer (they were already
                            % coregistered in previous preprocessing)
                            % copying to the viewer folder a copy of the original fmri file (copy file)
                            fmriFiles = fullfile( curDir, [ files{j}  '.*'] );
                            fprintf('Found: %s\n', fmriFiles);
                            copyfile( fmriFiles, viewerFilesPath );
                            break
                        end
                    end
                    if foundStr
                        break
                    end
                end
            end
        end
    end
    
    % loading them and multiply them.
    % load the activation image and header files of the first file
    if exist(fullfile(viewerFilesPath, [activation1, '.hdr']), 'file')
        [ activation1_hdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [activation1, '.hdr']));
        nii = load_nii(fullfile(viewerFilesPath, [activation1, '.hdr']));
    else
        [ activation1_hdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [activation1, '.nii']));
        nii = load_nii(fullfile(viewerFilesPath, [activation1, '.nii']));
    end
    [ activation1_img, activation1_hdr ] = load_nii_img( activation1_hdr, filetype, fileprefix, machine );
    
    % load the activation image and header files of the second file
    if exist(fullfile(viewerFilesPath, [activation2, '.hdr']), 'file')
        [ activation2_hdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [activation2, '.hdr'] ));
    else
        [ activation2_hdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [activation2, '.nii'] ));
    end
    [ activation2_img, activation2_hdr ] = load_nii_img( activation2_hdr, filetype, fileprefix, machine );
    
    % calculate the and of these activations by multiplying their values
    activation1_img_double = double(activation1_img);
    activation2_img_double = double(activation2_img);
    
    %merging by multiplying one matrix with the other
    mergedActivation_img = (activation1_img_double).*(activation2_img_double);
    %     nii.img = int16(mergedActivation_img);
    nii.img = mergedActivation_img;
    
    nii.fileprefix = fullfile(viewerFilesPath, [filename, '.hdr']);
    %     if exist(fullfile(viewerFilesPath, [filename, '.hdr']), 'file')
    %         nii.fileprefix = fullfile(viewerFilesPath, [filename, '.hdr']);
    %     else
    %         nii.fileprefix = fullfile(viewerFilesPath, [filename, '.nii']);
    %     end
    % view_nii(nii1);
    % save the resultant activation file
    save_nii(nii, fullfile(viewerFilesPath, filename));
    
    % updating waitbar
    step = step + 5;
    str = sprintf('Applying merge activations (%d/%d)\nProcessing fMRI files..', curFileList_index, numel(ind));
    waitbar(step/100, h, str,...
        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
    
    % ---------------------------------------- Present Results ----------------------------------------
    %     fprintf('Superimpose file(s) on SPGR...\n');
    
    % updating waitbar
    step = step + 3;
    str = sprintf('Applying merge activations (%d/%d)\nSuperimpose file(s) on SPGR..', curFileList_index, numel(ind));
    waitbar(step/100, h, str,...
        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
    
    % load SPGR's header information (SPGRhdr) and its image matrix (SPGRimg)
    [ SPGRhdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile( anatomyPath, anatomyfile) );
    [ SPGRimg, SPGRhdr ] = load_nii_img( SPGRhdr, filetype, fileprefix, machine );
    SaturationValue = double( max( SPGRimg(:) ) );
    
    % turning the SPGRimg matrix into a vector of doubles and change each value in
    % it with the following : 255 * doubleSPGRimg cell value / saturationValue (the maximum
    % value in the SPGRimg matrix
    doubleSPGRimg = double( SPGRimg(:) );
    doubleSPGRimg255 = 255 * doubleSPGRimg / SaturationValue;
    SPGRimgSize = size( SPGRimg );
    
    % prepparing the array that contains the SPGR image into which we will soon
    % insert the fibers\ activations (from the coregImg variable)
    % outSPGRwithFibers = [];
    if createColorMatrix == 0,
        superimposedSPGR = SPGRimg(:);
    else
        % 3 columns represent the R G and B colors of the superimposed file
        superimposedSPGRwithColor(:,1) = uint8( doubleSPGRimg255 );
        superimposedSPGRwithColor(:,2) = uint8( doubleSPGRimg255 );
        superimposedSPGRwithColor(:,3) = uint8( doubleSPGRimg255 );
    end
    
    % change file name to reflect the files merged!
    %     mricronName = strrep(filename, 'Merged_', '');
    mricronName = ['view' filename];
    mricronFilename = fullfile( subPath, 'viewer', [mricronName '.bat'] );
    
    mricronFID = fopen( mricronFilename, 'wt' );
    fprintf( mricronFID, 'start /MAX mricron .\\%s ', anatomyfile);
    
    % --- Load the Merged Activation File
    %     filename = seriesName;
    intensityValue = str2double(superimpose_list{1,2});
    viewerColor = str2double(superimpose_list{1,3});
    
    % preparing the parameters for the mricron batch file
    coreg_fileName_forMricron = fullfile( '.', 'files', [ filename '.hdr'] );
    threshold = 0;
    
    % loading the merged activation file header and changing several parameters
    [ mergedHdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [filename '.hdr' ]) );
    [ mergedImg, mergedHdr ] = load_nii_img( mergedHdr, filetype, fileprefix, machine );
    
    %outFunc_nii = load_untouch_nii( [ fmriFiles(1:end-1) 'hdr' ] );
    outFunc_nii.hdr = mergedHdr;
    outFunc_nii.img = mergedImg;
    outFunc_nii.hdr.dime.datatype = 2;
    outFunc_nii.hdr.dime.bitpix = 8;
    outFunc_nii.hdr.dime.scl_slope = 0;
    
    % we go over the fmri image matrix and convert it into a matrix of logicals
    if sum( outFunc_nii.img(:) ) > 0,  % positive map
        outFunc_nii.img = outFunc_nii.img > 0;
        colorBounds = ' -l 0.5 ';
    else % negative map
        outFunc_nii.img = outFunc_nii.img < 0;
        colorBounds = ' -h -0.5 ';
        mergedImg = mergedImg * (-1); % turn image to positive values
    end
    
    % we look in the matrix for those cells indices that are greater than the threshold
    maskFibers = find( mergedImg(:) > threshold );
    save_nii( outFunc_nii, fullfile( viewerFilesPath, [ filename '_bin.nii' ] ) );
    clear outFunc_nii;
    
    if createColorMatrix == 0,
        % we are going over the matrix of the SPGR and insert in each place
        % there was a fiber\activation a certain value, calculated as:
        % the location in the coregistered image * saturationValue *
        % intensityValue / maximum value in the coregistered image
        superimposedSPGR( maskFibers ) = double(mergedImg( maskFibers )) * SaturationValue * intensityValue / double(max(mergedImg(:)));
    else
        % inserting the colors.. because its RGB we need to rescale it to
        % 255.
        color = rgb(colorScheme{jj}) * 255;
        superimposedSPGRwithColor( maskFibers, 1 ) = color(1);
        superimposedSPGRwithColor( maskFibers, 2 ) = color(2);
        superimposedSPGRwithColor( maskFibers, 3 ) = color(3);
        
    end
    
    % updating the mricron batch file
    fprintf( mricronFID, '-o %s %s -c -%d ', coreg_fileName_forMricron, colorBounds, viewerColor );
end

fclose( mricronFID );

if createColorMatrix == 0,
    % creating a matrix with vector of the SPGR and fibers using the
    % dimension of the SPGR
    outMergedWithSPGR = reshape(superimposedSPGR, SPGRimgSize );
    outMergedWithSPGR_nii = make_nii( outMergedWithSPGR, SPGRhdr.dime.pixdim(2:4) );
    %     SPGRFibersForShow_nii = make_nii( reshape(SPGRFibersForShow, SPGRsize ), hdrSPGR.dime.pixdim(2:4) );
    
else % generate color matrix
    outSPGRcoregImgColor( :,:,:,1 ) = reshape(superimposedSPGRwithColor(:,1), SPGRimgSize );
    outSPGRcoregImgColor( :,:,:,2 ) = reshape(superimposedSPGRwithColor(:,2), SPGRimgSize );
    outSPGRcoregImgColor( :,:,:,3 ) = reshape(superimposedSPGRwithColor(:,3), SPGRimgSize );
    
    % taking one representative slice (#30) - just to check if its visually
    % good.
    colorImage(:,:,1) = outSPGRcoregImgColor( :,:,30,1);
    colorImage(:,:,2) = outSPGRcoregImgColor( :,:,30,2);
    colorImage(:,:,3) = outSPGRcoregImgColor( :,:,30,3);
    figure; image( colorImage );
    outMergedWithSPGR_nii = make_nii( outSPGRcoregImgColor, SPGRhdr.dime.pixdim(2:4) );
end
% view_nii( SPGRwithFibers_nii);
% view_nii( SPGRFibersForShow_nii );


% --------------------------- output coregstration result on DICOM files --------------------------

if writeOutputDicoms,
    fprintf('Creating superimposed dicom files..\n');
    
    %         step = (step + 1)/100;
    %         waitbar(step, h, sprintf('Applying merge activations (%d/%d)\nCreating DICOMs (%d/%d)', curFileList_index, numel(ind), 0, SPGRimgSize(3)), 'windowstyle', 'modal');
    
    if ~exist( dicomOutputPath,'dir' )
        mkdir( dicomOutputPath );
    end
    
    
    SeriesUID = dicomuid;
    t = clock;
    SeriesDate = [ num2str(t(1)), num2str(t(2),'%0.2d'), num2str(t(3),'%0.2d') ];
    SeriesTime = [ num2str(t(4),'%0.2d'), num2str(t(5),'%0.2d'), num2str(floor(t(6)),'%0.2d') ];
    SPGRdicomFiles = dir( fullfile( SPGRdicomPath, '*.dcm') );
    templateSeriesFile = SPGRdicomFiles(1).name(1:8);
    outputSeriesFile = templateSeriesFile;
    outputSeriesFile(3) = newSeriesPrefix;
    
    % (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se
    oldSeriesNumber = regexp(SPGRdicomPath, '(?<=Se)\d+', 'match');
    
    for jj = 1:SPGRimgSize(3),
        
        % updating waitbar
        step = step + jj/SPGRimgSize(3);
        str = sprintf('Applying merge activations (%d/%d)\nCreating DICOMs (%d/%d)', curFileList_index, numel(ind), jj, SPGRimgSize(3));
        waitbar(step/100, h, str,...
            'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
        
        curSPGRfile = fullfile( SPGRdicomPath, [ templateSeriesFile num2str(jj,'%0.3d') '.dcm' ] );
        metadata = dicominfo( curSPGRfile );
        
        metadata.SeriesNumber = str2double(newSeriesPrefix)*100 + str2double(oldSeriesNumber);
        metadata.SeriesDate = SeriesDate;
        metadata.AcquisitionDate = SeriesDate;
        metadata.SeriesTime = SeriesTime;
        metadata.SeriesInstanceUID = SeriesUID;
        outputFileName = fullfile( dicomOutputPath, [ outputSeriesFile num2str(jj,'%0.3d') '.dcm' ] );
        
        if createColorMatrix == 0,
            metadata.SeriesDescription = newSeriesName;
            if upDownFlip
                status = dicomwrite(flipud( rot90(outMergedWithSPGR(:,:,jj))), outputFileName, metadata, 'CreateMode', 'Copy' );
            else
                status = dicomwrite( rot90(outMergedWithSPGR(:,:,jj)), outputFileName, metadata, 'CreateMode', 'Copy' );
            end;
        else
            metadata.SeriesDescription = [ 'Color ' newSeriesName ];
            colorImage(:,:,1) = rot90( outSPGRcoregImgColor( :, :, jj, 1 ) );
            colorImage(:,:,2) = rot90( outSPGRcoregImgColor( :, :, jj, 2 ) );
            colorImage(:,:,3) = rot90( outSPGRcoregImgColor( :, :, jj, 3 ) );
            status = dicomwrite( colorImage, outputFileName, metadata, 'CreateMode', 'Copy' );
        end
        
        if ~isempty( status )
            if( ~strcmp( status.SuspectAttribute{1}, '(0018,0021)' ) |  ~strcmp( status.SuspectAttribute{2}, '(0018,0022)' ) ),
                warning( [ 'dicomewrite status is not empty at file number ' num2str( jj ) ] );
            end
        end
    end
end

fclose( 'all' );

step = 100/100;
waitbar(step, h, sprintf('Finished!'))
pause(0.1)

fprintf('Finished!\n');

end