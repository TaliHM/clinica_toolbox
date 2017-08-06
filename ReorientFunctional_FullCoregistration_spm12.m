% this script reorients an fmri image according to the manual
% coregistration needed (estimated with slicer program)
% and reslices the images according to the SPGR after the manual coregistration
clear all; clc;
fprintf('\n\nInitializing SPM12...\n');
spm_jobman('initcfg');
spm('defaults','FMRI');


load('subInfo.mat');
justToCheck = 0;
pTable = {'', '7'; '', '8'; '', '9'};

% rotate LR,rotate AP, rotate UD
% shifts in x,y and z (mm) and last three are rotations (angles)
% should be taken from slicer first three parameters are:    right forward up pitch roll yaw

% move
right = 0 % cor - right - left
forward = -2 % ax, mov - forward - backward
up = -22 % sag, mov - up-down

% rot
yaw = -2 % ax - right - left
pitch = 6 % sag - forward - backward
roll = 0 % cor left - right

TransformParamsSlicer = [right forward up pitch roll yaw]
%TransformParamsSlicer = [0 0 0 0 0 0]

%%%%%%%%%%%% enter the following parameters %%%%%%%%%%%%%
subPath = subInfo.path
anatomyfile = subInfo.SPGR

fileTemplate = [subInfo.parameters.fileTemplate '_']; % e.g. 'vol_'
volumesFormat = subInfo.parameters.volumesFormat; % 'nii' or 'img'
nFirstVolumesToSkip = subInfo.parameters.nFirstVolumesToSkip;
templatePath = subInfo.parameters.templatePath;

% setting the path to the anat folder and the func folder
subPath = subInfo.path;
analysisPath = fullfile( subPath, 'Analysis' );
anatomyPath = fullfile( analysisPath, 'anat' );
funcPath = fullfile( analysisPath, 'func' );

isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');

sliceTimingPrefix = ['a' fileTemplate];
realignPrefix = ['r' sliceTimingPrefix];
coregPrefix = realignPrefix;

% let's see if fMRIsession field exist - and if it does we'll go over it
% and coregister them one by one
fields = subInfo.fMRIsession;
fieldnameToAccess = sort(fieldnames(fields));

if ~isempty(isEEG)
    % meanavol file will always be in the first folder analyzed in the
    % group.
    meanfile_seriesNumber = str2double(pTable(1,2));
    meanfile_seriesDescription = fields.(fieldnameToAccess{1}).seriesDescription;
    meanfile_fullSeriesName = ['Se' num2str( meanfile_seriesNumber, '%0.2d' ) '_' meanfile_seriesDescription ];
    
    % setting the path to the current series func folder
    meanFilePath = fullfile(funcPath, meanfile_fullSeriesName);
end

foundSeries = 0;
for i = 1:size(pTable, 1)
    for k = 1:size(fieldnameToAccess, 1)
        if str2double(pTable{i,2}) == fields.(fieldnameToAccess{k}).seriesNumber
            foundSeries = 1;
            break
        end
    end
    
    seriesNumber = fields.(fieldnameToAccess{k}).seriesNumber;
    seriesDescription = fields.(fieldnameToAccess{k}).seriesDescription;
    fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
    
    % setting the path to the current series func folder
    fullSeriesFuncPath = fullfile(funcPath, fullSeriesName);
    
    if ~isempty(isEEG)
        meanfile = dir( fullfile( meanFilePath, [ 'mean*.' volumesFormat ] ) );
    else
        % remember that in the realignment stage, in addition to reslicing
        % the images, it also creates a mean of the resliced image.
        % so we need it.
        meanfile = dir( fullfile( fullSeriesFuncPath, [ 'mean*.' volumesFormat ] ) );
    end
    
    if isempty( meanfile )
        errorStr = sprintf('Cant find file mean*.%s', volumesFormat );
        error( errorStr );
    elseif length( meanfile ) > 1,
        errorStr = sprintf('More than one mean*.%s files!', volumesFormat);
        error( errorStr );
    else
        meanfile = meanfile.name;
        if justToCheck
            % if it's the first time we're trying to do orientation - we
            % need to make a copy of the meanavol file so we can play with
            % it (later when we'll be sure this is the reorientation we
            % want - we will save it a s the meanavol file.
            destination = fullfile(fullSeriesFuncPath, ['tmp_' meanfile]);
            %if ~exist(destination, 'file')
            source = fullfile(fullSeriesFuncPath, meanfile);
            copyfile(source, destination);
            
            % and saving original copy
            destination = fullfile(fullSeriesFuncPath, ['org_' meanfile]);
            
            if ~exist(destination, 'file')
                copyfile(source, destination);
            end
            %end
            meanfile = ['tmp_' meanfile];
        else
            source = fullfile(fullSeriesFuncPath, ['tmp_' meanfile]);
            %if ~exist(destination, 'file')
            destination = fullfile(fullSeriesFuncPath, meanfile);
            copyfile(source, destination);
        end
    end
    cd(subPath)
    
    %%%%%%%%%%%%%% the following section changes the header to reorient the
    %%%%%%%%%%%%%% image according to the shifts from slicer
   
    % convert slicer params to SPM params (change degrees to radians etc.)
    transformParamsSPM=TransformParamsSlicer.*[1 1 1 -pi/180 pi/180 -pi/180]
    
    % adding scaling ones and affine zeros
    transformParamsSPM=[transformParamsSPM 1 1 1 0 0 0]
    
     % creating the transfortm matrix
    reorientMatrix = spm_matrix(transformParamsSPM)
    
    
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
    
    %files{length(files)+1} = meanfile;% adding the copymmeanavol file to the ones that need to be resliced
    
    clear matlabbatch
    load( fullfile(  templatePath, 'Reorient_template_spm12.mat' ) );% load reorienting template
    
    matlabbatch{1}.spm.util.reorient.transform.transM = reorientMatrix;
    
    if justToCheck
        fprintf('Doing reorientation on a copy named tmp_meanavol*\n');
        %         source = fullfile(fullSeriesFuncPath, meanfile);
        %         destination = fullfile(fullSeriesFuncPath, ['ORG_' meanfile]);
        %         copyfile(source, destination);
        matlabbatch{1}.spm.util.reorient.srcfiles = cellstr( strcat( [fullSeriesFuncPath '\'], meanfile, ',1' ) );
    else
        
        % save the transform matrix in the subjetc's folder
        subInfo.parameters.reorientMatrix = reorientMatrix;
        save(fullfile(subPath, 'subInfo.mat'), 'subInfo')
        
        matlabbatch = updateMatlabatch4eegProcess(subInfo, pTable, matlabbatch, 'reorient', '');
        
        if ~isempty(isEEG)
            %matlabbatch{1}.spm.util.reorient.srcfiles(end+1) = cellstr( strcat( [meanFilePath '\'], meanfile, ',1' ) );
        else
            matlabbatch{1}.spm.util.reorient.srcfiles = cellstr( strcat( [fullSeriesFuncPath '\'], files, ',1' ) );
            matlabbatch{1}.spm.util.reorient.srcfiles(end+1) = cellstr( strcat( [fullSeriesFuncPath '\'], meanfile, ',1' ) );
        end
        
    end
    
    if ~isempty(isEEG)
        fprintf('\nReorineting %s\n', subInfo.name);
    else
        fprintf('\nReorineting %s - %s\n', subInfo.name, fullSeriesName);
    end
    
    
    fprintf('--------------------------------------------------------\n');
    fprintf('Anatomy file: %s\n', anatomyfile);
    fprintf('mean file: %s\n', meanfile);
    if ~justToCheck
        fprintf('Reorienting on files with the prefix: %s\n', realignPrefix);
    end
    
    spm_jobman( 'run', matlabbatch );
    
    
    %%%%%%%%%%%%%%% after reorienting the header, this section reslices the
    %%%%%%%%%%%%%%% images to the SPGR
    
    if ~justToCheck
        % for eeg-fmri session
        if isempty(isEEG)
            load( fullfile(  templatePath, 'Coregister_reslice_template.mat' ) );
            matlabbatch{1}.spm.spatial.coreg.write.ref = cellstr( strcat(anatomyPath ,'\', anatomyfile, ',1' ) );
            matlabbatch{1}.spm.spatial.coreg.write.source = cellstr( strcat( [fullSeriesFuncPath '\'], files, ',1' ) );
            
            spm_jobman( 'run', matlabbatch );
        end
        break
    else
        if ~isempty(isEEG)
            cmdFile = fullfile( subPath, 'viewer', [ 'checkRegistration_EEG_fMRI_Reorient_meanavol.bat' ] );
        else
            cmdFile = fullfile( subPath, 'viewer', [ 'checkRegistration_' fullSeriesName '.bat' ] );
        end
        
        batchFID = fopen( cmdFile , 'wt' );
        fprintf( batchFID,...
            'start /MAX mricron .\\%s -o %s -l 300 -h 5555 -c -40',...
            anatomyfile, fullfile(meanFilePath, meanfile));
        fclose( batchFID );
        
        %         filename = strrep(filename, '\\fmri-t2\clinica$', 'M:')
        winopen(cmdFile);
        break
    end
end


