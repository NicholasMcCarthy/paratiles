function feature_vector = extract_histogram_features( varargin )
% Constructs GLCMs from each channel of an input image and extracts
% haralick features.

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 20-05-2013
% Updated: 20-05-2013

%% PARSE INPUTS

inputs = ParseInputs(varargin{:});


%% CONSTRUCT GLCMS & EXTRACT FEATURES

feature_matrix = zeros(size(inputs.Image, 3)*length(inputs.NumLevels) ,9); %One row for each channel and number of bins

c = 1;                                                  % feature_matrix row index
for z = 1:size(inputs.Image,3);                         % for each channel in the input image
    for nl = inputs.NumLevels                           % for each NumLevel specified in parameter
        
        feature_matrix(c,:) = histogram_features_opt(inputs.Image(:,:,z), 'NumLevels', nl);  % Extract features and add to feature_matrix
        
        c = c + 1;
    end
end

% Reshape results matrix
feature_vector = reshape(feature_matrix', 1, size(feature_matrix, 1) * size(feature_matrix, 2));


function PI = ParseInputs(varargin)

% PARSE INPUT PARAMETERS
% Basically a wrapper for inputParser


% Anonymous functions for parser
check_image_dimensions = @(x) length(size(x)) == 2 || size(x, 3) == 3 ;    % Need better checks here
check_numlevels_vector = @(x) isscalar(x) || isvector(x);   % Checks if 'NumLevels' is scalar or a vector 

p = inputParser;
p.addRequired('Image', check_image_dimensions);             % Must input an image
p.addParamValue('NumLevels', 256, check_numlevels_vector);    % Defaults to 256 bins

p.parse(varargin{:});                                       % Parse the results

PI = p.Results;
   
