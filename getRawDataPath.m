function [studyPath, seriesDir] = getRawDataPath(subPath)

studyDir = dir(fullfile(subPath, 'Study*'));

if (length(studyDir) == 1)
    % enter to the study dir and show all series numbers
    studyDirName = studyDir.name;
    studyPath = fullfile(subPath, studyDirName);
    if exist(studyPath, 'dir')
        cd(studyPath)
    end
else
    rawDataDir = 'Raw_Data';
    studyDir = dir(fullfile(subPath, rawDataDir, 'Study*'));
    if ~isempty(studyDir)
        studyDirName = studyDir.name;
        studyPath = fullfile(subPath, rawDataDir, studyDirName);
        if exist(studyPath, 'dir')
            cd(studyPath)
        end
    end
end

if isempty(studyDir)
    rawDataDir = 'Raw_Data';
    studyDir = dir(fullfile(subPath, rawDataDir, 'Series*'));
    
    if ~isempty(studyDir)
        studyPath = fullfile(subPath, rawDataDir);
        if exist(studyPath, 'dir')
            cd(studyPath)
        end
    else
        studyPath = subPath;
    end
end

seriesDir = dir(fullfile(studyPath, 'Series*'));

if ~isempty(seriesDir)
    return
else
    error('NO series folder was found!\n');
end
end
