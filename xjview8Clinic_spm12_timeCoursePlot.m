function xjview8Clinic_spm12_timeCoursePlot(hObject)

global DELAY;
handles = guidata( hObject ); % retrieve GUI data

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
seriesName = char(regexp(handles.imageFileName{1}, 'Se\w*(\d*rep[)]', 'match'));
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

% load 4D file
fprintf('loading 4D information..\n');
seriesFuncPath = fullfile( funcPath, seriesName);
if isempty( handles.file4D ),
    % load 4D paradigm information
    file4Dname = dir( fullfile( seriesFuncPath, '4D*.nii' ) );
    if isempty( file4Dname ),
        error( [ 'Can''t find 4D file for time-course at: ' seriesFuncPath ] );
    end
    handles.file4D = load_nii( fullfile( seriesFuncPath, file4Dname(1).name ) );
    guidata( hObject, handles );% Store GUI data
end

% Preparing data for plotting..
% Get current xHair position
xHair_mni = spm_orthviews( 'Pos' );

ClusterCheck = get( handles.xClusterCheck, 'Value' );
if ClusterCheck
    % Get all Displayed voxels coordinates in mni
    mni = cell2mat( handles.currentDisplayMNI' );
else
    % Use only the xHair-voxel's coordinate
    mni = xHair_mni';
end
% convert mni coordinate to matrix coordinate
cor = mni2cor( mni, handles.M{1} );

% Return the cluster index for a point list (locations [x y x]' {in voxels}
% ([3 x m] matrix))
A = spm_clusters( cor' );

% convert xHair coordinate to matrix coordinate
xyzcor = mni2cor(xHair_mni', handles.M{1});

% Get indexes of displayed voxels that are withing the cluster marked by xHair
pos = [];
for ii = 1:size(xyzcor,1)
    pos0 = find(cor(:,1)==xyzcor(ii,1) & cor(:,2)==xyzcor(ii,2) & cor(:,3)==xyzcor(ii,3));
    if isempty(pos0)
        continue;
    end
    pos = [pos find(A==A(pos0(1)))];
end

pos = unique(pos);
ClusterSize = length( pos );
if isempty(pos)
    set(handles.infoTextBox, 'string', 'Cluster wasn''t found. If you want a single voxel time-course, please uncheck "Use Cluster"');
    beep;
    return;
else
    set(handles.infoTextBox, 'string', [ 'Cluster size displayed in time-course is: ' num2str( ClusterSize ) ] );
    %     set(handles.infoTextBox, 'string', handles.cond_names.Condition_Names(:) );
end

tmpmni = mni(pos,:);
coordinates = mni2cor( tmpmni, handles.M{1} ); %coordinates of pixel or cluster

% Getting all the time-course values of the cluster and averaging
timeCourseAll = zeros( ClusterSize, size( handles.file4D.img, 4 ) );
for ii = 1:ClusterSize,
    timeCourseAll( ii, : ) = squeeze( handles.file4D.img( coordinates(ii,1), coordinates(ii,2), coordinates(ii,3), : ) );
end

if ClusterCheck,
    timeCourse = mean( timeCourseAll );
else
    timeCourse = timeCourseAll;
end

%%%%%%%%%%%%%%%%%
%   PLOTTING!   %
%%%%%%%%%%%%%%%%%

try
    axes( handles.TimeCourseFigure );
catch
    handles.TimeCourseFigure = axes('Parent',gcf,'units','normalized','Position',[0.51, 0.025, 0.47, 0.340],'Visible','on');
    guidata( hObject, handles );
    UserData.hReg = [];
    set( handles.TimeCourseFigure, 'UserData', UserData );
    spm_XYZreg( 'XReg', handles.hReg, handles.TimeCourseFigure, @TimeCourseCoordUpdate );
end

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
fprintf('timecourse\t[%d %d]\n', min(timeCourse), max(timeCourse));
fprintf('ylim\t\t[%d %d]\n', minTCpoint, maxTCpoint);

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