function rest_copySPMfiles(subInfo, fullSeriesName, fileType)

% fileType = nii\img\hdr
subPath = subInfo.path;
analysisPath = fullfile( subPath, 'Analysis' );
funcPath = fullfile( analysisPath, 'func' );
SPGRpath = fullfile(analysisPath, 'anat', subInfo.SPGR);

[restFilteredPath, roiName, ext] = fileparts(fullSeriesName);

scanType = regexpi(fullSeriesName, '(rest)+[^(_| )]*', 'match');
if ~isempty(scanType)
    
    fieldname = regexpi(fullSeriesName, '(Se\d*_\w+)', 'match');
    if ~isempty(fieldname)
        fullSeriesFuncPath = fullfile(funcPath, fieldname{1});
        fieldname = lower(fieldname{1});
        
        if isfield(subInfo.fMRIsession, fieldname)
            fullContrastList = {'Positive Effect'; 'Negative Effect'};
            if isfield(subInfo.fMRIsession.(fieldname), 'contrasts')
                contrasts = subInfo.fMRIsession.(fieldname).contrasts;
                fullContrastList(end+1 : end+size(contrasts,1) , 1) = contrasts(:,1);
            end
            
            filesPath = fullfile(fullSeriesName, ['spmT_*.' fileType]);
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
                destination = resultsPath;
                
                if (~exist(destination, 'dir'))
                    mkdir(destination);
                end
                source = filesPath;
                copyfile(source, destination)
                
                % now we'll rename the spmT files into something more
                % readable...
                for ind = 1:length(spmTfiles)
                    % extract the number of the spmT and save them
                    curSPMTfile = regexp(spmTfiles{ind},'(\w*_\d*)', 'match');
                    source = fullfile(resultsPath, spmTfiles{ind});
                    newSPMTfilename = strrep(fullContrastList{ind}, ' ', '_');
                    destination = fullfile(resultsPath, [ char(curSPMTfile) '_' newSPMTfilename '_' roiName '.' fileType]);
                    fprintf('%s --> %s\n', spmTfiles{ind},  [ char(curSPMTfile) '_' newSPMTfilename '_' roiName '.' fileType]);
                    movefile(source, destination)
                    
%                     % and we will create an mriCron file
%                     mricronFile = 'M:\mricron2014\mricron';
%                     cmdFile = fullfile( resultsPath, [char(curSPMTfile) '_' newSPMTfilename '_' roiName '.bat']);
%                     batchFID = fopen( cmdFile , 'wt' );
%                     % calling the MRIcroN program and uploading the spmT file and SPGR file
%                     % -c -1 - grayscale
%                     % -c -7 - 1hot.lut
%                     % -b -1 additive transparency
%                     % -l - min Z-score statistical
%                     % -h max Z-score statistical
%                     % -x maximize the window to fit full screen
%                     
%                     % mricron 2014
%                     fprintf( batchFID,...
%                         'start /MAX %s %s -c -0 -o %s -c -7 -l 0 -h 3',...
%                         mricronFile, SPGRpath, destination);
%                     fclose( batchFID );
                end
            else
                fprintf('No %s files in current directory.\n', fileType);
            end
        end
    end
end
end