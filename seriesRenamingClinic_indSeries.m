function [subInfo, status_flag] = seriesRenamingClinic_indSeries(subInfo)

% scan the current folder and find the new subfolders to apply series
% renaming on
subPath = subInfo.path;

% let's first recheck that all fits. if something does not fit (between
% series index and the series name) - alert the user
studyPath = fullfile(subPath, 'Series');
studyName = dir([studyPath '*']);

if (~isempty(studyName))
    
    [subInfo, wholeScanSession] = uploadWholeScanSession(subInfo);
    
    % let's first inform the table that we need to do them 
    logicals = cell2mat(wholeScanSession(:,1));
    wholeScanSession(logicals == 0) = {1};
    % insert the new series in the proper place in subInfo.wholeScanSession
    for i = 1:size(wholeScanSession, 1)
        curScan = str2double(wholeScanSession{i, 2});
        subInfo_scanSession = str2double(subInfo.wholeScanSession(:,2));
        
        % checking that the series numbers are unique (no doubles)
        idx = find(subInfo_scanSession == curScan);
        
        % no duplicates were found
        if ~isempty(idx)
            subInfo.wholeScanSession(idx,:) = wholeScanSession(i,:);
        else
            newlist = [subInfo.wholeScanSession; wholeScanSession(i,:)]
            newlist_data = newlist(2:end,:);
            
            A = newlist_data(:,2);
            
            C = cell(numel(A));
            [Sorted_A, Index_A] = sort(str2double(A));
            % C(:,1) = strtrim(cellstr(num2str(Sorted_A)));
            C = newlist_data(Index_A,:);
            
            subInfo.wholeScanSession = C;
        end
    end
    
    % save subInfo
    fprintf('Saving subInfo.m file..\n');
    save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
end

% apply seriesRenaming
% pTable = subInfo.wholeScanSession(2:end,:);
% [subInfo, status_flag] = seriesRenamingClinic(subInfo, pTable)

end


