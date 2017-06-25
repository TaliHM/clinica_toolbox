function varargout = processRest(varargin)
%PROCESSREST M-file for processRest.fig
%      PROCESSREST, by itself, creates a new PROCESSREST or raises the existing
%      singleton*.
%
%      H = PROCESSREST returns the handle to a new PROCESSREST or the handle to
%      the existing singleton*.
%
%      PROCESSREST('Property','Value',...) creates a new PROCESSREST using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to processRest_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      PROCESSREST('CALLBACK') and PROCESSREST('CALLBACK',hObject,...) call the
%      local function named CALLBACK in PROCESSREST.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help processRest

% Last Modified by GUIDE v2.5 06-Apr-2016 10:23:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @processRest_OpeningFcn, ...
    'gui_OutputFcn',  @processRest_OutputFcn, ...
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


% --- Executes just before processRest is made visible.
function processRest_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for processRest
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
    
    % setting subject name nicely...
    s = strsplit(lower(subInfo.name), {'_', ' '});
    s = s(~cellfun('isempty',deblank(s)));
    s = regexprep(s,'(\<[a-z])','${upper($1)}');
    s = strjoin(s, ' ');
    
    set(handles.subName, 'String', s)
    
    % now setting the SPGR_text - which shows the current spgr file that we are
    % using for coregistration
    %anatomyfile = regexp(subInfo.SPGR, '\w*[^.nii]', 'match');
    str = sprintf('%s', subInfo.SPGR);
    set(handles.SPGR_text, 'String', str);
    
    if isfield(subInfo, 'id'), set(handles.id, 'String', subInfo.id); end
    if isfield(subInfo, 'age'), set(handles.age, 'String', subInfo.age); end
    if isfield(subInfo, 'gender'), set(handles.gender, 'String', subInfo.gender); end
    if isfield(subInfo, 'tumorType'), set(handles.tumorType, 'String', subInfo.tumorType); end
    
    % let's update this figure with the subject's default parameters
    if ~isfield(subInfo, 'parameters'),
        subInfo = setDefaultParameters(subInfo);
    end
    
    if isfield(subInfo.parameters, 'cutoff'), set(handles.cutoff, 'String', sprintf('%.2f  -  %.2f', subInfo.parameters.cutoff)); end
    if isfield(subInfo.parameters, 'roiRadius'), set(handles.roiRadius, 'String', subInfo.parameters.roiRadius); end
    
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
    
    
    % and checking if there is an roi table, if there is - let's show it
    if isfield(subInfo, 'fMRIsession')
        fields = subInfo.fMRIsession;
        fld = fieldnames(fields);
        % we analyze according to the scan type (either fMRI, DTI, mprage or flair)
        f = regexpi(fld, '(rest)+[^(_| )]*', 'match');
        loc = find(~cellfun(@isempty, f));
        
        % if it is an fMRI series we need to do some additional
        % things before convering to nifti files..
        if ~isempty(loc)
            restSession = fld{loc};
            if isfield(subInfo.fMRIsession.(restSession), 'roiTable')
                roiTable = subInfo.fMRIsession.(restSession).roiTable;
                emptyRows = roiTable(:,2:end);
                roiTable( all(cellfun(@isempty,emptyRows),2), : ) = [];
                
                % adding one line in case we want to add another roi
                roiTable{end+1, 1} = 0;
                roiTable{end, 2} = '';
                roiTable{end, 3} = '';
                roiTable{end, 4} = 0;
                roiTable{end, 5} = 0;
                
                set(handles.roiTable, 'Data', roiTable)
            end
        end
    end
end
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes processRest wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = processRest_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath

if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
    
    % first we need to check that we have the white matter (WM) and CSF
    % coordinates..
    % let's check that the coordinates are correct ( 3 coordinates,
    % seperated by a comma or space
    wmCenter = get(handles.wmCenter, 'String');
    wm_coords = strsplit(wmCenter, {'[', ',', ' ', ']'});
    wm_coords = wm_coords(~cellfun('isempty',deblank(wm_coords)));
    
    csfCenter = get(handles.csfCenter, 'String');
    csf_coords = strsplit(csfCenter, {'[', ',', ' ', ']'});
    csf_coords = csf_coords(~cellfun('isempty',deblank(csf_coords)));
    
    if (size(wm_coords,2) ~= 3) || (size(csf_coords,2) ~= 3)
        errordlg('Sorry, but the white matter \ CSF coordinates are wrong..')
    end
    
    % if they exist we save them in the rest field in
    % subInfo.fMRIsession (for future upload of the subject)
    % let's see if fMRIsession field exist - and if it does we'll find
    % our rest session
    
    if isfield(subInfo, 'fMRIsession')
        fields = subInfo.fMRIsession;
        fld = fieldnames(fields);
        % we analyze according to the scan type (either fMRI, DTI, mprage or flair)
        f = regexpi(fld, '(rest)+[^(_| )]*', 'match');
        loc = find(~cellfun(@isempty, f));
        
        % if it is an fMRI series we need to do some additional
        % things before convering to nifti files..
        if ~isempty(loc)
            restSession = fld{loc};
        else
            errordlg('No rest session in subInfo.fMRIsession field!')
        end
        
        % updating subInfo file
        subInfo.parameters.wmCenter = str2double(wm_coords);
        subInfo.parameters.csfCenter = str2double(csf_coords);
        
        % we also want to save the roi table the user created.
        roiTable = get(handles.roiTable, 'Data');
        emptyRows = roiTable(:,2:3);
        roiTable( all(cellfun(@isempty,emptyRows),2), : ) = [];
        
        subInfo.fMRIsession.(restSession).roiTable = roiTable;
        
        save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
        
        % than we get a list of our ROIs to process and do them one by one.
        [subInfo, status_flag] = processRestClinic(subInfo, roiTable);
        
    else
        errordlg('No subInfo.fMRIsession field!')
    end
    
    close;
end



% --- Executes on button press in browse_btn.
function browse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to browse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fprintf('\n');
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
        
        processRest_OpeningFcn(hObject, eventdata, handles, subInfo)
        
    else
        processRest_OpeningFcn(hObject, eventdata, handles, subPath)
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
    
    wm = strsplit(get(handles.wmCenter, 'String'), {'[', ',', ' ', ']'});
    wm = wm(~cellfun('isempty',deblank(wm)));
    
    if ~isempty([wm{:}])
        subInfo.parameters.wmCenter = [str2double(wm{1}), str2double(wm{2}), str2double(wm{3})];
    end
    
    csf = strsplit(get(handles.csfCenter, 'String'), {'[', ',', ' ', ']'});
    csf = csf(~cellfun('isempty',deblank(csf)));
    
    if ~isempty([csf{:}])
        subInfo.parameters.csfCenter = [str2double(csf{1}), str2double(csf{2}), str2double(csf{3})];
    end
    
    save( fullfile(subPath, 'subInfo.mat'), 'subInfo')
    
    subInfo = subParameters(subInfo);
    uiwait
    load(subInfofile)
    processRest_OpeningFcn(hObject, eventdata, handles, subInfo)
end


% --- Executes on button press in filter.
function filter_Callback(hObject, eventdata, handles)
% hObject    handle to filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of filter


% --- Executes on button press in est.
function est_Callback(hObject, eventdata, handles)
% hObject    handle to est (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of est


function cutoff_Callback(hObject, eventdata, handles)
% hObject    handle to cutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cutoff as text
%        str2double(get(hObject,'String')) returns contents of cutoff as a double


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


function roiRadius_Callback(hObject, eventdata, handles)
% hObject    handle to roiRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of roiRadius as text
%        str2double(get(hObject,'String')) returns contents of roiRadius as a double


% --- Executes during object creation, after setting all properties.
function roiRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roiRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when entered data in editable cell(s) in roiTable.
function roiTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to roiTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
roiTable = get(handles.roiTable, 'Data');
row = eventdata.Indices(1);
col = eventdata.Indices(2);

if (col == 2) || (col == 3)
    if ~isempty(deblank(roiTable{row,2})) && ~isempty(deblank(roiTable{row,3}))
        
        % let's check that the coordinates are correct ( 3 coordinates,
        % seperated by a comma
        coords = strsplit(roiTable{row, 3}, {'[', ',', ' ', ']'});
        coords = coords(~cellfun('isempty',deblank(coords)));
        
        if (size(coords,2) == 3)
            roiTable{row, 1} = true; % do rest process
            roiTable{row, 4} = true; % apply filtering
            roiTable{row, 5} = true; % apply estimation
            roiTable{row, 3} = sprintf('          [%s   %s   %s]', coords{:});
            % roiTable{row, 3} = sprintf('[%s   %s   %s]', coords{:});
            
            % if we are standing on the last row - let's add one in case we want to
            % insert some more
            if (row == size(roiTable,1))
                % adding one line in case we want to add another roi
                roiTable{end+1, 1} = 0;
                roiTable{end, 2} = '';
                roiTable{end, 3} = '';
                roiTable{end, 4} = 0;
                roiTable{end, 5} = 0;
            end
        end
        
    elseif isempty(deblank(roiTable{row,2})) && isempty(deblank(roiTable{row,3}))
        roiTable{row, 1} = false; % do not do rest process
        roiTable{row, 4} = false; % do not apply filtering
        roiTable{row, 5} = false; % do not apply estimation
    end
end

if (col == 1)
    val = double(roiTable{row, col});
    if (val == 1)
        
        %         % if we are standing on the last row - let's add one in case we want to
        %         % insert some more
        %         if (row == size(roiTable,1))
        %             % adding one line in case we want to add another roi
        %             roiTable{end+1, 1} = 0;
        %             roiTable{end, 2} = '';
        %             roiTable{end, 3} = '';
        %             roiTable{end, 4} = 0;
        %             roiTable{end, 5} = 0;
        %         end
        
        roiTable{row, 1} = true; % do not do rest process
        roiTable{row, 4} = true; % do not apply filtering
        roiTable{row, 5} = true; % do not apply estimation
    else
        roiTable{row, 1} = false; % do not do rest process
        roiTable{row, 4} = false; % do not apply filtering
        roiTable{row, 5} = false; % do not apply estimation
        
    end
end

set(handles.roiTable, 'Data', roiTable);

% --- Executes when selected cell(s) is changed in roiTable.
function roiTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to roiTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)



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
