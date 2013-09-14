function selected_files = getTiffLayer( varargin )
%GETTIFFLAYER Returns the filepath of a tiff IFD layer after the base
%(multi-layer) Tiff has been split using tiffsplit.
% Input:
%            filepath   -   Path to multilayer image.
%            IFD        -   IFD to get path to.
%            force      -   Throw an error if the image layer is not found. (Default: true)
%
%	See also: unpackTiff, repackTiff

%% Parse inputs
p = inputParser;

p.addRequired('Filepath', @(x) exist(x, 'file') ~= 0)
p.addRequired('IFD', @(x) isnumeric(x) || all(arrayfun(@isnumeric, x))); 
p.addOptional('Force', 1, @(x) x==true || x==false);

p.parse(varargin{:});

file_path = p.Results.Filepath;
IFD = p.Results.IFD;
force = p.Results.Force;

%% 
% Determines file prefix of input image
file_prefix = [ '.' fliplr(strtok(fliplr(file_path), '.'))];

% Cell array for files
selected_files = cell(1,length(IFD));

for i = 1:length(IFD)

    selected_file = regexprep(file_path, file_prefix, sprintf('_aa%s.tif', char(96+IFD(i))));

    if ~exist(selected_file, 'file')
        if force
            error('MATLAB:unpackTiff', 'Something went wrong: %s [%i] not found!', file_path, i);
        end
    end

    selected_files{i} = selected_file;
end
    
end

