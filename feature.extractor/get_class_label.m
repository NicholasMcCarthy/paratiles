
function results = get_class_label( varargin)
%  GET_CLASS_LABEL Determines class label of an input block_struct.dataage.
%  IN: a greyscale image, optional flag for returning values as integers or
%  strings
%  OUT: string value of assigned class 
%
%  Nicholas McCarthy 2012
%  <nicholas.mccarthy@gmail.com>

%% Parse inputs

% Some anonymous validation functions
is_image = @(x) size(x, 3) == 1 && isa(x, 'uint8');   % == 1 because this should be a gray-scale image .. 
is_valid_type = @(x) strcmpi(x, 'integer') || strcmpi(x, 'string');

p = inputParser;
p.addRequired('Image', is_image);
p.addOptional('ReturnType', 'integer', is_valid_type);
p.parse(varargin{:});

I = p.Results.Image;
ReturnType = p.Results.ReturnType;


%% CLASS-LABELS AND RGB PIXEL VALUES
    
% Returns label as the mask class value
u = unique(I);

max = 0;
for ix = 1:length(u);
    if sum(I(:) == u(ix)) > max
        label = u(ix);
        max = sum(I(:) == u(ix));
    end
end

if strcmpi(ReturnType, 'string')
    label = num2str(label);

    % Convert integer values to string ..  Yeah .. (don't ask)
    label = regexprep(label, '28', 'G34');
    label = regexprep(label, '56', 'G4');
    label = regexprep(label, '85', 'G45');
    label = regexprep(label, '113', 'G5');
    label = regexprep(label, '141', 'INF');
    label = regexprep(label, '170', 'ART');
    label = regexprep(label, '198', 'TIS');
    label = regexprep(label, '255', 'NON');
    label = regexprep(label, '0', 'G3');

    results = label;
else
    results = label;
end

end

