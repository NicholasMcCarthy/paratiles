function [FV, GLCM] = GLCMVector( varargin )
%GLCMVECTOR Returns a vector of total-adjacency GLCM values. 
% The GLCM is calculated symmetrically, thus only the upper triangle values
% of the GLCM are returned (to avoid duplication). 
%
% Inputs: 
%   -   A gray scale / single channel of RGB image
%   -   'Offsets' : offsets for GLCM calculation
%   -   'GrayLimits' : graylimits for GLCM calculation
%   -   'NumLevels' : numlevels for GLCM calculation
%
%   See: 'help graycomatrix' for further details on offsets, graylimits and
%           numlevels.
% 

default_offsets =  [ 0 1 ; -1 1 ; -1 0 ; -1 -1 ];      % Offsets for 0, 45, 90, 135 degree angles
default_graylimits = [0 255];                          % Default gray limits . .
default_numlevels = 255;                               % Default number of bins

is_single_channel_image = @(I) any(cellfun(@(x) strcmp(x, class(I)), {'uint8', 'double'}) & size(I, 3) == 1);

p = inputParser;

p.addRequired('Image', is_single_channel_image);
p.addParamValue('Offsets', @isnumeric);
p.addParamValue('GrayLimits',  @isnumeric);
p.addParamValue('NumLevels',  @isnumeric);

p.parse(varargin{:});

image = p.Results.Image;
offsets = p.Results.Offsets;
numlevels = p.Results.NumLevels;
graylimits = p.Results.GrayLimits;

% Obtain GLCM
glcm = graycomatrix(image(:,:,1), 'Offset', offsets, 'NumLevels', numlevels, 'GrayLimits', graylimits, 'Symmetric', true); 

% Sum GLCMs in each direction
GLCM = (glcm(:,:,1) + glcm(:,:,2) + glcm(:,:,3) + glcm(:,:,4));

% Normalize GLCM to unit range 
gmax = max(max(GLCM));
gmin = min(min(GLCM));

GLCM = GLCM - gmin;
GLCM = GLCM ./ (gmax-gmin);

% Pre-allocate feature vector 
N = size(GLCM, 1); % i.e. numlevels
FV = zeros(1, (N*(N+1))/2);

i = 1;
for x = 1:N
    for y = x:N
        FV(i) = GLCM(x,y);
        i= i+1;
    end
end

