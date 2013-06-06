
function ret = validateInput(cellstr) 

    ret = true;
    for i = 1:length(cellstr)
        
        if ~exist(char(cellstr(i)), 'file');
            ret = false;
            break;
        end
    end
end