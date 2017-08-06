function xjview8Clinic_spm12_timeCoursePlot(hObject)

global DELAY;
handles = guidata( hObject ); % retrieve GUI data

try
    axes( handles.TimeCourseFigure );
catch
    handles.TimeCourseFigure = axes('Parent',gcf,'units','normalized','Position',[0.51, 0.025, 0.47, 0.340],'Visible','on');
    guidata( hObject, handles );
    UserData.hReg = [];
    set( handles.TimeCourseFigure, 'UserData', UserData );
    spm_XYZreg( 'XReg', handles.hReg, handles.TimeCourseFigure, @TimeCourseCoordUpdate );
end

% f = figure;
% axes('units','normalized','Visible','on', 'Position',[0.0690978886756238 0.11 0.869481765834932 0.741648351648352]);

subPath = handles.rootFolder;
if exist(fullfile(subPath, 'subInfo.mat'), 'file')
    subInfofile = fullfile(subPath, 'subInfo.mat');
    load(subInfofile)
    subInit = createSubInitials(subInfo);
else
    [p subName.name e] = fileparts(subPath)
    subInit = createSubInitials(subName);
end

analysisPath = fullfile( subPath, 'Analysis' );
anatomyPath = fullfile( analysisPath, 'anat' );
funcPath = fullfile( analysisPath, 'func' );

condColors = { 'CornflowerBlue', 'LightGreen', 'Amethyst', 'SandyBrown',...
    'Coral', 'LightPink', 'DarkGray', 'Plum'  };


%%%% Loading paradigm file, 4D file and condition names and durations %%%%
%
seriesName = strrep(handles.subDetails{2}, 'Series Name: ', '');
if isempty(seriesName)
    seriesName = char(regexp(handles.imageFileName{1}, 'Se\w*(\d*rep[)]', 'match'));
end

fieldname = strsplit(lower(seriesName), {'_', ' ', '-', '(', ')', '|'});
fieldname = fieldname(~cellfun('isempty',deblank(fieldname)));
fieldname = lower(strjoin(fieldname, '_'));

fprintf('\n\nTime Course\n');
fprintf('-------------------------------\n');
fprintf('%s_%s\n', subInit, seriesName);
fprintf('-------------------------------\n');

if exist('subInfo', 'var')
    % let's find the current series in the subInfo structure
    fields = subInfo.fMRIsession;
    fieldnameToAccess = fieldnames(fields);
    %let's extract the paradigm (conditions onsets and duration) and
    %condition names
    fprintf('loading paradigm information..\n');
    if isfield(fields, fieldname)
        if isfield( subInfo.fMRIsession.(fieldname), 'condOnsets') && ...
                isfield( subInfo.fMRIsession.(fieldname), 'condDurations')
            handles.paradigm.condOnsets = subInfo.fMRIsession.(fieldname).condOnsets;
            handles.paradigm.condDurations = subInfo.fMRIsession.(fieldname).condDurations;
        else
            warning( [ 'Can''t find fields condOnsets and condDurations in structure: subInfo.fMRIsession.' fieldname ] );
            set( handles.infoTextBox, 'string', [ 'Can''t find fields condOnsets and condDurations in structure: subInfo.fMRIsession.' fieldname ] );
            handles.paradigm = '';
        end
        guidata( hObject, handles ); % Store GUI data
        
        % loading condition names..
        fprintf('loading condition names..\n');
        if isfield( subInfo.fMRIsession.(fieldname), 'condNames')
            handles.condNames = subInfo.fMRIsession.(fieldname).condNames;
        else
            warning( [ 'Can''t find field condNames in structure: subInfo.fMRIsession.' fieldname ] );
            set( handles.infoTextBox, 'string', [ 'Can''t find field condNames in structure: subInfo.fMRIsession.' fieldname ] );
            handles.condNames = '';
        end
        guidata( hObject, handles ); % Store GUI data
    end
    
else
    % there is no subInfo file - and the data is from preioues (older)
    % processing
    
    %let's extract the paradigm (conditions onsets and duration) and
    %condition names
    fprintf('loading paradigm information..\n');
    seriesDicomPath = fullfile( subPath, [subInit '_' seriesName]);
    paradigmFile =  fullfile( seriesDicomPath, 'paradigm.mat' );
    if exist( paradigmFile ,'file'),
        handles.paradigm = load( paradigmFile );
    else
        warning( [ 'Can''t find paradigm file for ploting onstes: ' seriesDicomPath]);
        set( handles.infoTextBox, 'string', [ 'Can''t find paradigm file for ploting onstes: ' seriesDicomPath]);
        handles.paradigm = '';
    end
    guidata( hObject, handles ); % Store GUI data
    
    % loading condition names..
    fprintf('loading condition names..\n');
    condNamesFile = fullfile( seriesDicomPath, 'Conds_Names.mat' );
    if exist( condNamesFile ,'file'),
        handles.condNames = load(condNamesFile );
    else
        warning( [ 'Can''t find paradigm file for ploting onstes: ' seriesDicomPath]);
        set( handles.infoTextBox, 'string', [ 'Can''t find Conds_Names file for legend: ' seriesDicomPath]);
        handles.condNames = '';
    end
    guidata( hObject, handles ); % Store GUI data
end


% Preparing data for plotting..
% Get current xHair position
xHair_mni = spm_orthviews( 'Pos' );

% convert xHair coordinate to matrix coordinate
xHair_mat = mni2cor(xHair_mni', handles.M{1});

ClusterCheck = get( handles.xClusterCheck, 'Value' );
if ClusterCheck
    % Get all Displayed voxels coordinates in mni
    curVoxel_mni = cell2mat( handles.currentDisplayMNI' );
else
    % Use only the xHair-voxel's coordinate
    curVoxel_mni = xHair_mni';
end

% convert mni coordinate to matrix coordinate
curVoxel_mat = mni2cor( curVoxel_mni, handles.M{1} );

% Return the cluster index for a point list (locations [x y x]' {in voxels}
% ([3 x m] matrix)). It characterises a point list of voxel values defined with
% their locations (L) in terms of edge, face and vertex connected
% subsets, returning a list of indices in A, such that the ith location
% belongs to cluster A(i) (using an 18 connectivity scheme).
A = spm_clusters( curVoxel_mat' );

% Get indexes of displayed voxels that are within the cluster marked by xHair
xHairIndex_mat = curVoxel_mat(:,1) == xHair_mat(1,1) & curVoxel_mat(:,2) == xHair_mat(1,2) & curVoxel_mat(:,3) == xHair_mat(1,3);
nCluster = A(xHairIndex_mat);

if isempty(nCluster)
    str = sprintf('Cluster wasn''t found. \n\nIf you want a single voxel time-course, please uncheck "Use Cluster"');
    set(handles.infoTextBox, 'string', str);
    beep;
    return;
end

ind = A == nCluster;
cluster_mat = curVoxel_mat(ind,:);
clusterSize = size(cluster_mat, 1);

fprintf('Cluster number: %d\n', nCluster)
fprintf('Cluster size: %d voxels\n', clusterSize)
% cluster_mat = unique(cluster_mat) ASK WHY UNIQUE?

% taking the same voxels in the mni (as done above in the matrix)
cluster_mni = curVoxel_mni(ind,:);

% convert mni coordinate to matrix coordinate
cluster_mat = mni2cor( cluster_mni, handles.M{1} );

% load 4D file
tic
fprintf('loading 4D information..\n');
fprintf('This may take a while..\n');
fullSeriesFuncPath = fullfile( funcPath, seriesName);

if exist(fullfile(fullSeriesFuncPath, '4D'), 'dir')
    fprintf('Doing it the new style.. (data is in %s)\n', fullfile(fullSeriesFuncPath, '4D'));
    % loading in the new way - with the ssravol files themselves
    % Reading the relevant volumes for estimation
    % searching for the files that underwent smoothing (these
    % are the files with the 'srra' prefix, e.g.: 'sravol_*.nii)
    
    fileTemplate = [subInfo.parameters.fileTemplate '_']; % e.g. 'vol_'
    volumesFormat = subInfo.parameters.volumesFormat; % 'nii' or 'img'
    
    sliceTimingPrefix = ['a' fileTemplate];
    realignPrefix = ['r' sliceTimingPrefix];
    coregPrefix = ['r' realignPrefix];
    SmoothPrefix = ['s' coregPrefix];
    
    d = dir( fullfile( fullSeriesFuncPath, [ SmoothPrefix '*.' volumesFormat ] ) );
    files = { d.name }';
    
    % making sure that the dir function does not mess with the file
    % order
    str  = sprintf('%s#', files{:});
    s = [SmoothPrefix '%d.nii#'];
    num  = sscanf(str, s);
    [dummy, index] = sort(num);
    files = files(index);
    
    timeCourseAll = zeros( clusterSize, size( files, 1 ) );
    
    % going to the relevant 3D dir and extracting the relevant slice
    d = dir( fullfile( fullSeriesFuncPath, '4D', 'slice*.nii') );
    slice_files = { d.name }';
    
    % making sure that the dir function does not mess with the file
    % order
    str  = sprintf('%s#', slice_files{:});
    s = 'slice_%d.nii#';
    num  = sscanf(str, s);
    [dummy, index] = sort(num);
    slice_files = slice_files(index);
    
    firstfile = fullfile( fullSeriesFuncPath, '4D', slice_files{1} );
    [ hdr3D, filetype, fileprefix, machine ] = load_nii_hdr( firstfile );
    
    slice_ls = unique(cluster_mat(:,3));
    n = 1;
    
    for s = 1:size(slice_ls, 1)
        ind = cluster_mat(:,3) == slice_ls(s);
        curSliceGroup = cluster_mat(ind, :);
        curSlicePath = fullfile( fullSeriesFuncPath, '4D', slice_files{slice_ls(s)});
        curSlice_img = load_nii_img( hdr3D, filetype, curSlicePath(1:end-4), machine );
        
        for ii = 1:size(curSliceGroup, 1),
            timeCourseAll( n, : ) = curSlice_img( curSliceGroup(ii,1), curSliceGroup(ii,2), : );
            n = n+ 1;
        end
    end
else
    if isempty( handles.file4D ),
        % load 4D paradigm information
        file4Dname = dir( fullfile( fullSeriesFuncPath, '4D*.nii' ) );
        if ~isempty( file4Dname ),
            handles.file4D = load_nii( fullfile( fullSeriesFuncPath, file4Dname(1).name ) );
            guidata( hObject, handles );% Store GUI data
        end
    end
    
    if ~isempty( handles.file4D ),
        % loading the old way - with 4D files...
        % Getting all the time-course values of the cluster and averaging
        timeCourseAll = zeros( clusterSize, size( handles.file4D.img, 4 ) );
        for ii = 1:clusterSize,
            timeCourseAll( ii, : ) = squeeze( handles.file4D.img( cluster_mat(ii,1), cluster_mat(ii,2), cluster_mat(ii,3), : ) );
        end
    else
        error('NO 4D files or dir!')
    end
end

toc

if ClusterCheck,
    timeCourse = mean( timeCourseAll );
else
    timeCourse = timeCourseAll;
end

%%%%%%%%%%%%%%%%%
%   PLOTTING!   %
%%%%%%%%%%%%%%%%%

hold on;
cla
curAxis = axis;
fontSize = 11;

minTCpoint = round((min(timeCourse)-10)/10)*10;
maxTCpoint =  round((max(timeCourse)+10)/10)*10;

% minTCpoint = round((min(timeCourse)-5)/10)*10;
% maxTCpoint =  round((max(timeCourse)+5)/10)*10;


set(handles.rect(1), 'BackgroundColor', rgb('Black'));
set(handles.text(1), 'String', 'Time Course', 'FontSize', fontSize, 'FontName', 'Arial', 'FontWeight', 'bold')

if ~isempty( handles.paradigm )
    for curCond = 1:size( handles.paradigm.condOnsets, 2 ),
        curColor = rgb(condColors(curCond));
        set(handles.rect(curCond+1), 'BackgroundColor', curColor);
        set(handles.text(curCond+1), 'String', handles.condNames(curCond), 'FontSize', fontSize, 'FontName', 'Arial');
        for scanPoint = 1:size( handles.paradigm.condOnsets, 1 ),
            if( handles.paradigm.condOnsets( scanPoint, curCond ) ~= 0 )
                if( handles.paradigm.condDurations( scanPoint, curCond ) == 0 ),
                    
                    curOnset = handles.paradigm.condOnsets( scanPoint, curCond )+DELAY;
                    lineColor = char(condColors( mod(curCond-1,length(condColors))+1 ));
                    
                    plot( [curOnset, curOnset], [curAxis(3), curAxis(4)], 'Color', rgb(lineColor) );
                else
                    curOnset = handles.paradigm.condOnsets( scanPoint, curCond )+DELAY;
                    curDuration = handles.paradigm.condDurations( scanPoint, curCond );
                    
                    ptch = patch([ curOnset, curOnset, curOnset + curDuration, curOnset + curDuration],...
                        [minTCpoint, maxTCpoint, maxTCpoint, minTCpoint], [0 0 0],  'FaceColor', curColor);
                end
            end
        end
    end
    
else
    title( 'Paradigm not found' );
end

plot( timeCourse, 'Color', rgb('Black'), 'LineWidth', 2, 'Marker', 'x', 'MarkerSize', 6);
maxX = size(timeCourse, 2);
maxXlim = ((maxX+2)/10)*10;

% let's set the axis so it would look nice..
fprintf('Time course range:\t[%.2f %.2f]\n', min(timeCourse), max(timeCourse));
fprintf('Ylim range:\t\t[%d %d]\n', minTCpoint, maxTCpoint);


% str = sprintf('Cluster number: %d \nCluster size: %d voxels \n\nxHair MNI: [ %.2f,  %.2f,  %.2f ] \n\nTime course range\t[ %.2f - %.2f ] \nYlim range\t[ %d - %d ] \n',...
%     nCluster, clusterSize, xHair_mni, min(timeCourse), max(timeCourse), minTCpoint, maxTCpoint);
str = sprintf('Cluster #%d \nCluster size: %d voxels \n\nxHair MNI: [ %.2f,  %.2f,  %.2f ] \n\nTime course range: [ %.2f - %.2f ] \n',...
    nCluster, clusterSize, xHair_mni, min(timeCourse), max(timeCourse));
set(handles.infoTextBox, 'string', str );
set(handles.infoTextBox, 'FontSize', 10 );


set(gca, 'FontSize',fontSize, 'FontWeight','bold');

set(gca, 'XLim', [0  maxXlim]);
set(gca,'XTick',[0:5:maxXlim]);
% set(gca,'XTickLabels',[])
% set(gca,'XTickLabels',[0:5:maxXlim]);

set(gca, 'YLim', [minTCpoint maxTCpoint]);
set(gca,'YTick',[minTCpoint:5:maxTCpoint]);
set(gca,'YTickLabels',[minTCpoint:5:maxTCpoint]);

hold off;
guidata(hObject, handles);
fprintf('Done! :)\n');

return;