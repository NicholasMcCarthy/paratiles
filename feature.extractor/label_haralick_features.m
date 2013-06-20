
function label_vector = label_haralick_features( varargin )
% Gets the labels for the feature vector

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 20-05-2013
% Updated: 04-06-2013

%% PARSE INPUTS

inputs = ParseInputs(varargin{:});

%% Build cell array of labels for specified Haralick parameters

label_vector = cell(1,inputs.NumGLCMs*15);

if inputs.UseStrings
    L = {'energy', 'contrast', 'corr', 'sumofvar', 'idm', 'sumavg', 'sumvar', 'sument', ...
        'entropy', 'diffvar', 'diffent', 'infocorr1', 'infocorr2', 'cshad', 'cprom'};
else
    L = 1:15;
end

c = 1;                                                  % feature_matrix row index

% Labels generated in this order because it will be done the same way in
% extract_haralick_features function
for z = inputs.Channels;                                % For each specified channel
    for nl = inputs.NumLevels                       % For each specified quantization
        for d = inputs.Distances                            % For each specified distance

            label = strcat(z, '_q', num2str(nl), '_d', num2str(d), '_');
            
            for l = L
                
                if inputs.UseStrings 
                    i = l;
                else 
                    i = strcat('f', num2str(l));
                end
                
                label_vector{c} = char(strcat(label, i));  % Extract features and add to feature_matrix

                c = c + 1;
            end
            
        end
    end
end

% Prepend prefix if one is specified
if ~isempty(inputs.Prefix)
    label_vector = cellfun(@(x) strcat(inputs.Prefix, '_', x), label_vector, 'UniformOutput', false);
end


function PI = ParseInputs(varargin)

% Workaround for having a required value with paramvalue 
if (~strcmpi(varargin{1}, 'channels')) 
    error('label_haralick_features::Must supply a channels arguments');
end

% Anonymous functions for parser
check_scalar_vector = @(x) isscalar(x) || isvector(x);
check_use_strings = @(x) islogical(x);

p = inputParser;
p.addParamValue('Channels', 'I', @iscellstr);              % 
p.addParamValue('NumLevels', 256, check_scalar_vector);    % Defaults to GLCM with 256 bins
p.addParamValue('Distances', 1, check_scalar_vector);      % Defaults to pixel distance 1
p.addParamValue('UseStrings', false, check_use_strings);   % Can output string values for each feature
p.addParamValue('Prefix', '', @ischar);                    % Will prepend this prefix to any output labels

p.parse(varargin{:});                                       % Parse the results

NumGLCMs = length(p.Results.NumLevels) * length(p.Results.Distances) * length(p.Results.Channels); % Number of bins * number of channels GLCMs can be calculated on.

% Note: No check for alpha channel
PI.Channels = p.Results.Channels;
PI.Distances = p.Results.Distances;
PI.NumLevels = p.Results.NumLevels;
PI.UseStrings = p.Results.UseStrings;
PI.Prefix = p.Results.Prefix;
PI.NumGLCMs = NumGLCMs;





