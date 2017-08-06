function varargout = superimpose(varargin)
% SUPERIMPOSE MATLAB code for superimpose.fig
%      SUPERIMPOSE, by itself, creates a new SUPERIMPOSE or raises the existing
%      singleton*.
%
%      H = SUPERIMPOSE returns the handle to a new SUPERIMPOSE or the handle to
%      the existing singleton*.
%
%      SUPERIMPOSE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SUPERIMPOSE.M with the given input arguments.
%
%      SUPERIMPOSE('Property','Value',...) creates a new SUPERIMPOSE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before superimpose_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to superimpose_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help superimpose

% Last Modified by GUIDE v2.5 28-Jun-2017 11:22:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @superimpose_OpeningFcn, ...
    'gui_OutputFcn',  @superimpose_OutputFcn, ...
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


% --- Executes just before superimpose is made visible.
function superimpose_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to superimpose (see VARARGIN)

global subPath
global dtiSPGRfile
global restSPGRfile
dtiSPGRfile = '';
restSPGRfile = '';

% Choose default command line output for superimpose
handles.output = hObject;

% let's clear all fields, listboxes and tables...
set(handles.files_list, 'String', '');
set(handles.files_list, 'Value', 1);
set(handles.files_table, 'Data', {'', '', '', ''});
set(handles.superimpose_list, 'String', '');

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
    % setting up the paths
    analysisPath = fullfile( subPath, 'Analysis' );
    
    [subInfo, handles] = updateGUIparameters(subInfo, handles, 'superimpose');
    
% % % %     % now setting the SPGR_text - which shows the current spgr file that we are
% % % %     % using for coregistration
% % % %     %anatomyfile = regexp(subInfo.SPGR, '\w*[^.nii]', 'match');
% % % %     if isfield(subInfo, 'SPGR')
% % % %         str = sprintf('%s', subInfo.SPGR);
% % % %     else
% % % %         str = '';
% % % %     end
% % % %     set(handles.SPGR_text, 'String', str);
% % % %     
% % % %     % let's update this figure with the subject's information
% % % %     if isfield(subInfo, 'name'), set(handles.subName, 'String', subInfo.name); end
% % % %     if isfield(subInfo, 'id'), set(handles.id, 'String', subInfo.id); end
% % % %     if isfield(subInfo, 'age'), set(handles.age, 'String', subInfo.age); end
% % % %     if isfield(subInfo, 'gender'), set(handles.gender, 'String', subInfo.gender); end
% % % %     if isfield(subInfo, 'tumorType'), set(handles.tumorType, 'String', subInfo.tumorType); end
% % % %     
% % % %     % let's update this figure with the subject's default parameters
% % % %     if ~isfield(subInfo, 'parameters'),
% % % %         subInfo = setDefaultParameters(subInfo);
% % % %     end
% % % %     
% % % %     if isfield(subInfo.parameters, 'dti_nDirections'), set(handles.dti_nDirections, 'String', subInfo.parameters.dti_nDirections); end
% % % %     if isfield(subInfo.parameters, 'infSupFlip'), set(handles.infSupFlip, 'String', subInfo.parameters.infSupFlip); end
% % % %     if isfield(subInfo.parameters, 'upDownFlip'), set(handles.upDownFlip, 'String', subInfo.parameters.upDownFlip); end
% % % %     
% % % %     if isfield(subInfo.parameters, 'wmCenter'),
% % % %         if ~isempty(subInfo.parameters.wmCenter)
% % % %             set(handles.wmCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.wmCenter));
% % % %         else
% % % %             set(handles.wmCenter, 'String', '')
% % % %         end
% % % %     end
% % % %     
% % % %     if isfield(subInfo.parameters, 'csfCenter'),
% % % %         if ~isempty(subInfo.parameters.csfCenter)
% % % %             set(handles.csfCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.csfCenter));
% % % %         else
% % % %             set(handles.csfCenter, 'String', '')
% % % %         end
% % % %     end
    
    fmrifiles = {};
    
    if isfield(subInfo, 'fMRIsession')
        if ~isempty(subInfo.fMRIsession)
            fields = subInfo.fMRIsession;
            fieldnameToAccess = fieldnames(fields);
            
            % setting up the path
            funcPath = fullfile( analysisPath, 'func' );
            
            for i = 1:numel(fieldnameToAccess)
                seriesNumber = fields.(fieldnameToAccess{i}).seriesNumber;
                seriesDescription = fields.(fieldnameToAccess{i}).seriesDescription;
                fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
                
                resultsPath = fullfile(funcPath, fullSeriesName, 'Results');
                
                allFiles = dir(resultsPath);
                allFiles([allFiles.isdir]) = [];
                names = {allFiles.name}';
                % now lets set the fmri files..
                for i = 1:numel(names)
                    name = names{i};
                    
                    isHDRfile = regexp(name, 'hdr', 'match');
                    if ~isempty(isHDRfile)
                        [~,name] = fileparts(names{i});
                        fmrifiles{end+1} = name;
                    end
                    
                    isNIIfile = regexp(name, 'nii', 'match');
                    if ~isempty(isNIIfile) && isempty(strfind(name, 'spmT'))
                        [~,name] = fileparts(names{i});
                        fmrifiles{end+1} = name;
                    end
                    
                end
            end
        end
    end
    
    % now let's search in the analysis folder itself for things to show
    dirs = dir(fullfile(analysisPath));
    dirs = {dirs.name};
    dirs = dirs(3:end);
    
    % check that we have other folders than the default ones (i.e.;
    % DTI_41, func, anat, and LI)
    dirType = regexpi(lower(dirs), '^(?=.*\<(?:dti20|dti_41|dti_31|li|anat|func|out)\>).*', 'match');
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
                        
                        spmFiles = dir(fullfile(eegLagsPath, curSess, curLag, 'Results'));
                        spmFiles = {spmFiles.name};
                        spmFiles = spmFiles(3:end);
                        
                        if ~isempty(spmFiles)
                            
                            % now lets set the fmri files..
                            for i = 1:numel(spmFiles)
                                isHDRfile = regexp(spmFiles{i}, 'hdr', 'match');
                                if ~isempty(isHDRfile)
                                    [~,name] = fileparts(spmFiles{i});
                                    fmrifiles{end+1} = name;
                                end
                                
                                isNIIfile = regexp(spmFiles{i}, 'nii', 'match');
                                if ~isempty(isNIIfile)
                                    [~,name] = fileparts(spmFiles{i});
                                    fmrifiles{end+1} = name;
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
                    isHDRfile = regexp(names{i}, 'hdr', 'match');
                    if ~isempty(isHDRfile)
                        [~,name] = fileparts(names{i});
                        fmrifiles{end+1} = name;
                    end
                    
                    isNIIfile = regexp(names{i}, 'nii', 'match');
                    if ~isempty(isNIIfile)
                        [~,name] = fileparts(names{i});
                        fmrifiles{end+1} = name;
                    end
                    
                end
            end
            
        end
    end
    
    [~,idx] = unique(fmrifiles,'first');
    fmriOrder = fmrifiles(sort(idx));
    fmriFiles = fmriOrder';
    
    % now lets set the fibers files..
    fibersPath = fullfile(analysisPath, ['DTI_' num2str(subInfo.parameters.dti_nDirections)], 'Fibers');
    dtifiles = {};
    allFiles = dir(fibersPath);
    allFiles([allFiles.isdir]) = [];
    names = {allFiles.name}';
    
    for i = 1:numel(names)
        name = names{i};
        isBinfile = regexp(name, 'bin', 'match');
        alreadyCoregistered = regexp(name, '\<r+\w*', 'match');
        
        if ~isempty(isBinfile) && isempty(alreadyCoregistered)
            [~,name] = fileparts(names{i});
            dtifiles{end+1} = name;
        end
    end
    
    [~,idx] = unique(dtifiles,'first');
    dtiOrder = dtifiles(sort(idx));
    dtiFiles = dtiOrder';
    
    files_list = [fmriFiles; dtiFiles];
    set(handles.files_list, 'String', files_list)
    set(handles.files_table, 'Data', {'' '' '' ''});
    
    if isempty(fmrifiles) && isempty(dtifiles)
        str = sprintf('No fMRI or DTI files were found!');
        msgbox(str)
        fprintf('%s\n', str);
        uiwait
    end
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes superimpose wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = superimpose_OutputFcn(hObject, eventdata, handles)
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




function tr_Callback(hObject, eventdata, handles)
% hObject    handle to tr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tr as text
%        str2double(get(hObject,'String')) returns contents of tr as a double


% --- Executes during object creation, after setting all properties.
function tr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dti_nDirections_Callback(hObject, eventdata, handles)
% hObject    handle to dti_nDirections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dti_nDirections as text
%        str2double(get(hObject,'String')) returns contents of dti_nDirections as a double


% --- Executes during object creation, after setting all properties.
function dti_nDirections_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dti_nDirections (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fileTemplate_Callback(hObject, eventdata, handles)
% hObject    handle to fileTemplate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fileTemplate as text
%        str2double(get(hObject,'String')) returns contents of fileTemplate as a double


% --- Executes during object creation, after setting all properties.
function fileTemplate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileTemplate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function volumesFormat_Callback(hObject, eventdata, handles)
% hObject    handle to volumesFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of volumesFormat as text
%        str2double(get(hObject,'String')) returns contents of volumesFormat as a double


% --- Executes during object creation, after setting all properties.
function volumesFormat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to volumesFormat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxTranslation_Callback(hObject, eventdata, handles)
% hObject    handle to maxTranslation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxTranslation as text
%        str2double(get(hObject,'String')) returns contents of maxTranslation as a double


% --- Executes during object creation, after setting all properties.
function maxTranslation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxTranslation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function  varargout = infSupFlip_Callback(hObject, eventdata, handles)
% hObject    handle to infSupFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of infSupFlip as text
%        str2double(get(hObject,'String')) returns contents of infSupFlip as a double
varargout{1} = 1;
val = str2double(get(handles.infSupFlip,'String'));

if (val < 0) || (val > 1) || isnan(val)
    %     if (get(handles.process_btn, 'Value') ~=1)
    %         str = sprintf('Sorry, only 0 or 1 are allowed..');
    %         errordlg(str);
    %     end
    %
    %     %setting it back to defauld (lag = 0)
    %     set(handles.infSupFlip, 'String', '0')
    varargout{1} = 0;
end



% --- Executes during object creation, after setting all properties.
function infSupFlip_CreateFcn(hObject, eventdata, handles)
% hObject    handle to infSupFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function smoothSize_Callback(hObject, eventdata, handles)
% hObject    handle to smoothSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smoothSize as text
%        str2double(get(hObject,'String')) returns contents of smoothSize as a double


% --- Executes during object creation, after setting all properties.
function smoothSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smoothSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function varargout = lag_Callback(hObject, eventdata, handles)
% hObject    handle to lag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lag as text
%        str2double(get(hObject,'String')) returns contents of lag as a double
varargout{1} = 1;
val = str2double(get(handles.lag,'String'));

if (val < -2) || (val > 1) || isnan(val)
    
    %     if (get(handles.process_btn, 'Value') ~=1)
    %         str = sprintf('Sorry, incorrect lag parameter was inserted \n(Can be only: -2, -1, 0, or 1)');
    %         errordlg(str);
    %     end
    %
    %     %setting it back to defauld (lag = 0)
    %     set(handles.lag, 'String', '0')
    varargout{1} = 0;
end


% --- Executes during object creation, after setting all properties.
function lag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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



function writeOutputDicoms_Callback(hObject, eventdata, handles)
% hObject    handle to writeOutputDicoms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of writeOutputDicoms as text
%        str2double(get(hObject,'String')) returns contents of writeOutputDicoms as a double

val = str2double(get(hObject, 'String'));
if val
    set(handles.createColorMatrix_text, 'Enable', 'on');
    set(handles.createColorMatrix, 'Enable', 'on');
    set(handles.text28, 'Enable', 'on');
else
    set(handles.createColorMatrix_text, 'Enable', 'off');
    set(handles.createColorMatrix, 'Enable', 'off');
    set(handles.text28, 'Enable', 'off');
end

% --- Executes during object creation, after setting all properties.
function writeOutputDicoms_CreateFcn(hObject, eventdata, handles)
% hObject    handle to writeOutputDicoms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_btn.
function save_btn_Callback(hObject, eventdata, handles)
% hObject    handle to save_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
if ~isempty(subPath)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        % let's update this figure with the subject's default parameters
        if ~isfield(subInfo, 'parameters'),
            subInfo = setDefaultParameters(subInfo);
        end
        
        if isfield(subInfo, 'tumorType'),
            if ~isequal(get(handles.tumorType, 'String'), num2str(subInfo.tumorType)),
                subInfo.tumorType = get(handles.tumorType, 'String');
            end
        else
            subInfo.tumorType = get(handles.tumorType, 'String');
        end
        
        % let's save the changed parameters to the subject's subInfo file
        if ~isequal(get(handles.infSupFlip, 'String'), num2str(subInfo.parameters.infSupFlip)),
            subInfo.parameters.infSupFlip = str2double(get(handles.infSupFlip, 'String'));
        end
        
        if ~isequal(get(handles.upDownFlip, 'String'), num2str(subInfo.parameters.upDownFlip)),
            subInfo.parameters.upDownFlip = str2double(get(handles.upDownFlip, 'String'));
        end
        
        save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
    end
end

% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
% first we will save the parameters to the subInfo.mat file (if there
% is a need in the future to inspect what were parameters used)
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
        if ~isequal(get(handles.infSupFlip, 'String'), num2str(subInfo.parameters.infSupFlip)) || ...
                ~isequal(get(handles.upDownFlip, 'String'), num2str(subInfo.parameters.upDownFlip))
            reSave_flag = 1;
        end
    end
end

if reSave_flag,
    % open msg dlg and ask the user if we can continue
    % Construct a questdlg with two options
    str = sprintf('There are certain parameters that were changed, \nSave before starting superimpose sprocess?');
    choice = questdlg(str, ...
        'Save and exit?', ...
        'Yes','No', 'Yes');
    % Handle response
    if isequal(choice, 'Yes')
        disp('Saving the new parameters.')
        save_btn_Callback(hObject, eventdata, handles)
    end
    subInfo = superimpose_OutputFcn(hObject, eventdata, handles);
end

% send the files from the files_table, one at a time to the
% superimposeClinic
files_table = get(handles.files_table, 'Data');
createColorDcm = get(handles.createColorDcm, 'Value');
superimposeClinic(subInfo, files_table, createColorDcm)
% close;

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
        
        if isfield(subInfo.parameters, 'dti_nDirections'), set(handles.dti_nDirections, 'String', subInfo.parameters.dti_nDirections); end
        if isfield(subInfo.parameters, 'infSupFlip'), set(handles.infSupFlip, 'String', subInfo.parameters.infSupFlip); end
        if isfield(subInfo.parameters, 'upDownFlip'), set(handles.upDownFlip, 'String', subInfo.parameters.upDownFlip); end
        
        if isfield(subInfo.parameters, 'wmCenter'),
            if ~isempty(subInfo.parameters.wmCenter)
                set(handles.wmCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.wmCenter));
            else
                set(handles.wmCenter, 'String', '')
            end
        end
        
        if isfield(subInfo.parameters, 'csfCenter'),
            if ~isempty(subInfo.parameters.csfCenter)
                set(handles.csfCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.csfCenter));
            else
                set(handles.csfCenter, 'String', '')
            end
        end
        
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
        
        superimpose_OpeningFcn(hObject, eventdata, handles, subInfo)
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


% --- Executes on selection change in superimpose_list.
function superimpose_list_Callback(hObject, eventdata, handles)
% hObject    handle to superimpose_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns superimpose_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from superimpose_list


% --- Executes during object creation, after setting all properties.
function superimpose_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to superimpose_list (see GCBO)
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
superimpose_list = cellstr(get(handles.superimpose_list, 'String'));
files_list = get(handles.files_list, 'String');

% get the selected files..
selected = get(handles.files_list, 'Value');
files = files_list(selected);

% add them to the current superimpose list
if isempty([superimpose_list{:}])
    superimpose_list{1} = strjoin(files', ' + ');
else
    superimpose_list{end+1} = strjoin(files', ' + ');
end

set(handles.superimpose_list, 'String', superimpose_list);

% now let's update the file's table
files_table = get(handles.files_table, 'Data');
ind = find(cellfun(@isempty,files_table(:,2)));
if isempty(ind)
    ind = size(files_table,1 )+1;
elseif ind > 1
    ind = size(files_table,1 )+1;
end

files_table{ind, 1} = '*';

for i = 1:numel(files)
    
    % file name
    files_table{ind, 2} = files{i};
    
    % if it's a dti file
    isBinFile = regexp(files{i}, 'bin', 'match');
    if ~isempty(isBinFile)
        
        % intensity
        files_table{ind, 3} = '1';
        
        % viewer color
        files_table{ind, 4} = '1';
        fname = char(regexp(files{i}, '\w*^[^_]*', 'match'));
        switch lower(fname)
            case 'af'
                files_table{ind, 4} = '6';
            case {'or', 'or1'}
                files_table{ind, 4} = '3';
            case 'pt'
                files_table{ind, 4} = '1';
        end
        
    else
        % if it's fmri file
        % intensity
        files_table{ind, 3} = '1';
        
        % viewer color
        files_table{ind, 4} = '7'; % arbitrary default value..
        % now let's see if there any specific colors to give.
        % fname = char(regexp(files{i}, '\w*^[^_]*', 'match'));
        fname = regexp(files{i}, '^[^\d+]+(?=c)', 'match');
        
        if isempty(fname)
            fname = files{i};
        else
            fname = [fname{:}];
        end
        
        fname = strrep(fname, '_', '');
        
        switch lower(char(fname))
            case {'vgpic', 'defread', 'defreadrussian', 'ftminus'}
                files_table{ind, 4} = '8';
            case {'aud', 'defaud', 'auddef', 'auddefdiff', 'audvg', 'vgaud', 'audvgheb',...
                    'auddefinitionsrussian', 'audvgrussian'}
                files_table{ind, 4} = '9';
            case {'lips', 'motorlips'}
                files_table{ind, 4} = '1';
        end
        
        if numel(files) > 1
            fname = regexp(files, '\w*^[^_]*', 'match');
            % if all cells have the same content - we need to assign them
            % different color number
            if isequal(fname{1}, fname{1:end})
                switch lower(char(fname{1}))
                    case {'vgpic', 'defaud', 'auddef', 'audvg', 'vgaud',...
                            'audvgheb', 'defread', 'lips', 'defreadrussian',...
                            'auddefinitionsrussian', 'audvgrussian'}
                        files_table{ind, 4} = num2str(i+7);
                    case 'ft'
                        files_table{ind, 4} = num2str(i+6);
                    case 'legs'
                        files_table{ind, 4} = num2str(i+2);
                    case 'rest'
                        files_table{ind, 4} = num2str(i+4);
                end
            end
        end
    end
    ind = ind + 1;
end

nextLineIndex = ind;
if (numel(files) == 1)
    nextLineIndex = ind-1;
else
    nextLineIndex = ind-numel(files);
end

% create new superimposed DICOMs - by default - no
files_table{nextLineIndex, 5} = false;
% files_table{nextLineIndex, 5} = '0';

% new series number
files_table{nextLineIndex, 7} = '';

% new seires name
files_table{nextLineIndex, 6} = '';

% new series number
% files_table{nextLineIndex, 7} = '7';

% % new seires name
% fname = regexp(files, '\w*^[^_]*', 'match');
% fname = [fname{:}];
% newSeriesName = {'SPGR'};
%
% isBinFile = regexp(files, 'bin', 'match');
% isRestFile = regexpi(files, 'rest', 'match');
%
% % adding the dti part to the folder's name
%
% binFiles = find(~cellfun(@isempty,isBinFile));
% % if it has a recurring name (we use only one file name, not both)
% if ~isempty(binFiles)
%     if numel(binFiles) > 1 && isequal(fname{binFiles(1)}, fname{binFiles(1:end)})
%         newSeriesName = [newSeriesName 'FIBERS' fname{binFiles(1)}];
%     else
%         newSeriesName = [newSeriesName 'FIBERS' fname{binFiles}];
%     end
% end
%
% fmriFiles = find(cellfun(@isempty,isBinFile));
% if ~isempty(fmriFiles)
%     if numel(fmriFiles) > 1 && isequal(fname{fmriFiles(1)}, fname{fmriFiles(1:end)})
%         newSeriesName = [newSeriesName fname{fmriFiles(1)}];
%     else
%         newSeriesName = [newSeriesName fname{fmriFiles}];
%     end
% end
%
% restFiles = find(~cellfun(@isempty,isRestFile));
% if ~isempty(restFiles)
%     files_table{nextLineIndex, 7} = '8';
%
%     if numel(restFiles) == numel(files)
%         for i = 1:numel(files)
%             file = regexpi(files{i},  '(?<=rest_)\w+', 'match');
%             newSeriesName = [newSeriesName file];
%         end
%     else
%         newSeriesName = [newSeriesName fname{restFiles}];
%     end
%
% end
%
% newSeriesName = strjoin(newSeriesName, '_');
% files_table{nextLineIndex, 6} = newSeriesName;

set(handles.files_table, 'Data', files_table)

% --- Executes on button press in remove_btn.
function remove_btn_Callback(hObject, eventdata, handles)
% hObject    handle to remove_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% let's get the current files shown in both lists
superimpose_list = cellstr(get(handles.superimpose_list, 'String'));

% get the selected files..
selected = get(handles.superimpose_list, 'Value');
files = superimpose_list(selected);
f = strtrim(regexp(files, '[+]', 'split'));
f = [f{:}];

% now let's update the file's table
files_table = get(handles.files_table, 'Data');

A = strfind( files_table(:,2), f{1} );
ind = find(~cellfun(@isempty,A));
removeInd = [];

if ~isempty(ind)
    % so we found the line with the first file name,
    % we now want to make sure that it's the first file from the two files and
    % that the second file also matches..
    for i = 1:length(ind)
        curInd = ind(i);
        if isequal(files_table{curInd, 1} , '*');
            removeInd = [curInd];
            for j = 1:size(f,2)-1
                if strcmp( files_table{curInd+j, 2}, f(j+1))
                    removeInd = [removeInd curInd+j];
                else
                    removeInd = [];
                    break
                end
            end
        end
    end
end

files_table(removeInd,:) = [];
set(handles.files_table, 'Data', files_table);

% remove them from the current superimpose list
% find the string and remove it from the superimpose list
superimpose_list(selected) = [];
set(handles.superimpose_list, 'String', superimpose_list);
set(handles.superimpose_list, 'Value', 1);


% --- Executes on button press in clearAll_btn.
function clearAll_btn_Callback(hObject, eventdata, handles)
% hObject    handle to clearAll_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.superimpose_list, 'String', '');
set(handles.superimpose_list, 'Value', 1);
set(handles.files_table, 'Data', {'' '' '' ''});

% --- Executes when entered data in editable cell(s) in files_table.
function files_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to files_table (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
global subPath

files_table = get(hObject, 'Data');

curRow = eventdata.Indices(1);
curCol = eventdata.Indices(2);

if (curCol == 3)
    val = str2double(eventdata.EditData);
    if (val < 0) || (val > 1)
        errordlg('Please select a number between 0 and 1..!');
        eventdata.Error = 'Please select a number between 0 and 1..!';
        eventdata.NewData = eventdata.PreviousData;
    end
end
files_table{eventdata.Indices(1), eventdata.Indices(2)} = eventdata.NewData;

% if the value == 1 - this means we will create new DICOM files. let's show
% the user the name and new series name in the files_table
if (curCol == 5)
    
    if isequal(files_table{curRow, 1}, '*')
        val = eventdata.EditData;
        if (val == 0)
            files_table(curRow, 6:7) = {'', ''};
        else
            
            % going over the list and dealing with each pair (or triplet) of files at a
            % time.
            asteriskLocList = find(strcmp('*', files_table(:,1)));
            [asteriskIndex c] = find(asteriskLocList == curRow);
            
            if size(asteriskLocList, 1) == 1
                finishRow = size(files_table,1);
            elseif (asteriskLocList(asteriskIndex) == asteriskLocList(end))
                if (asteriskLocList(asteriskIndex) == size(files_table,1))
                    finishRow = asteriskLocList(asteriskIndex);
                else
                    finishRow = size(files_table,1);
                end
            else
                finishRow = asteriskLocList(asteriskIndex+1)-1;
            end
            
            beginRow = asteriskLocList(asteriskIndex);
            files = files_table(beginRow:finishRow, 2);
            
            % new series number
            files_table{curRow, 7} = '7';
            
            % new seires name
            newSeriesName = {'SPGR'};
            
            isBinFile = regexp(files, 'bin', 'match');
            isRestFile = regexpi(files, 'rest', 'match');
            
            % adding the dti part to the folder's name
            binFiles = find(~cellfun(@isempty,isBinFile));
            % if it has a recurring name (we use only one file name, not both)
            if ~isempty(binFiles)
                fname = regexp(files(binFiles), '\w*^[^_]*', 'match');
                fname = [fname{:}];
                fname = unique(fname);
                
                if numel(binFiles) > 1 && isequal(fname{1}, fname{1:end})
                    newSeriesName = [newSeriesName 'FIBERS' fname{1}];
                else
                    newSeriesName = [newSeriesName 'FIBERS' fname];
                end
            end
            
            fmriFiles = find(cellfun(@isempty,isBinFile));
            if ~isempty(fmriFiles)
                if (isempty(find(~cellfun(@isempty,isRestFile)))) || numel(fmriFiles) ~= numel(isRestFile)
                    tmpNewSeriesName = newSeriesName;
                    
                    fname = files(fmriFiles);
                    for n = 1:numel(fname)
                        curFname = fname(n);
                        curFname = regexp(curFname, '^[^\d+]+(?=c)', 'match');
                        curFname = [curFname{:}];
                        if ~isempty(curFname)
                            curFname = strrep(curFname, '_', '');
                        else
                            curFname = files{n};
                        end
                        tmpNewSeriesName = [tmpNewSeriesName curFname];
                    end
                    if numel(fmriFiles) > 1 && isequal(fname{fmriFiles(1)}, fname{fmriFiles(1:end)})
                        newSeriesName = [newSeriesName fname{fmriFiles(1)}];
                    else
                        newSeriesName = tmpNewSeriesName;
                    end
                end
            end
            
            restFiles = find(~cellfun(@isempty,isRestFile));
            if ~isempty(restFiles)
                files_table{curRow, 7} = '8';
                
                if numel(restFiles) == numel(files)
                    for i = 1:numel(files)
                        file = regexpi(files{i},  '(?<=rest_)\w+', 'match');
                        newSeriesName = [newSeriesName file];
                    end
                else
                    newSeriesName = [newSeriesName fname{restFiles}];
                end
                newSeriesName = strrep(newSeriesName, 'Rest', '');
            end
            
            newSeriesName = strjoin(newSeriesName, '_');
            
            %             % check if there are already folders with this name
            %             counter = 0;
            %             sName = newSeriesName;
            %             ls = dir(fullfile(subPath, 'Analysis'));
            %             ls = {ls.name};
            %             ind = strfind(ls, sName);
            %             ind = find(~cellfun(@isempty, ind));
            %             if ~isempty(ind)
            %                 newSeriesName = [sName sprintf('_%.2d', size(ind,2) + 1)] ;
            %                 counter = counter + size(ind,2);
            %             end
            %
            %             % check if there are already folders with this name int he
            %             % table list
            %             f = files_table(:, 6);
            %             f = cellfun(@num2str,f,'un',0);
            %             f = unique(f);
            %             ind = strfind(f,sName);
            %             ind = find(~cellfun(@isempty, ind));
            %
            %             if ~isempty(ind)
            %                 counter = counter + size(ind,1);
            %                 newSeriesName = [sName sprintf('_%.2d', counter + 1)] ;
            %             end
            %
            files_table{curRow, 6} = newSeriesName;
        end
    else
        files_table(curRow, 6:7) = {'', ''};
    end
end

set(hObject, 'Data', files_table);


% --- Executes when selected cell(s) is changed in files_table.
function files_table_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to files_table (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)



function createColorMatrix_Callback(hObject, eventdata, handles)
% hObject    handle to createColorMatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of createColorMatrix as text
%        str2double(get(hObject,'String')) returns contents of createColorMatrix as a double


% --- Executes during object creation, after setting all properties.
function createColorMatrix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to createColorMatrix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dtiFilePrefix_Callback(hObject, eventdata, handles)
% hObject    handle to dtiFilePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dtiFilePrefix as text
%        str2double(get(hObject,'String')) returns contents of dtiFilePrefix as a double


% --- Executes during object creation, after setting all properties.
function dtiFilePrefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dtiFilePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function upDownFlip_Callback(hObject, eventdata, handles)
% hObject    handle to upDownFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of upDownFlip as text
%        str2double(get(hObject,'String')) returns contents of upDownFlip as a double


% --- Executes during object creation, after setting all properties.
function upDownFlip_CreateFcn(hObject, eventdata, handles)
% hObject    handle to upDownFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function wmCenter_Callback(hObject, eventdata, handles)
% hObject    handle to wmCenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wmCenter as text
%        str2double(get(hObject,'String')) returns contents of wmCenter as a double
wmCenter = get(handles.wmCenter, 'String');

% let's check that the coordinates are correct ( 3 coordinates,
% seperated by a comma or space
coords = strsplit(wmCenter, {'[', ',', ' ', ']'});
coords = coords(~cellfun('isempty',deblank(coords)));

if (size(coords,2) == 3)
    wmCenter = sprintf('[ %s   %s   %s]', coords{:});
else
    str = sprintf('Sorry, you have inserted wrong set of coordinates..');
    errordlg(str);
    wmCenter = [];
end

set(handles.wmCenter, 'String', wmCenter);

% --- Executes during object creation, after setting all properties.
function wmCenter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wmCenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function csfCenter_Callback(hObject, eventdata, handles)
% hObject    handle to csfCenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of csfCenter as text
%        str2double(get(hObject,'String')) returns contents of csfCenter as a double
csfCenter = get(handles.csfCenter, 'String');

% let's check that the coordinates are correct ( 3 coordinates,
% seperated by a comma or space
coords = strsplit(csfCenter, {'[', ',', ' ', ']'});
coords = coords(~cellfun('isempty',deblank(coords)));

if (size(coords,2) == 3)
    csfCenter = sprintf('[ %s   %s   %s]', coords{:});
else
    str = sprintf('Sorry, you have inserted wrong set of coordinates..');
    errordlg(str);
    csfCenter = [];
end

set(handles.csfCenter, 'String', csfCenter);

% --- Executes during object creation, after setting all properties.
function csfCenter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csfCenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in dtiSPGR.
function dtiSPGR_Callback(hObject, eventdata, handles)
% hObject    handle to dtiSPGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global dtiSPGRfile
global subPath
SPGRpath = fullfile(subPath, 'Analysis', 'anat');
dtiSPGRfile = uigetfile(fullfile(SPGRpath, '*.nii'), 'Select anatomy file') ;


% --- Executes on button press in refresh_btn.
function refresh_btn_Callback(hObject, eventdata, handles)
% hObject    handle to refresh_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
varargin{1} = subPath;
clearAll_btn_Callback(hObject, eventdata, handles);
superimpose_OpeningFcn(hObject, eventdata, handles, varargin)


% --- Executes on button press in restSPGR.
function restSPGR_Callback(hObject, eventdata, handles)
% hObject    handle to restSPGR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global restSPGRfile
global subPath
SPGRpath = fullfile(subPath, 'Analysis', 'anat');
restSPGRfile = uigetfile(fullfile(SPGRpath, '*.nii'), 'Select anatomy file') ;


% --- Executes on button press in resetDtiSPGR_btn.
function resetDtiSPGR_btn_Callback(hObject, eventdata, handles)
% hObject    handle to resetDtiSPGR_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global dtiSPGRfile
dtiSPGRfile = '';


% --- Executes on button press in resetRestSPGR_btn.
function resetRestSPGR_btn_Callback(hObject, eventdata, handles)
% hObject    handle to resetRestSPGR_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global restSPGRfile
restSPGRfile = '';


% --- Executes on button press in createColorDcm.
function createColorDcm_Callback(hObject, eventdata, handles)
% hObject    handle to createColorDcm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of createColorDcm
