function [subInfo, doCoreg] = changeSPGRfile(subInfo)

% changing the subject SPGR file by going to the anat folder and asking the
% subject to change it.
doCoreg = 1;
if isfield(subInfo, 'path')
    
    SPGRpath = fullfile( subInfo.path, 'Analysis', 'anat');
    
    SPGRfile = uigetfile(fullfile(SPGRpath, '*.nii'), 'Select anatomy file') ;
    if ischar(SPGRfile)
        if isequal(subInfo.SPGR, SPGRfile)
            fprintf('Same SPGR was selected, remaining with %s as the SPGR file in subInfo.m..\n', subInfo.SPGR);
            doCoreg = 0;
        else
            subInfo.SPGR = SPGRfile;
            fprintf('Saving %s as the new SPGR file in subInfo.m..\n IMPORTANT - you need to redo Coregistration!!', subInfo.SPGR);
            save( subInfo.path, 'subInfo')
        end
        
    else
        fprintf('No SPGR was selected, remaining with %s as the SPGR file in subInfo.m..\n', subInfo.SPGR);
    end
else
    errordlg(sprintf('Cannot find subject''s folder! \nsubInfo.path is not specified!'))
end