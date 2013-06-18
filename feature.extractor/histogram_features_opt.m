function stats = histogram_features_opt( varargin )
% ------------
% Description:
% ------------
%  This function returns first-order statistical features computed from
%  histograms:
%   Minimum     - Minimum intensity value in image.
%   Mean        - Mean intensity value in image.
%   Maximum     - Maximum intensity value in image.
%   StdDev      - Standard Deviation of pixel intensities in image.
%   Variance    - Distance of each value from the mean
%   Skewness    - The asymmetry about the mean in intensity level distribution.
%   Kurtosis    - Kurtosis of histogram
%   Energy      - Energy of .,f f
%   Entropy     - etc..

% ---------
% Created: 28/04/2012
%----------
% Author:
% -----------
%    (C)Xunkai Wei <xunkai.wei@gmail.com>
%    Beijing Aeronautical Technology Research Center
%    Beijing %9203-12,10076
% 
% ------------
% Updated: 12/06/2013
% ------------
% By:
% ------------
%     Nick McCarthy <nicholas.mccarthy@gmail.com>
%       University College Dublin, Complex and Adaptive Systems Laboratory
%   
%% Check Parameters

[I, NL, GL] = ParseInputs(varargin{:});


%% Scale image to specified number of levels.

if GL(2) == GL(1)                       
    SI = ones(size(I));                         % If graylimits are equal, scaled image is just ones
else                                    
    slope = (NL-1) / (GL(2) - GL(1));
    intercept = 1 - (slope*(GL(1)));
    SI = round(imlincomb(slope,I,intercept,'double'));
end

% Clip values if user had a value that is outside of the range, e.g., double
% image = [0 .5 2;0 1 1]; 2 is outside of [0,1]. The order of the following
% lines matters in the event that NL = 0.
SI(SI > NL) = NL;
SI(SI < 1) = 1;             %% <- And for 0 values?

%% Calculate histogram

[X Y Z] = size(SI);         % Get image size
Gray_vector = 1:NL;         % Generate gray level vector
Histogram = zeros(1,NL);    % Preallocate histogram vector

for i = 1:NL
    Histogram(i) = sum(sum(SI==i));
end

%% Calculate histogram statistics
% Calculate obtains the approximate probability density of occurrence of the intensity
% levels

Prob                = Histogram./(X*Y);         % Histogram to probability mass function

Minimum             = min(min(SI));

Maximum             = max(max(SI));

Mean                = sum(Prob.*Gray_vector);

% -----------------------------

tt = (Gray_vector - Mean);

Variance    = sum(Prob.*(tt.^2));

StdDev      = sqrt(Variance);
% StdDev = std(SI(:));

SK = zeros(1, 2); 

for i = 1:2
    k = i+2;
    SK(i) = StdDev^(-k)*sum(Prob.*(tt.^k));
end

Skewness = SK(1);
Kurtosis = SK(2);

% Skewness = calculateSkewness(Gray_vector, Prob, Mean, StdDev);
% Skewness = skewness(SI(:));  % SLOW

% Kurtosis = calculateKurtosis(Gray_vector, Prob, Mean, StdDev);
% Kurtosis = kurtosis(SI(:)); % SLOW

Energy              = sum(Prob.*Prob);

% Entropy             = -sum(Prob.*log(Prob)); 
% log(0) = -Inf       % Causes a NaN error when summing Entropy value
% Replacing with code below, which ignores NaN values - NM

En                  = Prob.*log(Prob);
Entropy             = -sum(En(~isnan(En)));

stats = [Minimum Mean Maximum StdDev Variance Skewness Kurtosis Energy Entropy];

function [I, nl, gl] = ParseInputs(varargin)

p = inputParser;

imagevalidator      = @(x) validateattributes(x, {'logical', 'numeric'}, {'2d', 'real', 'nonsparse'}, 'histogram_features_opt', 'the input image');
numlevelsvalidator  = @(x) isnumeric(x) & isscalar(x);
graylimitsvalidator = @(x) isnumeric(x) & isvector(x) & size(x, 2) == 2 ;

p.addRequired('Image', imagevalidator);
p.addParamValue('NumLevels', [], numlevelsvalidator);
p.addParamValue('GrayLimits', [], graylimitsvalidator);

p.parse(varargin{:});

% ---------------
% Assign Defaults
% ---------------

if isempty(p.Results.NumLevels)
    
    if islogical(p.Results.Image)
        nl = 2;
    else
        nl = 8;
    end
else
    nl = p.Results.NumLevels;
end

if isempty(p.Results.GrayLimits)
    gl = getrangefromclass(p.Results.Image);
else
    gl = p.results.GrayLimits;
end

I = p.Results.Image;

 
% % Parse Input Arguments
% if nargin ~= 1
% 
%     paramStrings = {'NumLevels','GrayLimits'};
% 
%     for k = 2:2:nargin
% 
%         param = lower(varargin{k});
%         inputStr = iptcheckstrs(param, paramStrings, mfilename, 'PARAM', k);
%         idx = k + 1;  %Advance index to the VALUE portion of the input.
%         if idx > nargin
%             eid = sprintf('Images:%s:missingParameterValue', mfilename);
%             msg = sprintf('Parameter ''%s'' must be followed by a value.', inputStr);
%             error(eid,'%s', msg);
%         end
% 
%         switch (inputStr)
%             case 'NumLevels'
%                 nl = varargin{idx};
%                 iptcheckinput(nl,{'logical','numeric'},...
%                     {'real','integer','nonnegative','nonempty','nonsparse'},...
%                     mfilename, 'NL', idx);
%                 if numel(nl) > 1
%                     eid = sprintf('Images:%s:invalidNumLevels',mfilename);
%                     msg = 'NL cannot contain more than one element.';
%                     error(eid,'%s',msg);
%                 elseif islogical(I) && nl ~= 2
%                     eid = sprintf('Images:%s:invalidNumLevelsForBinary',mfilename);
%                     msg = 'NL must be two for a binary image.';
%                     error(eid,'%s',msg);
%                 end
%                 nl = double(nl);
% 
%             case 'GrayLimits'
% 
%                 gl = varargin{idx};
%                 iptcheckinput(gl,{'logical','numeric'},{'vector','real'},...
%                     mfilename, 'GL', idx);
%                 if isempty(gl)
%                     gl = [min(I(:)) max(I(:))];
%                 elseif numel(gl) ~= 2
%                     eid = sprintf('Images:%s:invalidGrayLimitsSize',mfilename);
%                     msg = 'GL must be a two-element vector.';
%                     error(eid,'%s',msg);
%                 end
%                 gl = double(gl);
%         end
%     end
% end

