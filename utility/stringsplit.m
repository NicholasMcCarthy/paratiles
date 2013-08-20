function cellArray = stringsplit( string, delimiter )
%STRINGSPLIT Splits a string / char array into a cell array by delimiter.
% If there is no delimiter found, returns the entire input string in a cell.

% Find indices of delimiter in string
idx = regexp(string, delimiter);

% Create cell array for split values
cellArray = cell(1, length(idx));

% If idx has values 
if not(isempty(idx))
    
    % Add start and end indices 
    idx = [0 idx length(string)+1];

    % For each interval, put it in the cell array
    for i = 1:length(idx)-1;
        cellArray{i} = string(idx(i)+1:idx(i+1)-1);
    end
    
% If no delimiters found, then return the entire string in a cell    
elseif not(isempty(string))    % Presuming it's not empty .. 
    
    cellArray = mat2cell(string);
    
end
