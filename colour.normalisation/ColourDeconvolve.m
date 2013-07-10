
function G = ColourDeconvolve( varargin )

% This function performs colour deconvolution of an input image.

% Input: a H&E stained colour image I
% Output: a colour image G which has been deconvolved using preset H&E
% deconvolution values

% NOTE: Currently using just preset H&E values, input parameters are set to
% allow a separate deconvolution matrix to be supplied but as there is
% currently no way to obtain this you should probably avoid doing this
% (unless you really know what you're doing).


%% Presets

% H&E Preset value
OD_Preset = [0.18 0.20 0.08 ; 0.01 0.13 0.01 ; 0.10 0.21 0.29];

%% Parse inputs
p = inputParser;

is_image = @(I) isnumeric(I) && size(I, 3) == 3;
is_od_matrix = @(x) size(x, 1) == 3 && size(x, 2) == 3;

p.addRequired('Image', is_image);
p.addOptional('ODMatrix', OD_Preset, is_od_matrix);

p.parse(varargin{:});

I = p.Results.Image;
H = p.Results.ODMatrix;

%% Normalize OD Matrix

for r = 1:3
	H(r,:) = H(r,:) ./sqrt(sum(H(r,:).^2));
end


%% Colour deconvolve

[X Y Z] = size(I);  % Image dimensions

G = double(I);                  % Convert image to double
G = reshape(G, X*Y, Z);     % Reshape image to row vector (each row is a pixel triplet)
G = G';                              % Flip row vector so each column is a pixel triplet (purely for matlab matrix multiplication)

for r = 1:size(G, 2)            % I hope I'm doing this bit right .. 
    G(:,r) = H * G(:,r);
end

G = uint8(G);                    % Convert deconvolved values back to uint8
G = G';                              % Flip pixel column vectors
G = reshape(G, X, Y, Z);    % And reshape to original dimensions

end

