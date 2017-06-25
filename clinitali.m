function varargout = clinitali(varargin)
% CLINITALI MATLAB code for clinitali.fig
%      CLINITALI, by itself, creates a new CLINITALI or raises the existing
%      singleton*.
%
%      H = CLINITALI returns the handle to a new CLINITALI or the handle to
%      the existing singleton*.
%
%      CLINITALI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CLINITALI.M with the given input arguments.
%
%      CLINITALI('Property','Value',...) creates a new CLINITALI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before clinitali_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to clinitali_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help clinitali

% Last Modified by GUIDE v2.5 26-May-2016 14:14:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @clinitali_OpeningFcn, ...
    'gui_OutputFcn',  @clinitali_OutputFcn, ...
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


% --- Executes just before clinitali is made visible.
function clinitali_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to clinitali (see VARARGIN)

% Choose default command line output for clinitali
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


% UIWAIT makes clinitali wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = clinitali_OutputFcn(hObject, eventdata, handles)
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
        files = {dcmFiles.name}';
        
        if ~isempty(files)
            createPacsReport(subInfo)
        else
            str = sprintf('No ReportForAccel folder!! \nPlease create the folder and relevant files (#.dcm) and try again');
            errordlg(str);
        end
        
    end
else
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
    
    reportForAccelPath = fullfile(subInfo.path, 'ReportForAccel');
    dcmFiles = dir(fullfile(reportForAccelPath, '*.dcm'));
    files = {dcmFiles.name}';
    
    if ~isempty(files)
        createPacsReport(subInfo)
    else
        errordlg('No ReportForAccel folder!!');
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
