function [] = saveWekaModel(varargin)
% SAVEWEKAMODEL Save Weka model to file.
% 
% Usage: saveWekaModel('/path/to/save/location', mymodel) 
%        saveWekaModel('/path/to/save/location', mymodel, false)
% 
%   Setting third input parameter to false will throw an error if
%   overwriting an existing file. Default is to overwrite. 


%% Parse inputs
if nargin < 2
    error('MATLAB:saveWekaModel', 'Not enough input arguments.');
elseif nargin > 3
    error('MATLAB:saveWekaModel', 'Too many input arguments.');
end

file_path = varargin{1};
model = varargin{2};

if nargin == 3
    overwrite = varargin{3};
else 
    overwrite = true;   % Default is to overwrite
end

% Check if file exists, overwrite or throw error
if exist(file_path, 'file')
    if overwrite
        msg = sprintf('Overwriting existing file at: %s', file_path);
        disp(msg);
    else
        error('MATLAB:saveWekaModel', 'File at %s already exists. and you set overwrite to FALSE\n%s', file_path);
    end
end

% Check that model is a weka classifier object. Otherwise throw an error.
if isempty(regexp(class(model), 'weka.classifiers', 'once'))
    error('MATLAB:saveWekaModel', 'Object supplied is not a Weka classifier: %s \n', class(model));
end

%% Try writing the object. Or (guess what) throw an error.

try 
    
%     jfile = java.io.File(java.lang.String(file_path));
%     fos = java.io.FileOutputStream(jfile);
%     oos = java.io.ObjectOutputStream(fos);
%     oos.writeObject(model);
%     oos.flush();
%     oos.close();

    weka.core.SerializationHelper.write(file_path, model);
    
catch err
    error('MATLAB:saveWekaModel', 'Error saving weka model [%s] to: %s \n', class(model), file_path);
end

end

