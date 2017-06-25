function subInit = createSubInitials(subInfo)

subName = subInfo.name;
s = strsplit(subName, {'_', ' '});

switch size(s,2)
    case 1
        errordlg('Subject with one name?!.. are you sure?');
    case 2
        subInit = upper([s{1}(1:2) s{2}(1:2)]);
    case 3
        n = str2double(s{1});
        if isnumeric(n) && ~isnan(n)
            % it's an eeg-fmri session that starts with a number
            subInit = upper([s{2}(1:2) s{3}(1:2)]);
        else
            subInit = upper([s{1}(1:2) s{2}(1) s{3}(1)]);
        end
    case 4
        n = str2double(s{1});
        if isnumeric(n) && ~isnan(n)
            % it's an eeg-fmri session that starts with a number
            subInit = upper([s{2}(1:2) s{3}(1) s{4}(1)]);
        else
            subInit = upper([s{1}(1) s{2}(1) s{3}(1) s{4}(1)]);
        end
    case 5
        n = str2double(s{1});
        if isnumeric(n) && ~isnan(n)
            % it's an eeg-fmri session that starts with a number
            subInit = upper([s{2}(1) s{3}(1) s{4}(1) s{5}(1)]);
        else
            subInit = upper([s{1}(1) s{2}(1) s{3}(1) s{4}(1) s{5}(1)]);
        end
        
end
end
