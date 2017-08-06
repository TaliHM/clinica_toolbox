function [AmountAct,AmountActInd,AmountStandardInd,SumAct,SumActInd,SumStandardInd] = LIallThreshClinic(subInfo, LI_list, createOccMask, createMidSagMask, reverseOccMask, reverseMidSagMask)
%%% this functions purpose is to automatically evaluate the lateralization
%%% by merging two activations and checking when they coexist. the only
%%% parameter it needs as an input is the RelativeThresh, which is the
%%% number of voxels with the highest amplitude you want to keep before
%%% merging the activations. currently the suggested ratio is around 1/100.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% step = 1;
% str = sprintf('Applying Lateralization index processing\n');
% h = waitbar(step/100, str,...
%     'name', 'Processing', 'windowstyle', 'modal', 'DefaulttextInterpreter', 'none');

FileVersion = 'v1';  % 17.03.2016 THM
disp( [ 'Lateralization processing, version: ' FileVersion ] );

%------------------------ Setting initial parameters %--------------------------
subPath = subInfo.path;

% 1 - right; 0 = 0; THM changed it from previous versions!! (it was
% backwards, that is: USED TO BE 0 = right handed, 1= left handed)
handedness = subInfo.parameters.rightHanded;
minDist = subInfo.parameters.minDist;

occipitalDots = 'OccMask2points'; % mask file of cerebellum and occipital
midSagitalNii = 'MidSag3points'; % mask file with 4 points on the mid sagital plane
colorScheme = {'RoyalBlue'; 'ForestGreen';'FireBrick'};

% setting the path to the anat folder and the func folder
analysisPath = fullfile( subPath, 'Analysis' );
funcPath = fullfile( analysisPath, 'func' );
LIpath = fullfile(analysisPath, 'LI');

% isEEG = regexp(lower(subPath), 'eeg-fmri', 'match');
% if ~isempty(isEEG)
%     eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
% end

if ~exist(LIpath, 'dir')
    mkdir(LIpath);
end

viewerFilesPath = fullfile( subPath, 'viewer', 'files' );

% the plot will have 5 values but for researh purpose i want to save much
% more
hezkotForPlot = [5:10];
hezkotForResearch = [5:0.1:10];
thresholdsForPlot = 2.^(-hezkotForPlot);
thresholdsForResearch = 2.^(-hezkotForResearch);
mone = 0;

% finding which indices in the research are for the plot
for i = 1:length(hezkotForResearch)
    if length(find(hezkotForPlot==hezkotForResearch(i))) > 0
        mone = mone + 1;
        ThresholdForPlotInd(mone) = i;
    end;
end;

%%%%% Instert Norms From Wada Project
% LeftMeans = [0.527924811	0.658578688	0.765959954	0.877155794	0.929519784	0.979254405]; OLD
% LeftStds = [0.175549164	0.1502949	0.172357441	0.11372439	0.080238167	0.044662946];OLD
% BilateralMeans = [-0.104267718	-0.162370342	-0.174924684	-0.160657621	-0.082962146	-0.114247034];OLD
% BilateralStds = [0.189751782	0.241652407	0.384444818	0.627373135	0.823691321	0.844763614];OLD
% RightMeans = [-0.500676405	-0.523660926	-0.613822912	-0.63949892	-0.707952885	-0.805042096];OLD
% RightStds = [0.285738069	0.290283299	0.292606465	0.258332862	0.281519144	0.291951662];OLD

LeftMeans = [0.4621    0.5793    0.6896    0.8053    0.8646    0.9263];
LeftStds = [0.1906    0.1912    0.1947    0.1675    0.1698    0.1646];
BilateralMeans = [-0.1043   -0.1624   -0.1749   -0.1607   -0.0830   -0.1142];
BilateralStds = [0.1898    0.2417    0.3844    0.6274    0.8237    0.8448];
RightMeans = [-0.5172   -0.5567   -0.6512   -0.6864   -0.7511   -0.8375];
RightStds = [0.2587    0.2719    0.2772    0.2581    0.2731    0.2730];

% insert weights from logistic regression (train_logreg of MVPA toolbox)
% with penalty 0.104
weights = [
    0.4501    0.1698   -0.3678;
    0.5383   -0.1422   -0.3860;
    0.6243   -0.1560   -0.4278;
    0.7345   -0.4574   -0.3795;
    0.7624   -0.3447   -0.4836;
    0.8754   -0.2135   -0.59529]';


% insert weights from logistic regression (train_logreg of MVPA toolbox)
% with penalty 4.6
weightsRight = [
    0.7810   -0.0502   -0.6175
    1.0616   -0.6126   -0.6849
    1.1010   -0.6565   -0.7449
    0.9950   -0.9135   -0.7904
    0.7083   -0.5852   -0.9372
    0.9187   -0.6783   -1.0342
    ]';

% insert weights from logistic regression (train_logreg of MVPA toolbox)
% with penalty 9.8
weightsLeft = [
    0.5930    0.0845   -0.4319
    0.7812   -0.3007   -0.4087
    0.7858   -0.3107   -0.4308
    0.6385   -0.4595   -0.4226
    0.3673   -0.1746   -0.5631
    0.5636   -0.2069   -0.6438
    ]';

betasLeft = [-3.1342  ;  -2.2636  ;  -1.3006  ;  -0.6495  ;  -0.9027   ; -2.7672];
thetasLeft = [-0.8992;  4.3293];
betasRight = [-3.7579;   -2.7491;   -1.2468;   -0.5418;   -0.8468;   -3.8891];
thetasRight = [0.1030; 5.1656];

% 1 - right; 0 = left
if handedness
    LateralityProb = [90,5,5];% probability in the general public
    weights = weightsRight;
    betas = betasRight;
    thetas = thetasRight;
else
    LateralityProb = [60,20,20]; % probability in the general pubplic
    weights = weightsLeft;
    betas = betasLeft;
    thetas = thetasLeft;
end
%-------------------------------------------------------------------------------

%%%%%% load the midsagital mask and claculate the mid sagital plane %%%%%%
if createOccMask
    
    fprintf('Loading the midsagital mask and claculating the mid sagital plane..\n');
    
    % check if the relevant MidSag3points mask file exist
    if exist(fullfile(LIpath, [midSagitalNii '.img'] ), 'file')
        nii_midSagital = load_nii( fullfile(LIpath, midSagitalNii));
        [rightImg,leftImg,midImg,paramsMidSag] = CalcMidSagPlane(nii_midSagital.img, minDist, reverseMidSagMask);
        if createMidSagMask
            % saving a left side mask
            leftMask = nii_midSagital;
            leftMask.img = int16(leftImg);
            save_nii(leftMask, [ LIpath, '\LeftMask.hdr']);
            
            % saving a right side mask
            rightMask = nii_midSagital;
            rightMask.img = int16(rightImg);
            save_nii(rightMask, [ LIpath, '\RightMask.hdr']);
            
            % saving a mid mask
            midMask = nii_midSagital;
            midMask.img = int16(midImg);
            save_nii(midMask, [ LIpath, '\midMask.hdr']);
            
            % ask the user to continue..
            % open msg dlg and ask the user if we can continue
            % Construct a questdlg with two options
            str = sprintf('please check if the mid sagital plane is good and create the 2 dots for occipital mask (press continue when finished)');
            choice = questdlg(str, ...
                'Lateralization processing paused (please check markings)', ...
                'Continue','Abort', 'Continue');
            % Handle response
            switch choice
                case 'Abort'
                    disp('Aborting!')
                    return
                case 'Continue'
                    disp('Ok, let''s Continue!')
            end
            
        end
    end
    
    %%%%%% load the cerebellum and ocipital mask %%%%%%
    clacMask_flag = 1;
    if exist(fullfile(LIpath,  'CerebellumAndOccipitalMask.img'), 'file')
        
        str = sprintf('Are you sure you want to recalculate the Occipital Cerebellum Mask?');
        choice = questdlg(str, ...
            'Lateralization processing paused', ...
            'Yes','No', 'Yes');
        % Handle response
        switch choice
            case 'No'
                disp('Skip recalculation of the Occipital Cerebellum Mask!')
                clacMask_flag = 0;
            case 'Yes'
                disp('Ok, let''s Continue!')
        end
    end
    
    % check if the relevant OccipitalDots mask file exist
    if clacMask_flag
        if exist(fullfile(LIpath, [occipitalDots '.img'] ), 'file')
            nii_occDots = load_nii( fullfile(LIpath, occipitalDots));
            occDotsImg = nii_occDots.img;
            [occipitalImg, params] = CalcOccipitalMask(occDotsImg, paramsMidSag, reverseOccMask);
            
            occMask = nii_occDots;
            occMask.img = int16(occipitalImg);
            save_nii(occMask, [ LIpath, '\CerebellumAndOccipitalMask.hdr']);
            
            str = sprintf('please check if the occipital and cerebellum mask is good.\nIf not, please correct it manually');
            choice = questdlg(str, ...
                'Lateralization processing paused (please check markings)', ...
                'Continue','Abort', 'Continue');
            % Handle response
            switch choice
                case 'Abort'
                    disp('Aborting!')
                    return
                case 'Continue'
                    disp('Ok, let''s Continue!')
            end
        end
    end
end
% none_cereb_mat=int16(1-cereb_mat);% invert

% going over the list and dealing with each pair of files at a
% time.
for l = 1:numel(LI_list)
    curFiles = LI_list{l};
    splitFiles = strsplit(curFiles, '+ ');
    
    %     if ~isempty(isEEG)
    %         series1 = char(deblank(splitFiles{1}));
    %         series2 = char(deblank(splitFiles{2}));
    %     else
    series1 = char(deblank(regexp(splitFiles{1}, '[^(?<=Se_\d)]\w*[^(*rep)]', 'match')));
    series2 = char(deblank(regexp(splitFiles{2}, '[^(?<=Se_\d)]\w*[^(*rep)]', 'match')));
    %     end
    
    files_list = {series1; series2};
    
    %%%%%% load the coregistered files %%%%%%%%%%%%%
    fprintf('Loading the activation files..\n');
    % go to the folder and extract the fMRI files
    % let's see if fMRIsession field exist - and if it does we'll go over it
    % and search for the relevant fmri folder
    if isfield(subInfo, 'fMRIsession')
        fields = subInfo.fMRIsession;
        fieldnameToAccess = fieldnames(fields);
        
        for k = 1:numel(files_list)
            curSeries = files_list{k};
            
            %             if ~isempty(isEEG)
            %                 removeLagStr = regexp(curSeries, 'Lag_-?\d+', 'match');
            %                 curContrast = strrep(curSeries, [char(removeLagStr) '_'], '');
            %             else
            curContrast = regexp(curSeries, 'spmT_\d\w*', 'match');
            %             end
            
            file = regexp(char(curSeries), 'rest', 'match');
            
            if isempty(file)
                %file = lower(regexp(char(curSeries), '^[^spmT]+(?=spmT)', 'match'));
                % find the location of spmT
                spmTloc = strfind(curSeries, '_spmT');
                file = lower(curSeries(1:spmTloc-1));
                
            end
            
            if isempty(file)
                file = curSeries;
            end
            
            file = char(strrep(file, '_', ''));
            
            
            % going over the fmri fields in subInfo and checking if our file
            % matches one of them.
            foundStr = 0;
            for i = 1:numel(fieldnameToAccess)
                
                % extracting the current fmri session name
                seriesDescription = fields.(fieldnameToAccess{i}).seriesDescription;
                sName = regexp(lower(seriesDescription), '^[^(]+(?=)', 'match');
                seriesName = char(strrep(sName, '_', ''));
                
                f = findTaskName(seriesName, file);
                
                if ~isempty(f)
                    foundStr = 1;
                    
                    % setting the path to the current series func folder
                    seriesNumber= fields.(fieldnameToAccess{i}).seriesNumber;
                    fullSeriesName = ['Se' num2str( seriesNumber, '%0.2d' ) '_' seriesDescription ];
                    fullSeriesFuncPath = fullfile(funcPath, fullSeriesName);
                    
                    % copying the img and hdr of the activation file into the
                    % superimpose folder in the viewer (they were already
                    % coregistered in previous preprocessing)
                    % copying to the viewer folder a copy of the original fmri file (copy file)
                    fmriFiles = fullfile( fullSeriesFuncPath, 'spmT_files', [ char(curContrast)  '.nii'] );
                    
                    if ~exist(fmriFiles, 'file')
                        fmriFiles = fullfile( fullSeriesFuncPath, 'Results', [ char(curContrast)  '.nii'] );
                    end
                    
                    destination = fullfile(viewerFilesPath,  [ char(curSeries)  '.nii']);
                    fprintf('Found: %s\n', fmriFiles);
                    copyfile( fmriFiles, destination );
                    break
                end
            end
            
            if ~foundStr
                
                % now let's search in the analysis folder itself for things to show
                dirs = dir(fullfile(analysisPath));
                dirs = {dirs.name};
                dirs = dirs(3:end);
                
                % check that we have other folders than the default ones (i.e.;
                % DTI_41, func, anat, and LI)
                dirType = regexpi(lower(dirs), '(dti_41|li|anat|func|out*)+[^(_| |-)]*', 'match');
                idx = find(cellfun(@isempty,dirType));
                
                if ~isempty(idx)
                    for n = 1:numel(idx)
                        %                         if strcmpi(dirs{idx(n)}, 'eeg_lags')
                        %
                        %                             eegLagsPath = fullfile(analysisPath, 'EEG_Lags');
                        %
                        %                             sessionDirs = dir(eegLagsPath);
                        %                             sessionDirs = {sessionDirs.name};
                        %                             sessionDirs = sessionDirs(3:end);
                        %
                        %                             for s = 1:size(sessionDirs, 2)
                        %                                 curSess = sessionDirs{s};
                        %
                        %                                 lagDirs = dir(fullfile(eegLagsPath, curSess));
                        %                                 lagDirs = {lagDirs.name};
                        %                                 lagDirs = lagDirs(3:end);
                        %
                        %                                 for lg = 1:size(lagDirs, 2)
                        %                                     curLag = lagDirs{lg};
                        %
                        %                                     resultsPath = fullfile(eegLagsPath, curSess, curLag, 'spmT_files');
                        %                                     spmFiles = dir(resultsPath);
                        %                                     spmFiles = {spmFiles.name};
                        %                                     spmFiles = spmFiles(3:end);
                        %
                        %                                     if ~isempty(spmFiles)
                        %
                        %                                         % find if the file exists
                        %                                         if isequal(char(removeLagStr), curLag) && ...
                        %                                             exist(fullfile(resultsPath, [ char(curContrast) '.nii']), 'file')
                        %                                             foundStr = 1;
                        %
                        %                                             % copying the img and hdr of the activation file into the
                        %                                             % superimpose folder in the viewer (they were already
                        %                                             % coregistered in previous preprocessing)
                        %                                             % copying to the viewer folder a copy of the original fmri file (copy file)
                        %                                             fmriFiles = fullfile( resultsPath, [ char(curContrast)  '.nii'] );
                        %                                             destination = fullfile(viewerFilesPath, [ curLag '_' char(curContrast)  '.nii'] );
                        %                                             fprintf('Found: %s\n', fmriFiles);
                        %                                             copyfile( fmriFiles, destination );
                        %                                             break
                        %                                         end
                        %                                     end
                        %                                 end
                        %                                 if foundStr
                        %                                     break
                        %                                 end
                        %                             end
                        %                         else
                        curDir = fullfile(analysisPath, dirs{idx(n)});
                        % now lets set the fmri files..
                        % find if the file exists
                        if exist(fullfile(curDir, [ char(curContrast) '.nii']), 'file')
                            foundStr = 1;
                            
                            % copying the img and hdr of the activation file into the
                            % superimpose folder in the viewer (they were already
                            % coregistered in previous preprocessing)
                            % copying to the viewer folder a copy of the original fmri file (copy file)
                            fmriFiles = fullfile( curDir, [  char(curContrast)  '.*'] );
                            destination = fullfile(viewerFilesPath, [char(curContrast)  '.*'] );
                            fprintf('Found: %s\n', fmriFiles);
                            copyfile( fmriFiles, destination );
                            break
                        end
                        %                         end
                        if foundStr
                            break
                        end
                    end
                end
            end
        end
    end
    
    % now, after we moved the files to the viewer\files folder - we can upload
    % them.
    series1_nii = load_nii(fullfile( viewerFilesPath, [series1 '.nii'])); % loading the activation
    series1_img = double(series1_nii.img);
    series2_nii = load_nii(fullfile( viewerFilesPath, [series2 '.nii'])); % loading the activation
    seires2_img = double(series2_nii.img);
    
    %%%%%%%%%%%%%%%%% setting the threshold for activation  %%%%%%%%%%%%%%%
    series1_totalVoxels = size(series1_img,1)*size(series1_img,2)*size(series1_img,3);
    series2_totalVoxels = size(seires2_img,1)*size(seires2_img,2)*size(seires2_img,3);
    
    if series1_totalVoxels ~= series2_totalVoxels
        error('a','auditory and visual images are not the same size ');
    end;
    
    tempVoxels = series1_totalVoxels;
    delta = 0.1;
    
    %%%%%%%%% masking %%%%%%%%%%%%%%%%%%
    fprintf('Masking..\n');
    nii_none_cereb = load_nii( fullfile(LIpath, 'CerebellumAndOccipitalMask') );
    none_cereb_mat = nii_none_cereb.img;
    series1_img = series1_img .* double(none_cereb_mat);
    seires2_img = seires2_img .* double(none_cereb_mat);
    RightMask = load_nii(fullfile(LIpath, '\RightMask.hdr'));
    LeftMask = load_nii(fullfile(LIpath, '\LeftMask.hdr'));
    rightImg = RightMask.img;
    leftImg = LeftMask.img;
    
    %%%%%%%%%%%%% running on all thresholds %%%%%%%%%%%
    fprintf('Running on all thresholds..\n');
    thresholds = thresholdsForResearch;
    for i = 1:numel(thresholds)
        %%%%%%%%
        tempThresh = 0;
        tempVoxels = series1_totalVoxels;
        while tempVoxels > series1_totalVoxels * thresholds(i) % while the number of voxels is larger than the threshold
            tempThresh = tempThresh + delta; % increase the absolute threshold
            series1_img = series1_img .* double((series1_img > tempThresh));
            tempVoxels = length(find(series1_img > tempThresh)); % check how many voxels are left
        end
        
        tempThresh=0;
        tempVoxels = series1_totalVoxels;
        while tempVoxels > series1_totalVoxels * thresholds(i) % while the number of voxels is larger than the threshold
            tempThresh = tempThresh + delta; % increase the absolute threshold
            seires2_img = seires2_img .* double((seires2_img > tempThresh));
            tempVoxels = length(find(seires2_img > tempThresh)); % check how many voxels are left
        end
        
        % calculate the and of these activations by multiplying their values
        series1_imgDouble = double(series1_img);
        series2_imgDouble = double(seires2_img);
        ImgActMult = (series1_imgDouble) .* (series2_imgDouble);
        nii_tog = series1_nii;
        nii_tog.img = double(ImgActMult);
        
        % arranging file name...
        series1_spmTinx = strfind(series1, '_spmT');
        series1_name = series1(1:series1_spmTinx-1);
        series1_name = char(strrep(series1_name, '_', ''));
        
        series2_spmTinx = strfind(series2, '_spmT');
        series2_name = series2(1:series2_spmTinx-1);
        series2_name = char(strrep(series2_name, '_', ''));
        
        nii_tog.fileprefix = fullfile(viewerFilesPath, ['LI_' series1_name '_' series2_name '.hdr']);
        % view_nii(nii1);
        
        % save the resultant activation file
        if length(find(thresholdsForPlot == thresholds(i)) > 0) % if we want to plot and save  this
            save_nii(nii_tog, fullfile(LIpath, ['LI_' series1_name '_' series2_name '_p' num2str(thresholds(i)) '.hdr']));
        end;
        
        
        [AmountAct(i),AmountActInd(i),AmountStandardInd(i),SumAct(i),SumActInd(i),SumStandardInd(i),NoActivation] = CalcLateralityIndex_new(nii_tog, 0, rightImg, leftImg);
        
        if (NoActivation)&&(i>1)
            SumActInd(i)=sign(SumActInd(i-1));
            SumStandardInd(i)=sign(SumStandardInd(i-1));
        end
    end
    
    %%%%%%%%%%%%%% creating figure %%%%%%%%%%%%%%%%%%%%
    fprintf('Creating and saving the LI figure..\n');
    f = figure('Position', [100, 100, 900, 700]);
    fontsz = 12;
    
    %%%% top subplot %%%
    ax1 = subplot(2,1,1);
    set(gca, 'FontSize', fontsz, 'FontWeight','bold');
    hold on;
    
    SumStandardIndForPlot = SumStandardInd(ThresholdForPlotInd);
    plot(ax1, hezkotForPlot, SumStandardIndForPlot, 'Color', rgb('Black'), 'LineWidth', 2.5);
    plot(ax1, hezkotForPlot, LeftMeans, 'Color', rgb('RoyalBlue'), 'LineWidth', 2);%plot(hezkot,LeftMeans+LeftStds,'b:');plot(hezkot,LeftMeans-LeftStds,'b:');
    plot(ax1, hezkotForPlot, BilateralMeans, 'Color', rgb('ForestGreen'), 'LineWidth', 2);%plot(hezkot,BilateralMeans+BilateralStds,'g:');plot(hezkot,BilateralMeans-BilateralStds,'g:');
    plot(ax1, hezkotForPlot, RightMeans, 'Color', rgb('FireBrick'), 'LineWidth', 2);%plot(hezkot,RightMeans+RightStds,'r:');plot(hezkot,RightMeans-RightStds,'r:');
    
    % setting up the LI title
    %     if length(find(SumStandardInd > 0)) == length(SumStandardInd)
    %         %     figure;plot(hezkot,abs(SumActInd));axis([hezkot(1) hezkot(end) 0.5 1]);
    %         str = sprintf('Lateralization Index \nthis subject has a LEFT dominance in all thresholds');
    %     else
    %         if length(find(SumStandardInd < 0)) == length(SumStandardInd)
    %             %         figure;plot(hezkot,abs(SumActInd));axis([hezkot(1) hezkot(end) 0.5 1]);
    %             str = sprintf('Lateralization Index \nthis subject has a RIGHT dominance in all thresholds');
    %         else
    %             %          figure;plot(hezkot,SumActInd);axis([hezkot(1) hezkot(end) -1 1]);
    %             str = sprintf('Lateralization Index \nthis subject has a MIXED dominance in all thresholds');
    %         end;
    %     end;
    str = sprintf('Lateralization Index');
    title(str,'FontSize',fontsz+1);
    
    % setting up parameters
    set(gca, 'Position', [0.1300 0.6138 0.7750 0.3412]);
    set(gca, 'YLim', [-1 1]);
    set(gca, 'XLim', [hezkotForPlot(1) hezkotForPlot(end)]);
    set(gca,'XTick',hezkotForPlot);
    set(gca,'XTickLabel',['0.033'; '0.016'; '0.008'; '0.004'; '0.002' ;'0.001']);
    xlabel('Threshold (percentage of remaining voxels)');
    ylabel('Lateralization Index');
    
    %%% calculating the chances of being left/right or bilateral in language
    ProbLeft = normpdf(SumStandardIndForPlot, LeftMeans, LeftStds);
    ProbBilateral = normpdf(SumStandardIndForPlot, BilateralMeans, BilateralStds);
    ProbRight = normpdf(SumStandardIndForPlot, RightMeans, RightStds);
    temp = LateralityProb'*ones(1,length(ProbLeft));
    ProbNorm = temp.*[ProbLeft;ProbBilateral; ProbRight];
    temp2 = ones(3,1)*sum(ProbNorm,1);
    ProbFinal = (ProbNorm./temp2)*100;
    ProbFinalForPlot = ProbFinal;
    
    % the following lines deal with the situation where one of the options gets
    % a value very close to 100%. we do not wish to report 100% so the graph will
    % report 99%. and put 1% in the second highest option
    for i=1:size(ProbFinal,2);
        if ProbFinal(1,i) > 99
            ProbFinalForPlot(1,i) = 99;
            if ProbFinal(2,i) > ProbFinal(3,i)
                ProbFinalForPlot(2,i) = 1;
            else
                ProbFinalForPlot(3,i) = 1;
            end
        end
        
        if ProbFinal(2,i) > 99
            ProbFinalForPlot(2,i) = 99;
            if ProbFinal(1,i) > ProbFinal(3,i)
                ProbFinalForPlot(1,i) = 1;
            else
                ProbFinalForPlot(3,i) = 1;
            end
        end
        
        if ProbFinal(3,i) > 99
            ProbFinalForPlot(3,i) = 99;
            if ProbFinal(1,i) > ProbFinal(2,i)
                ProbFinalForPlot(1,i) = 1;
            else
                ProbFinalForPlot(2,i) = 1;
            end
        end
    end
    
    ProbFinalForPlot = double(ProbFinalForPlot);
    deltax = 0.2;
    
    e1 = -betas'*SumStandardIndForPlot'+thetas(1);
    e2 = -betas'*SumStandardIndForPlot'+thetas(2);
    
    LRprob(1) = exp(e1)/(1+exp(e1));
    LRprob(3) = 1-exp(e2)/(1+exp(e2));
    LRprob(2) = 1-LRprob(1)-LRprob(3);
    
    % names{1} = ['left ' num2str(round(LRprob(1)))];
    % names{2} = ['bilateral' num2str(round(LRprob(2)))];
    % names{3} = ['right' num2str(round(LRprob(3)))];
    
    %%% the following lines deal with the situation where one of the options
    %%% gets a value very close to 100%. we do not wish to report 100% so the
    % graph will report 99%. and put 1% in the second highest option
    LRprobForPlot = LRprob;
    if LRprob(1) > 0.99
        LRprobForPlot(1) = 0.99;
        if LRprob(2) > LRprob(3)
            LRprobForPlot(2) = 0.01;
        else
            LRprobForPlot(3) = 0.01;
        end
    end
    
    if LRprob(2) > 0.99
        LRprobForPlot(2) = 0.99;
        if LRprob(1) > LRprob(3)
            LRprobForPlot(1) = 0.01;
        else
            LRprobForPlot(3) = 0.01;
        end
    end
    
    if LRprob(3) > 0.99
        LRprobForPlot(3) = 0.99;
        if LRprob(1) > LRprob(2)
            LRprobForPlot(1) = 0.01;
        else
            LRprobForPlot(2) = 0.01;
        end
    end
    LogRegProb=LRprob;
    
    LRprobForPlot = double(LRprobForPlot);
    
    %%%% bottom subplot %%%%
    ax2 = subplot(2,1,2);
    set(gca, 'FontSize', fontsz, 'FontWeight','bold');
    hold on;
    
    for col = 1:numel(LRprobForPlot)
        loc = col;
        data = 100 * LRprobForPlot(col);
        color = colorScheme(col);
        bar(loc, data, 'FaceColor', rgb(colorScheme{col}));
    end
    
    xlimvals = get(gca, 'XLim');
    ylimvals = get(gca, 'YLim');
    
    % setting axis parameters
    set(gca, 'Position', [0.1300 0.0800 0.7750 0.3412]);
    set(gca, 'XLim', [0 xlimvals(2) + 0.5])
    set(gca, 'YLim', [0 ylimvals(2) + 17])
    set(gca,'XMinorTick','off');
    set(gca,'XTick',1:3);
    set(gca,'XTickLabel',{'Left', 'Bilateral', 'Right'});
    
    % setting the title of each bar
    for i = 1:numel(LRprobForPlot)
        t = text(i, 0, [num2str(round(100*LRprobForPlot(i))) '%']);
        set(t, 'Position', [i (100 * LRprobForPlot(i) + 15)],...
            'HorizontalAlignment', 'Center', 'VerticalAlignment', 'top',...
            'FontWeight','bold', 'FontSize',fontsz, 'FontName','Arial');
    end
    
    xlabel('Final probability considering handness');
    
    % setting up the legend
    legs{1}='Left';
    legs{2}='Bilateral';
    legs{3}='Right';
    lgnd = legend(legs,'FontSize', fontsz-2);
    set(lgnd, 'Position', [0.0314 0.4476 0.1333 0.0995]);
    
    % saving results into a mat file and into the subInfo file of the subject
    eval(['save ' LIpath '\LI_' series1_name '_' series2_name '_savedVariables hezkotForPlot hezkotForResearch thresholdsForPlot thresholdsForResearch AmountAct AmountActInd AmountStandardInd SumAct SumActInd SumStandardInd SumStandardIndForPlot ProbFinal LogRegProb']);
    
    subInfo.LI.hezkotForPlot = hezkotForPlot;
    subInfo.LI.hezkotForResearch = hezkotForResearch;
    subInfo.LI.thresholdsForPlot = thresholdsForPlot;
    subInfo.LI.thresholdsForResearch = thresholdsForResearch;
    subInfo.LI.amountAct = AmountAct;
    subInfo.LI.amountActInd = AmountActInd;
    subInfo.LI.amountStandardInd = AmountStandardInd;
    subInfo.LI.sumAct = SumAct;
    subInfo.LI.sumActInd = SumActInd ;
    subInfo.LI.sumStandardInd = SumStandardInd;
    subInfo.LI.sumStandardIndForPlot = SumStandardIndForPlot ;
    subInfo.LI.probFinal = ProbFinal;
    subInfo.LI.logRegProb = LogRegProb;
    
    save( fullfile(subPath, 'subInfo.mat'), 'subInfo');
    
    saveas(gcf, fullfile(subPath, 'viewer',  ['LI_' series1_name '_' series2_name '.jpg']));
    saveas(gcf, fullfile(subPath, 'viewer',  ['LI_' series1_name '_' series2_name '.bmp']));
    hgexport(gcf, fullfile(subPath, 'viewer',  ['LI_' series1_name '_' series2_name '.fig']));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rightmat, leftmat, midmat, params] = CalcMidSagPlane(MidSagImg, MinDist, ReverseLR)

sagsN = size(MidSagImg,1);
corsN = size(MidSagImg,2);
axesN = size(MidSagImg,3);
mone = 0;
dots1Found = 0;
dots2Found = 0;
% the purpose of the following loop is to find the dots that are marked and
% make sure there are only 4 dots, two on each axial slide
for k = 1:axesN
    temp = sum(sum(MidSagImg(:,:,k))); % calc how many voxels in the slice are colored
    if temp > 0
        mone = mone + 1;
        axials(mone) = i; %% ASK tomer should be k?
        if temp > 2
            error(['too many voxels are marked on axial slice ' num2str(k)]);
        else
            if mone > 2
                error('too many axial slices are marked');
            else
                [x,y] = find(MidSagImg(:,:,k) == 1);
                
                if temp == 1
                    dots1(1,1:3) = [x(1),y(1),k];
                    dots1Found = 1;
                end
                
                if temp == 2
                    dots2(1,1:3) = [x(1),y(1),k];
                    dots2(2,1:3) = [x(2),y(2),k];
                    dots2Found = 1;
                end
            end
        end
    end
end

if (mone < 2) || (dots1Found == 0) || (dots2Found == 0)
    error('not enough axial slices are marked');
end

dots = [dots1; dots2];
if size(dots,1) ~= 3
    error('there should be exactly three points marked in the mid-sagital mask');
end;

%%%%% calculating the coefficents of the midsagital plane: Ax+By+Cz+D=0
A = dots(1,2)*(dots(2,3)-dots(3,3))+dots(2,2)*(dots(3,3)-dots(1,3))+dots(3,2)*(dots(1,3)-dots(2,3));
B = dots(1,3)*(dots(2,1)-dots(3,1))+dots(2,3)*(dots(3,1)-dots(1,1))+dots(3,3)*(dots(1,1)-dots(2,1));
C = dots(1,1)*(dots(2,2)-dots(3,2))+dots(2,1)*(dots(3,2)-dots(1,2))+dots(3,1)*(dots(1,2)-dots(2,2));
D = -dots(1,1)*(dots(2,2)*dots(3,3)-dots(3,2)*dots(2,3))-dots(2,1)*(dots(3,2)*dots(1,3)-dots(1,2)*dots(3,3))-dots(3,1)*(dots(1,2)*dots(2,3)-dots(2,2)*dots(1,3));

% normalizing
params = [A,B,C,D]/sqrt(A^2+B^2+C^2);
for l = 1:sagsN
    for j = 1:corsN
        for k = 1:axesN
            distmat(l,j,k) = params*[l,j,k,1]';
        end
    end
end

if ReverseLR
    leftmat = distmat<-MinDist;
    rightmat = distmat>MinDist;
else
    leftmat = distmat>MinDist;
    rightmat = distmat<-MinDist;
end

midmat = (distmat<2).*(distmat>-2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [occipitalMask, params] = CalcOccipitalMask(occDots_mat, paramsMidSag, ReverseMask)
sagsN = size(occDots_mat,1);
corsN = size(occDots_mat,2);
axesN = size(occDots_mat,3);
mone = 0;
dotsFound = 0;

% the purpose of the following loop is to find the dots that are marked and
% make sure there are only 4 dots, two on each axial slide
for k = 1:axesN
    temp = sum(sum(occDots_mat(:,:,k))); % calc how many voxels in the slice are colored
    if temp > 0
        mone = mone+1;
        axials(mone) = i; % HERE ask tomer - should it be k?
        if temp > 2
            error(['too many voxels are marked on axial slice ' num2str(k)]);
        else
            if mone > 2
                error('too many axial slices are marked');
            else
                [x,y] = find(occDots_mat(:,:,k)==1);
                
                if temp == 1
                    if dotsFound == 0
                        dots(1,1:3) = [x(1),y(1),k];
                    else
                        dots(2,1:3) = [x(1),y(1),k];
                    end
                    dotsFound = dotsFound+1;
                end
                
                if temp == 2
                    dots(1,1:3) = [x(1),y(1),k];
                    dots(2,1:3) = [x(2),y(2),k];
                    dotsFound = dotsFound + 2;
                end
            end
        end
    end
end

if (mone < 2)
    error('not enough axial slices are marked');
end;

if size(dots,1) ~= 2
    error('there should be exactly two points marked in the occipital mask');
end

% dots(:,1)=sagsN*ones(size(dots,1),1)-dots(:,1);
dots = flipud(dots); % for some reason i switched the dots
t1 = -paramsMidSag*[dots(1,1:3) 1]'/(sum(paramsMidSag(1:3).^2)); % this t1 value helps to find the projection dot of dot1 on the mid sasgital plane
t2 = -paramsMidSag*[dots(2,1:3) 1]'/(sum(paramsMidSag(1:3).^2)); % this t2 value helps to find the projection dot of dot2 on the mid sasgital plane
dotsnew(1,1:3) = dots(1,1:3)+paramsMidSag(1:3)*(t1+10); % find two (the first) dots on the line that is orthogonal to the mid sag plane and passes through dot 1
dotsnew(2,1:3) = dots(1,1:3)-paramsMidSag(1:3)*(t1-10); % find two (the second) dots on the line that is orthogonal to the mid sag plane and passes through dot 1
dotsnew(3,1:3) = dots(2,1:3)+paramsMidSag(1:3)*t2; % project the second dot on the plane and find the projection dot
dotsold = dots;

%%%%% calculating the coefficents of the midsagital plane: Ax+By+Cz+D=0
dots = dotsnew;
A = dots(1,2)*(dots(2,3)-dots(3,3))+dots(2,2)*(dots(3,3)-dots(1,3))+dots(3,2)*(dots(1,3)-dots(2,3));
B = dots(1,3)*(dots(2,1)-dots(3,1))+dots(2,3)*(dots(3,1)-dots(1,1))+dots(3,3)*(dots(1,1)-dots(2,1));
C = dots(1,1)*(dots(2,2)-dots(3,2))+dots(2,1)*(dots(3,2)-dots(1,2))+dots(3,1)*(dots(1,2)-dots(2,2));
D = -dots(1,1)*(dots(2,2)*dots(3,3)-dots(3,2)*dots(2,3))-dots(2,1)*(dots(3,2)*dots(1,3)-dots(1,2)*dots(3,3))-dots(3,1)*(dots(1,2)*dots(2,3)-dots(2,2)*dots(1,3));
% normalizing
params = [A,B,C,D]/sqrt(A^2+B^2+C^2);
for l = 1:sagsN
    for j = 1:corsN
        for k = 1:axesN
            distmat(l,j,k) = params*[l,j,k,1]';
        end
    end
end

occipitalMask = distmat<0;
if ReverseMask
    occipitalMask = distmat>0;
end

% occipitalMask=zeros(sagsN,corsN,axesN);
% occipitalMask(occipitalMaskLeft+occipitalMaskRight>0)=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [AmountAct, AmountActInd, AmountStandardInd, SumAct, SumActInd, SumStandardInd, NoActivation] = CalcLateralityIndex_new(nii_activation, thresh, rightmat, leftmat)
% this function compares the number of voxels on the left hemesphere
% compared to the right (AmountAct) and the amount of activation on the left
% hemisphere compared to the right (SumAct). if the result is positive
% there is more activation on the left, if it is negative there is more
% activation on the right
% keep in mind that the left hemesphere is on the right side of the image
% matrix (lower x indices)
% subPath = 'M:\clinica\Tomer_Gazit' ;
% thresh=0;
NoActivation = 0;
% nii_activation = load_nii( [subPath,'\viewer\',ActivationFile] );
data = double(nii_activation.img);
[x,y,z] = size(data);

%%%%%%%%%%%% counting the number of active voxels big/small
dataRight = data.*double(rightmat);
dataLeft = data.*double(leftmat);
locs_right = find(dataRight(:,:,:)>thresh); % find the locations on the right (left side of the big matrix) where the activations are larger than 0
locs_left = find(dataLeft(:,:,:)>thresh); % find the locations on the left (left side of the big matrix) where the activations are larger than 0
if length(locs_right) > length(locs_left)
    if length(locs_left) == 0
        AmountAct = -100;
    else
        AmountAct = -length(locs_right)/length(locs_left); % calc the amount of active voxels: right/left
    end
    
    AmountActInd = -length(locs_right)/(length(locs_right)+length(locs_left));
    AmountStandardInd = -(length(locs_right)-length(locs_left))/(length(locs_right)+length(locs_left));
else
    if length(locs_right) == 0
        AmountAct = 100;
    else
        AmountAct = length(locs_left)/length(locs_right); % calc the amount of active voxels: left/right
    end
    
    AmountActInd = length(locs_left)/(length(locs_right)+length(locs_left));
    AmountStandardInd = (length(locs_left)-length(locs_right))/(length(locs_right)+length(locs_left));
end

if (length(locs_left)==0)&&(length(locs_right)==0)
    AmountActInd = 0;
    warning('there is no activation at all !! ');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% now for suming the activities left -right

if length(locs_right) == 0
    warning('no right activation');
end

if length(locs_left) == 0
    warning('no left activation');
end

SumActRight = sum( data(locs_right));
SumActLeft = sum( data(locs_left));

if length(SumActRight)==0
    SumActRight=0;
end

if length(SumActLeft)==0
    SumActLeft=0;
end

if SumActRight > SumActLeft
    if (SumActLeft==0)
        SumAct = -100;
    else
        SumAct = -SumActRight/SumActLeft; % calc the amount of active voxels: right/left
    end
    
    SumActInd = -(SumActRight)/(SumActRight+SumActLeft);
    SumStandardInd = -(SumActRight-SumActLeft)/(SumActRight+SumActLeft);
else
    if SumActRight == 0
        SumAct = 100;
    else
        SumAct = SumActLeft/SumActRight; % calc the amount of active voxels: left/right
    end
    
    SumActInd = (SumActLeft)/(SumActRight+SumActLeft);
    SumStandardInd = (SumActLeft-SumActRight)/(SumActRight+SumActLeft);
end

% SumAct=SumActLeft-SumActRight;
if (length(locs_left)==0)&&(length(locs_right)==0) % in the case where there is no activation at all
    SumActInd = 0;
    warning('there is no activation at all !! ');
    NoActivation = 1;
end