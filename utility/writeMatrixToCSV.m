function [ output_args ] = writeMatrixToCSV( data, labels, folder )
% Writes a matrix object data to a specified folder.
% Each matrix column is its own .csv file, using the labels vector idx 
% as filename.

for col = 1:size(data, 2);
    
    colName = labels{col};
    
    path = strcat(folder, colName, '.csv');
    
    csvwrite(path, double(data(:,col)))
end

