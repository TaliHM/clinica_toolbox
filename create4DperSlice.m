function create4DperSlice(subInfo, pTable, logFID, h)
% creating 4D file per slice

tic

%------------------------ Setting initial parameters %--------------------------
subPath = subInfo.path;
fileTemplate = [subInfo.parameters.fileTemplate '_']; % e.g. 'vol_'
volumesFormat = subInfo.parameters.volumesFormat; % 'nii' or 'img'
step = 10;

sliceTimingPrefix = ['a' fileTemplate];
realignPrefix = ['r' sliceTimingPrefix];
coregPrefix = ['r' realignPrefix];
SmoothPrefix = ['s' coregPrefix];
%-------------------------------------------------------------------------------

cd(subPath)

subInit = createSubInitials(subInfo);

% setting the path to the anat folder and the func folder
analysisPath = fullfile( subPath, 'Analysis' );
anatomyPath = fullfile( analysisPath, 'anat' );
funcPath = fullfile( analysisPath, 'func' );

% we take only what is marked!
logicals = cell2mat(pTable(:,1));
pTable(logicals == 0,:) = [];

%     % let's see if fMRIsession field exist - and if it does we'll go over it
%     % and coregister them one by one
fields = subInfo.fMRIsession;
fieldnameToAccess = sort(fieldnames(fields));

for i = 1:size(pTable, 1)
    % find the corresponding field in subInfo
    for k = 1:size(fieldnameToAccess)
        if str2double(pTable{i,2}) == fields.(fieldnameToAccess{k}).seriesNumber
            break
        end
    end
    
    seriesNumber= fields.(fieldnameToAccess{k}).seriesNumber;
    seriesDescription = fields.(fieldnameToAccess{k}).seriesDescription;
    fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
    
    % setting the path to the current series func folder
    fullSeriesFuncPath = fullfile(funcPath, fullSeriesName);
    
    % updating waitbar
    step = step + 10;
    curProcess = 'Generating 4D';
    str = sprintf('%s  (%d/%d sessions)\n%s..',...
        [subInit '_' fullSeriesName], i, size(pTable, 1), curProcess);
    
    if ishandle(h)
        waitbar(step/100, h, str,...
            'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
    else
        h = waitbar(step/100, str,...
            'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');
    end
    
    % Generate 4D nii file for later time-course inspection
    fprintf('Generating 4D for series %s.\n', fullSeriesName );
    
    if logFID > 0
        % update log file with start time of estimating
        t = clock;
        sTime = [ num2str( t(4), '%0.2d' ) ':' num2str( t(5), '%0.2d' ) ':' num2str( round (t(6) ), '%0.2d' ) ];
        str = sprintf('%s -  Generating 4D file..', sTime );
        disp( str );
        fprintf( logFID, '%s\n', str );
    end
    
    fieldname = strrep(lower(fullSeriesName), '(', '_');
    fieldname = strrep(fieldname, ')', '');
    
    isEEG = regexp(fieldname, 'eeg_fmri', 'match');
    if ~isempty(isEEG)
        coregPrefix = realignPrefix;
        SmoothPrefix = ['s' coregPrefix];
    end
    
    % Reading the relevant volumes for estimation
    % searching for the files that underwent smoothing (these
    % are the files with the 'srra' prefix, e.g.: 'sravol_*.nii)
    d = dir( fullfile( fullSeriesFuncPath, [ SmoothPrefix '*.' volumesFormat ] ) );
    smooth_files = { d.name }';
    
    % making sure that the dir function does not mess with the file
    % order
    str  = sprintf('%s#', smooth_files{:});
    s = [SmoothPrefix '%d.nii#'];
    num  = sscanf(str, s);
    [dummy, index] = sort(num);
    smooth_files = smooth_files(index);
    
    zDim = size(smooth_files,1);
    
    firstfile = fullfile( fullSeriesFuncPath, smooth_files{1} );
    [ hdr3D, filetype, fileprefix, machine ] = load_nii_hdr( firstfile );
    
    nii4D.hdr = hdr3D;
    nii4D.hdr.dime.dim(1) = 4;
    nii4D.hdr.dime.dim(5) = zDim;
    nii4D.img = zeros( hdr3D.dime.dim(2), hdr3D.dime.dim(3), hdr3D.dime.dim(4), zDim );
    
    for nn = 1:zDim,
        nii4D.img(:,:,:,nn) = load_nii_img( hdr3D, filetype, fullfile( fullSeriesFuncPath, smooth_files{nn}(1:end-4)), machine );
    end
    
    if ~isempty(smooth_files)
        % create a 4D folder
        if ~exist(fullfile(fullSeriesFuncPath, '4D'), 'dir')
            mkdir(fullfile(fullSeriesFuncPath, '4D'))
        end
        
        cd(fullfile(fullSeriesFuncPath, '4D'))
        
        reverseStr = '';
        for zSlice = 1:size(nii4D.img, 3)
            nii3D.hdr = hdr3D;
            nii3D.hdr.dime.dim(4) = zDim;
            nii3D.img = zeros( hdr3D.dime.dim(2), hdr3D.dime.dim(3), zDim);
            
            filename = fullfile(fullSeriesFuncPath, '4D', ['slice_' num2str(zSlice, '%.3d') '.nii']);
            nii3D.fileprefix = fullfile(fullSeriesFuncPath, '4D', ['slice_' num2str(zSlice, '%.3d')]);
            
            nii3D.img = squeeze(nii4D.img(:,:,zSlice,:));
            
            % Display the progress
            msg = sprintf('Creating slice_%.3d.nii', zSlice); %Don't forget this semicolon
            fprintf([reverseStr, msg]);
            reverseStr = repmat(sprintf('\b'), 1, length(msg));
            
            save_nii(nii3D, filename)
            clear nii3D
        end
    end
    clear nii4D
    fprintf('Done! :)\n');
    toc
end
end