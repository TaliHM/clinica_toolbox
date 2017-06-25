function [subInfo] = setDefaultParameters(subInfo)
% setting the default parameters for future preprocessing
% (processWithFullCoreg and superimpose)

subPath = subInfo.path;

%% general parameters
subInfo.parameters.templatePath = 'M:\Scripts\BatchTemplates\templates_SPM12';
%subInfo.parameters.viewerPath = 'M:\viewer_SPM';
subInfo.parameters.dti_nDirections = 41;
subInfo.parameters.fileTemplate = 'vol';
subInfo.parameters.volumesFormat = 'nii';
subInfo.parameters.dtiFilePrefix = 'dti';

%% parameters for processWithFullCoreg
subInfo.parameters.maxTranslation = 3;
subInfo.parameters.maxRotation = 0.5;
subInfo.parameters.acquisitionOrder = 0; % 0 - top-down; 1 - bottom-up

% smooth size is different between eeg and fMRI
subInfo.parameters.smoothSize = 4;
isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
if ~isempty(isEEG)
    subInfo.parameters.smoothSize = 6;
end

% lag is also different between eeg a fmri
subInfo.parameters.lag = 0;
isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
if ~isempty(isEEG)
    subInfo.parameters.lag = [1, 0, -1, -2, -3, -4, -5 ];
end

% how many volumes to skip at the beggining
% if its the old magnet (GE) than we need to take off the first 6 volumes.
% otherwise - only 3 volumes to be skipped.
% eeg - 0 skipped
scannerName = subInfo.dcmInfo_org.Manufacturer;
if strfind(scannerName, 'GE')
    subInfo.parameters.nFirstVolumesToSkip = 6;
end

isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
if ~isempty(isEEG)
    subInfo.parameters.nFirstVolumesToSkip = 0;
else
    subInfo.parameters.nFirstVolumesToSkip = 3;
end

%% parameters for superimpose
subInfo.parameters.upDownFlip = 0; % if it's simens than we should not do up down flip.
subInfo.parameters.infSupFlip = 0; % does a inferior-superior flip is needed?
% subInfo.parameters.writeOutputDicoms = 1; % if DICOM results wanted as well
% subInfo.parameters.createColorMatrix = 0; % DICOM with colors..!

%% parameters for lateralization index
subInfo.parameters.createOccMask = 1;
subInfo.parameters.handedness = 0;% 0 = right handed, 1= left handed
subInfo.parameters.reverseMask = 0;
subInfo.parameters.reverseLR = 0;
subInfo.parameters.minDist = 5;

%% parameters for rest processing
subInfo.parameters.cutoff = [0.01,0.08]; %Hz cutoff of bandpass filter
subInfo.parameters.roiRadius = 2; % sphere radius size
subInfo.parameters.wmCenter = [];
subInfo.parameters.csfCenter = [];

%% parameters for eeg processing
subInfo.parameters.globalThresh = 9.0;
subInfo.parameters.motionThresh = 2.0;
subInfo.parameters.applyArt = 1;
subInfo.parameters.fmriFirstTrigger = [];

% saving..
save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
end