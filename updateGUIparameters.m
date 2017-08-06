function [subInfo, handles] = updateGUIparameters(subInfo, handles, proc)

%% general parameters
% let's update this figure with the subject's information
if isfield(subInfo, 'name'), set(handles.subName, 'String', subInfo.name); end
if isfield(subInfo, 'id'), set(handles.id, 'String', subInfo.id); end
if isfield(subInfo, 'age'), set(handles.age, 'String', subInfo.age); end
if isfield(subInfo, 'gender'), set(handles.gender, 'String', subInfo.gender); end
if isfield(subInfo, 'tumorType'), set(handles.tumorType, 'String', subInfo.tumorType); end

% let's update this figure with the subject's default parameters
if ~isfield(subInfo, 'parameters'),
    subInfo = setDefaultParameters(subInfo);
end

% now setting the SPGR_text - which shows the current spgr file that we are
% using for coregistration
%anatomyfile = regexp(subInfo.SPGR, '\w*[^.nii]', 'match');
if ~strcmp(proc, 'LIallThresh')
    if strcmp(proc, 'processWithFullCoreg')
        if isfield(subInfo, 'SPGR')
            str = sprintf('%s', subInfo.SPGR);
        else
            str = '';
        end
        set(handles.SPGR_btn, 'String', str);
    else
        if isfield(subInfo, 'SPGR')
            str = sprintf('%s', subInfo.SPGR);
        else
            str = '';
        end
        set(handles.SPGR_text, 'String', str);
    end
end

% how many volumes to skip at the beggining
% if its the old magnet (GE) than we need to take off the first 6 volumes.
% otherwise - only 3 volumes to be skipped.
% eeg - 0 skipped
scannerName = subInfo.dcmInfo_org.Manufacturer;

%%
if strcmp(proc, 'processWithFullCoreg') || isempty(proc)
    if isfield(subInfo.parameters, 'maxTranslation'), set(handles.maxTranslation, 'String', subInfo.parameters.maxTranslation); end
    if isfield(subInfo.parameters, 'maxRotation'), set(handles.maxRotation, 'String', subInfo.parameters.maxRotation); end
    if isfield(subInfo.parameters, 'acquisitionOrder'), set(handles.acquisitionOrder, 'String', subInfo.parameters.acquisitionOrder); end
    
    if strfind(scannerName, 'GE')
        set(handles.nFirstVolumesToSkip_fmri, 'String', '6');
        set(handles.nFirstVolumesToSkip_eeg, 'String', '6');
    else
        set(handles.nFirstVolumesToSkip_fmri, 'String', '3');
        set(handles.nFirstVolumesToSkip_eeg, 'String', '0');
    end
    
    set(handles.smoothSize_fmri, 'String', '4');
    set(handles.lag_fmri, 'String', '0');
    
    set(handles.smoothSize_eeg, 'String', '6');
    set(handles.lag_eeg, 'String',  sprintf('[%d  %d  %d  %d  %d  %d  %d]', ([1, 0, -1, -2, -3, -4, -5 ])));
    
    % let's see if fMRIsession field exist - and if it does we'll go over it
    % and coregister them one by one
    fields = subInfo.fMRIsession;
    fieldnameToAccess = fieldnames(fields);
    f = strfind(fieldnameToAccess, 'eeg_fmri');
    ind = find(~cellfun(@isempty,f));
    
    % deleting unnecessary fields
    % only fmri session
    if isempty(ind)
        set(handles.nFirstVolumesToSkip_eeg, 'String', '-');
        set(handles.smoothSize_eeg, 'String', '-');
        set(handles.lag_eeg, 'String', '-');
    elseif size(ind,1) == size(fieldnameToAccess) % only eeg-fmri session
        % set all fiels to show nothing
        set(handles.nFirstVolumesToSkip_fmri, 'String', '-');
        set(handles.smoothSize_fmri, 'String', '-');
        set(handles.lag_fmri, 'String', '-');
        
    end
    
    
end
%%
if strcmp(proc, 'eegProcess_estCont') || strcmp(proc, 'artProcessing') || isempty(proc)
    if strfind(scannerName, 'GE')
        set(handles.nFirstVolumesToSkip_eeg, 'String', '6');
    else
        set(handles.nFirstVolumesToSkip_eeg, 'String', '0');
    end
    if strcmp(proc, 'eegProcess_estCont')|| isempty(proc)
        set(handles.lag_eeg, 'String',  sprintf('[%d  %d  %d  %d  %d  %d  %d]', ([1, 0, -1, -2, -3, -4, -5 ])));
    end
    
    if strcmp(proc, 'artProcessing') || isempty(proc)
        if isfield(subInfo.parameters, 'globalThresh'), set(handles.globalThresh, 'String', subInfo.parameters.globalThresh); end
        if isfield(subInfo.parameters, 'motionThresh'), set(handles.motionThresh, 'String', subInfo.parameters.motionThresh); end
    end
end

%%
if strcmp(proc, 'superimpose') || strcmp(proc, 'mergeActivations') || strcmp(proc, 'processRest') || isempty(proc)
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
    
    if strcmp(proc, 'superimpose') || strcmp(proc, 'mergeActivations') || isempty(proc)
        if isfield(subInfo.parameters, 'dti_nDirections'), set(handles.dti_nDirections, 'String', subInfo.parameters.dti_nDirections); end
        if isfield(subInfo.parameters, 'infSupFlip'), set(handles.infSupFlip, 'String', subInfo.parameters.infSupFlip); end
        if isfield(subInfo.parameters, 'upDownFlip'), set(handles.upDownFlip, 'String', subInfo.parameters.upDownFlip); end
    end
    if strcmp(proc, 'processRest') || isempty(proc)
        if isfield(subInfo.parameters, 'cutoff'), set(handles.cutoff, 'String', sprintf('%.2f  -  %.2f', subInfo.parameters.cutoff)); end
        if isfield(subInfo.parameters, 'roiRadius'), set(handles.roiRadius, 'String', subInfo.parameters.roiRadius); end
    end
    
end
%%
if strcmp(proc, 'LIallThresh') || isempty(proc)
    if isfield(subInfo.parameters, 'rightHanded'), set(handles.rightHanded, 'Value', subInfo.parameters.rightHanded); end
    if isfield(subInfo.parameters, 'minDist'), set(handles.minDist, 'String', subInfo.parameters.minDist); end
    
    if strcmp(proc, 'LIallThresh')
        set(handles.createOccMask, 'Value', 1);
        set(handles.createMidSagMask, 'Value', 1);
        %     if isfield(subInfo.parameters, 'leftHanded'), set(handles.leftHanded, 'Value', subInfo.parameters.leftHanded); end
        set(handles.reverseOccMask, 'Value', 0);
        set(handles.reverseMidSagMask, 'Value', 0);
    end
end
end