function G = im2roi( image_path, s )
% This function performs tissue ROI selection on an input image.
% Input: A path colour image I, block size for reduction s
% Output: Bounding box coordinates of tissue areas in image.
%   In a biopsy, there may be 3 sets of coordinates, in RP just one. 
% 
% Author: Nicholas McCarthy
% Created: 30/05/2013
% Updated: 30/05/2013
%
% NOTE: Input image is path to image, not the image itself (to avoid
% loading entire image into memory.

%% Check inputs
parser = inputParser;

% check input is a valid file and an image or throw error

%%

myfunc = @(block_struct) mean(mean(block_struct.data));

% Reduce image dimensions by getting mean of blockproc areas 
G = blockproc(image_path, [s s], myfunc);

G = im2bw(G);                           % Convert to binary image
G = imopen(~G, strel('square', 3));      % Close holes and invert mask 
G = imfill(G, 8, 'holes');

CC = bwconncomp(G);
RP = regionprops(CC, 'BoundingBox');

% Scale coordinates back up to size of original image ?

end

