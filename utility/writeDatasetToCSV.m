function [ output_args ] = writeDatasetToCSV( D, folder )
% Writes a dataset object D to a specified folder.
% Each dataset column is its own .csv file, using the dataset column header
% as filename.

if (~isa(D, 'dataset'))
    error('writeDatasetToCSV', 'Input must be a dataset object');
end

for col = 1:size(D, 2);
    
    colName = D.Properties.VarNames{col};
    
    path = strcat(folder, colName, '.csv');

    csvwrite(path, double(D(:,col)))
end

