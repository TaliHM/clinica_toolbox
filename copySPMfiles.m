function copySPMfiles(subInfo, fullSeriesName, fileType, varargin)

% fileType = nii\img\hdr
subPath = subInfo.path;
analysisPath = fullfile( subPath, 'Analysis' );
funcPath = fullfile( analysisPath, 'func' );

cont = {};
isEEG = regexp(lower(fullSeriesName), 'eeg_fmri', 'match');
if ~isempty(isEEG)
    fullSeriesFuncPath = fullfile(analysisPath, 'EEG_Lags', fullSeriesName);
    
    lg = regexp(lower(fullSeriesName), '\\lag_-?\d+', 'match');
    sName = deblank(strrep(lower(fullSeriesName), lg, ' '));
    
    fullContrastList = {};
    if ~isempty(varargin)
        fullContrastList = varargin{:};
    end
    
else
    fullSeriesFuncPath = fullfile(funcPath, fullSeriesName);
    % Going to the current field in the subInfo structure
    fieldname = regexp(lower(fullSeriesName), '\w*[^(\d*rep)]*', 'match');
    fieldname = strjoin(fieldname,'_');
    if isfield(subInfo.fMRIsession.(fieldname), 'contrasts')
        cont = subInfo.fMRIsession.(fieldname).contrasts;
    end
    fullContrastList = {'Positive_Effect', 'Negative_Effect'};
    
    if ~isempty(cont)
        fullContrastList(1, end+1 : end+size(cont,1)) = cont(:,1);
        %fullContrastList = fullContrastList';
    end
    
    %     if size(fullContrastList, 1) > 1
    %         fullContrastList = fullContrastList';
    %     end
    
end

filesPath = fullfile(fullSeriesFuncPath, ['spmT_*.' fileType]);
files = dir(filesPath);
files = { files.name }';

% making sure that the dir function does not mess with the file
% order
str  = sprintf('%s#', files{:});
s = ['spmT_%d.' fileType '#'];
num  = sscanf(str, s);
[dummy, index] = sort(num);
spmTfiles = files(index);

if ~isempty(spmTfiles)
    % first let's copy these files to the spmT_original
    % directory
    fprintf('Renaming spmT_*.%s files..\n', fileType);
    resultsPath = fullfile(fullSeriesFuncPath, 'Results');
    
    if (~exist(resultsPath, 'dir'))
        mkdir(resultsPath);
    end
    
    
    spmTpath = fullfile(fullSeriesFuncPath, 'spmT_files');
    destination = spmTpath;
    
    if (~exist(destination, 'dir'))
        mkdir(destination);
    end
    
    source = filesPath;
    movefile(source, destination)
    
    % now we'll rename the spmT files into something more
    % readable...
    for ind = 1:length(spmTfiles)
        % extract the number of the spmT and save them
        curSPMTfile = regexp(spmTfiles{ind},'(\w*_\d*)', 'match');
        
        source = fullfile(spmTpath, spmTfiles{ind});
        
        % creating the new spmT file with a bit more readable name...
        newSPMTfilename = fullContrastList(:, ind);
        
        if ~isempty(isEEG)
            s = regexpi(sName, '[se]\d+', 'match');
            name = strrep(s{:}, 'e', '');
            
            if size(newSPMTfilename, 1) == size(name',1)
                contStr = [];
                %if ~isequal(size(u,1), size(newSPMTfilename,1))
                str = [];
                
                % if its the same contrast over the other sessions - we
                % will write the name of the contrast once.
                if sum(strcmp(newSPMTfilename, newSPMTfilename{1})) == size(newSPMTfilename,1)
                    str = ['Se' strjoin(name, '_') '_' newSPMTfilename{1}];
                else
                    s = newSPMTfilename';
                    n = name;
                    
                    % removing empty cells
                    index = strcmp(s, '');
                    s(index) = [];
                    n(index) = [];
                    
                    index = strcmp(s, ' ');
                    s(index) = [];
                    n(index) = [];
                    
                    a = 1;
                    while ~isempty(s)
                        
                        if ~isequal(s{a}, ' ')
                            taskDir = strcmp(s, s{a});
                            index = find(taskDir == 1);
                            
                            if ~isempty(index)
                                str = [str 'Se' strjoin(n(index), '_') '_' s{a}];
                                s(index) = [];
                                n(index) = [];
                            end
                            
                            if ~isempty(s)
                                str = [str '_'];
                            end
                        end
                    end
                end
                
                abbrStr = regexprep(lower(str), '(short spikes|short spike|spikes short|spike short)', 'shortSpk');
                abbrStr = regexprep(abbrStr, '(long spikes|long spike|spikes long|spike long)', 'longSpk');
                abbrStr = regexprep(abbrStr, '(large spikes|large spike)', 'largeSpk');
                abbrStr = regexprep(abbrStr, '(small spikes|small spike)', 'smallSpk');
                abbrStr = regexprep(abbrStr, '(possible spike|possible spikes)', 'possibleSpk');
                abbrStr = regexprep(abbrStr, '(maybe short|short maybe)', 'maybeShortSkp');
                abbrStr = regexprep(abbrStr, '(maybe long|long maybe)', 'maybeLongSpk');
                %abbrStr = regexprep(abbrStr, '(junk)', 'jnk');
                %abbrStr = regexprep(abbrStr, '(maybe)', 'm');
                abbrStr = regexprep(abbrStr, '(maybe|may be|maybe spike|spike maybe|maybe spikes|spikes maybe|may be spike|spike may be|may be spikes|spikes may be)', 'maybeSkp');
                abbrStr = regexprep(abbrStr, '(right spikes|right spike)', 'rightSpk');
                abbrStr = regexprep(abbrStr, '(left spikes|left spike)', 'leftSpk');
                abbrStr = regexprep(abbrStr, '(spike|spikes)', 'spk');
                abbrStr = regexprep(abbrStr, '(epoch|epochs)', 'epc');
                
                contStr = strrep(deblank(abbrStr), ' ', '_');
                newSPMTfilename = contStr;
            else
                error('Number of spmT files is not equal to number of contrasts!')
            end
            
        end
        
        %newSPMTfilename = strrep(fullContrastList{ind}, ' ', '_');
        destination = fullfile(spmTpath, [ char(curSPMTfile) '_' char(newSPMTfilename) '.' fileType]);
        fprintf('%s --> %s\n', spmTfiles{ind},  [ char(curSPMTfile) '_' char(newSPMTfilename) '.' fileType]);
        movefile(source, destination)
        %             % and we will create an mriCron file
        %             mricronFile = 'M:\mricron2014\mricron';
        %             cmdFile = fullfile( resultsPath, [char(curSPMTfile) '_' newSPMTfilename '.bat']);
        %             batchFID = fopen( cmdFile , 'wt' );
        %             % calling the MRIcroN program and uploading the spmT file and SPGR file
        %             % -c -1 - grayscale
        %             % -c -7 - 1hot.lut
        %             % -b -1 additive transparency
        %             % -l - min Z-score statistical
        %             % -h max Z-score statistical
        %             % -x maximize the window to fit full screen
        %
        %             % mricron 2014
        %             fprintf( batchFID,...
        %                 'start /MAX %s %s -c -0 -o %s -c -7 -l 0 -h 3',...
        %                 mricronFile, SPGRpath, destination);
        %             fclose( batchFID );
        
        %         fprintf('\n');
        % else
        %     fprintf('No %s files in current directory.\n', fileType);
    end
    fprintf('\n');
end