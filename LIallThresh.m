function varargout = LIallThresh(varargin)
% LIallThresh MATLAB code for LIallThresh.fig
%      LIallThresh, by itself, creates a new LIallThresh or raises the existing
%      singleton*.
%
%      H = LIallThresh returns the handle to a new LIallThresh or the handle to
%      the existing singleton*.
%
%      LIallThresh('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LIallThresh.M with the given input arguments.
%
%      LIallThresh('Property','Value',...) creates a new LIallThresh or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LIallThresh_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LIallThresh_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LIallThresh

% Last Modified by GUIDE v2.5 23-May-2016 23:46:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LIallThresh_OpeningFcn, ...
    'gui_OutputFcn',  @LIallThresh_OutputFcn, ...
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


% --- Executes just before LIallThresh is made visible.
function LIallThresh_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LIallThresh (see VARARGIN)

% Choose default command line output for LIallThresh
handles.output = hObject;

if length(varargin) == 1
    if iscell(varargin{1})
        subPath = varargin{1};
        subPath = char(subPath{:});
        
        if exist(fullfile(subPath, 'subInfo.mat'), 'file')
            subInfofile = fullfile(subPath, 'subInfo.mat');
            load(subInfofile)
        end
    elseif isstruct(varargin{1})
        subInfo = varargin{1};
    end
    
    subPath = subInfo.path;
    
    % let's update this figure with the subject's information
    if isfield(subInfo, 'name'), set(handles.subName, 'String', subInfo.name); end
    if isfield(subInfo, 'id'), set(handles.id, 'String', subInfo.id); end
    if isfield(subInfo, 'age'), set(handles.age, 'String', subInfo.age); end
    if isfield(subInfo, 'gender'), set(handles.gender, 'String', subInfo.gender); end
    if isfield(subInfo, 'tumorType'), set(handles.tumorType, 'String', subInfo.tumorType); end
    
    % let's update this figure with the subject's default parameters
    if ~isfield(subInfo, 'parameters'),
        subInfo = setDefaultParameters(subInfo);
    end
    
    if isfield(subInfo.parameters, 'createOccMask'), set(handles.createOccMask, 'String', subInfo.parameters.createOccMask); end
    if isfield(subInfo.parameters, 'handedness'), set(handles.handedness, 'String', subInfo.parameters.handedness); end
    if isfield(subInfo.parameters, 'reverseMask'), set(handles.reverseMask, 'String', subInfo.parameters.reverseMask); end
    if isfield(subInfo.parameters, 'reverseLR'), set(handles.reverseLR, 'String', subInfo.parameters.reverseLR); end
    if isfield(subInfo.parameters, 'minDist'), set(handles.minDist, 'String', subInfo.parameters.minDist); end
    
    
    if isfield(subInfo, 'fMRIsession')
        fields = subInfo.fMRIsession;
        fieldnameToAccess = fieldnames(fields);
        
        % setting up the paths
        analysisPath = fullfile( subPath, 'Analysis' );
        funcPath = fullfile( analysisPath, 'func' );
        
        fmrifiles = {};
        for i = 1:numel(fieldnameToAccess)
            seriesNumber = fields.(fieldnameToAccess{i}).seriesNumber;
            seriesDescription = fields.(fieldnameToAccess{i}).seriesDescription;
            fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
            
            resultsPath = fullfile(funcPath, fullSeriesName, 'spmT_files');
            
            if ~exist(resultsPath, 'dir')
                resultsPath = fullfile(funcPath, fullSeriesName, 'Results');
            end
            
            allFiles = dir(resultsPath);
            allFiles([allFiles.isdir]) = [];
            names = {allFiles.name}';
            
            % now lets set the fmri files..
            for i = 1:numel(names)
                name = names{i};
                isNIIfile = regexp(name, 'nii', 'match');%%%%%%%%%%%%%%%% tomer try
                if ~isempty(isNIIfile)
                    sName = regexp(fullSeriesName, '[^(?<=Se_\d)]\w*[^(*rep)]', 'match');
                    
                    [~,name] = fileparts(names{i});
                    % spmTfile = regexp(char(name),'[^spmT_]\d+\w+', 'match');
                    % without numbers - spmTfile = regexp(char(name),'[^spmT_\d*]\w+', 'match');
                    fmrifiles{end+1} = ['Se' num2str( seriesNumber, '%0.2d' ) '_' char(sName) '_' char(name)];
                end
            end
        end       
        
         % now let's search in the analysis folder itself for things to show
        dirs = dir(fullfile(analysisPath));
        dirs = {dirs.name};
        dirs = dirs(3:end);
        
        % check that we have other folders than the default ones (i.e.;
        % DTI_41, func, anat, and LI)
        dirType = regexpi(lower(dirs), '(dti20|dti_41|li|anat|func|out*)+[^(_| |-)]*', 'match');
        idx = find(cellfun(@isempty,dirType));
        
        if ~isempty(idx)
            for n = 1:numel(idx)
                if strcmpi(dirs{idx(n)}, 'eeg_lags')
                    
                    eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
                    
                    sessionDirs = dir(eegLagsPath);
                    sessionDirs = {sessionDirs.name};
                    sessionDirs = sessionDirs(3:end);
                    
                    for s = 1:size(sessionDirs, 2)
                        curSess = sessionDirs{s};
                        
                        lagDirs = dir(fullfile(eegLagsPath, curSess));
                        lagDirs = {lagDirs.name};
                        lagDirs = lagDirs(3:end);
                        
                        for lg = 1:size(lagDirs, 2)
                            curLag = lagDirs{lg};
                            
                            spmFiles = dir(fullfile(eegLagsPath, curSess, curLag, 'spmT_files'));
                            spmFiles = {spmFiles.name};
                            spmFiles = spmFiles(3:end);
                            
                            if ~isempty(spmFiles)
                                
                                % now lets set the fmri files..
                                for i = 1:numel(spmFiles)                                    
                                    isNIIfile = regexp(spmFiles{i}, 'nii', 'match');
                                    if ~isempty(isNIIfile)
                                        [~,name] = fileparts(spmFiles{i});
                                        fmrifiles{end+1} = [curLag '_' char(name)];
                                    end
                                end
                            end
                        end
                    end
                else
                    curDir = fullfile(analysisPath, dirs{idx(n)});
                    
                    allFiles = dir(curDir);
                    allFiles([allFiles.isdir]) = [];
                    names = {allFiles.name}';
                    % now lets set the fmri files..
                    for i = 1:numel(names)
                        isNIIfile = regexp(names{i}, 'nii', 'match');
                        if ~isempty(isNIIfile)
                            [~,name] = fileparts(names{i});
                            fmrifiles{end+1} = [curLag '_' char(name)];
                        end
                        
                    end
                end 
            end
        end
        
       
        [~,idx] = unique(fmrifiles,'first');
        fmriOrder = fmrifiles(sort(idx));
        fmriFiles = fmriOrder';
    end
    
    files_list = fmriFiles;
    set(handles.files_list, 'String', files_list)
    
    if isempty(fmrifiles)
        str = sprintf('No fMRI files were found!');
        msgbox(str)
        fprintf('%s\n', str);
        uiwait
    end
    set(handles.LI_list, 'String', '');
    set(handles.files_list, 'Value', 1);
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LIallThresh wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LIallThresh_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

global subPath
if ~isempty(subPath)
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        varargout{1} = subInfo;
    end
end


function tumorType_Callback(hObject, eventdata, handles)
% hObject    handle to tumorType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tumorType as text
%        str2double(get(hObject,'String')) returns contents of tumorType as a double


% --- Executes during object creation, after setting all properties.
function tumorType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tumorType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function id_Callback(hObject, eventdata, handles)
% hObject    handle to id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of id as text
%        str2double(get(hObject,'String')) returns contents of id as a double


% --- Executes during object creation, after setting all properties.
function id_CreateFcn(hObject, eventdata, handles)
% hObject    handle to id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function age_Callback(hObject, eventdata, handles)
% hObject    handle to age (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of age as text
%        str2double(get(hObject,'String')) returns contents of age as a double


% --- Executes during object creation, after setting all properties.
function age_CreateFcn(hObject, eventdata, handles)
% hObject    handle to age (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function gender_Callback(hObject, eventdata, handles)
% hObject    handle to gender (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gender as text
%        str2double(get(hObject,'String')) returns contents of gender as a double


% --- Executes during object creation, after setting all properties.
function gender_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gender (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function subName_Callback(hObject, eventdata, handles)
% hObject    handle to subName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subName as text
%        str2double(get(hObject,'String')) returns contents of subName as a double


% --- Executes during object creation, after setting all properties.
function subName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
% first we will save the parameters to the subInfo.mat file (if there
% is a need in the future to inspec what were parameters used)
reSave_flag = 0;
if ~isempty(subPath)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        if isfield(subInfo, 'tumorType'),
            if ~isequal(get(handles.tumorType, 'String'), num2str(subInfo.tumorType)),
                reSave_flag = 1;
            end
        end
        
        % let's save the changed parameters to the subject's subInfo file
        if ~isequal(get(handles.createOccMask, 'String'), num2str(subInfo.parameters.createOccMask)) || ...
                ~isequal(get(handles.handedness, 'String'), num2str(subInfo.parameters.handedness)) || ...
                ~isequal(get(handles.reverseMask, 'String'), num2str(subInfo.parameters.reverseMask)) || ...
                ~isequal(get(handles.reverseLR, 'String'), num2str(subInfo.parameters.reverseLR)) || ...
                ~isequal(get(handles.minDist, 'String'), num2str(subInfo.parameters.minDist))
            reSave_flag = 1;
        end
    end
end

if reSave_flag,
    % open msg dlg and ask the user if we can continue
    % Construct a questdlg with two options
    str = sprintf('There are certain parameters that were changed, \nSave before starting lateralization sprocess?');
    choice = questdlg(str, ...
        'Save before processing?', ...
        'Yes','No', 'Yes');
    % Handle response
    if isequal(choice, 'Yes')
        disp('Saving the new parameters.')
        save_btn_Callback(hObject, eventdata, handles)
    end
end
varargout = LIallThresh_OutputFcn(hObject, eventdata, handles);

LI_list = get(handles.LI_list, 'String');
LIallThreshClinic(subInfo, LI_list)
close;

function edit17_Callback(hObject, eventdata, handles)
% hObject    handle to infSupFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of infSupFlip as text
%        str2double(get(hObject,'String')) returns contents of infSupFlip as a double


% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to infSupFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in changeParameters.
function changeParameters_Callback(hObject, eventdata, handles)
% hObject    handle to changeParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
if ~isempty(subPath)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        subInfo = subParameters(subInfo);
        uiwait
        
        load(subInfofile)
        
        if isfield(subInfo.parameters, 'createOccMask'), set(handles.createOccMask, 'String', subInfo.parameters.createOccMask); end
        if isfield(subInfo.parameters, 'handedness'), set(handles.handedness, 'String', subInfo.parameters.handedness); end
        if isfield(subInfo.parameters, 'reverseMask'), set(handles.reverseMask, 'String', subInfo.parameters.reverseMask); end
        if isfield(subInfo.parameters, 'reverseLR'), set(handles.reverseLR, 'String', subInfo.parameters.reverseLR); end
        if isfield(subInfo.parameters, 'minDist'), set(handles.minDist, 'String', subInfo.parameters.minDist); end
        
    end
end

% --- Executes on button press in browse_btn.
function browse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to browse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath

rawDataPath = 'M:\clinica\patients\Full_Scans';
% curMonth = datestr(now, 'mmmm');
% curPath = fullfile(rawDataPath, curMonth);
cd(rawDataPath);
newSubPath = uigetdir(rawDataPath,'Select subject''s path for viewing parameters');

if ischar(newSubPath)
    subPath = newSubPath;
    cd(subPath);
    
    [p subName e] = fileparts(subPath);
    set(handles.subName, 'String', subName)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        LIallThresh_OpeningFcn(hObject, eventdata, handles, subInfo)
        
    end
end


% --- Executes on selection change in files_list.
function files_list_Callback(hObject, eventdata, handles)
% hObject    handle to files_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns files_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from files_list


% --- Executes during object creation, after setting all properties.
function files_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to files_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in LI_list.
function LI_list_Callback(hObject, eventdata, handles)
% hObject    handle to LI_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns LI_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LI_list


% --- Executes during object creation, after setting all properties.
function LI_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LI_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in add_btn.
function add_btn_Callback(hObject, eventdata, handles)
% hObject    handle to add_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% let's get the current files shown in both lists
LI_list = cellstr(get(handles.LI_list, 'String'));
files_list = get(handles.files_list, 'String');

% get the selected files..
selected = get(handles.files_list, 'Value');
files = files_list(selected);

% add them to the current LIallThresh list
if isempty([LI_list{:}])
    LI_list{1} = strjoin(files', ' + ');
else
    LI_list{end+1} = strjoin(files', ' + ');
end

set(handles.LI_list, 'String', LI_list);


% --- Executes on button press in remove_btn.
function remove_btn_Callback(hObject, eventdata, handles)
% hObject    handle to remove_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% let's get the current files shown in both lists
LI_list = cellstr(get(handles.LI_list, 'String'));

% get the selected files..
selected = get(handles.LI_list, 'Value');
files = LI_list(selected);
f = strtrim(regexp(files, '[+]', 'split'));
f = [f{:}];

% remove them from the current LIallThresh list
% find the string and remove it from the LIallThresh list
LI_list(selected) = [];
set(handles.LI_list, 'String', LI_list);
set(handles.LI_list, 'Value', 1);


% --- Executes on button press in clearAll_btn.
function clearAll_btn_Callback(hObject, eventdata, handles)
% hObject    handle to clearAll_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.LI_list, 'String', '');
set(handles.LI_list, 'Value', 1);



function createOccMask_Callback(hObject, eventdata, handles)
% hObject    handle to createOccMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of createOccMask as text
%        str2double(get(hObject,'String')) returns contents of createOccMask as a double


% --- Executes during object creation, after setting all properties.
function createOccMask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to createOccMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function handedness_Callback(hObject, eventdata, handles)
% hObject    handle to handedness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of handedness as text
%        str2double(get(hObject,'String')) returns contents of handedness as a double


% --- Executes during object creation, after setting all properties.
function handedness_CreateFcn(hObject, eventdata, handles)
% hObject    handle to handedness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function reverseMask_Callback(hObject, eventdata, handles)
% hObject    handle to reverseMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of reverseMask as text
%        str2double(get(hObject,'String')) returns contents of reverseMask as a double


% --- Executes during object creation, after setting all properties.
function reverseMask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reverseMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function reverseLR_Callback(hObject, eventdata, handles)
% hObject    handle to reverseLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of reverseLR as text
%        str2double(get(hObject,'String')) returns contents of reverseLR as a double


% --- Executes during object creation, after setting all properties.
function reverseLR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to reverseLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minDist_Callback(hObject, eventdata, handles)
% hObject    handle to minDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minDist as text
%        str2double(get(hObject,'String')) returns contents of minDist as a double


% --- Executes during object creation, after setting all properties.
function minDist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in refresh_btn.
function refresh_btn_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
varargin{1} = subPath;
clearAll_btn_Callback(hObject, eventdata, handles);
LIallThresh_OpeningFcn(hObject, eventdata, handles, varargin)