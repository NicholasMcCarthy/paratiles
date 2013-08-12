function [selected_file image_info numIFDs] = unpackTiff( varargin )
% UNPACKTIFF % Splits a large multi-IFD TIFF Image
% Uses the 'tiffsplit' function from the libtiff library

% Input:    Pathname to a valid multilayer .tiff or .scn image
%           IFD Layer, a valid 

%% Parse inputs

p = inputParser;

p.addRequired('Filepath', @(x) exist(x, 'file') ~= 0)
p.addRequired('IFD', @isnumeric);
p.addOptional('Force', 0, @(x) x==true || x==false);

p.parse(varargin{:});

file_path = p.Results.Filepath;
IFD = p.Results.IFD;

% Assuming that file_path is a valid .tiff or .scn image

% 1. Check file_path is a valid file

% Assuming that file_path is a valid .tiff or .scn image

fprintf('Tiffsplitting image %s[%i] \n', file_path, IFD);

% 1. Check file_path is a valid file

if exist(file_path, 'file') == 0
    msg = sprintf('%s is an invalid file', file_path);
    error('MATLAB:unpackTiff', msg);
end


if p.Results.Force == 0 % i.e., not checking the image very hard ..
    
    disp('Not forcing image.. (gently)');
    

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
    disp('Forcing image (may break and stuff)');
end

% 4. Tiffsplit the image 

file_prefix = [ '.' fliplr(strtok(fliplr(file_path), '.'))];

tiffsplit_prefix = regexprep(file_path, file_prefix, '_'); % Replace .tif with file identifier

tiffsplit_cmd = sprintf('tiffsplit %s %s', file_path, tiffsplit_prefix);

system(tiffsplit_cmd);

% 5. Get selected files file_path_aaa.tif 

% char(96+IFD) should refer to correct char identifier for selected IFD
selected_file = regexprep(file_path, file_prefix, sprintf('_aa%s.tif', char(96+IFD))); 

if ~exist(selected_file, 'file')
    msg = (sprintf('Something went wrong, unpacked Tiff does not exist!'));
    error('MATLAB:unpackTiff', msg);
end

end

