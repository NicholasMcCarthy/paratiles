function D = mymat2dataset( mat, labels )
% Creates a dataset object from an input matrix and vector of labels
% Input: a matrix of data mat, cell array of labels 
% Output: dataset object

% Note: Created this function because my matlab version doesn't have
% mat2dataset function. Nick M. 

if (size(mat, 2) ~= size(labels, 2))
    error('Parameter matrix and labels should have same number of columns.');
elseif (~iscell(labels))
    error('Labels must be a cell array.');
end;
    
D = dataset();

for i = 1:size(mat, 2)
    
    D = horzcat(D, dataset(mat(:,i), 'VarNames', labels{i}));

end

