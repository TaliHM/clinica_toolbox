function [f] = findTaskName(seriesName, file)

f = strfind(seriesName, char(file));

if isempty(f)
    % if the names are taken from the older scripts...
    switch seriesName
        case 'audvgheb'
            seriesName = 'vgaud';
            
        case 'auddefdiff'
            seriesName = 'defaud';
            
        case {'ft', 'fteasy'}
            seriesName = 'ftminus';
            f = strfind(seriesName, char(file));
            if isempty(f)
                seriesName = 'ftplus';
                f = strfind(seriesName, char(file));
            end
            
            if isempty(f)
                seriesName = 'ftminuseasy';
                f = strfind(seriesName, char(file));
                if isempty(f)
                    seriesName = 'ftpluseasy';
                end
            end
            
        case 'motorbothhands'
            seriesName = 'motorbothhandsminus';
            f = strfind(seriesName, char(file));
            if isempty(f)
                seriesName = 'motorbothhandsplus';
            end
            
        case 'motorbothlegs'
            seriesName = 'motorbothlegsminus';
            f = strfind(seriesName, char(file));
            if isempty(f)
                seriesName = 'motorbothlegsplus';
            end
            
            
            
        case 'parpar'
            seriesName = 'parparup';
            f = strfind(seriesName, char(file));
            if isempty(f)
                seriesName = 'parpardown';
                f = strfind(seriesName, char(file));
                if isempty(f)
                    seriesName = 'parparleft';
                    f = strfind(seriesName, char(file));
                    if isempty(f)
                        seriesName = 'parparright';
                    end
                end
            end
            
        case 'centerperiphery'
            seriesName = 'centerperipheryminus';
            f = strfind(seriesName, char(file));
            if isempty(f)
                seriesName = 'centerperipheryplus';
                f = strfind(seriesName, char(file));
            end
            
            
            %  seriesName = 'ftminus';
            %  case 'legs_sensory'
            %  seriesName = 'sensory_both_legs';
            %  case 'hand_sensory'
            %  seriesName = 'sensory_both_hands';
    end
end
f = strfind(seriesName, char(file));
end
