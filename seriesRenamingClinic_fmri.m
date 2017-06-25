function subInfo = seriesRenamingClinic_fmri(subInfo, dcm, raw, pTable, curSeriesName_oldFormat, logFID)
% before anything - we need to find out if the current
% folder is the rest session - needed to be treated
% differently because it does not have an index in the
% protocol table

% creating subject's path and initials
subPath = subInfo.path;
subInit = createSubInitials(subInfo);

% creating seriesIndices array
% first column is the series number as designated by the MRI scanner (mri_idx)
% second column is the series number according the clinical fMRI table (pTable_idx).
logicals = cell2mat(pTable(:,1));
pTable(logicals == 0,:) = [];
mri_idx = pTable(:,2);
pTable_idx = pTable(:,5);
seriesIndices = [mri_idx, pTable_idx];
seriesIndices = cellfun(@str2num, seriesIndices, 'UniformOutput', false);

% creating series names array
seriesNames = pTable(:,4);

% studyDirName = dir(fullfile(subPath, 'Study*'));

% studyDir = dir(fullfile(subPath, 'Study*'));
% if (length(studyDir) == 1)
%     % enter to the study dir and show all series numbers
%     studyDirName = studyDir.name;
%     cd(fullfile(subPath,studyDirName))
% else
%     studyDirName = '';
% end
% 
% % if (length(studyDirName) == 1)
% % enter to the study dir and show all series numbers
% studyPath = fullfile(subPath, studyDirName);

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


str = sprintf('Series no. %s', num2str( dcm.SeriesNumber ) );
disp( str );
fprintf( logFID, '\n%s\n', str );
fprintf( logFID, '--------------\n' );

dicomFiles = dir( fullfile( studyPath, curSeriesName_oldFormat, '*.dcm' ) );
isRest = char(regexp(lower(dcm.SeriesDescription), 'rest', 'match'));

if ~isempty(isRest)
    curSeriesName_newFormat = 'Rest';
    curSeriesName_newFormat_path = fullfile( subPath, [ subInit '_Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat ]);
    
    % moving the files of the current series to a new folder with the proper series name
    t = clock;
    startTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
    
    source = fullfile( studyPath, curSeriesName_oldFormat );
    destination = curSeriesName_newFormat_path;
    [status,msg,msgid] = copyfile(source, destination);
    
    % If all is good - we update the log file and rename folder to the series name
    if (status == 1)
        % str = sprintf('%s - Successfully converted Series no. %s to %s', startTime, num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
        str = sprintf('%s - Successfully converted to %s', startTime, curSeriesName_newFormat );
        disp( str );
        fprintf( logFID, '%s\n', str );
    else
        errorStr = sprintf('Failed to convert Series no. %s to %s', num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
        warning( errorStr );
        fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
    end
    
    % updating subInfo structure..
    sName = regexp(lower(curSeriesName_newFormat), '\w*[^(\d*rep)]*', 'match');
    sName = strjoin(sName,'_');
    fieldname = ['se' num2str( dcm.SeriesNumber, '%0.2d') '_' sName];
    
    subInfo.fMRIsession.(fieldname).seriesNumber = dcm.SeriesNumber;
    subInfo.fMRIsession.(fieldname).seriesDescription = curSeriesName_newFormat;
    subInfo.fMRIsession.(fieldname).dcmInfo_org = dcm;
    
else % it's an fmri session thatexists in out protocol table file (and not the rest session)
    % finding the dcm series number and match to the seriesIndices that
    % contains the folders' indices, numbers and names that we need to rename.
    curSeries_pTableIndex = find( [seriesIndices{:,1}] == dcm.SeriesNumber );
    
    % if we have two same series numbers - but they are related to
    % different scans (like, e.g., one series was added from a previous
    % scan).
    % we need the fmri session - so if its a dti or spgr - nothing will be
    % in the second column (that shows the number of protocol table index)
    if (size(curSeries_pTableIndex, 2) > 1)
        for k = 1:size(curSeries_pTableIndex,2)
            if ~isempty(seriesIndices{curSeries_pTableIndex(k),2})
                curSeriesName_newFormat = char(seriesNames(curSeries_pTableIndex(k)));
                curSeries_pTableIndex = curSeries_pTableIndex(k);
                break
            end
        end
    else
        curSeriesName_newFormat = char(seriesNames(curSeries_pTableIndex));
    end
    
    if ~isempty(curSeriesName_newFormat)
        %         curSeriesName_newFormat = strsplit(dcm.SeriesDescription, {'_', ' ', '-', '|'});
        %         curSeriesName_newFormat = curSeriesName_newFormat(~cellfun('isempty',deblank(curSeriesName_newFormat)));
        %
        %         if size(curSeriesName_newFormat,2) == 1
        %             a = strfind(lower(curSeriesName_newFormat), 'ft');
        %             if ~isempty(a{:})
        %                 sName = regexpi(curSeriesName_newFormat, '\w*[^(\d*rep)]*', 'match');
        %                 sName = [sName{:}];
        %                 curSeriesName_newFormat = [upper(sName{1}) '(' sName{2} ')' ];
        %             else
        %                 curSeriesName_newFormat = [curSeriesName_newFormat{:}];
        %             end
        %         end
        %         else
        curSeriesName_newFormat = regexprep(curSeriesName_newFormat,'(\<[a-z])','${upper($1)}');
        %         curSeriesName_newFormat = strjoin(curSeriesName_newFormat, '_');
        %         end
        
        
        curSeriesName_newFormat_path = fullfile( subPath, [ subInit '_Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat ]);
        
        % Verify that all dicom files in this series were copied
        % and checking that number of repetitions (nRep) matches number of
        % dicoms (dicomFiles) in the folder
        nRep = regexp(lower(curSeriesName_newFormat), '\d[^rep)]*', 'match');
        nRep = str2num(nRep{:});
        if (nRep ~= size(dicomFiles, 1))
            errorStr = sprintf('Wrong number of dicom files in Series no. %s - should be %s, found %s', num2str( tempInfo.SeriesNumber ), num2str(nRep), num2str( size( dicomFiles,1) )) ;
            error( errorStr );
            fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
        else
            
            % moving the files of the current series to a new folder with the proper series name
            t = clock;
            startTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
            
            source = fullfile( studyPath, curSeriesName_oldFormat );
            destination = curSeriesName_newFormat_path;
            [status,msg,msgid] = copyfile(source, destination, 'f');
            
            % If all is good - we update the log file and rename folder to the series name
            if (status == 1)
                % str = sprintf('%s - Successfully converted Series no. %s to %s', startTime, num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
                str = sprintf('%s - Successfully converted to %s', startTime, curSeriesName_newFormat );
                disp( str );
                fprintf( logFID, '%s\n', str );
            else
                errorStr = sprintf('Failed to convert Series no. %s to %s', num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
                warning( errorStr );
                fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
            end
            
            
            % Extract data from Protocol file about conditions their duration and names
            nCol = cell2mat(raw(2:end,2));
            if (curSeries_pTableIndex < length(nCol)) % we are within the range of nCol
                % the index we should look in the protocolTable.xlsx.
                curSeriesIndex = seriesIndices{curSeries_pTableIndex, 2};
                curSeriesIndex = find(nCol == curSeriesIndex)+1; % + 1 becuase we copied the column without the header
                
                % this is the path to the location of the relevant protocol file
                % (the prt file)
                seriesPath = raw{curSeriesIndex,5};
                
                % go to the prt file and copy it to the subject's current series
                % folder
                prtFile = [raw{ curSeriesIndex, 4 } '.prt' ];
                
                % copying the file to the relevant dir
                source = fullfile( seriesPath, prtFile );
                destination = fullfile( curSeriesName_newFormat_path, prtFile ) ;
                copyfile( source, destination);
                
                % getting number of conditions from the series prt file
                % first, let's remove the blank lines rom the prtData
                fileID = fopen(fullfile( seriesPath, prtFile ),'r', 'n', 'US-ASCII');
                prtData_withBlankLines = textscan(fileID,'%s','Delimiter','\n');
                prtData_withBlankLines = [prtData_withBlankLines{:}];
                prtData = prtData_withBlankLines;
                prtData = prtData(~cellfun('isempty', prtData));
                
                % updating subInfo structure..
                sName = regexp(lower(curSeriesName_newFormat), '\w*[^(\d*rep)]*', 'match');
                sName = strjoin(sName,'_');
                fieldname = ['se' num2str( dcm.SeriesNumber, '%0.2d') '_' sName];
                
                subInfo.fMRIsession.(fieldname).seriesNumber = dcm.SeriesNumber;
                subInfo.fMRIsession.(fieldname).seriesDescription = curSeriesName_newFormat;
                subInfo.fMRIsession.(fieldname).dcmInfo_org = dcm;
                subInfo.fMRIsession.(fieldname).prtFile = prtData;
                
                p = strfind(prtData, 'NrOfConditions:');
                r = find(~cellfun(@isempty,p));
                nCon_line = prtData{r};
                nCon = str2num(cell2mat(regexp(nCon_line, '\d', 'match')));
                
                % checking throughout the prt file to see if this is really
                % the number of condition (we just check how many times the
                % word 'Color' appears - should be the same as the
                % number of conditions - nCon).
                exp = '^Color: \d* \d* \d*';
                p = regexp(prtData, exp, 'match');
                conColors_lineIndex = find(~cellfun(@isempty,p));
                
                if (nCon ~= size(conColors_lineIndex, 1)) ,
                    error( [ 'Mismatch of conditions when reading prt file: ' fullfile( seriesPath, prtFile) ] );
                end
                
                Conds_and_Onsets = [];
                Conds_and_Durations = [];
                condNames = [];
                
                % going over each condition, extracting number of onsets,
                % condition names and their durations
                for curCon = 1:nCon-1, % minus 1 since blank is not a condition
                    startRange = conColors_lineIndex(curCon)+1;
                    endRange = conColors_lineIndex(curCon+1)-1;
                    conRange = prtData(startRange:endRange);
                    
                    condNames{curCon} = conRange{1};
                    numOfOnsets = str2num(conRange{2});
                    
                    onsetExp = '\d*[^\d*]';
                    split1 = regexp(conRange(3:end), onsetExp, 'match');
                    condOnsets = str2double(cellfun(@(x) x{1},split1, 'UniformOutput', false));
                    
                    endExp = '\s*[^\d*]\d*';
                    split1 = regexp(conRange(3:end), endExp, 'match');
                    endOnsets = str2double(cellfun(@(x) x{1},split1, 'UniformOutput', false));
                    
                    Conds_and_Onsets(1:size(condOnsets,1), curCon) = condOnsets;
                    Conds_and_Durations(1:size(condOnsets,1), curCon) = endOnsets-condOnsets;
                    
                end
                
                % updating subInfo structure..
                subInfo.fMRIsession.(fieldname).condNames = condNames;
                subInfo.fMRIsession.(fieldname).condOnsets = Conds_and_Onsets;
                subInfo.fMRIsession.(fieldname).condDurations = Conds_and_Durations;
                
                Condition_Names = condNames;
                save( fullfile( curSeriesName_newFormat_path, 'paradigm.mat' ), 'Conds_and_Onsets', 'Conds_and_Durations' );
                save( fullfile( curSeriesName_newFormat_path, 'Conds_Names.mat' ), 'Condition_Names');
                
                % Saving contrast names
                contrasts = {};
                
                cName = 7; % contrast name
                cNum = 8; % contrast weights
                r = cellfun(@(x) any(isnan(x(:))), raw(curSeriesIndex,cName:end));
                nanCell = find(r, 1, 'first');
                % we found the nan cell - which is 1 cell beyond the index
                % we need. so we subtract it and devide by 1 (because half
                % of the cells are names and half are weights)
                cellCount = ((nanCell-1)/2);
                
                % two options that nanCell would be empty:
                % 1. the first contrast cell is nan (which is ok)
                % 2. contrast list is full with contrasts (and we want to
                % catch this option)
                if isempty(nanCell) && ischar(raw{curSeriesIndex,size(r,2)})
                    % here we don't need -1 because we get to the end of
                    % the contrast list (no nans at all). we do -6 because
                    % we need to include cell #7.
                    cellCount = ((size(raw,2)-6)/2);
                end
                
                if (cellCount > 0)
                    for cRow = 1:cellCount
                        curContrast = strrep(raw{curSeriesIndex, cName}, '.', '');
                        contrasts{cRow,1} = curContrast;
                        contrasts{cRow,2} = str2num(raw{curSeriesIndex, cNum});
                        
                        cName = cName +2;
                        cNum= cNum+2;
                        % fprintf('\n%s\t[%s]',contrasts{cRow,1}, num2str(contrasts{cRow,2}));
                    end
                    % fprintf('\n');
                    
                    % updating subInfo structure..
                    subInfo.fMRIsession.(fieldname).contrasts = contrasts;
                    save( fullfile( curSeriesName_newFormat_path, 'Contrasts.mat' ), 'contrasts' );
                end
            end
        end
        
        % if it is an fmri session but it does not exists in our protocol table file
        % and it's not a rest sessin..
    else
        %         curSeriesName_newFormat = char(pTable(curSeries_pTableIndex,3));
        %         curSeriesName_newFormat = strrep(lower(curSeriesName_newFormat), 'fmri_', '');
        
        curSeriesName_newFormat = strsplit(dcm.SeriesDescription, {'_', ' ', '-', '|'});
        curSeriesName_newFormat = curSeriesName_newFormat(~cellfun('isempty',deblank(curSeriesName_newFormat)));
        
        
        %maybe it's an eeg-fmri session? we will know by checking the
        %path
        % searching for the Analysis in the path string and
        % extracting the name before it
        isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
        
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
        
        curSeriesName_newFormat_path = fullfile( subPath, [ subInit '_Se' num2str( dcm.SeriesNumber, '%0.2d' ) '_' curSeriesName_newFormat ]);
        
        % moving the files of the current series to a new folder with the proper series name
        t = clock;
        startTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
        
        source = fullfile( studyPath, curSeriesName_oldFormat );
        destination = curSeriesName_newFormat_path;
        [status,msg,msgid] = copyfile(source, destination);
        
        % If all is good - we update the log file and rename folder to the series name
        if (status == 1)
            % str = sprintf('%s - Successfully converted Series no. %s to %s', startTime, num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
            str = sprintf('%s - Successfully converted to %s', startTime, curSeriesName_newFormat );
            disp( str );
            fprintf( logFID, '%s\n', str );
        else
            errorStr = sprintf('Failed to convert Series no. %s to %s', num2str( dcm.SeriesNumber ), curSeriesName_newFormat );
            warning( errorStr );
            fprintf( logFID, '\nWarning !! %s\n\n', errorStr );
        end
        
        % updating subInfo structure..
        sName = regexp(lower(curSeriesName_newFormat), '\w*[^(\d*rep)]*', 'match');
        sName = strjoin(sName,'_');
        fieldname = ['se' num2str( dcm.SeriesNumber, '%0.2d') '_' sName];
        
        subInfo.fMRIsession.(fieldname).seriesNumber = dcm.SeriesNumber;
        subInfo.fMRIsession.(fieldname).seriesDescription = curSeriesName_newFormat;
        subInfo.fMRIsession.(fieldname).dcmInfo_org = dcm;
        
    end
    save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
end
% end
end