function [subInfo, wholeScanSession] = uploadWholeScanSession(subInfo)

fprintf('uploading protocoleTable.xlsx file..\n\n')
protocolPath = '\\fmri-t2\clinica$\protocols-new';
protocolFile = 'ProtocolsTable.xls';
pfile = fullfile(protocolPath, protocolFile);
cd(protocolPath);
if ((exist(pfile, 'file')) == 2)
    [data, txt, protocolFile_raw] = xlsread(pfile);
    % [data, txt, protocolFile_raw] = xlsread(pfile, '', '', 'basic'); % basic for quicker reading
else
    fprintf('%s file was not found!!\n', pfile);
end

if isstruct(subInfo)
    subPath = subInfo.path;
else
    subPath = subInfo;
    subInfo = {};
end

% we need to go to the first dcm file and extract the info by
% ourselves
% let's check how many dicom files in this directory
[studyPath, seriesDir] = getRawDataPath(subPath);

if ~isempty(seriesDir)
    seriesDirName = {seriesDir.name}';
    
    % going over each Series..
    for k = 1:size(seriesDirName,1),
        dicomFiles = dir( fullfile( studyPath, seriesDirName{k}, '*.dcm' ) );
        % let's get the info from the dcm file of the current series
        if ~isempty(dicomFiles)
            dcm = dicominfo( fullfile( studyPath, seriesDirName{k}, dicomFiles(1).name ) );
            break
        end
    end
end

if isfield(dcm.PatientName, 'MiddleName')
    s = lower([dcm.PatientName.FamilyName '_'...
        dcm.PatientName.MiddleName '_'...
        dcm.PatientName.GivenName]);
elseif ~isfield(dcm.PatientName, 'GivenName') && isfield(dcm.PatientName, 'FamilyName')
    s = lower(dcm.PatientName.FamilyName);
elseif ~isfield(dcm.PatientName, 'FamilyName') && isfield(dcm.PatientName, 'GivenName')
    s = lower(dcm.PatientName.GivenName);
else
    s = lower([dcm.PatientName.FamilyName '_'...
        dcm.PatientName.GivenName]);
end


% and setting the gui with the subject's info..
s = strsplit(s, {'_', ' '});
s = lower(s(~cellfun('isempty',deblank(s))));
s = regexprep(s,'(\<[a-z])','${upper($1)}');

isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
% fixing some mess, making all dirs to be in the format of
% number of subject_family name_ given name
if ~isempty(isEEG)
    [p sn e] = fileparts(subPath);
    n = strsplit(sn, {'_', ' '});
    if isnumeric(str2double(n{1}))
        newDirName = [n{1} s];
        newDirName = strjoin(newDirName, '_');
        
        source = subPath;
        destination = fullfile(p, newDirName);
        if ~exist(destination, 'dir')
            movefile(source, destination)
            subPath = destination;
            cd(subPath)
            
            if exist(source, 'dir')
                rmdir(source)
            end
        end
        
    end
end

s = strjoin(s, ' ');
subName = s;

fprintf('\n');
fprintf('Uploading subject''s whole scan session.. \n(this may take a while since I''m loading info from the dcm file of each scan..)\n');

cd(subPath);
% let's see the folders we have and get into the study folder
% find the index of a file \ folder
 [studyPath, seriesDir] = getRawDataPath(subPath);
 
if ~isempty(seriesDir)
    sDirNames = { seriesDir(:).name }';
    
    wholeScanSession = {};
    
    %let's save the series number and description from the dcm file
    fprintf('uploading dicom info:\n')
    for i = 1:size(sDirNames,1)
        d = fullfile(studyPath, sDirNames{i});
        cd(d);
        dcmFiles = dir(fullfile(d, '*.dcm'));
        dcm = dicominfo(dcmFiles(1).name); % because the first two places are for . and ..
        dcmSeriesName = dcm.SeriesDescription;
        dcmSeriesNumber = num2str(dcm.SeriesNumber);
        fprintf('%s --> %s..\n', sDirNames{i}, dcmSeriesName);
        
        wholeScanSession{i, 2} = ['     ' dcmSeriesNumber] ;
        wholeScanSession{i, 3} = dcmSeriesName;
        
        
        % we need to show only the fMRI scans
        % we analyze according to the scan type (fMRI)
        scanType = regexpi(lower(dcmSeriesName), '(fmri|rest)+[^(_| )]*', 'match');
        
        if ~isempty(scanType)
            wholeScanSession{i, 1} = true;
            nfiles = dir(d);
            nfiles([nfiles.isdir]) = [];
            
            % let's set the (optional) series name
            % 1. removing all dots, slashes etc. from the string
            % 2. rebuilding the string with _ between words (this is the
            % format in the protocolTable.xlsx). and trying to find it in
            % the table.
            % 3. check if there is correct number of dicoms in the folder
            seriesNameTmp = strsplit(dcmSeriesName, {' ', '_', '-'}, 'CollapseDelimiters',true);
            seriesName = lower(strjoin(seriesNameTmp(:,2:end), '_'));
            seriesName = regexprep(seriesName, '\.', '');
            
            switch seriesName
                case 'vg_aud'
                    seriesName = 'aud_vg';
                case 'def_aud'
                    seriesName = 'aud_def';
                case 'legs_sensory'
                    seriesName = 'sensory_both_legs';
                case 'hand_sensory'
                    seriesName = 'sensory_both_hands';
                case 'finger_tapping'
                    seriesName = 'ft';
                case 'aud_def_russian'
                    seriesName = 'aud_definitions_russian';
                case '468rep_world_list'
                    seriesName = '468rep_wordlist';
            end
            
            s = lower(protocolFile_raw(:,6));
            seriesLoc = regexp(s, seriesName, 'match');
            [row col] = find(~cellfun(@isempty,seriesLoc));
            
            if (isempty(row))
                seriesName = regexprep(seriesName, '_', '');
                seriesLoc = regexp(s, seriesName, 'match');
                [row col] = find(~cellfun(@isempty,seriesLoc));
            end
            
            pName = '';
            pNum = '';
            wholeScanSession{i, 5} = '';
            wholeScanSession{i, 6} = '';
            mismatch_flag = 1;
            
            if (length(row) == 1)
                pName = num2str(protocolFile_raw{row, 6});
                pNum = num2str(protocolFile_raw{row, 2});
                mismatch_flag = 0;
                
            elseif (length(row) > 1)
                for j = 1:length(row)
                    pName = num2str(protocolFile_raw{row(j), 6});
                    pNum = num2str(protocolFile_raw{row(j), 2});
                    % let's check that we have the same number of fles in the
                    % current folder
                    nRep = regexp(pName, '\d[^rep)]*', 'match');
                    nRep = str2num(nRep{:});
                    
                    % if we do not have the same number of files - set alert
                    % and tell me how many files there are in the remarks column
                    if (length(nfiles) == nRep)
                        mismatch_flag = 0;
                        break
                    end
                end
                % if we got though all the rows and did not find a match -
                % let's state that in the remarks
                if (mismatch_flag == 1)
                    str = sprintf('nDcm = %d; nRep = %d', length(nfiles), nRep);
                    wholeScanSession{i, 6} = str;
                end
            end
            
            pName = strsplit(pName, {'_', ' '});
            pName = pName(~cellfun('isempty',deblank(pName)));
            
            if isempty(pName)
                % it's an fMRI session BUT it does not match
                % any row in the protocol table? check if its a
                % rest session
                %                     a = strfind(lower(seriesName), 'rest');
                %                     if ~isempty(a)
                %pName = ['Rest(' num2str(length(nfiles)) 'rep)']
                pName = '';
                %                     end
                
            elseif size(pName,2) > 1
                pName = regexprep(lower(pName),'(\<[a-z])','${upper($1)}');
                pName = strjoin(pName, '_');
            elseif size(pName,2) == 1
                a = strfind(lower(pName), 'ft');
                if ~isempty(a{:})
                    sName = regexpi(pName, '\w*[^(\d*rep)]*', 'match');
                    sName = [sName{:}];
                    pName = [upper(sName{1}) '(' sName{2} ')' ];
                else
                    pName = [pName{:}];
                end
            end
            
            wholeScanSession{i, 4} = pName;
            wholeScanSession{i, 5} = pNum;
            wholeScanSession{i, 6} = '';
        else
            wholeScanSession{i, 1} = false;
            wholeScanSession{i, 4} = '';
            wholeScanSession{i, 5} = '';
            wholeScanSession{i, 6} = '';
        end
    end
    
    % let's update the subjects structure!
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        if ~isfield(subInfo, 'name'), subInfo.name = subName; end
        if ~isfield(subInfo, 'id'), subInfo.id = dcm.PatientID; end
        if ~isfield(subInfo, 'age'), subInfo.age = dcm.PatientAge(2:3); end
        if ~isfield(subInfo, 'gender'), subInfo.gender = dcm.PatientSex; end
        if ~isfield(subInfo, 'dcmInfo_org'), subInfo.dcmInfo_org = dcm.dcmInfo_org; end
        if ~isfield(subInfo, 'path'), subInfo.path = subPath; end
        if ~isfield(subInfo, 'parameters'), subInfo = setDefaultParameters(subInfo); end
        
        
    else
        subInfo.name = subName;
        subInfo.id = dcm.PatientID;
        subInfo.age = dcm.PatientAge(2:3);
        subInfo.gender = dcm.PatientSex;
        subInfo.dcmInfo_org = dcm;
        subInfo.path = subPath;
        % these fields will be added when cliking on the process button:
        subInfo.wholeScanSession = {};
        subInfo.fMRIsession = {};
        subInfo = setDefaultParameters(subInfo);
    end
    
    fprintf('Saving subInfo.m file..\n');
    save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
end

% elseif (length(studyDir) ~= 1)
%     str = sprintf('more than one study in root directory');
%     errordlg(str)
% end

end
