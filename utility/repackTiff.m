function [status] = repackTiff( varargin )
%REPACKTIFF Given an input file, cleans up any remaining tiffsplit IFD images.
% 
% Inputs:	
%           pathname	- Path to a valid multilayer .tiff (i.e. .scn image)
%           debug       - Boolean value to display print commands while
%                        executing.
%
% Output:   
%           status      - Status returned by system rm function.
%
% See also: unpackTiff

%% Parse inputs

p = inputParser;

p.addRequired('Filepath', @(x) exist(x, 'file') ~= 0)
p.addOptional('Debug', 0, @(x) x==true || x==false);

p.parse(varargin{:});

file_path =  p.Results.Filepath;
print_debug = p.Results.Debug;

%%

if print_debug; fprintf('repackTiff(%s)', file_path); end

file_prefix = [ '.' fliplr(strtok(fliplr(file_path), '.'))];

tiffsplit_wildcard = regexprep(file_path, file_prefix, '_aa*'); % Replace .tif with file identifier

%deleted_files = ls(tiffsplit_wildcard);

rm_cmd = sprintf('rm %s', tiffsplit_wildcard);


if print_debug; fprintf('Running command: \n \t%s\n', rm_cmd); end;

status = system(rm_cmd);

end