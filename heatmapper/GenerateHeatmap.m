function hmap = GenerateHeatmap( varargin )
% Generates a heatmap.
% Input: A matrix of tile classification labels
% Output: A heatmap matrix

%% Parse Inputs

inputs = ParseInputs(varargin);

end

function inputs = ParseInputs(varargin)

p = inputParser;

clsimgvalidator = @(x) validateattributes(x, {'numeric'}, {'2d'}); % This could be handled better ..
colormapvalidator = @(x) validateattributes(x, {'double'}, {'2d'});

p.addRequired('ImageLabels', clsimgvalidator);
p.addParamValue('Colormap', colormap(jet(10)), colormapvalidator) % American english :F 

end