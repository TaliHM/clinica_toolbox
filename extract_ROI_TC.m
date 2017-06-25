function tc = extract_ROI_TC(rois, imgPath, file_type)

d = dir(fullfile(imgPath, file_type));
%P = cell2mat(strcat([imgPath '\'], {d.name}'));
files = { d.name }';

% making sure that the dir function does not mess with the file
% order.
str  = sprintf('%s#', files{:});
s = ['srravol_%d.nii#'];
num  = sscanf(str, s);
[dummy, index] = sort(num);
files = files(index);

P = cellstr(strcat([imgPath '\'], files));
mY = get_marsy(rois{:}, char(P), 'mean');  % extract data into marsy data object
tc = summary_data(mY); % get summary time course(s)
