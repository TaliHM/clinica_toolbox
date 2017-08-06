function varargout = viewActivations(varargin)
% viewActivations MATLAB code for viewActivations.fig
%      viewActivations, by itself, creates a new viewActivations or raises the existing
%      singleton*.
%
%      H = viewActivations returns the handle to a new viewActivations or the handle to
%      the existing singleton*.
%
%      viewActivations('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in viewActivations.M with the given input arguments.
%
%      viewActivations('Property','Value',...) creates a new viewActivations or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before viewActivations_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to viewActivations_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help viewActivations

% Last Modified by GUIDE v2.5 22-Jun-2017 12:51:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @viewActivations_OpeningFcn, ...
    'gui_OutputFcn',  @viewActivations_OutputFcn, ...
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


% --- Executes just before viewActivations is made visible.
function viewActivations_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to viewActivations (see VARARGIN)
global subPath

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
    
    if isfield(subInfo, 'SPGR')
        set(handles.spgr_text, 'String', subInfo.SPGR)
    end
    
    if isfield(subInfo, 'name')
        % setting subject name nicely...
        s = strsplit(lower(subInfo.name), {'_', ' '});
        s = s(~cellfun('isempty',deblank(s)));
        s = regexprep(s,'(\<[a-z])','${upper($1)}');
        s = strjoin(s, ' ');
        
        set(handles.subName, 'String', s)
    end
    
    analysisPath = fullfile(subPath, 'Analysis');
    eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
    
    % setting the fMRI scanning sessions..
    if isfield(subInfo, 'fMRIsession')
        fields = subInfo.fMRIsession;
        fieldnameToAccess = fieldnames(fields);
        
        fld = {};
        
        for i = 1:size(fieldnameToAccess,1)
            fieldname = fieldnameToAccess{i};
            fld{end+1,1} = subInfo.fMRIsession.(fieldname).seriesDescription;
        end
        
        f = strfind(lower(fld), 'eeg_fmri');
        ind = find(cellfun(@isempty,f));
        fld = fld(ind);
        
        set(handles.lagMenu, 'Visible', 'off');
        
        isEEG = ~isempty(find(~cellfun(@isempty,f), 1));
        if ~isempty(isEEG)
            % we are not using the data in the subInfo, but rather go to
            % the Analysis\EEG_lags folder.
            d = dir(eegLagsPath);
            eegfmriDirs = {d.name};
            eegfmriDirs = eegfmriDirs(3:end)';
            
            for e = 1:size(eegfmriDirs,1)
                fld{end+1,1} = eegfmriDirs{e};
            end
            
            set(handles.lagMenu, 'Visible', 'on');
        end
        
        % now let's search in the analysis folder itself for things to show analysisPath
        d = dir(analysisPath );
        isub = [d(:).isdir]; % returns logical vector
        dirs = {d(isub).name}';
        dirs = dirs(3:end);
        
        % check that we have other folders than the default ones (i.e.;
        % DTI_41, func, anat, and LI)
        dirType = regexpi(lower(dirs), '(dti20|dti_41|li|anat|func|eeg_lags|out*)+[^(_| |-)]*', 'match');
        idx = find(cellfun(@isempty,dirType));
        
        if ~isempty(idx)
            for n = 1:numel(idx)
                fld{end+1,1} = dirs{idx(n)};
            end
        end
        
        set(handles.taskMenu, 'String', fld);
        set(handles.taskMenu, 'Value', 1);
        
        % setting the fMRI scanning sessions..
        %         if isfield(subInfo, 'fMRIsession')
        %             fields = subInfo.fMRIsession;
        %             fieldnameToAccess = fieldnames(fields);
        fields = subInfo.fMRIsession;
        fieldnameToAccess = fieldnames(fields);
        nTask = get(handles.taskMenu, 'Value');
        taskList = get(handles.taskMenu, 'string');
        taskName = taskList{nTask};
        % find the corresponding field in subInfo
        for k = 1:size(fieldnameToAccess)
            if isequal( taskName, fields.(fieldnameToAccess{k}).seriesDescription)
                break
            end
        end
        
        if isequal( taskName, fields.(fieldnameToAccess{k}).seriesDescription)
            seriesNumber= fields.(fieldnameToAccess{k}).seriesNumber;
            seriesDescription = fields.(fieldnameToAccess{k}).seriesDescription;
            fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
            
            fieldname = strrep(lower(fullSeriesName), '(', '_');
            fieldname = strrep(fieldname, ')', '');
            set(handles.lagMenu, 'Visible', 'off');
        end
        
        
        % going over each field extracting existing contrasts
        % excluding rest sessions (this session only underwent
        % smoothing)
        if isempty(strfind(fieldname, 'rest'))
            if isfield(subInfo.fMRIsession, fieldname)
                if isfield(subInfo.fMRIsession.(fieldname), 'prtFile')
                    fullContrastList = {'Positive_Effect'; 'Negative_Effect'};
                    if isfield(subInfo.fMRIsession.(fieldname), 'contrasts')
                        contrasts = subInfo.fMRIsession.(fieldname).contrasts;
                        fullContrastList(end+1 : end+size(contrasts,1) , 1) = contrasts(:,1);
                    end
                else
                    fullContrastList = {'Sorry, no contrasts in here!'};
                end
            end
        elseif ~isempty(isEEG)
            fullContrastList = {};
            
            % going to the sub directory and extracting the
            % contrasts (spmT files)
            contrasts = [];
            
            lagDirs = dir(fullfile(eegLagsPath, fieldname));
            lagDirs = {lagDirs.name};
            lagDirs = lagDirs(3:end)';
            
            set(handles.lagMenu, 'String', lagDirs);
            
            curLag = lagDirs{1};
            spmFiles = dir(fullfile(eegLagsPath, fieldname, curLag, 'spmT_files'));
            spmFiles = {spmFiles.name};
            spmFiles = spmFiles(3:end);
            
            for sfile = 1:size(spmFiles, 2)
                curSpmFile = spmFiles{sfile};
                %                         sf = regexp(spmFiles{sfile},'[^spmT_\d*]\w+[^.nii]', 'match');
                %                         curSpmFile = regexp(char(sf), '[^(?<=Se_\d)]\w*[^(*rep)]', 'match');
                nSpm = regexp(spmFiles{sfile},'spmT_\d*', 'match');
                sf = strrep(curSpmFile, [char(nSpm) '_'], '');
                sf = strrep(sf, '.nii', '');
                %                         contrasts{end+1} = [curLag '_'  char(nSpm) '_' char(curSpmFile)];
                contrasts{end+1} = sf;
            end
            
            fullContrastList = contrasts';
            
        else % if its a rest session
            % setting up the path to the results folder
            seriesNumber = fields.(fieldname).seriesNumber;
            seriesDescription = fields.(fieldname).seriesDescription;
            fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
            
            analysisPath = fullfile( subPath, 'Analysis' );
            funcPath = fullfile( analysisPath, 'func' );
            spmTpath = fullfile(funcPath, fullSeriesName, 'spmT_files');
            
            if ~exist(spmTpath, 'dir')
                spmTpath = fullfile(funcPath, fullSeriesName, 'Results');
            end
            
            allFiles = dir(fullfile(spmTpath, '*.nii'));
            fileNames = {allFiles.name}';
            
            fullContrastList = regexprep(fileNames, 'spmT_\d+_', '');
        end
        
        set(handles.contrastList, 'String', fullContrastList);
        set(handles.contrastList, 'Value', 1);
    else
        errordlg('There are no fields in subInfo.fMRIsession')
    end
end

% Choose default command line output for viewActivations
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes viewActivations wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = viewActivations_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in contrastList.
function contrastList_Callback(hObject, eventdata, handles)
% hObject    handle to contrastList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns contrastList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from contrastList


% --- Executes during object creation, after setting all properties.
function contrastList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contrastList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in taskMenu.
function taskMenu_Callback(hObject, eventdata, handles)
% hObject    handle to taskMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns taskMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from taskMenu
global subPath
% [p subName e] = fileparts(subPath);
% set(handles.subName, 'String', subName)


fullContrastList = {'Sorry, no contrasts in here!'};
if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
    
    % setting the fMRI scanning sessions..
    if isfield(subInfo, 'fMRIsession')
        fields = subInfo.fMRIsession;
        fieldnameToAccess = fieldnames(fields);
        nTask = get(handles.taskMenu, 'Value');
        taskList = get(handles.taskMenu, 'string');
        taskName = taskList{nTask};
        
        if nTask > size(fieldnameToAccess, 1)
            fieldname = '';
            % probably it's in the analysis folder
            taskNames = get(handles.taskMenu, 'String');
            curTask = taskNames{nTask};
            
            switch curTask
                case 'objLoc_across_3sessions'
                    n = strfind(fieldnameToAccess, 'objloc');
                    
                    in = find(~cellfun(@isempty,n));
                    
                    if ~isempty(in)
                        nTask = in(1);
                    end
            end
        else
            
            % find the corresponding field in subInfo
            for k = 1:size(fieldnameToAccess)
                if isequal( taskName, fields.(fieldnameToAccess{k}).seriesDescription)
                    break
                end
            end
            
            if isequal( taskName, fields.(fieldnameToAccess{k}).seriesDescription)
                seriesNumber= fields.(fieldnameToAccess{k}).seriesNumber;
                seriesDescription = fields.(fieldnameToAccess{k}).seriesDescription;
                fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
                
                fieldname = strrep(lower(fullSeriesName), '(', '_');
                fieldname = strrep(fieldname, ')', '');
                set(handles.lagMenu, 'Visible', 'off');
            end
        end
        
        isEEG = regexp(lower(taskName), 'eeg_fmri', 'match');
        
        if ~isempty(isEEG)
            set(handles.lagMenu, 'Visible', 'on');
            fieldname = taskName;
            
            analysisPath = fullfile(subPath, 'Analysis');
            eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
            
            % % % %             taskNames = get(handles.taskMenu, 'String');
            % % % %             nTask = get(handles.taskMenu, 'Value');
            % % % %
            lagNames =  get(handles.lagMenu, 'String');
            
            if strcmp(lagNames, 'Select Lag')
                lagDirs = dir(fullfile(eegLagsPath, fieldname));
                lagDirs = {lagDirs.name};
                lagDirs = lagDirs(3:end)';
                set(handles.lagMenu, 'String', lagDirs);
                lagNames = lagDirs;
            end
            fullContrastList = {};
            
            % going to the sub directory and extracting the
            % contrasts (spmT files)
            contrasts = [];
            
            nLag = get(handles.lagMenu, 'Value');
            curLag = lagNames{nLag};
            
            spmFiles = dir(fullfile(eegLagsPath, fieldname, curLag, 'spmT_files'));
            spmFiles = {spmFiles.name};
            spmFiles = spmFiles(3:end);
            
            for sfile = 1:size(spmFiles, 2)
                curSpmFile = spmFiles{sfile};
                nSpm = regexp(spmFiles{sfile},'spmT_\d*', 'match');
                sf = strrep(curSpmFile, [char(nSpm) '_'], '');
                sf = strrep(sf, '.nii', '');
                contrasts{end+1} = sf;
            end
            
            fullContrastList = contrasts';
            
        elseif isempty(strfind(fieldname, 'rest'))
            if isfield(subInfo.fMRIsession, fieldname)
                if isfield(subInfo.fMRIsession.(fieldname), 'prtFile')
                    fullContrastList = {'Positive_Effect'; 'Negative_Effect'};
                    if isfield(subInfo.fMRIsession.(fieldname), 'contrasts')
                        contrasts = subInfo.fMRIsession.(fieldname).contrasts;
                        fullContrastList(end+1 : end+size(contrasts,1) , 1) = contrasts(:,1);
                    end
                else
                    fullContrastList = {'Sorry, no contrasts in here!'};
                end
            end
            
            %             set(handles.mricron_btn, 'Value', 0)
            %             set(handles.xjView_btn, 'Value', 1)
            
        else % if its a rest session
            % setting up the path to the results folder
            seriesNumber = fields.(fieldname).seriesNumber;
            seriesDescription = fields.(fieldname).seriesDescription;
            fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
            
            analysisPath = fullfile( subPath, 'Analysis' );
            funcPath = fullfile( analysisPath, 'func' );
            spmTpath = fullfile(funcPath, fullSeriesName, 'spmT_files');
            
            if ~exist(spmTpath, 'dir')
                spmTpath = fullfile(funcPath, fullSeriesName, 'Results');
            end
            
            allFiles = dir(fullfile(spmTpath, '*.nii'));
            fileNames = {allFiles.name}';
            
            if ~isempty(fileNames)
                fullContrastList = regexprep(fileNames, 'spmT_\d+_', '');
            end
            
            %             set(handles.mricron_btn, 'Value', 1)
            %             set(handles.xjView_btn, 'Value', 0)
        end
        
        if isempty(isEEG)
            % setting up the path to the results folder
            seriesNumber = fields.(fieldname).seriesNumber;
            seriesDescription = fields.(fieldname).seriesDescription;
            fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
            
            analysisPath = fullfile( subPath, 'Analysis' );
            funcPath = fullfile( analysisPath, 'func' );
            spmTpath = fullfile(funcPath, fullSeriesName, 'spmT_files');
            
            if ~exist(spmTpath, 'dir')
                spmTpath = fullfile(funcPath, fullSeriesName, 'Results');
            end
            
            allFiles = dir(fullfile(spmTpath, '*.nii'));
            fileNames = {allFiles.name}';
            
            if ~isempty(fileNames)
                fullContrastList = regexprep(fileNames, 'spmT_\d+_', '');
            end
        end
        set(handles.contrastList, 'String', fullContrastList);
        set(handles.contrastList, 'Value', 1);
    else
        errordlg('These is no fMRI session field in subInfo!')
    end
end


% --- Executes during object creation, after setting all properties.
function taskMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to taskMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in viewActivation_btn.
function viewActivation_btn_Callback(hObject, eventdata, handles)
% hObject    handle to viewActivation_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subPath

% [p subName e] = fileparts(subPath);
% set(handles.subName, 'String', subName)

if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
end

analysisPath = fullfile( subPath, 'Analysis' );

% setting up the path to the results folder
fields = subInfo.fMRIsession;
fieldnameToAccess = fieldnames(fields);
nTask = get(handles.taskMenu, 'Value');
taskList = get(handles.taskMenu, 'string');
taskName = taskList{nTask};

% find the corresponding field in subInfo
for k = 1:size(fieldnameToAccess)
    if isequal( taskName, fields.(fieldnameToAccess{k}).seriesDescription)
        break
    end
end

if isequal( taskName, fields.(fieldnameToAccess{k}).seriesDescription)
    seriesNumber= fields.(fieldnameToAccess{k}).seriesNumber;
    seriesDescription = fields.(fieldnameToAccess{k}).seriesDescription;
    fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
    
    fieldname = strrep(lower(fullSeriesName), '(', '_');
    fieldname = strrep(fieldname, ')', '');
else
    fieldname = taskName;
end

isEEG = regexp(lower(fieldname), 'eeg_fmri', 'match');
if ~isempty(isEEG)
    
    eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
    
    taskNames = get(handles.taskMenu, 'String');
    nTask = get(handles.taskMenu, 'Value');
    fieldname = taskNames{nTask};
    lagNames =  get(handles.lagMenu, 'String');
    
    if strcmp(lagNames, 'Select Lag')
        lagDirs = dir(fullfile(eegLagsPath, fieldname));
        lagDirs = {lagDirs.name};
        lagDirs = lagDirs(3:end)';
        set(handles.lagMenu, 'String', lagDirs);
        lagNames = lagDirs;
    end
    
    nLag = get(handles.lagMenu, 'Value');
    curLag = lagNames{nLag};
    
    spmTpath = fullfile(eegLagsPath, fieldname, curLag, 'spmT_files');
    fullSeriesName = fieldname;
else
    
    if nTask > size(fieldnameToAccess, 1)
        % probably it's in the analysis folder
        taskNames = get(handles.taskMenu, 'String');
        curTask = taskNames{nTask};
        
        switch curTask
            case 'objLoc_across_3sessions'
                fullSeriesName = 'objLoc_across_3sessions';
                fieldname = 'objLoc_across_3sessions';
                spmTpath = fullfile(analysisPath, fullSeriesName, 'spmT_files');
        end
    end
    
    funcPath = fullfile( analysisPath, 'func' );
    spmTpath = fullfile(funcPath, fullSeriesName, 'spmT_files');
    
    if ~exist(spmTpath, 'dir')
        spmTpath = fullfile(funcPath, fullSeriesName, 'Results');
    end
    
    if ~exist(spmTpath, 'dir')
        error('Oh-uh.. no spmT folder in the current path: \n%s \nWas the processWithFullCoreg fully finished?\n', fullfile(funcPath, fullSeriesName));
    end
    
end

% desired contrast to show
nContrast = get(handles.contrastList, 'Value');
fullContrastList = get(handles.contrastList, 'String');

% spmT file..
curContrast = strrep(fullContrastList{nContrast}, ' ', '_');
curContrast = strrep(curContrast, '.nii', '');

if ~isempty(isEEG)
    % find the file in the folder
    allFiles = dir(spmTpath);
    allFiles([allFiles.isdir]) = [];
    files = {allFiles.name};
    
    contInd = strfind(files, curContrast);
    
    if ~isempty(contInd)
        idx = find(~cellfun(@isempty,contInd));
        
        if size(idx, 2) > 1
            for index = 1:size(idx,2)
                curI = idx(index);
                contInd = strfind(files(curI), [curContrast '.nii']);
                idx = find(~cellfun(@isempty,contInd));
                
                if ~isempty(idx)
                    idx = curI;
                    break;
                end
            end
        end
        
        spmTfile = fullfile(spmTpath, files{idx});
        
        detailsStr{1} = [subInfo.name];
        detailsStr{end+1} =  ['Series Name: ' fullSeriesName];
        detailsStr{end+1} = ['Contrast: ' curContrast ];
        detailsStr{end+1} =  ['spmT file: ' files{idx}];
        detailsStr{end+1} = curLag;
        
    end
else
    
    % go to the spmTfiles folder and search for the file.
    % find the index of a file \ folder
    allFiles = dir(spmTpath);
    allNames = {allFiles.name};
    contInd = strfind(allNames, curContrast);
    
    ind = find(~cellfun(@isempty,contInd));
    if ~isempty(ind)
        if (size(ind, 2) == 1)
            spmTfile = fullfile(spmTpath, allNames{ind});
        else
            
            names = allNames(ind)';
            
            for p = 1:size(names, 1)
                n = regexp(names{p},'[^spmT_\d*]\w*[^.nii]', 'match');
                
                contInd = strfind(n, curContrast);
                
                if ~isempty(contInd)
                    spmTfile = fullfile(spmTpath, names{p});
                    break
                end
            end
        end
    end
    
    
    % maybe its without the _?
    if ~exist(spmTfile, 'file')
        curContrast = strrep(curContrast, '_', ' ');
        contInd = strfind(allNames, curContrast);
        
        ind = find(~cellfun(@isempty,contInd));
        spmTfile = fullfile(spmTpath, allNames{ind});
    end
    
    if ~exist(spmTfile, 'file')
        spmTfile = fullfile(spmTpath, [curContrast '.nii']);
    end
    
    if ~isempty(strfind(fieldname, 'rest'))
        if strfind(lower(curContrast), 'positive_effect')
            nContrast = 1;
        elseif strfind(lower(curContrast), 'negative_effect')
            nContrast = 2;
        end
        spmTfile = fullfile(spmTpath, ['spmT_' num2str( nContrast, '%0.4d' ) '_' curContrast '.nii']);
        if ~exist(spmTfile, 'file')
            spmTfile = fullfile(spmTpath, [curContrast '.nii']);
        end
        
    end
    
    detailsStr{1} = [subInfo.name];
    detailsStr{end+1} =  ['Series Name: ' fullSeriesName];
    detailsStr{end+1} = ['Contrast: ' curContrast ];
    detailsStr{end+1} =  ['spmT file: ' allNames{ind}];
end

% uplodaing the relevant anatomy file..
if ~isempty(strfind(fieldname, 'objLoc'))
    anatomyfile = 'M:\clinica\Tali_HM\Scripts\Templates\SPGR_Template.nii';
else
    anatomyfile = fullfile(analysisPath, 'anat', subInfo.SPGR);
end

disp('initializing xjview with the following parameters:')
% fprintf('Subject folder: %s\n', subPath);
fprintf('Anatomy file: %s\n', anatomyfile);
fprintf('spmT file: %s\n\n', spmTfile);

% openWithMricron = get(handles.mricron_btn, 'Value');
% openWithXjview = get(handles.xjView_btn, 'Value');

% if openWithMricron
%     cmdFile = fullfile(resultsPath, ['spmT_' num2str( nContrast, '%0.4d' ) '_' curContrast '.bat']);
%     if exist(cmdFile, 'file')
%         system(['"' cmdFile '"']);
%     else
%         str = sprintf('Could not find %s!\n', cmdFile);
%         errordlg(str);
%     end
% elseif openWithXjview
% xjViewActivations(subInfo, fullSeriesName, spmTfile, anatomyfile, detailsStr)
% end


xjViewActivations(subInfo, fullSeriesName, spmTfile, anatomyfile, detailsStr)


% --- Executes during object creation, after setting all properties.
function viewActivation_btn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to viewActivation_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in xjView_btn.
function xjView_btn_Callback(hObject, eventdata, handles)
% hObject    handle to xjView_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of xjView_btn

thisRadio = get(hObject, 'Value');
if thisRadio
    set(handles.mricron_btn, 'Value', 0)
end

% --- Executes on button press in mricron_btn.
function mricron_btn_Callback(hObject, eventdata, handles)
% hObject    handle to mricron_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mricron_btn
thisRadio = get(hObject, 'Value');
if thisRadio
    set(handles.xjView_btn, 'Value', 0)
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
newSubPath = uigetdir(rawDataPath,'Select subject''s folder for viewing activations');

if ischar(newSubPath)
    subPath = newSubPath;
    cd(subPath);
    
    if exist(fullfile(subPath, 'subInfo.mat'), 'file')
        subInfofile = fullfile(subPath, 'subInfo.mat');
        load(subInfofile)
        
        viewActivations_OpeningFcn(hObject, eventdata, handles, subInfo)
    end
end


% --- Executes on selection change in lagMenu.
function lagMenu_Callback(hObject, eventdata, handles)
% hObject    handle to lagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lagMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lagMenu

global subPath

analysisPath = fullfile(subPath, 'Analysis');
eegLagsPath = fullfile(analysisPath, 'EEG_Lags');

taskNames = get(handles.taskMenu, 'String');
nTask = get(handles.taskMenu, 'Value');
fieldname = taskNames{nTask};
lagNames =  get(handles.lagMenu, 'String');
nLag = get(handles.lagMenu, 'Value');
curLag = lagNames{nLag};

fullContrastList = {};

% going to the sub directory and extracting the
% contrasts (spmT files)
contrasts = [];

spmFiles = dir(fullfile(eegLagsPath, fieldname, curLag, 'spmT_files'));
spmFiles = {spmFiles.name};
spmFiles = spmFiles(3:end);

for sfile = 1:size(spmFiles, 2)
    curSpmFile = spmFiles{sfile};
    nSpm = regexp(spmFiles{sfile},'spmT_\d*', 'match');
    sf = strrep(curSpmFile, [char(nSpm) '_'], '');
    sf = strrep(sf, '.nii', '');
    contrasts{end+1} = sf;
end

fullContrastList = contrasts';

set(handles.contrastList, 'String', fullContrastList);
set(handles.contrastList, 'Value', 1);



% --- Executes during object creation, after setting all properties.
function lagMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lagMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
