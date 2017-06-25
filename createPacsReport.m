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
fmriReportPath = dir(fullfile(subPath, 'fMRI_Report*'));
if ~isempty(fmriReportPath)
    fmriReportName = fmriReportPath.name;
    fprintf('Deleting %s\n', fullfile(subPath, fmriReportName))
    rmdir(fullfile(subPath, fmriReportName), 's')
end

% setting the full path to the raw (original) report folder
rawReportPath = fullfile(subPath, 'ReportForAccel');

% setting the full path to the spgr folder
SPGRdicomPath = fullfile( subPath, [subInit '_'  SPGRfolder{:}]);

% setting the results folder into which the new dicoms will be saved.
reportPath = fullfile(subPath, 'fMRI_Report');

if (~exist(reportPath, 'dir'))
    mkdir(reportPath);
end

% (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se
oldSeriesNumber = regexp(SPGRfolder, '(?<=Se)\d+', 'match');
oldSeriesNumber = [oldSeriesNumber{:}];

% now let's start taking care of those dicoms...
% let's take the dcm files of the report
dcmReportFiles = dir(fullfile(rawReportPath, '*.dcm'));
dcmReportFileNames = {dcmReportFiles.name}';

% making sure that the dir function (we used two lines ago) does not mess with
% the files' order.
% and we want the order to be backwards...
% (uploading issues - the files upload to the Accel needed to be in
% a descend order (10-1) - and this is how we recieve them,
% but the files to be uploaded to the pacs should be in ascend
% order..(1-10) - so we fix it in the for loop, in the meantime we arrange
% the files in a desced order..
str  = sprintf('%s#', dcmReportFileNames{:});
s = '%d.dcm#';
num  = sscanf(str, s);
[dummy, index] = sort(num, 'descend');
dcmReportFileNames = dcmReportFileNames(index);

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
for ind = 1:size(dcmReportFileNames,1)
    
    % we want the new dicoms to appear in a certain order, more
    % specifically in the order of the acquisition time of each dicom.
    % if we take one dicom and attach it's metadata to the report dicoms
    % they will appear in random order in the pacs - we want to avoid that.
    % therefore we take each spgr file at a time and attach its metadata to
    % the current report dicom to be saved.
    curSPGRfile = SPGRfiles(ind).name;
    metadata = dicominfo( fullfile( SPGRdicomPath, curSPGRfile ));
    
    curReportDCMfile = dcmReportFileNames{ind};
    X = dicomread( fullfile( rawReportPath, curReportDCMfile ));
    dcmReport = fullfile( reportPath , [ outputSeries num2str(ind,'%0.3d') '.dcm' ] );
    
    % in order to create a new series, we change the following parameters:
    metadata.SeriesDescription = 'fMRI_report';
    metadata.SeriesNumber = str2double(newSeriesPrefix)*100 + str2double(oldSeriesNumber);
    metadata.SeriesInstanceUID = SeriesUID;
    
    % and writing that dicom!
    status = dicomwrite(X, dcmReport, metadata, 'CreateMode', 'Copy' );
    fprintf('Writing dicom page #%d..\n', ind)
end

fprintf('Finished writing dicom files of the subject''s report!\n')
winopen(reportPath);
        
end