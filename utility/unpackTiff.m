function [selected_files image_info numIFDs] = unpackTiff( varargin )
% UNPACKTIFF % Splits a large multi-IFD TIFF Image
% Uses the 'tiffsplit' function from the libtiff library

% Input:    Pathname to a valid multilayer .tiff or .scn image
%           IFD Layer, a valid 

% Output:   Pathname to tiffsplit'd layer(s) 

%% Parse inputs

p = inputParser;

p.addRequired('Filepath', @(x) exist(x, 'file') ~= 0)
p.addRequired('IFD', @(x) isnumeric(x) || all(arrayfun(@isnumeric, x)));    % 
p.addOptional('Force', 0, @(x) x==true || x==false);

p.parse(varargin{:});

file_path = p.Results.Filepath;
IFD = p.Results.IFD;

% Assuming that file_path is a valid .tiff or .scn image

% 1. Check file_path is a valid file

% Assuming that file_path is a valid .tiff or .scn image

for i = 1:length(IFD)
    fprintf('Unpacking %s[%i] \n', file_path, IFD(i));
end

% 1. Check file_path is a valid file
if exist(file_path, 'file') == 0
    msg = sprintf('%s is an invalid file', file_path);
    error('MATLAB:unpackTiff', msg);
end

if p.Results.Force == 0 % i.e., not checking the image very hard ..
    
%     disp('Not forcing image.. (gently)');
    

    % 2. Check that file_path points to a valid image.
    try
        image_info = imfinfo(file_path);
    catch
        msg = (sprintf('%s is not a valid image', file_path));
        error('MATLAB:unpackTiff', msg);
    end
    
    % 3. Check the selected IFD is within bounds
    % Requires 'imagemagick' function

    T = Tiff(file_path);

    stop = 0;

    while stop == 0
        try 
            T.nextDirectory;
        catch   % Using the exception catch here to determine the number of IFDs in image .. (yes, I know)
            stop = 1;
        end
    end

    numIFDs = T.currentDirectory;
    T.setDirectory(1);

    if IFD > numIFDs
        msg = (sprintf('Invalid IFD specified. Image contains %i IFDs.', numIFDs));
        error('MATLAB:unpackTiff', msg);
    end
else
%     disp('Forcing image (may break and stuff)');
end

% 4. Tiffsplit the image 

file_prefix = [ '.' fliplr(strtok(fliplr(file_path), '.'))];

tiffsplit_prefix = regexprep(file_path, file_prefix, '_'); % Replace .tif with file identifier

tiffsplit_cmd = sprintf('tiffsplit %s %s', file_path, tiffsplit_prefix);

system(tiffsplit_cmd);

% 5. Get selected files file_path_aaa.tif 

selected_files = cell(1,length(IFD));

for i = 1:length(IFD)
    % char(96+IFD) should refer to correct char identifier for selected IFD
    selected_file = regexprep(file_path, file_prefix, sprintf('_aa%s.tif', char(96+IFD(i))));
    
    if ~exist(selected_file, 'file')
        msg = (sprintf('Something went wrong, unpacked Tiff does not exist!'));
        error('MATLAB:unpackTiff', msg);
    end
    
    selected_files{i} = selected_file;
end

disp('Image unpacked!');

end

