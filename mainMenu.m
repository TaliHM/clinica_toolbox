function varargout = mainMenu(varargin)
% MAINMENU MATLAB code for mainMenu.fig
%      MAINMENU, by itself, creates a new MAINMENU or raises the existing
%      singleton*.
%
%      H = MAINMENU returns the handle to a new MAINMENU or the handle to
%      the existing singleton*.
%
%      MAINMENU('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAINMENU.M with the given input arguments.
%
%      MAINMENU('Property','Value',...) creates a new MAINMENU or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mainMenu_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mainMenu_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mainMenu

% Last Modified by GUIDE v2.5 22-Jun-2017 22:30:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mainMenu_OpeningFcn, ...
    'gui_OutputFcn',  @mainMenu_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before mainMenu is made visible.
function mainMenu_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mainMenu (see VARARGIN)

% Choose default command line output for mainMenu
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

disp('Adding path: M:\spm12..');
addpath(genpath('M:\spm12'));

disp('Adding path: M:\xjview..');
addpath(genpath('M:\xjview'));

disp('Adding path: M:\clinica\pre-processing scripts\fMRI_scripts_SPM12..');
addpath(genpath('M:\clinica\pre-processing scripts\fMRI_scripts_SPM12'));
fprintf('OK! let''s get working!!\n');


% UIWAIT makes mainMenu wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = mainMenu_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in seriesRenaming.
function seriesRenaming_Callback(hObject, eventdata, handles)
% hObject    handle to seriesRenaming (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of seriesRenaming


% --- Executes on button press in processWithFullCoreg_btn.
function processWithFullCoreg_btn_Callback(hObject, eventdata, handles)
% hObject    handle to processWithFullCoreg_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of processWithFullCoreg_btn
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    processWithFullCoreg;
else
    varargin{1} = subPath;
    processWithFullCoreg(varargin);
end



% --- Executes on button press in superimpose_btn.
function superimpose_btn_Callback(hObject, eventdata, handles)
% hObject    handle to superimpose_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of superimpose_btn
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    superimpose;
else
    varargin{1} = subPath;
    superimpose(varargin);
end

% --- Executes on button press in browse_btn.
function browse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to browse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath

rawDataDir = 'M:\clinica\patients\Full_Scans';
% curMonth = datestr(now, 'mmmm');
% curDir = fullfile(rawDataDir, curMonth);
cd(rawDataDir);
newSubPath = uigetdir(rawDataDir,'Select subject''s folder');

if ischar(newSubPath)
    subPath = newSubPath;
    cd(subPath);
    [p subName e] = fileparts(subPath);
    set(handles.subName, 'String', subName)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        if ~isequal(subInfo.path, subPath)
            str = sprintf('subInfo.path = %s,\nChosen dir    = %s.\nShould I change it to the current path?', subInfo.path, newSubPath);
            choice = questdlg(str, ...
                'Change Path?', ...
                'Yes','No', 'Yes');
            if isequal(choice, 'Yes')
                subInfo.path = subPath;
                save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
            end
        end
    end
end



% --- Executes on button press in seriesRenaming_btn.
function seriesRenaming_btn_Callback(hObject, eventdata, handles)
% hObject    handle to seriesRenaming_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of seriesRenaming_btn
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    seriesRenaming;
else
    varargin{1} = subPath;
    seriesRenaming(varargin);
end




% --- Executes on button press in viewParameters_btn.
function viewParameters_btn_Callback(hObject, eventdata, handles)
% hObject    handle to viewParameters_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    subParameters;
else
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        if isfield(subInfo, 'parameters')
            subParameters(subInfo)
        end
    else
        errordlg('No subInfo file!!');
    end
end

% --- Executes on button press in viewActivations_btn.
function viewActivations_btn_Callback(hObject, eventdata, handles)
% hObject    handle to viewActivations_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    viewActivations;
else
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        if isfield(subInfo, 'fMRIsession')
            if ~isempty(subInfo.fMRIsession)
                viewActivations(subInfo)
            else
                errordlg('No subInfo.fMRIsession field!!');
            end
        end
    else
        errordlg('No subInfo file!!');
    end
end


% --- Executes on button press in processRest_btn.
function processRest_btn_Callback(hObject, eventdata, handles)
% hObject    handle to processRest_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    processRest;
else
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        if isfield(subInfo, 'fMRIsession')
            if ~isempty(subInfo.fMRIsession)
                fieldNames = fieldnames(subInfo.fMRIsession);
                % (?<=Se)\d+ - match one or more digits (\d+) only if it follows Se
                scanName = regexp(fieldNames, 'rest', 'match');
                scanName = [scanName{:}];
                
                if ~isempty(scanName)
                    processRest(subInfo)
                else
                    errordlg('No Rest session was found!!');
                    uiwait;
                    processRest(subInfo)
                end
            end
        end
    else
        errordlg('No subInfo file!!');
    end
end


% --- Executes on button press in createPacsReport_btn.
function createPacsReport_btn_Callback(hObject, eventdata, handles)
% hObject    handle to createPacsReport_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    rawDataDir = 'M:\clinica\patients\Full_Scans';
    % curMonth = datestr(now, 'mmmm');
    % curDir = fullfile(rawDataDir, curMonth);
    cd(rawDataDir);
    newSubPath = uigetdir(rawDataDir,'Select subject''s folder');
    
    if ischar(newSubPath)
        subPath = newSubPath;
        cd(subPath);
        
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        reportForAccelPath = fullfile(subInfo.path, 'ReportForAccel');
        dcmFiles = dir(fullfile(reportForAccelPath, '*.dcm'));
        
        if ~isempty(dcmFiles)
            createPacsReport(subInfo)
        else
            reportPath = fullfile(subPath, '*Report');
            
            if exist(reportPath, 'dir')
                createPacsReport(subInfo)
            else
                
                str = sprintf('No ReportForAccel folder!! \nPlease create the folder and relevant files (#.dcm) and try again');
                errordlg(str);
            end
            
        end
    end
else
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        reportForAccelPath = fullfile(subPath, 'ReportForAccel');
        dcmFiles = dir(fullfile(reportForAccelPath, '*.dcm'));
        
        if ~isempty(dcmFiles)
            createPacsReport(subInfo)
        else
            
            allFiles = dir(subPath);
            allFiles = allFiles([allFiles.isdir]);
            allNames = {allFiles.name};
            taskDir = strfind(lower(allNames), 'report');
            
            ind = find(~cellfun(@isempty,taskDir));
            if ~isempty(ind)
                createPacsReport(subInfo)
            else
                errordlg('No Report folder!!');
            end
        end
    else
        errordlg('No subInfo.mat file!!');
    end
end

% --- Executes on button press in mergeActivation_btn.
function mergeActivation_btn_Callback(hObject, eventdata, handles)
% hObject    handle to mergeActivation_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    mergeActivations;
else
    varargin{1} = subPath;
    mergeActivations(varargin);
end


% --- Executes on button press in LIallThresh_btn.
function LIallThresh_btn_Callback(hObject, eventdata, handles)
% hObject    handle to LIallThresh_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    LIallThresh;
else
    varargin{1} = subPath;
    LIallThresh(varargin);
end


% --- Executes on button press in ind_SeriesRenaming.
function ind_SeriesRenaming_Callback(hObject, eventdata, handles)
% hObject    handle to ind_SeriesRenaming (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath

subName = get(handles.subName, 'String');

if isempty(subName)
    rawDataDir = 'M:\clinica\patients\Full_Scans';
    % curMonth = datestr(now, 'mmmm');
    % curDir = fullfile(rawDataDir, curMonth);
    cd(rawDataDir);
    newSubPath = uigetdir(rawDataDir,'Select subject''s folder');
    
    if ischar(newSubPath)
        subPath = newSubPath;
        cd(subPath);
        
        if exist(fullfile(subPath, 'subInfo.mat'), 'file')
            subInfofile = fullfile(subPath, 'subInfo.mat');
            load(subInfofile)
            
            seriesRenaming_indSeries(subInfo);
        else
            errordlg('No subInfo file!!');
        end
    end
else
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        seriesRenaming_indSeries(subInfo);
    else
        errordlg('No subInfo file!!');
    end
end



% --- Executes on button press in artProcessing.
function artProcessing_Callback(hObject, eventdata, handles)
% hObject    handle to artProcessing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    artProcessing;
else
    varargin{1} = subPath;
    artProcessing(varargin);
end

% --- Executes on button press in eegProcess_estCont.
function eegProcess_estCont_Callback(hObject, eventdata, handles)
% hObject    handle to eegProcess_estCont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
subName = get(handles.subName, 'String');

if isempty(subName)
    clear all;
    eeg_estCont;
else
    varargin{1} = subPath;
    eegProcess_estCont(varargin);
end
