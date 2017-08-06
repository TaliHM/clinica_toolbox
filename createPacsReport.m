function createPacsReport(subInfo)

%------------------------ Setting initial parameters %--------------------------
% creating subject's path and initials
subPath = subInfo.path;
subInit = createSubInitials(subInfo);
SPGRpath = fullfile( subPath, 'Analysis', 'anat');

% anatomyfile = subInfo.SPGR;
% (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se

% let's prompt our user to select a file that would be the SPGR
% file
SPGRfile = uigetfile(fullfile(SPGRpath, '*.nii'), 'Select anatomy file') ;

if ischar(SPGRfile)
    anatomyfile = SPGRfile;
else
    SPGRfile = fullfile(subInfo.path, subInfo.SPGR);
    anatomyfile = subInfo.SPGR;
    str = sprintf('New SPGR was NOT selected, using the default one: \n%s', subInfo.SPGR);
    fprintf([str '\n']);
    msgbox(str);
end
fprintf('Selected anatomy file: %s\n', anatomyfile);

SPGRfolder = regexp(anatomyfile, '[^SPGR]+(\w*.*)[^nii]', 'tokens');
SPGRfolder = [SPGRfolder{:}];
% ------------------------------------------------------------------

% first let's check if there is already an fMRI report folder.
% If there is - delete it.
% orgReportPath = dir(fullfile(subPath, 'fMRI_Report*'));

% old way with ReportToAccel
% if ~isempty(orgReportPath)
%     fmriReportName = orgReportPath.name;
%     fprintf('Deleting %s\n', fullfile(subPath, fmriReportName))
%     rmdir(fullfile(subPath, fmriReportName), 's')
%
%     % setting the full path to the raw (original) report folder
%     rawReportPath = fullfile(subPath, 'ReportForAccel');
%
%     % setting the results folder into which the new dicoms will be saved.
%     reportPath = fullfile(subPath, 'fMRI_Report');
% end

allFiles = dir(subPath);
allDirs = allFiles([allFiles.isdir]);
allNames = {allDirs.name};
d = strfind(lower(allNames), 'report');
ind = find(~cellfun(@isempty,d));

if ~isempty(ind)
    if size(ind, 2) > 1
        for k = 1:size(ind)
            
            a = strfind(lower(allNames), ('fmri_report'));
            if ~isempty(a)
                b = find(~cellfun(@isempty,a));
                allNames(b) = [];
            end
            
            a = strfind(lower(allNames), ('reportforaccel'));
            if ~isempty(a)
                b = find(~cellfun(@isempty,a));
                allNames(b) = [];
            end
        end
        d = strfind(lower(allNames), 'report');
        ind = find(~cellfun(@isempty,d));
        
        if size(ind, 2) > 1
            error('Please make sure that you have only one dir with the name report in it..')
        elseif isempty(ind)
            orgReportPath = fullfile(subPath, 'ReportForAccel');
        else
            orgReportPath = fullfile(subPath, allDirs(ind).name);
        end
    else
        orgReportPath = fullfile(subPath, allDirs(ind).name);
    end
else
    orgReportPath = fullfile(subPath, 'ReportForAccel');
end

if ~isempty(dir(orgReportPath))
    source = orgReportPath;
    reportPath = fullfile(subPath, [strrep(subInfo.name, ' ', '_') '_Report']);
    
    if ~exist(reportPath, 'dir')
        movefile(source, reportPath);
    end
    
    % setting the full path to the raw (original) report folder
    source = reportPath;
    rawReportPath = fullfile(source, 'jpg');
    jpgFiles = fullfile(source, '*.jpg');
    if ~isempty(dir(jpgFiles))
        movefile(jpgFiles, rawReportPath)
    else
        rawReportPath = fullfile(source, 'png');
        pngFiles = fullfile(source, '*.png');
        if ~isempty(dir(pngFiles))
            movefile(pngFiles, rawReportPath)
        end
        
        rawReportPath = fullfile(source, 'dcm');
        dcmFiles = fullfile(source, '*.dcm');
        if ~isempty(dir(dcmFiles))
            movefile(dcmFiles, rawReportPath)
        end
    end
    
    
    % moving everything to it (if there are ppt and pdf files wlready in
    % the subPath)
    destination = reportPath;
    source = dir(fullfile(subPath, '*Report.pdf'));
    
    if ~isempty(source)
        movefile(source.name, destination);
    end
    
    source = dir(fullfile(subPath, '*Papers.pdf'));
    
    if ~isempty(source)
        movefile(source.name, destination);
    end
    
    source = dir(fullfile(subPath, '*Report.pptx'));
    
    if ~isempty(source)
        movefile(source.name, destination);
    end
    
    source = dir(fullfile(subPath, '*Report.ppt'));
    
    if ~isempty(source)
        movefile(source.name, destination);
    end
    
    % setting the full path to the spgr folder
    SPGRdicomPath = fullfile( subPath, [subInit '_'  SPGRfolder{:}]);
    
    dcmReportPath = fullfile(reportPath, 'fMRI_Report');
    if (~exist(dcmReportPath, 'dir'))
        mkdir(dcmReportPath);
    end
    
    % (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se
    oldSeriesNumber = regexp(SPGRfolder, '(?<=Se)\d+', 'match');
    oldSeriesNumber = [oldSeriesNumber{:}];
    
    % now let's start taking care of those dicoms...
    % let's take the dcm files of the report
    isDicomFile = dir(fullfile(rawReportPath, '*.dcm'));
    
    if ~isempty(isDicomFile)
        fprintf('Extracting data from DICOM files from: \n%s\n', fullfile(rawReportPath)); 
        reportFiles = isDicomFile;
        s = '%d.dcm#';
        order = 'descend';
    else
        fprintf('Extracting data from JPEG files from: \n%s\n', fullfile(rawReportPath)); 
        reportFiles = dir(fullfile(rawReportPath, '*.jpg'));
        s = 'Slide%d.JPG#';
        order = 'ascend';
    end
    
    reportFileNames = {reportFiles.name}';
    
    % making sure that the dir function (we used two lines ago) does not mess with
    % the files' order.
    % FOR DICOM - we want the order to be backwards...
    % FOR JPG - ascending order
    % (uploading issues - the files upload to the Accel needed to be in
    % a descend order (10-1) - and this is how we recieve them,
    % but the files to be uploaded to the pacs should be in ascend
    % order..(1-10) - so we fix it in the for loop, in the meantime we arrange
    % the files in a desced order..
    str  = sprintf('%s#', reportFileNames{:});
    num  = sscanf(str, s);
    [dummy, index] = sort(num, order);
    reportFileNames = reportFileNames(index);
    
    % let's extract the dicom files from spgr folder
    SPGRfiles = dir( fullfile( SPGRdicomPath, '*.dcm') );
    SPGRfileName = SPGRfiles(1).name;
    
    % Let's set the new parameters of the new dicom files
    % newSeriesPrefix - this will be the new prefix of the new series
    % e.g.: MR016001 --> MR916001
    % (this way we can know the series number of the original folder form which we extracted
    % the metadata)
    newSeriesPrefix = '9';
    outputSeries = SPGRfileName(1:8);
    outputSeries(3) = newSeriesPrefix;
    
    % we need only the template of the first spgr file to create the dicom.
    % however, we need the instance creation time of eich following spgr file
    % so that the report will be in the correct order in the pacs.
    % templateMetadata = dicominfo( fullfile( SPGRpath, SPGRfileName ));
    
    % unique ID (UID) of the dicom file to be written
    SeriesUID = dicomuid;
    
    % we are going over each dcm report file and saving it with the spgr
    % metadata (with slight changes)
    for ind = 1:size(reportFileNames,1)
        
        % we want the new dicoms to appear in a certain order, more
        % specifically in the order of the acquisition time of each dicom.
        % if we take one dicom and attach it's metadata to the report dicoms
        % they will appear in random order in the pacs - we want to avoid that.
        % therefore we take each spgr file at a time and attach its metadata to
        % the current report dicom to be saved.
        curSPGRfile = SPGRfiles(ind).name;
        metadata = dicominfo( fullfile( SPGRdicomPath, curSPGRfile ));
        
        curReportFile = reportFileNames{ind};
        
        if ~isempty(isDicomFile)
            X = dicomread( fullfile( rawReportPath, curReportFile ));
        else
            X = imread(fullfile(rawReportPath, curReportFile));
        end
        
        dcmFileName = fullfile( dcmReportPath , [ outputSeries num2str(ind,'%0.3d') '.dcm' ] );
        
        % in order to create a new series, we change the following parameters:
        metadata.SeriesDescription = 'fMRI_report';
        metadata.SeriesNumber = str2double(newSeriesPrefix)*100 + str2double(oldSeriesNumber);
        metadata.SeriesInstanceUID = SeriesUID;
        
        % and writing that dicom!
        status = dicomwrite(X, dcmFileName, metadata, 'CreateMode', 'Copy' );
        fprintf('Writing dicom page #%d..\n', ind)
    end
    
    fprintf('Finished writing dicom files of the subject''s report!\n')
    winopen(dcmReportPath);
else
    errordlg('No Report Folder was found');
end
end