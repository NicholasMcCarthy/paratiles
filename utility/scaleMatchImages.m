function G = scaleMatchImages( varargin )
%SCALEMATCHIMAGES Scales an input image I to match the given X and Y
% dimension lengths. If 'pad' option set will repeat borders to match size.

% Input:
%           I       - An image I to be rescaled
%           X       - X dimension width to scale I to.
%           Y       - Y dimension height to scale I to.
%           pad     - Boolean value, will pad border values if scaling is
%                       not exact

%% Parse Inputs
p = inputParser;

p.addRequired('Image', @isnumeric);
p.addRequired('X', @isnumeric);
p.addRequired('Y', @isnumeric);
p.addParamValue('Type', 'nearest', @(x) any(strcmp(x, {'nearest', 'bilinear', 'bicubic'})));
p.addParamValue('Pad', 0, @(x) x == true || x == false);

p.parse(varargin{:});


I = p.Results.Image;
X = p.Results.X;
Y = p.Results.Y;
pad = p.Results.Pad;
type = p.Results.Type;


%% Main function

% Check X and Y scaled dimensions are the same -> no skewing of image
[Xa Ya Za] = size(I);

if ~( round((X / Xa)) == round((Y / Ya)) )
    error('MATLAB:scaleMatchImages', 'Cannot linearly scale image with specified dimensions widths.');
end

% Determine scale factor ..

scaleFactor = X / Xa;

G = imresize(I, scaleFactor, type, 'Dither', true);

end

