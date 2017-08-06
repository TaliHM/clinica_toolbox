function superimposeClinic(subInfo, files_table, createColorDcm)

% DTI and fMRI superimposing script for Clinic
% superimpose - an array that contains the followings:
% filename (without extension), intensityValue, and viewerColor
global dtiSPGRfile
global restSPGRfile

FileVersion = 'v1';  % 17.03.2016 THM
disp( [ 'Superimpose processing, version: ' FileVersion ] );

%------------------------ Setting initial parameters %--------------------------
spmViewerPath = 'M:\viewer_SPM';

subPath = subInfo.path;
anatomyfile = subInfo.SPGR;
infSupFlip = subInfo.parameters.infSupFlip;
templatePath = subInfo.parameters.templatePath;
dtiFilePrefix = subInfo.parameters.dtiFilePrefix;
dti_nDirections = subInfo.parameters.dti_nDirections;
upDownFlip = subInfo.parameters.upDownFlip;

createColorMatrix = createColorDcm;
colorScheme = {'Red';'Yellow';'MediumBlue';'Lime';'Gold';'Orange'; 'DarkCyan'; 'FireBrick'; 'SeaGreen';'ForestGreen';'DarkBlue'; 'Teal';  'DarkOrange'; 'HotPink';
    'MediumPurple'; 'Chocolate'; 'DarkMagenta'; 'RoyalBlue'; 'LightCoral';
    'PaleVioletRed';   'Indigo';'Pink'; 'Black'; 'Amethyst';
    'CornFlowerBlue'; 'Crimson'; 'Gray'; 'LightSlateGray';
    'SteelBlue';  'DodgerBlue'; 'LightSalmon'; 'RosyBrown';
    'BurlyWood'; 'DarkSalmon'; 'CadetBlue';};

% creating subject name and initials
subInit = createSubInitials(subInfo);

% setting the path to the anat folder and the func folder
analysisPath = fullfile( subPath, 'Analysis' );
anatomyPath = fullfile( analysisPath, 'anat' );
funcPath = fullfile( analysisPath, 'func' );
dtiPath = fullfile( subPath, 'Analysis', [ 'DTI_' num2str( dti_nDirections ) ] );
fibersPath = fullfile( dtiPath, 'Fibers' );
viewerFilesPath = fullfile( subPath, 'viewer', 'files' );
%-------------------------------------------------------------------------------

step = 1;
str = sprintf('Applying superimpose processing\n');
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
    str = sprintf('Applying superimpose processing (%d/%d)\nInitializing parameters..', curFileList_index, numel(ind));
    waitbar(step/100, h, str,...
        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
    
    newSeriesPrefix = superimpose_list{1, 6};
    newSeriesName = superimpose_list{1, 5};
    writeOutputDicoms = superimpose_list{1, 4};
    
    if writeOutputDicoms
        dicomOutputName = ['out' newSeriesName];
        dicomOutputPath = fullfile( subPath, 'for_PACS', dicomOutputName );
    end
    
    % change file name to reflect the files superimposed!
    if isempty(newSeriesName)
        % new seires name
        files = superimpose_list(:,1);
        % fname = regexp(files, '\w*^[^_]*', 'match');
        newSeriesName = {'SPGR'};
        
        isBinFile = regexp(files, 'bin', 'match');
        isRestFile = regexpi(files, 'rest', 'match');
        
        % adding the dti part to the folder's name
        
        binFiles = find(~cellfun(@isempty,isBinFile));
        % if it has a recurring name (we use only one file name, not both)
        fname = regexp(files, '\w*^[^_]*', 'match');
        fname = [fname{:}];
        
        if ~isempty(binFiles)
            if numel(binFiles) > 1 && isequal(fname{binFiles(1)}, fname{binFiles(1:end)})
                newSeriesName = [newSeriesName 'FIBERS' fname{binFiles(1)}];
            else
                newSeriesName = [newSeriesName 'FIBERS' fname{binFiles}];
            end
            %         else
            %             isBinFile = [isBinFile{:}];
        end
        
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
            files_table{begin, 7} = '8';
            
            if numel(restFiles) == numel(files)
                for k = 1:numel(files)
                    file = regexpi(files{k},  '(?<=rest_)\w+', 'match');
                    newSeriesName = [newSeriesName file];
                end
            else
                newSeriesName = [newSeriesName fname{restFiles}];
            end
            newSeriesName = strrep(newSeriesName, 'Rest', '');
        end
        
        newSeriesName = strjoin(newSeriesName, '_');
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
    
    % check if the viewer directory exists
    if ~exist( fullfile( subPath, 'viewer' ) ,'dir'),
        mkdir( fullfile( subPath, 'viewer' ) );
        copyfile( spmViewerPath, fullfile( subPath, 'viewer' ) );
    end
    
    if ~exist( viewerFilesPath ,'dir'),
        mkdir( viewerFilesPath );
    end
    
    % check if there is SPGR file - if not - copying the existing file.
    if isempty(dir(fullfile( subPath, 'viewer', anatomyfile )))
        source = fullfile( anatomyPath, anatomyfile );
        destination = fullfile( subPath, 'viewer');
        copyfile( source, destination );
    end
    
    % % check if there is SPGR file - if not - copying the existing file.
    % if isempty(dir(fullfile( subFolder, 'viewer', 'SPGR*.nii' )))
    %     source = fullfile( anatomyFolder, anatomyFile );
    %     destination = fullfile( subFolder, 'viewer');
    %     copyfile( source, destination );
    % end
    
    % % check if the output directory is empty
    % SPGRdicomFiles = dir( [ dicomOutputPath '\*.dcm' ] );
    % if( ( size( SPGRdicomFiles, 1 ) ~= 0 ) && ( writeOutputDicoms == 1 ) ),
    %     Ruser = input( 'Warning: dicom output folder is not empty, continue ? (Y/N)', 's' );
    %     if strcmpi( Ruser, 'n' )
    %         disp( 'Quiting ...' );
    %         return;
    %     elseif strcmpi( Ruser, 'y' )
    %         disp( 'Continuing ...' );
    %     else
    %         error( 'User response is not allowed, only "Y" or "N" keys' );
    %     end
    % end
    
    dtiCoregistrationFlag = 0;
    FibersFilesToCoreg = {};
    coregImgCounter = 1;
    
    % check if DTI files need to be registered.
    % if DTI: load binary raw coregImg files and convert them to binary niftiis
    for jj = 1:size( superimpose_list, 1 ),
        
        % updating waitbar
        step = step + 5;
        str = sprintf('Applying superimpose processing (%d/%d)\nProcessing fMRI and/or DTI files..', curFileList_index, numel(ind));
        waitbar(step/100, h, str,...
            'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
        
        filename = superimpose_list{jj,1};
        % fprintf('Currently processing: %s\n', filename);
        
        isBinFile = regexp(filename, 'bin', 'match');
        if ~isempty([isBinFile{:}])
            
            match_files = dir(fullfile( fibersPath, [filename '*']));
            match_filesNames = {match_files.name}';
            
            % we have two version to deal with:
            % 1. DTI studio (old version)
            % 2. DSI studio (new version)
            % at first, we need to take both in account (hopefully in the
            % future we won't need the first version anymore)
            
            matfile = regexp(match_filesNames, ['(' filename '.mat)'], 'match');
            matfileIndex = find(~cellfun(@isempty, matfile));
            
            datfile = regexp(match_filesNames, ['(' filename '.dat)'], 'match');
            datfileIndex = find(~cellfun(@isempty, datfile));
            
            if ~isempty(matfileIndex) % if it's a file of DSI studio
                
                % load DTI NifTI header
                [ hdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile( dtiPath, [ dtiFilePrefix '_01.nii' ] ) );
                xDim = hdr.dime.dim(2);
                yDim = hdr.dime.dim(3);
                zDim = hdr.dime.dim(4);
                
                % rawFibersMatrixData.tracts - the (x,y,z) coordinates of each
                % tract
                % rawFibersMatrixData.length - the length of the fibers (e.g. length of [115 100 115...]
                % means that the first fiber is from the first coordinate in rawFibersMatrixData.tracts
                % until the 115th, the next fiber is from 116th coordinate and it
                % goes over the next 100 coordinates and so on..)
                rawFibersMatrixData = load( fullfile( fibersPath, [ filename '.mat' ] ));
                
                % now we need to create the fiber's vector based on the original
                % DTI NIFTI
                % we create a binary matrix where indecies of the fibers are
                % represented by 127
                rawFibers = zeros([xDim yDim zDim]);
                tracts = round(rawFibersMatrixData.tracts);
                for t = 1:size(tracts,2)
                    % [tracts(1,t), tracts(2,t), tracts(3,t)]
                    % rawFibers(tracts(1,t), tracts(2,t), tracts(3,t))
                    rawFibers(tracts(1,t), tracts(2,t), tracts(3,t)) = 127;
                end
                
                % NS: uncommment the following lines to inspect fiber in 3D
                % [x,y,z] = ind2sub(size(rawFibers), find(rawFibers));
                % figure;
                % scatter3(x,y,z);
                
                % we create a matrix filled with zeros from the dimensions of the
                % rawFiber we just created. this matrix will be used to do a
                % inferior-posterior flip and a left-right flip (if needed) or only a left-right flip.
                rawFibersSize = size( rawFibers );
                rawFibersFlip = zeros( rawFibersSize );
                nSlices = rawFibersSize(3);
                for ii = 1:nSlices,
                    if infSupFlip == 1,
                        rawFibersFlip(:,:,ii) = rawFibers(:,:,nSlices-ii+1); % do inferior-superior (up-down) flip on zDim
                        rawFibersFlip(:,:,ii) = fliplr( rawFibersFlip(:,:,ii) ); % do left-right flip on zDim
                    else
                        rawFibersFlip(:,:,ii) = fliplr( rawFibers(:,:,ii) ); % do left-right flip on zDim
                    end
                end
                
                % saving the new matrix - this will save only(!) the fiber itself.
                % hdr - of the original DTI NIFTI file
                % img - the matrix of the raw coregImg after flip.
                outFibers_nii.hdr = hdr;
                outFibers_nii.img = rawFibersFlip;
                save_nii( outFibers_nii, fullfile( fibersPath, [ filename '.nii' ] ) );
                
            elseif ~isempty(datfileIndex)  % if it's a file of DTI studio
                % load DTI NifTI header
                if exist(fullfile( dtiPath, [ dtiFilePrefix '_001.nii' ] ), 'file')
                    [ hdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile( dtiPath, [ dtiFilePrefix '_001.nii' ] ) );
                else
                    [ hdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile( dtiPath, [ dtiFilePrefix '_01.nii' ] ) );
                end
                
                xDim = hdr.dime.dim(2);
                yDim = hdr.dime.dim(3);
                
                % open the saved DTI studio .dat file for reading
                fid = fopen( fullfile( fibersPath, [ filename '.dat' ] ), 'rb' );
                if fid < 3
                    errorStr = sprintf('Can''t open file for reading: %s', fullfile( fibersPath, [filename '.dat' ] ));
                    error( errorStr );
                end
                
                % we get one long vector with zeros and non-zeros
                rawFibersVec = fread( fid, 'uint8' );
                fclose( fid );
                
                % calculating zDim from the dat file
                zDim = length(rawFibersVec)/(xDim*yDim);
                
                % we create a matrix from that fiber's vector with the dimensions from the
                % original DTI NIFTI file
                rawFibers = reshape( rawFibersVec, xDim, yDim, zDim );
                rawFibersSize = size( rawFibers );
                
                % we create a matrix filled with zeros from the dimensions of the
                % rawFiber we just created. this matrix will be used to do a
                % inferior-posterior flip (if needed) or only a left-right flip.
                rawFibersFlip = zeros( rawFibersSize );
                nSlices = rawFibersSize(3);
                for ii = 1:nSlices,
                    if infSupFlip == 1,
                        rawFibersFlip(:,:,ii) = rawFibers(:,:,nSlices-ii+1); % do inferior-superior (up-down) flip on zDim
                        rawFibersFlip(:,:,ii) = fliplr( rawFibersFlip(:,:,ii) ); % do left-right flip on zDim
                    else
                        rawFibersFlip(:,:,ii) = fliplr( rawFibers(:,:,ii) ); % do left-right flip on zDim
                    end
                end
                
                % saving the new matrix - this will save only(!) the fiber itself.
                % hdr - of the original DTI NIFTI file
                % img - the matrix of the raw coregImg after flip.
                outFibers_nii.hdr = hdr;
                outFibers_nii.img = rawFibersFlip;
                save_nii( outFibers_nii, fullfile( fibersPath, [ filename '.nii' ] ) );
            end
            
            % we need to coregister DTI files
            FibersFilesToCoreg( coregImgCounter, : ) = { filename };
            coregImgCounter = coregImgCounter + 1;
            dtiCoregistrationFlag = 1;
        end
    end
    
    
    % ----------------------------------------- Co - registration ---------------------------------------------
    % DTI co-registration
    if dtiCoregistrationFlag,
        disp( 'Coregistration' );
        
        % updating waitbar
        step = step + 3;
        str = sprintf('Applying superimpose processing (%d/%d)\nApplying DTI Coregistration..', curFileList_index, numel(ind));
        waitbar(step/100, h, str,...
            'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
        
        % clear matlabbatch variable
        clear matlabbatch;
        
        % loading the matlabbatch template file
        load( fullfile(  templatePath, 'Coregister_Estimate&Reslice_template.mat' ) );
        
        % we need to check if we need a different SPGR file for the DTI
        % co-registration
        % but first we need to check if all fiules are DTI files!
        files = superimpose_list(:,1);
        isAllBinFile = regexp( files, 'bin', 'match');
        
        % if one of the cells is empty - than it means that not all are DTI
        % files, which means that we cannot use the SPGR used for dti
        % files..
        if (isempty(find(cellfun(@isempty,isAllBinFile))))
            if ~isempty(dtiSPGRfile)
                anatomyfile = dtiSPGRfile;
                
                % check if there is SPGR file - if not - copying the existing file.
                if isempty(dir(fullfile( subPath, 'viewer', anatomyfile )))
                    source = fullfile( anatomyPath, anatomyfile );
                    destination = fullfile( subPath, 'viewer');
                    copyfile( source, destination );
                end
            end
        else
            anatomyfile = subInfo.SPGR;
        end
        
        % set the image that is assumed to remain stationary (SPGR)
        matlabbatch{1}.spm.spatial.coreg.estwrite.ref = ...
            cellstr( strcat( [ anatomyPath '\'  anatomyfile ], ',1' ) );
        
        % mean file for co-registration
        % creating a file named tempB0 from the first DTI NIFTI file
        meanfile = 'tempB0.nii';
        if exist(fullfile( dtiPath, [ dtiFilePrefix '_001.nii' ] ), 'file')
            copyfile( fullfile( dtiPath, [ dtiFilePrefix '_001.nii' ] ), ...
                fullfile( dtiPath, meanfile ) );
        else
            copyfile( fullfile( dtiPath, [ dtiFilePrefix '_01.nii' ] ), ...
                fullfile( dtiPath, meanfile ) );
        end
        
        % now we enter the mean file that will be jiggled about to best
        % match the reference image (SPGR).
        matlabbatch{1}.spm.spatial.coreg.estwrite.source = ...
            cellstr( strcat( [ dtiPath '\' meanfile ], ',1' ) );
        
        % now we enter the images (=fiber files) that need to remain in alignment with the source image (the mean file)
        matlabbatch{1}.spm.spatial.coreg.estwrite.other = cellstr( strcat( [ fibersPath '\' ], FibersFilesToCoreg, '.nii,1' ) );
        
        % save( 'dbg5' )
        spm_jobman( 'run', matlabbatch );
    end
    
    
    % ---------------------------------------- Present Results ----------------------------------------
    %     fprintf('Superimpose file(s) on SPGR...\n');
    
    % updating waitbar
    step = step + 3;
    str = sprintf('Applying superimpose processing (%d/%d)\nSuperimpose file(s) on SPGR..', curFileList_index, numel(ind));
    waitbar(step/100, h, str,...
        'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
    
    % check if all files are rest files and if so, check if you need to
    % change the SPGR and change it accordingly to what was selected.
    % we need to check if we need a different SPGR file for the DTI
    % co-registration
    % but first we need to check if all fiules are DTI files!
    files = superimpose_list(:,1);
    isAllRestFile = regexpi( files, 'rest', 'match');
    
    % if one of the cells is empty - than it means that not all are Rest
    % files, which means that we cannot use the SPGR used for dti
    % files..
    if (isempty(find(cellfun(@isempty,isAllRestFile))))
        if ~isempty(restSPGRfile)
            anatomyfile = restSPGRfile;
            
            % check if there is SPGR file - if not - copying the existing file.
            if isempty(dir(fullfile( subPath, 'viewer', anatomyfile )))
                source = fullfile( anatomyPath, anatomyfile );
                destination = fullfile( subPath, 'viewer');
                copyfile( source, destination );
            end
        else
            anatomyfile = subInfo.SPGR;
        end
    end
    
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
    
    % change file name to reflect the files superimposed!
    mricronFilename = fullfile( subPath, 'viewer', ['viewSuperimposed_'  newSeriesName '.bat'] );
    mricronFID = fopen( mricronFilename, 'wt' );
    fprintf( mricronFID, 'start /MAX mricron .\\%s ', anatomyfile);
    
    % --- load Superimposed Files
    for jj = 1:size( superimpose_list, 1 ),
        filename = superimpose_list{jj,1};
        intensityValue = str2double(superimpose_list{jj,2});
        viewerColor = str2double(superimpose_list{jj,3});
        
        isBinFile = regexp(filename, 'bin', 'match');
        if ~isempty([isBinFile{:}])
            
            % copying to the viewer folder a copy of the original fiber file
            %(bin file) and a copy of the coregistered fiber file (rbin file).
            destination = fullfile(viewerFilesPath);
            if ~exist( destination ,'dir'),
                mkdir( destination );
            end
            
            fiberPath = fullfile( fibersPath, [ filename '.nii' ] );
            source = fiberPath;
            copyfile( source, destination );
            
            coreg_fiberPath = fullfile( fibersPath, [ 'r' filename '.nii' ] );
            source = coreg_fiberPath;
            copyfile( source, destination );
            
            % preparing the parameters for the mricron batch file
            coreg_fileName_forMricron = fullfile( '.', 'files', [ 'r' filename '.nii' ] );
            colorBounds = ' -l 1 -h 1 ';
            threshold = 80;
            
            % load the coregistered fiber's header information (coregHdr) and its image matrix (coregImg)
            [ hdr, filetype, fileprefix, machine ] = load_nii_hdr( coreg_fiberPath );
            [ coregImg, coregHdr ] = load_nii_img( hdr, filetype, fileprefix, machine );
            
            % creating a vector of all cells indices that have a value
            % greater than the threshold
            maskFibers = find( coregImg(:) > threshold );
            
        else %FMRI
            
            % let's see if fMRIsession field exist - and if it does we'll go over it
            % and search for the relevant fmri folder
            if isfield(subInfo, 'fMRIsession')
                fields = subInfo.fMRIsession;
                fieldnameToAccess = fieldnames(fields);
                
                % file - the fmri file from the superimpose_list
                % this line will get you everything up to the cluster sizee
                
                file = lower(regexpi(char(filename), 'rest', 'match'));
                
                if isempty(file)
                    file = lower(regexp(filename, '^[^\d+]+(?=c)', 'match'));
                end
                
                if isempty(file)
                    file = filename;
                end
                
                file = char(strrep(file, '_', ''));
                %                 file = lower(regexp(filename, '^[^_]+(?=_)', 'match'));
                %                 file = char(strrep(file, '_', ''));
                
                % going over the fmri fields in subInfo and checking if our file
                % matches one of them.
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
                        fmriFiles = fullfile( fullSeriesFuncPath, 'Results', [ filename  '.*'] );
                        
                        if ~isempty(dir(fmriFiles))
                            fprintf('Found: %s\n', fmriFiles);
                            copyfile( fmriFiles, viewerFilesPath );
                            break
                        else
                            foundStr = 0;
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
                    dirType = regexpi(lower(dirs), '^(?=.*\<(?:dti20|dti_41|li|anat|func|out)\>).*', 'match');
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
                                            if exist(fullfile(resultsPath, [filename '.hdr']), 'file') || ...
                                                    exist(fullfile(resultsPath, [filename '.nii']), 'file')
                                                foundStr = 1;
                                                
                                                % copying the img and hdr of the activation file into the
                                                % superimpose folder in the viewer (they were already
                                                % coregistered in previous preprocessing)
                                                % copying to the viewer folder a copy of the original fmri file (copy file)
                                                fmriFiles = fullfile( eegLagsPath, curSess, curLag, 'Results', [ filename  '.*'] );
                                                if ~isempty(dir(fmriFiles))
                                                    fprintf('Found: %s\n', fmriFiles);
                                                    copyfile( fmriFiles, viewerFilesPath );
                                                    break
                                                else
                                                    foundStr = 0;
                                                end
                                            end
                                        end
                                    end
                                    if foundStr
                                        break
                                    end
                                end
                                if foundStr
                                    break
                                end
                            else
                                curDir = fullfile(analysisPath, dirs{idx(n)});
                                % now lets set the fmri files..
                                % find if the file exists
                                if exist(curDir, 'file')
                                    if isequal(dirs{idx(n)}, [filename '.hdr']) ||...
                                            isequal(dirs{idx(n)}, [filename '.nii'])
                                        
                                        foundStr = 1;
                                        % copying the img and hdr of the activation file into the
                                        % superimpose folder in the viewer (they were already
                                        % coregistered in previous preprocessing)
                                        % copying to the viewer folder a copy of the original fmri file (copy file)
                                        fmriFiles = fullfile( analysisPath, [ filename  '.*'] );
                                        if ~isempty(dir(fmriFiles))
                                            fprintf('Found: %s\n', fmriFiles);
                                            copyfile( fmriFiles, viewerFilesPath );
                                            break
                                        else
                                            foundStr = 0;
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                
                if foundStr
                    
                    % preparing the parameters for the mricron batch file
                    %coreg_fileName_forMricron = fullfile( viewerFilesPath, [ filename '.hdr'] ); % changed by Tomer 3/5/17 because of bug in file path.
                    coreg_fileName_forMricron = fullfile(  '.', 'files', [ filename '.hdr'] );
                    
                    isEEG = regexp(lower(filename), 'lag', 'match');
                    if writeOutputDicoms,
                        % before we upload the files, we need to check if we
                        % need to reslice them
                        % coregister EEG-fMRI session
                        % we coregisterthe patient's data to the his \ her SPGR.
                        
                        if ~isempty(isEEG)
                            fprintf('\n\nInitializing SPM12...\n');
                            spm_jobman('initcfg');
                            spm('defaults','FMRI');
                            
                            % updating waitbar
                            step = step + 3;
                            str = sprintf('Applying superimpose processing (%d/%d)\nApplying fMRI Coregistration..', curFileList_index, numel(ind));
                            waitbar(step/100, h, str,...
                                'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
                            
                            % clear matlabbatch variable
                            clear matlabbatch;
                            
                            % loading the matlabbatch template file
                            load( fullfile(  templatePath, 'Coregister_Reslice_template.mat' ) );
                            
                            % set the image that is assumed to remain stationary (SPGR)
                            matlabbatch{1}.spm.spatial.coreg.write.ref = ...
                                cellstr( strcat( [ anatomyPath '\'  anatomyfile ], ',1' ) );
                            
                            % now we enter the mean file that will be jiggled about to best
                            % match the reference image (SPGR).
                            if exist( fullfile(viewerFilesPath, [filename '.img' ]), 'file')
                                matlabbatch{1}.spm.spatial.coreg.write.source = ...
                                    cellstr( strcat( [ viewerFilesPath '\' filename '.img'], ',1' ) );
                            elseif exist( fullfile(viewerFilesPath, [filename '.nii' ]), 'file')
                                matlabbatch{1}.spm.spatial.coreg.write.source = ...
                                    cellstr( strcat( [ viewerFilesPath '\' filename '.nii'], ',1' ) );
                            end
                            
                            spm_jobman( 'run', matlabbatch );
                            
                            filename = ['r' filename];
                        end
                    end
                    
                    if exist( fullfile(viewerFilesPath, [filename '.hdr' ]), 'file')
                        [ fMRIhdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [filename '.hdr' ]) );
                    else
                        coreg_fileName_forMricron = fullfile( '.', 'files', [ filename '.nii'] );
                        [ fMRIhdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [filename '.nii' ]) );
                    end
                    
                    
                    %                     if exist( fullfile(viewerFilesPath, [filename '.hdr' ]), 'file')
                    %                         [ fMRIhdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [filename '.hdr' ]) );
                    %                     else
                    %                         coreg_fileName_forMricron = fullfile( '.', 'files', [ filename '.nii'] );
                    %                         [ fMRIhdr, filetype, fileprefix, machine ] = load_nii_hdr( fullfile(viewerFilesPath, [filename '.nii' ]) );
                    %                     end
                    %
                    threshold = 0;
                    
                    % loading the fmri file header and changing several parameters
                    [ coregImg, coregHdr ] = load_nii_img( fMRIhdr, filetype, fileprefix, machine );
                                        
                    %outFunc_nii = load_untouch_nii( [ fmriFiles(1:end-1) 'hdr' ] );
                    outFunc_nii.hdr = coregHdr;
                    outFunc_nii.img = coregImg;
                    outFunc_nii.hdr.dime.datatype = 2;
                    outFunc_nii.hdr.dime.bitpix = 8;
                    outFunc_nii.hdr.dime.scl_slope = 0;
                    
                    % turn NaN into zero:
                    outFunc_nii.img (isnan(outFunc_nii.img )) = 0;
                    
                    % we go over the fmri image matrix and convert it into a matrix of logicals
                    if sum( outFunc_nii.img(:) ) > 0,  % positive map
                        outFunc_nii.img = outFunc_nii.img > 0;
                        colorBounds = ' -l 0.5 ';
                        if ~isempty(isEEG)
                            threshold = 0.2;
                        end
                    else % negative map
                        outFunc_nii.img = outFunc_nii.img < 0;
                        colorBounds = ' -h -0.5 ';
                        
                        if ~isempty(isEEG)
                            threshold = 0.5;
                        end
                        coregImg = coregImg * (-1);
                    end
                    
                    % we look in the matrix for those cells indices that are greater than the threshold
                    maskFibers = find( coregImg(:) > threshold );
                    outFunc_nii.img = coregImg;
                    save_nii( outFunc_nii, fullfile( viewerFilesPath, [ filename '_bin.nii' ] ) );
                    clear outFunc_nii;
                end
                
            else
                errorStr = sprintf('No such fmri session in subInfo.fMRIsession!');
                error( errorStr );
            end
        end
        
        if createColorMatrix == 0,
            % we are going over the matrix of the SPGR and insert in each place
            % there was a fiber\activation a certain value, calculated as:
            % the location in the coregistered image * saturationValue *
            % intensityValue / maximum value in the coregistered image
            superimposedSPGR( maskFibers ) = double(coregImg( maskFibers )) * SaturationValue * intensityValue / double(max(coregImg(:)));
        else
            % inserting the colors.. because its RGB we need to rescale it to
            % 255.
            color = rgb(colorScheme{jj}) * 255;
            superimposedSPGRwithColor( maskFibers, 1 ) = color(1);
            superimposedSPGRwithColor( maskFibers, 2 ) = color(2);
            superimposedSPGRwithColor( maskFibers, 3 ) = color(3);
            
        end
        
        % updating the mricron batch file
        % changing the file name, if it contains an ampersand (&) we need to
        % add ^ so that the file could be reachable
        coreg_fileName_forMricron = strrep(coreg_fileName_forMricron, '&', '^&');
        fprintf( mricronFID, '-o %s %s -c -%d ', coreg_fileName_forMricron, colorBounds, viewerColor );
    end
    
    fclose( mricronFID );
    
    if createColorMatrix == 0,
        % creating a matrix with vector of the SPGR and fibers using the
        % dimension of the SPGR
        outSPGRsuperimposed = reshape(superimposedSPGR, SPGRimgSize );
        outSPGRsuperimposed_nii = make_nii( outSPGRsuperimposed, SPGRhdr.dime.pixdim(2:4) );
        %     SPGRFibersForShow_nii = make_nii( reshape(superimposedSPGR, SPGRsize ), SPGRhdr.dime.pixdim(2:4) );
        
        % saving the activations and fibers on the spgr
        save_nii( outSPGRsuperimposed_nii, fullfile( viewerFilesPath, [ 'Superimposed_' newSeriesName '_bin.nii' ] ) );
        
    else % generate color matrix
        outSPGRcoregImgColor( :,:,:,1 ) = reshape(superimposedSPGRwithColor(:,1), SPGRimgSize );
        outSPGRcoregImgColor( :,:,:,2 ) = reshape(superimposedSPGRwithColor(:,2), SPGRimgSize );
        outSPGRcoregImgColor( :,:,:,3 ) = reshape(superimposedSPGRwithColor(:,3), SPGRimgSize );
        
        % taking one representative slice (#30) - just to check if its visually
        % good.
        colorImage(:,:,1) = outSPGRcoregImgColor( :,:,30,1);
        colorImage(:,:,2) = outSPGRcoregImgColor( :,:,30,2);
        colorImage(:,:,3) = outSPGRcoregImgColor( :,:,30,3);
        % figure; image( colorImage );
        outSPGRsuperimposed_nii = make_nii( outSPGRcoregImgColor, SPGRhdr.dime.pixdim(2:4) );
        %save_nii( outSPGRsuperimposed_nii, fullfile( viewerFilesPath, [ filename 'outSPGRsuperimposed_bin.nii' ] ) );
    end
    % view_nii( SPGRwithFibers_nii);
    % view_nii( SPGRFibersForShow_nii );
    
% % % %     % runPython multislice from matlab - for hadas
% % % %     % creating a bat file with the following parameters:
% % % %     multisliceFilename = fullfile( subPath, 'viewer', ['createMultislice_'  newSeriesName '.bat'] );
% % % %     multisliceFID = fopen( multisliceFilename, 'wt' );
% % % %         
% % % %     pyFuncName = 'M:\clinica\Hadas\Python_scripts\createMultisliceImagesMatlab.py';
% % % %     isAllBin = regexp(superimpose_list(:,1), 'bin', 'match');
% % % %     if (isempty(find(cellfun(@isempty,isAllBin), 1)));
% % % %         files4Py = [];
% % % %         files4PyColor = [];
% % % %         if (size(isAllBin, 1) == 1)
% % % %             files4Py = [ fullfile( viewerFilesPath, [ superimpose_list{:,1} '.nii'] )  ' None'];
% % % %             files4PyColor = [superimpose_list{:,3} ' None'];
% % % %         else
% % % %             for g = 1:size(superimpose_list(:,1), 1)
% % % %                 files4Py = [files4Py ' ' fullfile( viewerFilesPath, [ superimpose_list{g,1} '.nii'] )]
% % % %                 files4PyColor = [files4PyColor ' ' superimpose_list{g,3}];
% % % %             end
% % % %         end
% % % %     end
% % % %     
% % % %     str = [pyFuncName ' ' subPath ' ' fullfile( anatomyPath, anatomyfile ) ' ' files4Py ' ' files4PyColor];
% % % %     fprintf( multisliceFID, '%s', str);
% % % %     fclose(multisliceFID);
    
    % --------------------------- output coregstration result on DICOM files --------------------------
    
    if writeOutputDicoms,
        fprintf('Creating superimposed dicom files..\n');
        
        %         step = (step + 1)/100;
        %         waitbar(step, h, sprintf('Applying superimpose processing (%d/%d)\nCreating DICOMs (%d/%d)', curFileList_index, numel(ind), 0, SPGRimgSize(3)), 'windowstyle', 'modal');
        
        if ~exist( dicomOutputPath,'dir' )
            mkdir( dicomOutputPath );
        end
        
        t = clock;
        SeriesDate = [ num2str(t(1)), num2str(t(2),'%0.2d'), num2str(t(3),'%0.2d') ];
        SeriesTime = [ num2str(t(4),'%0.2d'), num2str(t(5),'%0.2d'), num2str(floor(t(6)),'%0.2d') ];
        
        SeriesUID = dicomuid;
        % (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se
        SPGRseries = regexp(anatomyfile, '[^SPGR]+(\w*.*)[^nii]', 'tokens');
        SPGRseries = SPGRseries{1};
        SPGRdicomPath = fullfile( subPath, [subInit '_'  SPGRseries{:}]);
        SPGRdicomFiles = dir( fullfile( SPGRdicomPath, '*.dcm') );
        templateSeriesFile = SPGRdicomFiles(1).name(1:8);
        outputSeriesFile = templateSeriesFile;
        outputSeriesFile(3) = newSeriesPrefix;
        
        % (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se
        oldSeriesNumber = regexp(SPGRdicomPath, '(?<=Se)\d+', 'match');
        
        for jj = 1:SPGRimgSize(3),
            
            % updating waitbar
            step = step + jj/SPGRimgSize(3);
            str = sprintf('Applying superimpose processing (%d/%d)\nCreating DICOMs (%d/%d)', curFileList_index, numel(ind), jj, SPGRimgSize(3));
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
                    status = dicomwrite(flipud( rot90(outSPGRsuperimposed(:,:,jj))), outputFileName, metadata, 'CreateMode', 'Copy' );
                else
                    status = dicomwrite( rot90(outSPGRsuperimposed(:,:,jj)), outputFileName, metadata, 'CreateMode', 'Copy' );
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
end

fclose( 'all' );

step = 100/100;
waitbar(step, h, sprintf('Finished!'))
pause(0.1)
close;

fprintf('Finished!\n');

end