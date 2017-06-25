function protocolTable = updateSeries(pTable)
% updating the subject's table and checking on the way for errors (e.g.
% mismatch between number of repetitions stated and actual number of files
% in the folder or if we reached an index that does not exist in protocolTable.xlsx)

global subPath

fprintf('uploading protocoleTable.xlsx file..\n\n')
protocolPath = 'M:\protocols-new';
protocolFile = 'ProtocolsTable.xls';
pfile = fullfile(protocolPath, protocolFile);
cd(protocolPath);
if ((exist(pfile, 'file')) == 2)
    [data, txt, protocolFile_raw] = xlsread(pfile);
    % [data, txt, protocolFile_raw] = xlsread(pfile, '', '', 'basic'); % basic for quicker reading
else
    fprintf('%s file was not found!!\n', pfile);
end


protocolTable = pTable;
logicals = cell2mat(protocolTable(:,1));
row2update = find(logicals == 1);
nCol = cell2mat(protocolFile_raw(2:end,2));

for row = 1:length(row2update)
    curRow = row2update(row);
    curCellVal = str2num(protocolTable{curRow, 5});
    if (~isempty(curCellVal)) && (curCellVal < length(nCol))
        newSeriesIndex = find(nCol == curCellVal)+1;
        pName = num2str(protocolFile_raw{newSeriesIndex, 6});
        
        pName = strsplit(pName, {'_', ' '});
        pName = pName(~cellfun('isempty',deblank(pName)));
        
        if isempty(pName)
            % it's an fMRI session BUT it does not match
            % any row in the protocol table? check if its a
            % rest session
            a = strfind(lower(seriesName), 'rest');
            if ~isempty(a)
                %pName = ['Rest(' num2str(length(nfiles)) 'rep)']
                pName = '';
            end
            
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
        
        protocolTable{curRow, 4} = pName;
        
        % checking if number or rep is equal to number of files in the
        % folder
        
        studyDir = dir(fullfile(subPath, 'Study*'));
        
        if isempty(studyDir)
            rawDataDir = 'Raw_Data';
            studyDir = dir(fullfile(subPath, rawDataDir, 'Study*'));
        else
            rawDataDir = '';
        end
        
        if (length(studyDir) == 1)
            % enter to the study dir and show all series numbers
            studyDirName = studyDir.name;
            studyPath = fullfile(subPath, rawDataDir, studyDirName);
            if exist(studyPath, 'dir')
                cd(studyPath)
            end
        else
            studyPath = subPath;
        end
        
        
        %%%%%%
        
        %         studyPath = fullfile(subPath, 'Study');
        %         studyDirName = dir([studyPath '*']);
        %         studyDirName = studyDirName.name;
        
        
        sDir = dir(fullfile(studyPath, 'Series*'));
        %[~,idx] = sort([sDir.datenum]); % sort from oldest to newest
        
        sDirNames = { sDir(:).name };
        %loc = str2num(protocolTable{curRow, 2});
        curPath = fullfile(studyPath, char(sDirNames(curRow)));
        nfiles = dir(curPath);
        nfiles([nfiles.isdir]) = [];
        nRep = regexp(pName, '\d[^rep)]*', 'match');
        nRep = str2num(nRep{:});
        
        protocolTable{curRow, 6} = '';
        % if we do not have the same number of files - set alert
        % and tell me how files there are in the remarks column
        if (length(nfiles) ~= nRep)
            str = sprintf('nDcm = %d; nRep = %d', length(nfiles), nRep);
            protocolTable{curRow, 6} = str;
        end
        
    elseif (curCellVal > length(nCol)) % out of index
        str = sprintf('series Index = %d; nCol = %d', curCellVal, length(nCol));
        protocolTable{curRow, 6} = str;
        protocolTable{curRow, 4} = 'Out of series index! please reselect';
        
    else % isempty(curCellVal)
        protocolTable{curRow, 4} = '';
        protocolTable{curRow, 5} = '';
        protocolTable{curRow, 6} = '';
    end
    
end

end
