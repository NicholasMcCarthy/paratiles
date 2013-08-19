function model = loadWekaModel( file_path)
%LOADWEKAMODEL Load a saved Weka model from file.
% It is possible to use models created using Weka explorer or from other 
% code-bases provided the models have been saved using 
% weka.core.SerializationHelper (or equivelent outputstream).
%
%   Input: Path to a valid saved Weka model.
%
%   Output: Weka model.

if ~exist(file_path, 'file')
    msg = sprintf('No file found at: %s', file_path);
    disp(msg);
end

try
    
    model = weka.core.SerializationHelper.read(file_path);
    
catch err

    error('MATLAB:loadWekaModel', 'There was an error reading model object at: %s\n%s', file_path, err.message);

end

end
