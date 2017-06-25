function [roi_mask] = create_whole_brain_mask(anatomyPath, outPath, outFileName)
%Vo = create_whole_brain_mask(P,outpath, outfname);
%this function creates a whole brain mask using spm_imcalc function and the
%expression 'i1>mean(mean(mean(i1)))' and saveas a marsbar roi mat file under
%outfname_roi.mat

%P - full path to image used for the mask creation
%roi_mask - output marsbar roi mask
%outpath - path to save output iamge
%outfname - output file name 

Vi = spm_vol(char(anatomyPath));
Vo = struct(	'fname',	[fullfile(outPath, outFileName)],...
		'dim',		Vi(1).dim(1:3),...
		'dt',		Vi(1).dt,...
		'mat',		Vi(1).mat,...
		'descrip',	'spm - algebra');
f = ['i1>mean(mean(mean(i1)))'];

Vo = spm_imcalc(Vi,Vo,f);

[o, others] = maroi_image(Vo);
o = label(o, [outFileName(1:end-4) '_roi.nii']);%set roi label
o = descrip(o, [outFileName(1:end-4) '_roi.nii']);%set roi description

roi_mask = saveroi(o, fullfile(outPath, [outFileName(1:end-4) '_roi']));