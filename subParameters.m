function varargout = subParameters(varargin)
% SUBPARAMETERS MATLAB code for subParameters.fig
%      SUBPARAMETERS, by itself, creates a new SUBPARAMETERS or raises the existing
%      singleton*.
%
%      H = SUBPARAMETERS returns the handle to a new SUBPARAMETERS or the handle to
%      the existing singleton*.
%
%      SUBPARAMETERS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SUBPARAMETERS.M with the given input arguments.
%
%      SUBPARAMETERS('Property','Value',...) creates a new SUBPARAMETERS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before subParameters_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to subParameters_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help subParameters

% Last Modified by GUIDE v2.5 03-Aug-2017 09:09:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @subParameters_OpeningFcn, ...
    'gui_OutputFcn',  @subParameters_OutputFcn, ...
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


% --- Executes just before subParameters is made visible.
function subParameters_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to subParameters (see VARARGIN)

% Choose default command line output for subParameters
handles.output = hObject;

if length(varargin) == 1
    subInfo = varargin{1};
    subPath = subInfo.path;
    
    [subInfo, handles] = updateGUIparameters(subInfo, handles, '');
    
    
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
    % % % %     if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    % % % %         subInfofile = fullfile(subPath, 'subInfo.mat');
    % % % %         load(subInfofile)
    % % % %
    % % % %         % let's update this figure with the subject's information
    % % % %         if isfield(subInfo, 'name'), set(handles.subName, 'String', subInfo.name); end
    % % % %         if isfield(subInfo, 'id'), set(handles.id, 'String', subInfo.id); end
    % % % %         if isfield(subInfo, 'age'), set(handles.age, 'String', subInfo.age); end
    % % % %         if isfield(subInfo, 'gender'), set(handles.gender, 'String', subInfo.gender); end
    % % % %         if isfield(subInfo, 'tumorType'), set(handles.tumorType, 'String', subInfo.tumorType); end
    % % % %
    % % % %         % let's update this figure with the subject's default parameters
    % % % %         if ~isfield(subInfo, 'parameters'),
    % % % %             subInfo = setDefaultParameters(subInfo);
    % % % %         end
    % % % %
    % % % %         if isfield(subInfo.parameters, 'dti_nDirections'), set(handles.dti_nDirections, 'String', subInfo.parameters.dti_nDirections); end
    % % % %         if isfield(subInfo.parameters, 'infSupFlip'), set(handles.infSupFlip, 'String', subInfo.parameters.infSupFlip); end
    % % % %         if isfield(subInfo.parameters, 'upDownFlip'), set(handles.upDownFlip, 'String', subInfo.parameters.upDownFlip); end
    % % % %         if isfield(subInfo.parameters, 'fileTemplate'), set(handles.fileTemplate, 'String', subInfo.parameters.fileTemplate); end
    % % % %         if isfield(subInfo.parameters, 'volumesFormat'), set(handles.volumesFormat, 'String', subInfo.parameters.volumesFormat); end
    % % % %         if isfield(subInfo.parameters, 'maxTranslation'), set(handles.maxTranslation, 'String', subInfo.parameters.maxTranslation); end
    % % % %         if isfield(subInfo.parameters, 'maxRotation'), set(handles.maxRotation, 'String', subInfo.parameters.maxRotation); end
    % % % %         if isfield(subInfo.parameters, 'nFirstVolumesToSkip'), set(handles.nFirstVolumesToSkip_fmri, 'String', subInfo.parameters.nFirstVolumesToSkip); end
    % % % %         if isfield(subInfo.parameters, 'acquisitionOrder'), set(handles.acquisitionOrder, 'String', subInfo.parameters.acquisitionOrder); end
    % % % %         if isfield(subInfo.parameters, 'smoothSize'), set(handles.smoothSize_fmri, 'String', subInfo.parameters.smoothSize); end
    % % % %
    % % % %
    % % % %         if isfield(subInfo.parameters, 'lag'),
    % % % %             if length(subInfo.parameters.lag)  == 1
    % % % %                 set(handles.lag_fmri, 'String', subInfo.parameters.lag);
    % % % %             else
    % % % %                 lg = [];
    % % % %                 for gg = 1:size(subInfo.parameters.lag, 2)
    % % % %                     lg = [lg  sprintf(' %d ', subInfo.parameters.lag(gg))];
    % % % %                 end
    % % % %
    % % % %                 set(handles.lag_fmri, 'String', lg);
    % % % %             end
    % % % %         end
    % % % %
    % % % %
    % % % %         %         if isfield(subInfo.parameters, 'fmriFirstTrigger'),
    % % % %         %             if length(subInfo.parameters.fmriFirstTrigger)  == 1
    % % % %         %                 set(handles.fmriFirstTrigger, 'String', subInfo.parameters.fmriFirstTrigger);
    % % % %         %             else
    % % % %         %                 ft = [];
    % % % %         %                 for ff = 1:size(subInfo.parameters.fmriFirstTrigger, 2)
    % % % %         %                     ft = [ft  sprintf(' %d ', subInfo.parameters.fmriFirstTrigger(ff))];
    % % % %         %                 end
    % % % %         %
    % % % %         %                 set(handles.fmriFirstTrigger, 'String', ft);
    % % % %         %             end
    % % % %         %         end
    % % % %
    % % % %
    % % % %         if isfield(subInfo.parameters, 'roiRadius'), set(handles.roiRadius, 'String', subInfo.parameters.roiRadius); end
    % % % %         if isfield(subInfo.parameters, 'cutoff'), set(handles.cutoff, 'String', sprintf('%.2f  -  %.2f', subInfo.parameters.cutoff)); end
    % % % %         %         if isfield(subInfo.parameters, 'cutoff'), set(handles.cutoff, 'String', [ '[' num2str(subInfo.parameters.cutoff, '   %.2f') ']' ]); end
    % % % %
    % % % %         if isfield(subInfo.parameters, 'wmCenter'), set(handles.wmCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.wmCenter)); end
    % % % %         if isfield(subInfo.parameters, 'csfCenter'),set(handles.csfCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.csfCenter)); end
    % % % %
    % % % %         if strcmp(deblank(get(handles.wmCenter, 'String')), '[')
    % % % %             set(handles.wmCenter, 'String', '')
    % % % %         end
    % % % %
    % % % %         if strcmp(deblank(get(handles.csfCenter, 'String')), '[')
    % % % %             set(handles.csfCenter, 'String', '')
    % % % %         end
    % % % %
    % % % %         %         if isfield(subInfo.parameters, 'createOccMask'), set(handles.createOccMask, 'Value', subInfo.parameters.createOccMask); end
    % % % %         %         if isfield(subInfo.parameters, 'createMidSagMask'), set(handles.createMidSagMask, 'Value', subInfo.parameters.createMidSagMask); end
    % % % %         %          if isfield(subInfo.parameters, 'leftHanded'), set(handles.leftHanded, 'Value', subInfo.parameters.leftHanded); end
    % % % %         %         if isfield(subInfo.parameters, 'reverseMask'), set(handles.reverseMask, 'Value', subInfo.parameters.reverseMask); end
    % % % %         %         if isfield(subInfo.parameters, 'reverseLR'), set(handles.reverseLR, 'Value', subInfo.parameters.reverseLR); end
    % % % %
    % % % %         if isfield(subInfo.parameters, 'rightHanded'),
    % % % %             set(handles.rightHanded, 'Value', subInfo.parameters.rightHanded);
    % % % %
    % % % %             if subInfo.parameters.rightHanded
    % % % %                 set(handles.leftHanded, 'Value', 0);
    % % % %             else
    % % % %                 set(handles.leftHanded, 'Value', 1);
    % % % %             end
    % % % %         end
    % % % %
    % % % %
    % % % %         if isfield(subInfo.parameters, 'minDist'), set(handles.minDist, 'String', subInfo.parameters.minDist); end
    % % % %
    % % % %         if isfield(subInfo.parameters, 'globalThresh'), set(handles.globalThresh, 'String', subInfo.parameters.globalThresh); end
    % % % %         if isfield(subInfo.parameters, 'motionThresh'), set(handles.motionThresh, 'String', subInfo.parameters.motionThresh); end
    % % % %
    % % % %         % remove the browse button
    % % % %         set(handles.browse_btn, 'Visible', 'off')
    % % % %     end
    % remove the browse button
    set(handles.browse_btn, 'Visible', 'off')
end


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes subParameters wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = subParameters_OutputFcn(hObject, eventdata, handles)
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



function maxRotation_Callback(hObject, eventdata, handles)
% hObject    handle to maxRotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxRotation as text
%        str2double(get(hObject,'String')) returns contents of maxRotation as a double


% --- Executes during object creation, after setting all properties.
function maxRotation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxRotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function  varargout = acquisitionOrder_Callback(hObject, eventdata, handles)
% hObject    handle to acquisitionOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of acquisitionOrder as text
%        str2double(get(hObject,'String')) returns contents of acquisitionOrder as a double
varargout{1} = 1;
val = str2double(get(handles.acquisitionOrder,'String'));

if (val < 0) || (val > 1) || isnan(val)
    if (get(handles.done_btn, 'Value') ~=1)
        str = sprintf('Sorry, only 0 or 1 are allowed..');
        errordlg(str);
    end
    
    %setting it back to defauld (lag_fmri = 0)
    set(handles.acquisitionOrder, 'String', '0')
    varargout{1} = 0;
end



% --- Executes during object creation, after setting all properties.
function acquisitionOrder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to acquisitionOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function smoothSize_fmri_Callback(hObject, eventdata, handles)
% hObject    handle to smoothSize_fmri (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smoothSize_fmri as text
%        str2double(get(hObject,'String')) returns contents of smoothSize_fmri as a double


% --- Executes during object creation, after setting all properties.
function smoothSize_fmri_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smoothSize_fmri (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function varargout = lag_fmri_Callback(hObject, eventdata, handles)
% hObject    handle to lag_fmri (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lag_fmri as text
%        str2double(get(hObject,'String')) returns contents of lag_fmri as a double
% varargout{1} = 1;
% val = str2double(get(handles.lag_fmri,'String'));
%
% if (val < -2) || (val > 1) || isnan(val)
%
%     if (get(handles.done_btn, 'Value') ~=1)
%         str = sprintf('Sorry, incorrect lag_fmri parameter was inserted \n(Can be only: -2, -1, 0, or 1)');
%         errordlg(str);
%     end
%
%     %setting it back to defauld (lag_fmri = 0)
%     set(handles.lag_fmri, 'String', '0')
%     varargout{1} = 0;
% end


% --- Executes during object creation, after setting all properties.
function lag_fmri_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lag_fmri (see GCBO)
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



function nFirstVolumesToSkip_fmri_Callback(hObject, eventdata, handles)
% hObject    handle to nFirstVolumesToSkip_fmri (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nFirstVolumesToSkip_fmri as text
%        str2double(get(hObject,'String')) returns contents of nFirstVolumesToSkip_fmri as a double


% --- Executes during object creation, after setting all properties.
function nFirstVolumesToSkip_fmri_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nFirstVolumesToSkip_fmri (see GCBO)
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
val_acquisitionOrder = acquisitionOrder_Callback(hObject, eventdata, handles);
% val_lag = lag_Callback(hObject, eventdata, handles);

% both are incorrect
% if sum([val_lag val_acquisitionOrder]) ~= 2
if ~val_acquisitionOrder
    str = sprintf('Inferior-posterior conversion flag is incorrect. \nPlease fix before saving.. ');
    errordlg(str);
    return
else
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
            if ~isequal(get(handles.dti_nDirections, 'String'), num2str(subInfo.parameters.dti_nDirections)),
                subInfo.parameters.dti_nDirections = str2double(get(handles.dti_nDirections, 'String'));
            end
            
            if ~isequal(get(handles.infSupFlip, 'String'), num2str(subInfo.parameters.infSupFlip)),
                subInfo.parameters.infSupFlip = str2double(get(handles.infSupFlip, 'String'));
            end
            
            if ~isequal(get(handles.upDownFlip, 'String'), num2str(subInfo.parameters.upDownFlip)),
                subInfo.parameters.upDownFlip = str2double(get(handles.upDownFlip, 'String'));
            end
            
            if ~isequal(get(handles.fileTemplate, 'String'), subInfo.parameters.fileTemplate),
                subInfo.parameters.fileTemplate = get(handles.fileTemplate, 'String');
            end
            
            if ~isequal(get(handles.volumesFormat, 'String'), subInfo.parameters.volumesFormat),
                subInfo.parameters.volumesFormat = get(handles.volumesFormat, 'String');
            end
            
            if ~isequal(get(handles.maxTranslation, 'String'), num2str(subInfo.parameters.maxTranslation)),
                subInfo.parameters.maxTranslation = str2double(get(handles.maxTranslation, 'String'));
            end
            
            if ~isequal(get(handles.maxRotation, 'String'), num2str(subInfo.parameters.maxRotation)),
                subInfo.parameters.maxRotation = str2double(get(handles.maxRotation, 'String'));
            end
            
            if ~isequal(get(handles.nFirstVolumesToSkip_fmri, 'String'), num2str(subInfo.parameters.nFirstVolumesToSkip)),
                subInfo.parameters.nFirstVolumesToSkip = str2double(get(handles.nFirstVolumesToSkip_fmri, 'String'));
            end
            
            if ~isequal(get(handles.acquisitionOrder, 'String'), num2str(subInfo.parameters.acquisitionOrder)),
                subInfo.parameters.acquisitionOrder = str2double(get(handles.acquisitionOrder, 'String'));
            end
            
            if ~isequal(get(handles.smoothSize_fmri, 'String'), num2str(subInfo.parameters.smoothSize)),
                subInfo.parameters.smoothSize = str2double(get(handles.smoothSize_fmri, 'String'));
            end
            
            if ~isequal(get(handles.roiRadius, 'String'), num2str(subInfo.parameters.roiRadius)),
                subInfo.parameters.roiRadius = str2double(get(handles.roiRadius, 'String'));
            end
            
            l = strsplit(get(handles.lag_fmri, 'String'), {'[', ',', ' ', ']'});
            l = l(~cellfun('isempty',deblank(l)));
            if (size(l,2) > 1)
                lg = [];
                if ~isempty([l{:}])
                    for gg = 1:size(l,2)
                        lg = [lg, str2double(l{gg})];
                    end
                    
                    if ~isequal(get(handles.lag_fmri, 'String'), num2str(subInfo.parameters.lag)),
                        subInfo.parameters.lag = lg;
                    end
                end
            else
                subInfo.parameters.lag = str2double(get(handles.lag_fmri, 'String'));
            end
            
            
            %             f = strsplit(get(handles.fmriFirstTrigger, 'String'), {'[', ',', ' ', ']'});
            %             f = f(~cellfun('isempty',deblank(f)));
            %             if (size(f,2) > 1)
            %                 ft = [];
            %                 if ~isempty([f{:}])
            %                     for tt = 1:size(f,2)
            %                         ft = [ft, str2double(f{tt})];
            %                     end
            %
            %                     if ~isequal(get(handles.fmriFirstTrigger, 'String'), num2str(subInfo.parameters.fmriFirstTrigger)),
            %                         subInfo.parameters.fmriFirstTrigger = ft;
            %                     end
            %                 end
            %             else
            %                 subInfo.parameters.fmriFirstTrigger = str2double(get(handles.fmriFirstTrigger, 'String'));
            %             end
            
            
            
            co = strsplit(get(handles.cutoff, 'String'), '-');
            c = [str2double(co{1}), str2double(co{2})];
            
            if ~isequal(c, subInfo.parameters.cutoff),
                subInfo.parameters.cutoff(1) = c(1);
                subInfo.parameters.cutoff(2) = c(2);
            end
            
            wm = strsplit(get(handles.wmCenter, 'String'), {'[', ',', ' ', ']'});
            wm = wm(~cellfun('isempty',deblank(wm)));
            
            if ~isempty([wm{:}])
                wmc = [str2double(wm{1}), str2double(wm{2}), str2double(wm{3})];
                
                if ~isequal(get(handles.wmCenter, 'String'), num2str(subInfo.parameters.wmCenter)),
                    subInfo.parameters.wmCenter = wmc;
                end
            else
                wmc = wm;
            end
            
            
            
            csf = strsplit(get(handles.csfCenter, 'String'), {'[', ',', ' ', ']'});
            csf = csf(~cellfun('isempty',deblank(csf)));
            
            if ~isempty([csf{:}])
                csfc = [str2double(csf{1}), str2double(csf{2}), str2double(csf{3})];
                if ~isequal(get(handles.csfCenter, 'String'), num2str(subInfo.parameters.csfCenter)),
                    subInfo.parameters.csfCenter = csfc;
                end
                
            else
                csfc = csf;
            end
            
            
            %             if ~isequal(get(handles.createOccMask, 'Value'), num2str(subInfo.parameters.createOccMask)),
            %                 subInfo.parameters.createOccMask = str2double(get(handles.createOccMask, 'Value'));
            %             end
            %
            %             if ~isequal(get(handles.createMidSagMask, 'Value'), num2str(subInfo.parameters.createMidSagMask)),
            %                 subInfo.parameters.createMidSagMask = str2double(get(handles.createMidSagMask, 'Value'));
            %             end
            %
            if ~isequal(get(handles.rightHanded, 'Value'), num2str(subInfo.parameters.rightHanded)),
                subInfo.parameters.rightHanded = get(handles.rightHanded, 'Value');
            end
            %
            %              if ~isequal(get(handles.leftHanded, 'Value'), num2str(subInfo.parameters.leftHanded)),
            %                  subInfo.parameters.leftHanded = str2double(get(handles.leftHanded, 'Value'));
            %              end
            %
            %             if ~isequal(get(handles.reverseOccMask, 'Value'), num2str(subInfo.parameters.reverseOccMask)),
            %                 subInfo.parameters.reverseOccMask = str2double(get(handles.reverseOccMask, 'Value'));
            %             end
            %
            %             if ~isequal(get(handles.reverseMidSagMask, 'Value'), num2str(subInfo.parameters.reverseMidSagMask)),
            %                 subInfo.parameters.reverseMidSagMask = str2double(get(handles.reverseMidSagMask, 'Value'));
            %             end
            %
            if ~isequal(get(handles.minDist, 'String'), num2str(subInfo.parameters.minDist)),
                subInfo.parameters.minDist = str2double(get(handles.minDist, 'String'));
            end
            
            if ~isequal(get(handles.globalThresh, 'String'), num2str(subInfo.parameters.globalThresh)),
                subInfo.parameters.globalThresh = str2double(get(handles.globalThresh, 'String'));
            end
            
            if ~isequal(get(handles.motionThresh, 'String'), num2str(subInfo.parameters.motionThresh)),
                subInfo.parameters.motionThresh = str2double(get(handles.motionThresh, 'String'));
            end
            
            save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
        end
    end
end

% --- Executes on button press in done_btn.
function done_btn_Callback(hObject, eventdata, handles)
% hObject    handle to done_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
% we need to first check that all parameters are without change.
reSave_flag = 0;
val_acquisitionOrder = acquisitionOrder_Callback(hObject, eventdata, handles);
%val_lag = lag_Callback(hObject, eventdata, handles);

% both are incorrect
if ~val_acquisitionOrder
    str = sprintf('Inferior-posterior conversion flag is incorrect. \nPlease fix before exiting.. ');
    errordlg(str);
    return
else
    
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
            l = strsplit(get(handles.lag_fmri, 'String'), {'[', ',', ' ', ']'});
            l = l(~cellfun('isempty',deblank(l)));
            lg = [];
            if ~isempty([l{:}])
                for gg = 1:size(l,2)
                    lg = [lg, str2double(l{gg})];
                end
            else
                lg = [];
            end
            
            %             f = strsplit(get(handles.fmriFirstTrigger, 'String'), {'[', ',', ' ', ']'});
            %             f = f(~cellfun('isempty',deblank(f)));
            %             ft = [];
            %             if ~isempty([f{:}])
            %                 for tt = 1:size(f,2)
            %                     ft = [ft, str2double(f{tt})];
            %                 end
            %             else
            %                 ft = [];
            %             end
            
            
            co = strsplit(get(handles.cutoff, 'String'), '-');
            c = [str2double(co{1}), str2double(co{2})];
            
            wm = strsplit(get(handles.wmCenter, 'String'), {'[', ',', ' ', ']'});
            wm = wm(~cellfun('isempty',deblank(wm)));
            if ~isempty([wm{:}])
                wmc = [str2double(wm{1}), str2double(wm{2}), str2double(wm{3})];
            else
                wmc = [];
            end
            
            
            csf = strsplit(get(handles.wmCenter, 'String'), {'[', ',', ' ', ']'});
            csf = csf(~cellfun('isempty',deblank(csf)));
            if ~isempty([csf{:}])
                csfc = [str2double(csf{1}), str2double(csf{2}), str2double(csf{3})];
            else
                csfc = [];
            end
            
            %~isequal(ft, subInfo.parameters.fmriFirstTrigger) || ...
            
            if ~isequal(get(handles.dti_nDirections, 'String'), num2str(subInfo.parameters.dti_nDirections)) || ...
                    ~isequal(get(handles.infSupFlip, 'String'), num2str(subInfo.parameters.infSupFlip)) || ...
                    ~isequal(get(handles.upDownFlip, 'String'), num2str(subInfo.parameters.upDownFlip)) || ...
                    ~isequal(get(handles.fileTemplate, 'String'), subInfo.parameters.fileTemplate) || ...
                    ~isequal(get(handles.volumesFormat, 'String'), subInfo.parameters.volumesFormat) || ...
                    ~isequal(get(handles.maxTranslation, 'String'), num2str(subInfo.parameters.maxTranslation)) || ...
                    ~isequal(get(handles.maxRotation, 'String'), num2str(subInfo.parameters.maxRotation)) || ...
                    ~isequal(get(handles.nFirstVolumesToSkip_fmri, 'String'), num2str(subInfo.parameters.nFirstVolumesToSkip)) || ...
                    ~isequal(get(handles.acquisitionOrder, 'String'), num2str(subInfo.parameters.acquisitionOrder)) || ...
                    ~isequal(get(handles.smoothSize_fmri, 'String'), num2str(subInfo.parameters.smoothSize)) || ...
                    ~isequal(lg, subInfo.parameters.lag) || ...
                    ~isequal(get(handles.roiRadius, 'String'), num2str(subInfo.parameters.roiRadius)) || ...
                    ~isequal(c, subInfo.parameters.cutoff) || ...
                    ~isequal(wmc, subInfo.parameters.wmCenter) || ...
                    ~isequal(csfc, subInfo.parameters.csfCenter) || ...
                    ~isequal(get(handles.minDist, 'String'), num2str(subInfo.parameters.minDist)) || ...
                    ~isequal(get(handles.rightHanded, 'Value'), subInfo.parameters.rightHanded) || ...
                    ~isequal(get(handles.globalThresh, 'String'), num2str(subInfo.parameters.globalThresh)) || ...
                    ~isequal(get(handles.motionThresh, 'String'), num2str(subInfo.parameters.motionThresh))
                
                reSave_flag = 1;
            end
        end
    end
end

if reSave_flag,
    % open msg dlg and ask the user if we can continue
    % Construct a questdlg with two options
    str = sprintf('There are certain parameters that were changed, \nSave before exit?');
    choice = questdlg(str, ...
        'Save and exit?', ...
        'Yes','No', 'Yes');
    % Handle response
    if isequal(choice, 'Yes')
        disp('Saving the new parameters.')
        save_btn_Callback(hObject, eventdata, handles)
    end
end

varargout{1} = subParameters_OutputFcn(hObject, eventdata, handles);
close



function edit17_Callback(hObject, eventdata, handles)
% hObject    handle to acquisitionOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of acquisitionOrder as text
%        str2double(get(hObject,'String')) returns contents of acquisitionOrder as a double


% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to acquisitionOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in resetDefualtParameters.
function resetDefualtParameters_Callback(hObject, eventdata, handles)
% hObject    handle to resetDefualtParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global subPath
if ~isempty(subPath)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        subInfo = setDefaultParameters(subInfo);
        
        if isfield(subInfo.parameters, 'dti_nDirections'), set(handles.dti_nDirections, 'String', subInfo.parameters.dti_nDirections); end
        if isfield(subInfo.parameters, 'infSupFlip'), set(handles.infSupFlip, 'String', subInfo.parameters.infSupFlip); end
        if isfield(subInfo.parameters, 'upDownFlip'), set(handles.upDownFlip, 'String', subInfo.parameters.upDownFlip); end
        if isfield(subInfo.parameters, 'fileTemplate'), set(handles.fileTemplate, 'String', subInfo.parameters.fileTemplate); end
        if isfield(subInfo.parameters, 'volumesFormat'), set(handles.volumesFormat, 'String', subInfo.parameters.volumesFormat); end
        if isfield(subInfo.parameters, 'maxTranslation'), set(handles.maxTranslation, 'String', subInfo.parameters.maxTranslation); end
        if isfield(subInfo.parameters, 'maxRotation'), set(handles.maxRotation, 'String', subInfo.parameters.maxRotation); end
        if isfield(subInfo.parameters, 'nFirstVolumesToSkip'), set(handles.nFirstVolumesToSkip_fmri, 'String', subInfo.parameters.nFirstVolumesToSkip); end
        if isfield(subInfo.parameters, 'acquisitionOrder'), set(handles.acquisitionOrder, 'String', subInfo.parameters.acquisitionOrder); end
        if isfield(subInfo.parameters, 'smoothSize'), set(handles.smoothSize_fmri, 'String', subInfo.parameters.smoothSize); end
        
        if isfield(subInfo.parameters, 'lag'),
            if length(subInfo.parameters.lag)  == 1
                set(handles.lag_fmri, 'String', subInfo.parameters.lag);
            else
                set(handles.lag_fmri, 'String', sprintf('%d  %d  %d  %d  %d  %d  %d', subInfo.parameters.lag));
            end
        end
        
        %         if isfield(subInfo.parameters, 'fmriFirstTrigger'),
        %             if length(subInfo.parameters.fmriFirstTrigger)  == 1
        %                 set(handles.fmriFirstTrigger, 'String', subInfo.parameters.fmriFirstTrigger);
        %             else
        %                 ft = [];
        %                 for ff = 1:size(subInfo.parameters.fmriFirstTrigger, 2)
        %                     ft = [ft  sprintf(' %d ', subInfo.parameters.fmriFirstTrigger(ff))];
        %                 end
        %
        %                 set(handles.fmriFirstTrigger, 'String', ft);
        %             end
        %         end
        
        if isfield(subInfo.parameters, 'roiRadius'), set(handles.roiRadius, 'String', subInfo.parameters.roiRadius); end
        if isfield(subInfo.parameters, 'cutoff'), set(handles.cutoff, 'String', sprintf('%.2f  -  %.2f', subInfo.parameters.cutoff)); end
        if isfield(subInfo.parameters, 'wmCenter'), set(handles.wmCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.wmCenter)); end
        if isfield(subInfo.parameters, 'csfCenter'), set(handles.csfCenter, 'String', sprintf('[%d  %d  %d]', subInfo.parameters.csfCenter)); end
        
        if strcmp(deblank(get(handles.wmCenter, 'String')), '[')
            set(handles.wmCenter, 'String', '')
        end
        
        if strcmp(deblank(get(handles.csfCenter, 'String')), '[')
            set(handles.csfCenter, 'String', '')
        end
        
        
        %         if isfield(subInfo.parameters, 'createOccMask'), set(handles.createOccMask, 'Value', subInfo.parameters.createOccMask); end
        %         if isfield(subInfo.parameters, 'createMidSagMask'), set(handles.createMidSagMask, 'Value', subInfo.parameters.createMidSagMask); end
        if isfield(subInfo.parameters, 'rightHanded'), set(handles.rightHanded, 'Value', subInfo.parameters.rightHanded); end
        %         if isfield(subInfo.parameters, 'leftHanded'), set(handles.leftHanded, 'Value', subInfo.parameters.leftHanded); end
        %         if isfield(subInfo.parameters, 'reverseOccMask'), set(handles.reverseOccMask, 'Value', subInfo.parameters.reverseOccMask); end
        %         if isfield(subInfo.parameters, 'reverseMidSagMask'), set(handles.reverseMidSagMask, 'Value', subInfo.parameters.reverseMidSagMask); end
        if isfield(subInfo.parameters, 'minDist'), set(handles.minDist, 'String', subInfo.parameters.minDist); end
        
        if isfield(subInfo.parameters, 'globalThresh'), set(handles.globalThresh, 'String', subInfo.parameters.globalThresh); end
        if isfield(subInfo.parameters, 'motionThresh'), set(handles.motionThresh, 'String', subInfo.parameters.motionThresh); end
        
        
        %         if isfield(subInfo.parameters, 'cutoff'), set(handles.cutoff, 'String', [ '[' num2str(subInfo.parameters.cutoff, '   %.2f') ']' ]); end
        
        % if isfield(subInfo.parameters, 'wmCenter'), set(handles.wmCenter, 'String', subInfo.parameters.wmCenter); end
        % if isfield(subInfo.parameters, 'csfCenter'), set(handles.csfCenter, 'String', subInfo.parameters.csfCenter); end
    end
end


% --- Executes on button press in browse_btn.
function browse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to browse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath

rawDataPath = 'M:\clinica\patients\Full_Scans';
curMonth = datestr(now, 'mmmm');
curPath = fullfile(rawDataPath, curMonth);
cd(curPath);
newSubPath = uigetdir(curPath,'Select subject''s folder for viewing parameters');

if ischar(newSubPath)
    subPath = newSubPath;
    
    cd(subPath);
    
    [p subName e] = fileparts(subPath);
    set(handles.subName, 'String', subName)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        subParameters_OpeningFcn(hObject, eventdata, handles, subInfo)
    end
end



function cutoff_Callback(hObject, eventdata, handles)
% hObject    handle to cutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cutoff as text
%        str2double(get(hObject,'String')) returns contents of cutoff as a double
co = strsplit(get(handles.cutoff, 'String'), '-');
c1 = str2double(co{1});
c2 = str2double(co{2});

if (c1 > c2) || (c1 == 0) || (c2 == 0)
    str = sprintf('Sorry, you have inserted wrong range..');
    errordlg(str);
    
    % setting it back to default (lag_fmri = 0)
    set(handles.cutoff, 'String', sprintf('%.2f  -  %.2f', [0.02, 0.08]));
end


% --- Executes during object creation, after setting all properties.
function cutoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function roiRadius_Callback(hObject, eventdata, handles)
% hObject    handle to roiradius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of roiradius as text
%        str2double(get(hObject,'String')) returns contents of roiradius as a double


% --- Executes during object creation, after setting all properties.
function roiRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roiradius (see GCBO)
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
    wmCenter = sprintf('[%s   %s   %s]', coords{:});
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
    csfCenter = sprintf('[%s   %s   %s]', coords{:});
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



function infSupFlip_Callback(hObject, eventdata, handles)
% hObject    handle to infSupFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of infSupFlip as text
%        str2double(get(hObject,'String')) returns contents of infSupFlip as a double
val = str2double(get(handles.infSupFlip,'String'));
if (val < 0) || (val > 1) || isnan(val)
    
    if (get(handles.done_btn, 'Value') ~=1)
        str = sprintf('Sorry, This parameter can be either 0 or 1. \n(changing back to default)');
        errordlg(str);
    end
    
    %setting it back to defauld
    set(handles.infSupFlip, 'String', '0')
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



function upDownFlip_Callback(hObject, eventdata, handles)
% hObject    handle to upDownFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of upDownFlip as text
%        str2double(get(hObject,'String')) returns contents of upDownFlip as a double
val = str2double(get(handles.upDownFlip,'String'));
if (val < 0) || (val > 1) || isnan(val)
    
    if (get(handles.done_btn, 'Value') ~=1)
        str = sprintf('Sorry, This parameter can be either 0 or 1. \n(changing back to default)');
        errordlg(str);
    end
    
    %setting it back to defauld
    set(handles.upDownFlip, 'String', '0')
end

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

function edit31_Callback(hObject, eventdata, handles)
% hObject    handle to infSupFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of infSupFlip as text
%        str2double(get(hObject,'String')) returns contents of infSupFlip as a double


% --- Executes during object creation, after setting all properties.
function edit31_CreateFcn(hObject, eventdata, handles)
% hObject    handle to infSupFlip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function globalThresh_Callback(hObject, eventdata, handles)
% hObject    handle to globalThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of globalThresh as text
%        str2double(get(hObject,'String')) returns contents of globalThresh as a double


% --- Executes during object creation, after setting all properties.
function globalThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to globalThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function motionThresh_Callback(hObject, eventdata, handles)
% hObject    handle to motionThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of motionThresh as text
%        str2double(get(hObject,'String')) returns contents of motionThresh as a double


% --- Executes during object creation, after setting all properties.
function motionThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to motionThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fmriFirstTrigger_Callback(hObject, eventdata, handles)
% hObject    handle to fmriFirstTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fmriFirstTrigger as text
%        str2double(get(hObject,'String')) returns contents of fmriFirstTrigger as a double


% --- Executes during object creation, after setting all properties.
function fmriFirstTrigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fmriFirstTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in createMidSagMask.
function createMidSagMask_Callback(hObject, eventdata, handles)
% hObject    handle to createMidSagMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of createMidSagMask


% --- Executes on button press in rightHanded.
function rightHanded_Callback(hObject, eventdata, handles)
% hObject    handle to rightHanded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rightHanded
rightHandVal = get(hObject,'Value');
if rightHandVal
    set(handles.leftHanded, 'Value', 0);
end

% --- Executes on button press in leftHanded.
function leftHanded_Callback(hObject, eventdata, handles)
% hObject    handle to leftHanded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of leftHanded
leftHandVal = get(hObject,'Value');
if leftHandVal
    set(handles.rightHanded, 'Value', 0);
end

% --- Executes on button press in reverseOccMask.
function reverseOccMask_Callback(hObject, eventdata, handles)
% hObject    handle to reverseOccMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reverseOccMask


% --- Executes on button press in reverseMidSagMask.
function reverseMidSagMask_Callback(hObject, eventdata, handles)
% hObject    handle to reverseMidSagMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of reverseMidSagMask



function smoothSize_eeg_Callback(hObject, eventdata, handles)
% hObject    handle to smoothSize_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smoothSize_eeg as text
%        str2double(get(hObject,'String')) returns contents of smoothSize_eeg as a double


% --- Executes during object creation, after setting all properties.
function smoothSize_eeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smoothSize_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lag_eeg_Callback(hObject, eventdata, handles)
% hObject    handle to lag_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lag_eeg as text
%        str2double(get(hObject,'String')) returns contents of lag_eeg as a double


% --- Executes during object creation, after setting all properties.
function lag_eeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lag_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nFirstVolumesToSkip_eeg_Callback(hObject, eventdata, handles)
% hObject    handle to nFirstVolumesToSkip_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nFirstVolumesToSkip_eeg as text
%        str2double(get(hObject,'String')) returns contents of nFirstVolumesToSkip_eeg as a double


% --- Executes during object creation, after setting all properties.
function nFirstVolumesToSkip_eeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nFirstVolumesToSkip_eeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
