function varargout = processWithFullCoreg(varargin)
%PROCESSWITHFULLCOREG M-file for processWithFullCoreg.fig
%      PROCESSWITHFULLCOREG, by itself, creates a new PROCESSWITHFULLCOREG or raises the existing
%      singleton*.
%
%      H = PROCESSWITHFULLCOREG returns the handle to a new PROCESSWITHFULLCOREG or the handle to
%      the existing singleton*.
%
%      PROCESSWITHFULLCOREG('Property','Value',...) creates a new PROCESSWITHFULLCOREG using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to processWithFullCoreg_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      PROCESSWITHFULLCOREG('CALLBACK') and PROCESSWITHFULLCOREG('CALLBACK',hObject,...) call the
%      local function named CALLBACK in PROCESSWITHFULLCOREG.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help processWithFullCoreg

% Last Modified by GUIDE v2.5 02-Aug-2017 09:59:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @processWithFullCoreg_OpeningFcn, ...
    'gui_OutputFcn',  @processWithFullCoreg_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
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


% --- Executes just before processWithFullCoreg is made visible.
function processWithFullCoreg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for processWithFullCoreg
handles.output = hObject;
global subPath

% uploading protocol table file...
protocolPath = 'M:\protocols-new';
protocolFile = 'ProtocolsTable.xls';
pfile = fullfile(protocolPath, protocolFile);
%cd(protocolPath);
if ((exist(pfile, 'file')) == 2)
    [data, txt, protocolFile_raw] = xlsread(pfile); % basic for quicker reading
    % [data, txt, protocolFile_raw] = xlsread(pfile, '', '', 'basic'); % basic for quicker reading
else
    fprintf('%s file was not found!!\n', pfile);
end

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
    
    pTable = subInfo.wholeScanSession(2:end,:);
    logicals = cell2mat(pTable(:,1));
    pTable(logicals == 0,:) = [];
    
    % we need to show only the fMRI scans
    % we analyze according to the scan type (fMRI)
    % scanType = regexpi(pTable(:,3), '(fMRI|rest|ep2d)+[^(_| )]*', 'match');
    scanType = regexpi(pTable(:,3), '(fMRI|rest)+[^(_| )]*', 'match');
    row = find(~cellfun('isempty', scanType));
    ls = pTable(row,:);
    
    % checking if there are fMRI sessions that the runner did not mark them
    % as fmri (did not write fmri in the description) so we check the fifth
    % column to see if there is a number inserted...
    p = pTable;
    p = p(~cellfun('isempty',p(:,5)), :);
    
    ls = [p; pTable(row,:)];
    
    [A ia ic] = unique(ls(:,2));
    B = cell(numel(A));
    B = ls(ia,:);
    
    A = (B(:,2));
    C = cell(numel(A));
    [Sorted_A, Index_A] = sort(str2double(A));
    % C(:,1) = strtrim(cellstr(num2str(Sorted_A)));
    C = B(Index_A,:);
    
    ls = C;
    
    % now let's add if there are series without the fmri prefix..
    for k = 1:size(pTable,1)
        
        % let's search the name in the protocol table...
        tasksList = lower(protocolFile_raw(:,3));
        logicalArray = ~cellfun('isempty', strfind(tasksList, lower(pTable{k,3})));
        
        if (sum(logicalArray) > 0)
            ls(end+1, :) = pTable(k,:);
        end
    end
    
    set(handles.protocolTable, 'Data', ls);
    
    [subInfo handles] = updateGUIparameters(subInfo, handles, 'processWithFullCoreg');
    
    %     % now setting the SPGR_btn - which shows the current spgr file that we are
    %     % using for coregistration
    %     %anatomyfile = regexp(subInfo.SPGR, '\w*[^.nii]', 'match');
    %     if isfield(subInfo, 'SPGR')
    %         str = sprintf('%s', subInfo.SPGR);
    %     else
    %         str = '';
    %     end
    %     set(handles.SPGR_btn, 'String', str);
    %
    %     if isfield(subInfo, 'id'), set(handles.id, 'String', subInfo.id); end
    %     if isfield(subInfo, 'age'), set(handles.age, 'String', subInfo.age); end
    %     if isfield(subInfo, 'gender'), set(handles.gender, 'String', subInfo.gender); end
    %     if isfield(subInfo, 'tumorType'), set(handles.tumorType, 'String', subInfo.tumorType); end
    %
    %     % let's update this figure with the subject's default parameters
    %     if ~isfield(subInfo, 'parameters'),
    %         subInfo = setDefaultParameters(subInfo);
    %     end
    %
    %     if isfield(subInfo.parameters, 'maxTranslation'), set(handles.maxTranslation, 'String', subInfo.parameters.maxTranslation); end
    %     if isfield(subInfo.parameters, 'maxRotation'), set(handles.maxRotation, 'String', subInfo.parameters.maxRotation); end
    %     if isfield(subInfo.parameters, 'acquisitionOrder'), set(handles.acquisitionOrder, 'String', subInfo.parameters.acquisitionOrder); end
    %     if isfield(subInfo.parameters, 'nFirstVolumesToSkip_fmri'), set(handles.nFirstVolumesToSkip_fmri, 'String', subInfo.parameters.nFirstVolumesToSkip_fmri); end
    %     if isfield(subInfo.parameters, 'nFirstVolumesToSkip_eeg'), set(handles.nFirstVolumesToSkip_eeg, 'String', subInfo.parameters.nFirstVolumesToSkip_eeg); end
    %     if isfield(subInfo.parameters, 'smoothSize_fmri'), set(handles.smoothSize_fmri, 'String', subInfo.parameters.smoothSize_fmri); end
    %     if isfield(subInfo.parameters, 'smoothSize_eeg'), set(handles.smoothSize_eeg, 'String', subInfo.parameters.smoothSize_eeg); end
    %
    %     if isfield(subInfo.parameters, 'lag_fmri'), set(handles.lag_fmri, 'String', subInfo.parameters.lag_fmri); end
    %     if isfield(subInfo.parameters, 'lag_eeg'), set(handles.lag_eeg, 'String', sprintf('[%d  %d  %d  %d  %d  %d  %d]', subInfo.parameters.lag_eeg)); end
    %
    %
    %     % if its an EEG-fMRI session we are doing the estimate and contrast in
    %     % another gui.. let's make the checkbox of estimate and contrast
    %     % dissapear!
    %     isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
    %     if ~isempty(isEEG)
    %         set(handles.est, 'Enable', 'off');
    %         set(handles.contrast, 'Enable', 'off');
    %         set(handles.lag_fmri, 'Enable', 'off');
    %         set(handles.lag_text, 'Enable', 'off');
    %         set(handles.text12, 'Enable', 'off'); % the txt explaining the lags...
    %     end
    
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes processWithFullCoreg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = processWithFullCoreg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in segment_btn.
function segment_btn_Callback(hObject, eventdata, handles)
% hObject    handle to segment_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of segment_btn


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath

if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
    
    % first let's see if there are any overrides we need to do...
    processWithFullCoreg_part1 = get(handles.processWithFullCoreg_part1, 'Value');
    processWithFullCoreg_part2 = get(handles.processWithFullCoreg_part2, 'Value');
    coregApproval = get(handles.coregApproval, 'Value');
    create4D = get(handles.create4D, 'Value');
    pTable = get(handles.protocolTable, 'Data');
    
    sliceTiming = get(handles.sliceTiming, 'Value');
    realign  = get(handles.realign, 'Value');
    coreg  = get(handles.coreg, 'Value');
    smooth = get(handles.smoothing, 'Value');
    
    est  = get(handles.est, 'Value');
    if strcmp(get(handles.est, 'Enable'), 'off')
        est = 0;
    end
    
    contrast  = get(handles.contrast, 'Value');
    if strcmp(get(handles.contrast, 'Enable'), 'off')
        contrast = 0;
    end
    
    % now we move to the preprocessing stage itself.
    % the first part includes slice timing, realignment and
    % coregistration, after which the user is prompt to
    % continue (after examining the coregistration in
    % mricron
    if isfield(subInfo, 'fMRIsession')
        
        %         % we take only what is marked!
        %         logicals = cell2mat(pTable(:,1));
        %         pTable(logicals == 0,:) = [];
        
        % let's see if fMRIsession field exist - and if it does we'll go over it
        % and coregister them one by one
        fields = subInfo.fMRIsession;
        fieldnameToAccess = sort(fieldnames(fields));
        
        % we need to set the pTable to contain either fmri session or eeg-fmri
        % session.
        isEEG = regexp(lower(fieldnameToAccess), 'eeg_fmri', 'match');
        fmri_ind = find(cellfun(@isempty,isEEG));
        fmri_pTable = pTable(fmri_ind,:)
        
        % we take only what is marked!
        logicals = cell2mat(fmri_pTable(:,1));
        fmri_pTable(logicals == 0,:) = [];
        
        if ~isempty(isEEG)
            eeg_fmri_ind = find(~cellfun(@isempty,isEEG));
            eeg_fmri_pTable = pTable(eeg_fmri_ind,:)
            
            % we take only what is marked!
            logicals = cell2mat(eeg_fmri_pTable(:,1));
            eeg_fmri_pTable(logicals == 0,:) = [];
        end
        
        if processWithFullCoreg_part1
            if ~isempty(fmri_pTable)
                [subInfo, part1_status_flag] = processWithFullCoregClinic_sliceRealignCoreg(subInfo, fmri_pTable, sliceTiming, realign, coreg);
            end
            % find the corresponding field in subInfo
            if ~isempty(eeg_fmri_pTable)
                [subInfo, part1_status_flag] = processWithFullCoregClinic_sliceRealignCoreg(subInfo, eeg_fmri_pTable, sliceTiming, realign, coreg);
            end
            
            
            % when we finish this part we should ask if the user want to
            % continue to the next part of preprocessing - that is, to do
            % smoothing, estimation and contrast definition
            % but first, we'll open the viewer folder and let the user look
            % at the registrations..
            
            filename = fullfile( subPath, 'viewer');
            %         filename = strrep(filename, '\\fmri-t2\clinica$', 'M:')
            winopen(filename)
            
            % open msg dlg and ask the user if we can continue
            % Construct a questdlg with two options
            if (coregApproval == 1)
                str = sprintf('Finished the first part of preprocessing \n(Slice timing, realignment and coregistration)\n Would you like to continue?');
                choice = questdlg(str, ...
                    'Preprocessing paused (please check coregistration)', ...
                    'Yes','No', 'Yes');
                % Handle response
                switch choice
                    case 'Yes'
                        disp('Ok, let''s Continue!')
                        
                        % and than moving to the next stage -
                        % the second part of preprocessing -
                        % smoothing, estimation and contrast
                        % definition.
                        if processWithFullCoreg_part2
                            if ~isempty(fmri_pTable)
                                [subInfo, part2_status_flag] = processWithFullCoregClinic_smoothEstCont(subInfo, fmri_pTable, smooth, est, contrast, create4D);
                            end
                            
                            if ~isempty(eeg_fmri_pTable)
                                [subInfo, part2_status_flag] = processWithFullCoregClinic_smoothEstCont(subInfo, eeg_fmri_pTable, smooth, est, contrast, create4D);
                            end
                            
                        else
                            errordlg('Sorry, but you did not check the preprocessing part II option..')
                        end
                    case 'No'
                        disp('Aborting!')
                end
            else
                if processWithFullCoreg_part2
                    if ~isempty(fmri_pTable)
                        [subInfo, part2_status_flag] = processWithFullCoregClinic_smoothEstCont(subInfo, fmri_pTable, smooth, est, contrast, create4D);
                    end
                    if ~isempty(eeg_fmri_pTable)
                        [subInfo, part2_status_flag] = processWithFullCoregClinic_smoothEstCont(subInfo, eeg_fmri_pTable, smooth, est, contrast, create4D);
                    end
                else
                    errordlg('Sorry, but you did not check the preprocessing part II option..')
                end
            end
        end % if processWithFullCoreg_part1
        
        % if we checked only the second options of preprocessing..
        if processWithFullCoreg_part2 && (processWithFullCoreg_part1 == 0)
            if ~isempty(fmri_pTable)
                [subInfo, part2_status_flag] = processWithFullCoregClinic_smoothEstCont(subInfo, fmri_pTable, smooth, est, contrast, create4D);
            end
            
            if ~isempty(eeg_fmri_pTable)
                [subInfo, part2_status_flag] = processWithFullCoregClinic_smoothEstCont(subInfo, eeg_fmri_pTable, smooth, est, contrast, create4D);
            end
        end
        
        % if the user just was to compute 4D
        if (processWithFullCoreg_part1 == 0)...
                && (processWithFullCoreg_part2 == 0) && create4D
            if ~isempty(fmri_pTable)
                create4DperSlice(subInfo, fmri_pTable, [], []);
            end
            
            if ~isempty(eeg_fmri_pTable)
                create4DperSlice(subInfo, eeg_fmri_pTable, [], []);
            end
        end
        
        % if the user pressed the check box of
        % Apply skull stripping - we're doing
        % segmentation.
        skullstrip_flag = get(handles.segment_btn, 'Value');
        if skullstrip_flag
            [subInfo, segment_status_flag] = processWithFullCoregClinic_segment(subInfo);
        end
        
        close;
        % moving to the next window - view activations!
        % viewActivations(subInfo)
    end % if isfield(subInfo, 'fMRIsession')
end



% --- Executes on button press in browse_btn.
function browse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to browse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fprintf('\n');
fprintf('Uploading subject''s scanning session..\n');

global subName
global subPath

rawDataPath = 'M:\clinica\patients\Full_Scans';
% curMonth = datestr(now, 'mmmm');
% curPath = fullfile(rawDataPath, curMonth);
cd(rawDataPath);
newSubPath = uigetdir(rawDataPath,'Select subject for series renaming');

if ischar(newSubPath)
    subPath = newSubPath;
    cd(subPath);
    
    [p subName e] = fileparts(subPath);
    set(handles.subName, 'String', subName)
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        pTable = subInfo.wholeScanSession(2:end,:);
        logicals = cell2mat(pTable(:,1));
        pTable(logicals == 0,:) = [];
        
        % removig the remarks column
        keep = any(~cellfun('isempty', pTable), 1);
        pTable = pTable(:, keep);
        
        
        % we need to show only the fMRI scans
        % we analyze according to the scan type (fMRI)
        scanType = regexpi(pTable(:,3), '(fMRI|rest)+[^(_| )]*', 'match');
        row = find(~cellfun('isempty', scanType));
        
        set(handles.protocolTable, 'Data', pTable(row,:));
        
        [subInfo handles] = updateGUIparameters(subInfo, handles, 'processWithFullCoreg');
        
        %         % now setting the SPGR_btn - which shows the current spgr file that we are
        %         % using for coregistration
        %         %anatomyfile = regexp(subInfo.SPGR, '\w*[^.nii]', 'match');
        %         str = sprintf('%s', subInfo.SPGR);
        %         set(handles.SPGR_btn, 'String', str);
        %
        %         if isfield(subInfo, 'id'), set(handles.id, 'String', subInfo.id); end
        %         if isfield(subInfo, 'age'), set(handles.age, 'String', subInfo.age); end
        %         if isfield(subInfo, 'gender'), set(handles.gender, 'String', subInfo.gender); end
        %         if isfield(subInfo, 'tumorType'), set(handles.tumorType, 'String', subInfo.tumorType); end
        %
        %         % let's update this figure with the subject's default parameters
        %         if ~isfield(subInfo, 'parameters'),
        %             subInfo = setDefaultParameters(subInfo)    ;
        %         end
        %
        %         if isfield(subInfo.parameters, 'maxTranslation'), set(handles.maxTranslation, 'String', subInfo.parameters.maxTranslation); end
        %         if isfield(subInfo.parameters, 'maxRotation'), set(handles.maxRotation, 'String', subInfo.parameters.maxRotation); end
        %         if isfield(subInfo.parameters, 'nFirstVolumesToSkip'), set(handles.nFirstVolumesToSkip_fmri, 'String', subInfo.parameters.nFirstVolumesToSkip); end
        %         if isfield(subInfo.parameters, 'acquisitionOrder'), set(handles.acquisitionOrder, 'String', subInfo.parameters.acquisitionOrder); end
        %         if isfield(subInfo.parameters, 'smoothSize'), set(handles.smoothSize_fmri, 'String', subInfo.parameters.smoothSize); end
        %         if isfield(subInfo.parameters, 'lag'), set(handles.lag_fmri, 'String', subInfo.parameters.lag); end
        %
    end
end



% --- Executes on button press in processWithFullCoreg_part1.
function processWithFullCoreg_part1_Callback(hObject, eventdata, handles)
% hObject    handle to processWithFullCoreg_part1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of processWithFullCoreg_part1
val = get(hObject,'Value');

if val
    set(handles.acquisitionOrder, 'Enable', 'on');
    set(handles.nFirstVolumesToSkip_fmri, 'Enable', 'on');
    set(handles.nFirstVolumesToSkip_eeg, 'Enable', 'on');
    set(handles.maxTranslation, 'Enable', 'on');
    set(handles.maxRotation, 'Enable', 'on');
    set(handles.sliceTiming, 'Value', 1);
    set(handles.realign, 'Value', 1);
    set(handles.coreg, 'Value', 1);
else
    set(handles.acquisitionOrder, 'Enable', 'off');
    set(handles.nFirstVolumesToSkip_fmri, 'Enable', 'off');
    set(handles.nFirstVolumesToSkip_eeg, 'Enable', 'off');
    set(handles.maxTranslation, 'Enable', 'off');
    set(handles.maxRotation, 'Enable', 'off');
    set(handles.sliceTiming, 'Value', 0);
    set(handles.realign, 'Value', 0);
    set(handles.coreg, 'Value', 0);
end

% --- Executes on button press in processWithFullCoreg_part2.
function processWithFullCoreg_part2_Callback(hObject, eventdata, handles)
% hObject    handle to processWithFullCoreg_part2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of processWithFullCoreg_part2

val = get(hObject,'Value');

if val
    set(handles.smoothSize_fmri, 'Enable', 'on');
    set(handles.smoothSize_eeg, 'Enable', 'on');
    set(handles.lag_fmri, 'Enable', 'on');
    set(handles.lag_eeg, 'Enable', 'on');
    set(handles.smoothing, 'Value', 1);
    set(handles.est, 'Value', 1);
    set(handles.contrast, 'Value', 1);
else
    set(handles.smoothSize_fmri, 'Enable', 'off');
    set(handles.smoothSize_eeg, 'Enable', 'off');
    set(handles.lag_fmri, 'Enable', 'off');
    set(handles.lag_eeg, 'Enable', 'off');
    set(handles.smoothing, 'Value', 0);
    set(handles.est, 'Value', 0);
    set(handles.contrast, 'Value', 0);
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



function acquisitionOrder_Callback(hObject, eventdata, handles)
% hObject    handle to acquisitionOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of acquisitionOrder as text
%        str2double(get(hObject,'String')) returns contents of acquisitionOrder as a double


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



function lag_fmri_Callback(hObject, eventdata, handles)
% hObject    handle to lag_fmri (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lag_fmri as text
%        str2double(get(hObject,'String')) returns contents of lag_fmri as a double


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


% --- Executes during object creation, after setting all properties.
function id_CreateFcn(hObject, eventdata, handles)
% hObject    handle to id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function age_CreateFcn(hObject, eventdata, handles)
% hObject    handle to age (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function gender_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gender (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in changeParameters.
function changeParameters_Callback(hObject, eventdata, handles)
% hObject    handle to changeParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
    
    subInfo = subParameters(subInfo);
    uiwait
    load(subInfofile)
    processWithFullCoreg_OpeningFcn(hObject, eventdata, handles, subInfo)
end


% --- Executes on button press in sliceTiming.
function sliceTiming_Callback(hObject, eventdata, handles)
% hObject    handle to sliceTiming (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of sliceTiming


% --- Executes on button press in realign.
function realign_Callback(hObject, eventdata, handles)
% hObject    handle to realign (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of realign


% --- Executes on button press in coreg.
function coreg_Callback(hObject, eventdata, handles)
% hObject    handle to coreg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of coreg


% --- Executes on button press in smoothing.
function smoothing_Callback(hObject, eventdata, handles)
% hObject    handle to smoothing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of smoothing


% --- Executes on button press in est.
function est_Callback(hObject, eventdata, handles)
% hObject    handle to est (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of est


% --- Executes on button press in contrast.
function contrast_Callback(hObject, eventdata, handles)
% hObject    handle to contrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of contrast


% --- Executes during object creation, after setting all properties.
function SPGR_btn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SPGR_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in SPGR_btn.
function SPGR_btn_Callback(hObject, eventdata, handles)
% hObject    handle to SPGR_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% change the SPGR file..
%Verifying we have only one anatomy file (SPGR)
% let's prompt our user to select a file that would be the SPGR
% file
global subPath
newSPGRfile = uigetfile(fullfile(subPath, 'Analysis', 'anat', '*.nii'), 'Select anatomy file') ;

str = sprintf('SPGR file is about to change! \nAre you sure you want to do this?');
choice = questdlg(str, ...
    'Pre-processing paused', ...
    'Yes','No', 'Yes');
if isequal(choice, 'Yes')
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        subInfo.SPGR = newSPGRfile;
        str = sprintf('SPGR file was changed to: %s',  subInfo.SPGR);
        msgbox(str)
        set(handles.SPGR_btn, 'String', subInfo.SPGR);
        
        save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
    else
        str = sprintf('No subInfo file was found!');
        msgbox(str)
    end
    
    
end


% --- Executes on button press in coregApproval.
function coregApproval_Callback(hObject, eventdata, handles)
% hObject    handle to coregApproval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of coregApproval


% --- Executes on button press in create4D.
function create4D_Callback(hObject, eventdata, handles)
% hObject    handle to create4D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of create4D



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
