function xjViewActivationsTomerJuly17(subInfo, fullSeriesName, spmTfile, anatomyfile, detailsStr)

% 11.2014 - modified by THM
FileVersion = 'v1'; %18.02.2016 THM
subPath = subInfo.path;
%subFolder = subInfo;

isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
% if ~isempty(isEEG)
%     resultsPath = fullfile(subPath, 'Analysis', 'EEG_Lags', fullSeriesName);
% else
%     resultsPath = fullfile(subPath, 'Analysis', 'func', fullSeriesName);
% end
% % maybe its in the analysis path?
% if ~exist(resultsPath, 'dir')
%     resultsPath = fullfile(subPath, 'Analysis', fullSeriesName);
% end
resultsPath='M:\clinica\patients\Full_Scans\7-July\Shoshan_Noa\Analysis\func\Se25_Aud_Def_Spanish(61rep)\withArt'
%------------------------------------ ViewActivations parameters %------------------------------
xjviewFolder = '\\fmri-t2\clinica$\Scripts';
Lag = 0; % The delay between the action and the brain response.
% 0-->2*TR     1-->3*TR     -1-->1*TR      -2-->0*TR
initThreshold = 0.01;
% clusterSizeThreshold = 5;
% ----------------------------------------------------------------------------------------------

disp( [ 'ViewActivations script version: ' FileVersion ] );
addpath( xjviewFolder );

% set Lag delay
global DELAY;
switch Lag
    case -2
        DELAY = 0;
    case -1
        DELAY = 1;
    case 0
        DELAY = 2;
    case 1
        DELAY = 3;
end

% waitfor(msgbox('Please do uble-check that the tumor is on the correct side!!'));

% %===================== run xjviewer tool ====================
cd(resultsPath)
xjview8Clinic_spm12_Tomer(spmTfile);
hXJVIEW = gcf;


% Update handles structure
handles = guidata( hXJVIEW );

if isempty(handles)
    close;
    hXJVIEW = gcf;
    
end
handles = guidata( hXJVIEW );

handles.pValue = initThreshold;
handles.sectionViewTargetFile = anatomyfile;
handles.rootFolder = subPath;
handles.file4D = [];

% detailsStr{end+2} = 'Matrix:';
% detailsStr{end+1} = num2str(handles.M{1});
% detailsStr{end+2} = 'Dimensions:' ;
% detailsStr{end+1} = num2str(handles.DIM{1});
% handles.subDetails = detailsStr;

guidata(hXJVIEW, handles);

% set p value
set( handles.pValueEdit, 'String', num2str( initThreshold ) );
tempFunc = get( handles.allIntensityRadio, 'Callback' );
tempFunc( hXJVIEW, [], 'c' );
tempFunc = get( handles.pValueEdit, 'Callback' );
tempFunc( handles.pValueEdit, [] );
%
% % set cluster size
% % handles = guidata(hXJVIEW);
% handles.clusterSizeThreshold = clusterSizeThreshold;
% tempFunc = get( handles.allIntensityRadio, 'Callback' );
% tempFunc( hXJVIEW, [], 'c' );
% tempFunc = get( handles.clusterSizeThresholdEdit, 'Callback' );
% set( handles.clusterSizeThresholdEdit, 'String', clusterSizeThreshold );
% tempFunc( handles.clusterSizeThresholdEdit, [] );

% % % % set(handles.infoTextBox, 'string', handles.subDetails);

% set( handles.pValueEdit, 'String', num2str( initThreshold ) );
% tempFunc = get( handles.allIntensityRadio, 'Callback' );
% tempFunc( hXJVIEW, [], 'c' );
% tempFunc = get( handles.pValueEdit, 'Callback' );
% tempFunc( handles.pValueEdit, [] );

end