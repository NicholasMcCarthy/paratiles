function [ output_args ] = writeMatrixToCSV( data, labels, folder )
% Writes a dataset object D to a specified folder.
% Each dataset column is its own .csv file, using the dataset column header
% as filename.

for col = 1:size(data, 2);
    
    colName = labels{col};
    
    path = strcat(folder, colName, '.csv');

    csvwrite(path, double(data(:,col)))
end

