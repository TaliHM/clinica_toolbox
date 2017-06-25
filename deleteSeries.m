function protocolTable = deleteSeries(pTable)
% deleting the unmarked series

% going over the array and looking who got a false logical (first col = 0)
% and deleting these folders.
% then we just move the folders to the subject's folder (and not in
% Study-######)
% we are returning the fixed protocolTable with the remaining folders

% delete folders
% going over the array and looking for the false rows.
global subPath
protocolTable = pTable;
logicals = cell2mat(pTable(:,1));
folders2delete = find(logicals == 0);

studyPath = fullfile(subPath, 'Study');
studyDirName = dir([studyPath '*']);
if ~isempty(studyDirName)
    studyDirName = studyDirName.name;
    sDir = dir(fullfile(subPath, studyDirName, 'Series*'));
    sDirNames = { sDir(:).name };
    
    for row = 1:length(folders2delete)
        curFolder = fullfile(subPath, studyDirName, sDirNames{folders2delete(row)});
        rmdir(curFolder, 's');
    end
    
    rehash %Refresh function and file system path caches
end

% update protocolTable - removing all the rows with false (col =1)
protocolTable(logicals == 0,:) = [];
end