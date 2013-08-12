function [ output_args ] = unpackTiff( file_path, IFD )
% UNPACKTIFF % Splits a large multi-IFD TIFF Image
% Uses the 'tiffsplit' function from the libtiff library

% Input:    Pathname to a valid multilayer .tiff or .scn image
%           IFD Layer, a valid 


% Assuming that file_path is a valid .tiff or .scn image

alphabet = 'abcdefghijklmnopqrstuvwxyz'; % Needed for selecting tiffsplit files

% 1. Check file_path is a valid file

if exist(file_path, 'file') == 0
    msg = sprintf('%s is an invalid file', file_path);
    error('MATLAB:unpackTiff', msg);
end

% 2. Check that file_path points to a valid image.

try
    image_info = imfinfo(file_path);
catch
    msg = sprintf('%s is not a valid image', file_path);
    error('MATLAB:unpackTiff', msg);
end

% 3. Check the selected IFD is within bounds
% Requires 'imagemagick' function

T = Tiff(file_path);

if IFD > T.lastDirectory
    msg = sprintf('Invalid IFD specified. Image contains %i IFDs.', T.lastDirectory);
    error('MATLAB:unpackTiff', msg);
end



% 4. Tiffsplit the image 

tiffsplit_prefix = regexprep(file_path, '.tif', '_'); % REplace .tif with file identifier

cmd = sprintf('tiffsplit %s %s', file_path, tiffsplit_prefix);

[status cmdout] = system(cmd);

% 5. Get selected files file_path_aaa.tif 

selected_file = regexprep(file_path, '.tif', sprintf('_aa%s.tif', alphabet(IFD))); % Should refer to the selected IFD

end

