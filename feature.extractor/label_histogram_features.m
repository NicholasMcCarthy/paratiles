
function label_vector = label_histogram_features( varargin )
% Gets the labels for the feature vector

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 20-05-2013
% Updated: 04-06-2013

%% PARSE INPUTS

inputs = ParseInputs(varargin{:});


%% Construct label vector

label_vector = cell(1,length(inputs.Channels)*length(inputs.NumLevels)*9);

if inputs.UseStrings
    L = {'min', 'mean', 'max', 'stddev', 'variance', 'skewness', 'kurtosis', 'energy', 'entropy'};
else
    L = 1:9;
end

c = 1;                                                                   % label_vector idx
for z = inputs.Channels;                                                 % for each channel in the input image
    for nl = inputs.NumLevels                                            % for each NumLevel specified in parameter
        
        label = strcat(z, '_', num2str(nl), '_');
            
        for l = L

            if inputs.UseStrings 
                i = l;
            else 
                i = strcat('h', num2str(l));                            % h is the prefix for a histogram feature .. 
            end

            label_vector{c} = char(strcat(label, i));  % Extract features and add to feature_matrix

            c = c + 1;
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
p.addParamValue('UseStrings', false, check_use_strings);   % Can output string values for each feature
p.addParamValue('Prefix', '', @ischar);                    % Will prepend this prefix to any output labels 

p.parse(varargin{:});                                       % Parse the results

% Note: No check for alpha channel
PI.Channels = p.Results.Channels;
PI.NumLevels = p.Results.NumLevels;
PI.UseStrings = p.Results.UseStrings;
PI.Prefix = p.Results.Prefix;





