function varargout = seriesRenaming_indSeries(varargin)
% seriesRenaming_indSeries MATLAB code for seriesRenaming_indSeries.fig
%      seriesRenaming_indSeries, by itself, creates a new seriesRenaming_indSeries or raises the existing
%      singleton*.
%
%      H = seriesRenaming_indSeries returns the handle to a new seriesRenaming_indSeries or the handle to
%      the existing singleton*.
%
%      seriesRenaming_indSeries('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in seriesRenaming_indSeries.M with the given input arguments.
%
%      seriesRenaming_indSeries('Property','Value',...) creates a new seriesRenaming_indSeries or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before seriesRenaming_indSeries_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to seriesRenaming_indSeries_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help seriesRenaming_indSeries

% Last Modified by GUIDE v2.5 03-May-2017 09:52:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @seriesRenaming_indSeries_OpeningFcn, ...
    'gui_OutputFcn',  @seriesRenaming_indSeries_OutputFcn, ...
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


% --- Executes just before seriesRenaming_indSeries is made visible.
function seriesRenaming_indSeries_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to seriesRenaming_indSeries (see VARARGIN)

% Choose default command line output for seriesRenaming_indSeries
handles.output = hObject;
global subPath

if length(varargin) == 1
    
    if isstruct(varargin{1})
        subInfo = varargin{1};
        %        subPath = subInfo.path;
        
    elseif iscell(varargin{1}) || ischar(varargin{1})
        subPath = varargin{1};
        if iscell(varargin{1})
            subPath = char(subPath{:});
        end
        
        if exist(fullfile(subPath, 'subInfo.mat'), 'file')
            subInfofile = fullfile(subPath, 'subInfo.mat');
            load(subInfofile)
        end
    end
    
    
    % we need to make sure that there are Series folders in the subject's
    % path
    [studyPath, seriesDir] = getRawDataPath(subPath);
    
    if ~isempty(seriesDir)
        
        % we first want to make sure that we have not already preprocessed this
        % subject, let's see if the subject has a subInfo file, if he\she does we
        % will upload it instead and tell the user we are doing it.
        % uploadSubFlag = 1;
        wholeScanSession = {};
        if exist(fullfile(subPath, 'subInfo.mat'), 'file')
            subInfofile = fullfile(subPath, 'subInfo.mat');
            load(subInfofile)
            
            %         if isfield(subInfo, 'wholeScanSession')
            %             if ~isempty(subInfo.wholeScanSession)
            %                 % if so, let's inform the user and ask if we need to override existing
            %                 % files.
            %                 str = sprintf('%s has already a subInfo file, uploading existing data..', subInfo.name);
            %                 msgbox(str)
            %                 fprintf('%s\n', str);
            %                 uiwait
            %                 wholeScanSession = subInfo.wholeScanSession(2:end,:)
            %                 set(handles.protocolTable, 'Data', wholeScanSession)
            %                 uploadSubFlag = 0;
            %             end
            %         end
            
            
        end
        
        
        if isempty(wholeScanSession)
            [subInfo, wholeScanSession] = uploadWholeScanSession(subPath);
        else
            [subInfo, wholeScanSession] = uploadWholeScanSession(subInfo);
        end
        
        if ~isempty(wholeScanSession)
            % let's show the names in the gui's table
            set(handles.protocolTable, 'Data', wholeScanSession);
            cd(subPath)
        end
        
        set(handles.subName, 'String', subInfo.name);
        set(handles.id, 'String', subInfo.id);
        set(handles.age, 'String', subInfo.age);
        set(handles.gender, 'String', subInfo.gender);
        
        fprintf('Done uploading subject''s data.\n\n');
        
    else
        errStr = sprintf('No Series folders found! \nPlease make sure the Series folders are in place');
        errordlg(errStr);
    end
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes seriesRenaming_indSeries wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = seriesRenaming_indSeries_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
global subPath

[studyPath, seriesDir] = getRawDataPath(subPath);

if isempty(seriesDir)
    close;
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


% --- Executes on selection change in protocolTable.
function protocolTable_Callback(hObject, eventdata, handles)
% hObject    handle to protocolTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns protocolTable contents as cell array
%        contents{get(hObject,'Value')} returns selected item from protocolTable


% --- Executes during object creation, after setting all properties.
function protocolTable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to protocolTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.Callba
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
newSubPath = uigetdir(rawDataPath,'Select subject for series renaming');

if ischar(newSubPath)
    subPath = newSubPath;
    uploadSubFlag = 1;
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        if isfield(subInfo, 'wholeScanSession')
            if ~isempty(subInfo.wholeScanSession)
                % if so, let's inform the user and ask if we need to override existing
                % files.
                str = sprintf('%s has already a subInfo file, uploading existing data..', subInfo.name);
                msgbox(str)
                fprintf('%s\n', str);
                uiwait
                wholeScanSession = subInfo.wholeScanSession(2:end,:);
                set(handles.protocolTable, 'Data', wholeScanSession)
                uploadSubFlag = 0;
            end
        end
        
        if uploadSubFlag
            [subInfo, wholeScanSession] = uploadWholeScanSession(subInfo);
        end
        
        if ~isempty(wholeScanSession)
            % let's show the names in the gui's table
            set(handles.protocolTable, 'Data', wholeScanSession);
            cd(subPath)
        end
        
        % and setting the gui with the subject's info..
        set(handles.subName, 'String', subInfo.name);
        set(handles.id, 'String', subInfo.id);
        set(handles.age, 'String', subInfo.age);
        set(handles.gender, 'String', subInfo.gender);
        
        fprintf('Done uploading subject''s data.\n\n');
        
    else
        seriesRenaming_indSeries_OpeningFcn(hObject, eventdata, handles, subPath)
    end
end



% --- Executes when entered data in editable cell(s) in protocolTable.
function protocolTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to protocolTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

global subPath
% opening the folder for inspection

if ~isempty(eventdata.Indices)
    row = eventdata.Indices(1);
    col = eventdata.Indices(2);
    protocolTable = get(handles.protocolTable, 'Data');
    
    % if you press on the Description cell - the folder will open in a new window.
    
    [studyPath, seriesDir] = getRawDataPath(subPath);
    
    %%%%%%%%%%%%%%%%%%
    %     studyPath = fullfile(subPath, 'Study');
    %     studyDirName = dir([studyPath '*']);
    %     studyDirName = studyDirName.name;
    %      sDir = dir(fullfile(subPath, studyDirName, 'Series*'));
    sDirNames = { seriesDir(:).name };
    
    %loc = str2num(protocolTable{row, 2});
    curPath = fullfile(studyPath, char(sDirNames(row)));
    
    if (col == 3)
        winopen(curPath)
    end
    
    if (col == 1)
        val = double(protocolTable{row, col});
        dcmSeriesName = protocolTable{row, 3};
        
        if (val == 1) || (isempty(protocolTable{row, 5}))
            
            scanType = regexpi(dcmSeriesName, 'fMRI+[^(_| )]*', 'match');
            
            if ~isempty(scanType)
                protocolPath = 'M:\protocols-new';
                protocolFile = 'ProtocolsTable.xls';
                pfile = fullfile(protocolPath, protocolFile);
                cd(protocolPath);
                if ((exist(pfile, 'file')) == 2)
                    [data, txt, protocolFile_raw] = xlsread(pfile); % basic for quicker reading
                    % [data, txt, protocolFile_raw] = xlsread(pfile, '', '', 'basic'); % basic for quicker reading
                else
                    fprintf('%s file was not found!!\n', pfile);
                end
                % let's set the (optional) series name
                % 1. removing all dots, slashes etc. from the string
                % 2. rebuilding the string with _ between words (this is the
                % format in the protocolTable.xlsx). and trying to find it in
                % the table.
                % 3. check if there is correct number of dicoms in the folder
                seriesNameTmp = strsplit(dcmSeriesName, {' ', '_', '-'}, 'CollapseDelimiters',true);
                seriesName = lower(strjoin(seriesNameTmp(:,2:end), '_'));
                seriesName = regexprep(seriesName, '\.', '');
                
                switch seriesName
                    case 'vg_aud'
                        seriesName = 'aud_vg';
                    case 'def_aud'
                        seriesName = 'aud_def';
                    case 'legs_sensory'
                        seriesName = 'sensory_both_legs';
                    case 'hand_sensory'
                        seriesName = 'sensory_both_hands';
                end
                
                s = lower(protocolFile_raw(:,6));
                seriesLoc = regexp(s, seriesName, 'match');
                [r c] = find(~cellfun(@isempty,seriesLoc));
                
                if (isempty(r))
                    seriesName = regexprep(seriesName, '_', '');
                    seriesLoc = regexp(s, seriesName, 'match');
                    [r c] = find(~cellfun(@isempty,seriesLoc));
                end
                
                pName = '';
                pNum = '';
                protocolTable{row, 5} = '';
                protocolTable{row, 6} = '';
                mismatch_flag = 1;
                
                if (length(r) == 1)
                    pName = num2str(protocolFile_raw{r, 6});
                    pNum = num2str(protocolFile_raw{r, 2});
                    mismatch_flag = 0;
                elseif (length(r) > 1)
                    
                    for j = 1:length(r)
                        pName = num2str(protocolFile_raw{r(j), 6});
                        pNum = num2str(protocolFile_raw{r(j), 2});
                        % let's check that we have the same number of fles in the
                        % current folder
                        nRep = regexp(pName, '\d[^rep)]*', 'match');
                        nRep = str2num(nRep{:});
                        
                        % if we do not have the same number of files - set alert
                        % and tell me how many files there are in the remarks column
                        nfiles = dir(curPath);
                        nfiles([nfiles.isdir]) = [];
                        if (length(nfiles) == nRep)
                            mismatch_flag = 0;
                            break
                        end
                    end
                    
                    % if we got though all the rows and did not find a match -
                    % let's state that in the remarks
                    if (mismatch_flag == 1)
                        str = sprintf('nDcm = %d; nRep = %d', length(nfiles), nRep);
                        protocolTable{row, 6} = str;
                    end
                end
                
                protocolTable{row, 4} = pName;
                protocolTable{row, 5} = pNum;
                protocolTable{row, 6} = '';
            end
        elseif (val == 0)
            protocolTable{row, 4} = '';
            protocolTable{row, 5} = '';
        end
        set(handles.protocolTable, 'Data', protocolTable)
    end
end


% --- Executes on button press in process_btn.
function process_btn_Callback(hObject, eventdata, handles)
% hObject    handle to process_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath
[p subName e] = fileparts(subPath);
protocolTable = get(handles.protocolTable, 'Data');

% let's first recheck that all fits. if something does not fit (between
% series index and the series name) - alert the user
% studyPath = fullfile(subPath, 'Study');
% studyName = dir([studyPath '*']);
[studyPath, seriesDir] = getRawDataPath(subPath);

if (~isempty(seriesDir))
    
    protocolTable = updateSeries(protocolTable);
    set(handles.protocolTable, 'Data', protocolTable);
    
    % checking for errors of repetiotion mismatch with number of dicom files in
    % the directory
    fprintf('Checking if number of dicoms match number of repetitions..\n');
    mismatchError = protocolTable(:, 6);
    emptyCells = ~cellfun(@isempty,mismatchError);
    mismatch_nErr = emptyCells(emptyCells == 1);
    
    % checking for out of index errors
    fprintf('Checking if protocol table indices are correct..\n');
    indexError = protocolTable(:, 4);
    str = 'Out of series index!';
    t = strfind(indexError, str);
    index_nErr = find(~cellfun(@isempty,t));
    
    if (isempty(mismatch_nErr) && isempty(index_nErr))
        if exist(fullfile(subPath, 'subInfo.mat'), 'file')
            subInfofile = fullfile(subPath, 'subInfo.mat');
            load(subInfofile)
            
            % if so, we need to override existing files.
            doSR_flag = 1;
            if isfield(subInfo, 'wholeScanSession')
                if ~isempty(subInfo.wholeScanSession)
                    
                    for i = 1:size(protocolTable, 1)
                        curScan = str2double(protocolTable{i, 2});
                        subInfo_scanSession = str2double(subInfo.wholeScanSession(:,2));
                        
                        % checking that the series numbers are unique (no doubles)
                        idx = find(subInfo_scanSession == curScan);
                        
                        % duplicates were found
                        if ~isempty(idx)
                            if(size(idx,1) > 1)
                                % check doubles according to series name also
                                curScanName = protocolTable{i, 3};
                                subInfo_scanSessionName = subInfo.wholeScanSession(:,3);
                                logicalArray = ~cellfun('isempty', strfind(subInfo_scanSessionName, curScanName));
                                curScanIndex = find(logicalArray == 1);
                            else
                                curScanIndex = idx;
                            end
                            
                            if (subInfo.wholeScanSession{curScanIndex,1} == 0 &&...
                                    protocolTable{i, 1} == 1)
                                fprintf('%s --> found a duplicate - overriding existing scan\n', protocolTable{i,3} );
                                subInfo.wholeScanSession(curScanIndex,:) = protocolTable(i,:);
                            end
                        else
                            fprintf('%s --> adding new scan to subInfo.wholeScanSession\n', protocolTable{i,3} )
                            newlist = [subInfo.wholeScanSession; protocolTable(i,:)]
                            newlist_data = newlist(2:end,:)
                            
                            A = newlist_data(:,2)
                            
                            C = cell(numel(A));
                            [Sorted_A, Index_A] = sort(str2double(A));
                            % C(:,1) = strtrim(cellstr(num2str(Sorted_A)));
                            C = newlist_data(Index_A,:);
                            
                            subInfo.wholeScanSession = C;
                        end
                    end
                    str = sprintf('Series renaming was already done on this subject\n Adding the new series');
                end
            end
            
            if  doSR_flag, % apply series renaming again.
                %disp('let''s do some series renaming!')
                %titles = {'' 'Session #' 'Description' 'Series name' 'Series index' 'Remarks'};
                %subInfo.wholeScanSession = deal([titles; protocolTable]);
                fprintf('Saving subInfo.m file..\n\n');
                save( subInfofile, 'subInfo')
                
                %%%%%%%%%%%%%%%%%%%%%%
                % Series Renaming!! %%
                %%%%%%%%%%%%%%%%%%%%%%
                fprintf('OK, all is good, let''s continue!\n\n');
                % creating seriesIndices array
                % first column is the series number as designated by the MRI scanner (mri_idx)
                % second column is the series number according the clinical fMRI table (pTable_idx).
                logicals = cell2mat(protocolTable(:,1));
                protocolTable(logicals == 0,:) = [];
                
                [subInfo, status_flag] = seriesRenamingClinic(subInfo, protocolTable);
                
                if (status_flag == 0) % used to be 1
                    errStr = sprintf('Failed to do series renaming on %s !! \nPlease check if the series names and indices are correct', subName);
                    errordlg(errStr);
                end
                
            end
        end
    end
else
    errStr = sprintf('Cannot process %s !! \nPlease check if the series names and indices are correct or that the Study folder exists ', subName);
    errordlg(errStr);
    uiwait
end

% before closing we want to move the unnecessary study folder (we already
% changed what we needed...
if ~exist( fullfile( subPath, 'Raw_Data' ),'dir' ), % create folder: Unused_Raw_Data
    mkdir( fullfile( subPath, 'Raw_Data' ) );
end

if (status_flag == 1)
    createRawDataFolder = get(handles.createRawDataFolder, 'Value');
    
    if createRawDataFolder
        
        studyFolder = dir(fullfile(subPath, 'Study*'));
        if ~isempty(studyFolder)
            studyName = studyFolder.name;
            fprintf('Moving %s to Raw_Data folder\n', fullfile(subPath, studyName))
            movefile(fullfile(subPath, studyName), fullfile( subPath, 'Raw_Data' ) )
        end
        
        studyFolder = dir(fullfile(subPath, 'No_Study_Name*'));
        if ~isempty(studyFolder)
            studyName = studyFolder.name;
            fprintf('Moving %s to Raw_Data folder\n', fullfile(subPath, studyName))
            movefile(fullfile(subPath, studyName), fullfile( subPath, 'Raw_Data' ) )
        end
        
        studyFolder = dir(fullfile(subPath, 'Series*'));
        if ~isempty(studyFolder)
            fprintf('Moving %s to Raw_Data folder\n', fullfile(subPath, 'Series*'))
            movefile(fullfile(subPath, 'Series*'), fullfile( subPath, 'Raw_Data' ) )
        end
        
    else
        
        studyFolder = dir(fullfile(subPath, 'Study*'));
        if ~isempty(studyFolder)
            studyName = studyFolder.name;
            fprintf('Deleting %s\n', fullfile(subPath, studyName))
            rmdir(fullfile(subPath, studyName))
        end
        
        studyFolder = dir(fullfile(subPath, 'No_Study_Name*'));
        if ~isempty(studyFolder)
            studyName = studyFolder.name;
            fprintf('Deleting %s\n', fullfile(subPath, studyName))
            rmdir(fullfile(subPath, studyName) )
        end
        
        studyFolder = dir(fullfile(subPath, 'Series*'));
        if ~isempty(studyFolder)
            fprintf('Deleting %s\n', fullfile(subPath, 'Series*'))
            rmdir(fullfile(subPath, 'Series*'))
        end
    end
end
cd(subPath)
close;

% --- Executes when selected cell(s) is changed in protocolTable.
function protocolTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to protocolTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in update_btn.
function update_btn_Callback(hObject, eventdata, handles)
% hObject    handle to update_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if you press on the Series Index cell - it will update to the new
% protocol name according to the index.
global subPath

protocolPath = 'M:\protocols-new';
protocolFile = 'ProtocolsTable.xls';
pfile = fullfile(protocolPath, protocolFile);
cd(protocolPath);
if ((exist(pfile, 'file')) == 2)
    [data, txt, protocolFile_raw] = xlsread(pfile); % basic for quicker reading
    % [data, txt, protocolFile_raw] = xlsread(pfile, '', '', 'basic'); % basic for quicker reading
else
    fprintf('%s file was not found!!\n', pfile);
end

%opening the folder for inspection
protocolTable = get(handles.protocolTable, 'Data');
protocolTable = updateSeries(protocolTable);

set(handles.protocolTable, 'Data', protocolTable);
% Update handles structure
guidata(hObject, handles);
cd(subPath)


% --- Executes on button press in segment_btn.
function segment_btn_Callback(hObject, eventdata, handles)
% hObject    handle to segment_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of segment_btn



function tumorType_Callback(hObject, eventdata, handles)
% hObject    handle to tumorType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tumorType as text
%        str2double(get(hObject,'String')) returns contents of tumorType as a double
global subPath
tumorType = get(handles.tumorType, 'String');

if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
    subInfo.tumorType = tumorType;
    
    save( subInfofile, 'subInfo')
end

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


% --- Executes on button press in createRawDataFolder.
function createRawDataFolder_Callback(hObject, eventdata, handles)
% hObject    handle to createRawDataFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of createRawDataFolder
