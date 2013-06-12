function stats = histogram_features( varargin )
% ------------
% Description:
% ------------
%  This function returns first-order statistical features computed from
%  histograms:
%   Minimum     - Minimum intensity value in image.
%   Mean        - Average value of total number of intensity values.
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
% Updated by:
% ------------
%     Nick McCarthy <nicholas.mccarthy@gmail.com>
%       University College Dublin, Complex and Adaptive Systems Laboratory
%   
%

% Parameter checking
[I, NL, GL] = ParseInputs(varargin{:});
% Scale I so that it contains integers between 1 and NL.
if GL(2) == GL(1)
    SI = ones(size(I));
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

%--------------------------------------------------------------------------
% 1. Calculate histogram for all scaled gray level from 1 to NL
%--------------------------------------------------------------------------
% Get image size
s = size(SI);
% Generate gray level vector
Gray_vector = 1:NL;
% intialize parameters
Histogram = zeros(1,NL);

% Note: Switched this loop to use sum(sum()) as it is about twice as fast 
%       as using numel + find - NM

% Using inline function numel, make it easy
% for i =1:NL
%     Histogram(i) = numel(find(SI==i));
% end

for i = 1:NL
    Histogram(i) = sum(sum(SI==i));
end

%--------------------------------------------------------------------------
% 2. Now calculate its histogram statistics
%--------------------------------------------------------------------------
% Calculate obtains the approximate probability density of occurrence of the intensity
% levels

Prob                = Histogram./(s(1)*s(2));  % Histogram to probability mass function
% Return values
Minimum             = min(min(SI));

Mean                = sum(Prob.*Gray_vector);

Maximum             = max(max(SI));

% This calculates stddev incorrectly, replacing it. - NM
% StdDev              = std(std(SI));
StdDev              = std(SI(:)) ;

% An alternative (slower) 
% StdDev             = sqrt(mean2(arrayfun(@(x) abs(x - Mean)^2, SI)));

Variance            = sum(Prob.*(Gray_vector-Mean).^2);

Skewness            = calculateSkewness(Gray_vector,Prob,Mean,Variance);

Kurtosis            = calculateKurtosis(Gray_vector,Prob,Mean,Variance);

Energy              = sum(Prob.*Prob);

% Entropy             = -sum(Prob.*log(Prob)); 
% log(0) = -Inf       % Causes a NaN error when summing Entropy value
% Replacing with code below, which ignores NaN values - NM

En                  = Prob.*log(Prob);
Entropy             = -sum(En(~isnan(En)));

%-------------------------------------------------------------------------
% 3. Insert all features and return
%--------------------------------------------------------------------------

stats = [Minimum Mean Maximum StdDev Variance Skewness Kurtosis Energy Entropy];

% End of funtion
%--------------------------------------------------------------------------
% Utility functions
%--------------------------------------------------------------------------
function Skewness = calculateSkewness(Gray_vector,Prob,Mean,Variance)
% Calculate Skewness
term1    = Prob.*(Gray_vector-Mean).^3;
term2    = sqrt(Variance);
Skewness = term2^(-3)*sum(term1);

function Kurtosis = calculateKurtosis(Gray_vector,Prob,Mean,Variance)
% Calculate Kurtosis
term1    = Prob.*(Gray_vector-Mean).^4;
term2    = sqrt(Variance);
Kurtosis = term2^(-4)*sum(term1);

function [I, nl, gl] = ParseInputs(varargin)
% parsing parameter checking
% Inputs must be max seven item
iptchecknargin(1,5,nargin,mfilename);
%
% Check I
I = varargin{1};
iptcheckinput(I,{'logical','numeric'},{'2d','real','nonsparse'}, ...
    mfilename,'I',1);
% ------------------------
% Assign Defaults
% -------------------------
%
if islogical(I)
    nl = 2;
else
    nl = 8;
end
gl = getrangefromclass(I);

% Parse Input Arguments
if nargin ~= 1

    paramStrings = {'NumLevels','GrayLimits'};

    for k = 2:2:nargin

        param = lower(varargin{k});
        inputStr = iptcheckstrs(param, paramStrings, mfilename, 'PARAM', k);
        idx = k + 1;  %Advance index to the VALUE portion of the input.
        if idx > nargin
            eid = sprintf('Images:%s:missingParameterValue', mfilename);
            msg = sprintf('Parameter ''%s'' must be followed by a value.', inputStr);
            error(eid,'%s', msg);
        end

        switch (inputStr)
            case 'NumLevels'
                nl = varargin{idx};
                iptcheckinput(nl,{'logical','numeric'},...
                    {'real','integer','nonnegative','nonempty','nonsparse'},...
                    mfilename, 'NL', idx);
                if numel(nl) > 1
                    eid = sprintf('Images:%s:invalidNumLevels',mfilename);
                    msg = 'NL cannot contain more than one element.';
                    error(eid,'%s',msg);
                elseif islogical(I) && nl ~= 2
                    eid = sprintf('Images:%s:invalidNumLevelsForBinary',mfilename);
                    msg = 'NL must be two for a binary image.';
                    error(eid,'%s',msg);
                end
                nl = double(nl);

            case 'GrayLimits'

                gl = varargin{idx};
                iptcheckinput(gl,{'logical','numeric'},{'vector','real'},...
                    mfilename, 'GL', idx);
                if isempty(gl)
                    gl = [min(I(:)) max(I(:))];
                elseif numel(gl) ~= 2
                    eid = sprintf('Images:%s:invalidGrayLimitsSize',mfilename);
                    msg = 'GL must be a two-element vector.';
                    error(eid,'%s',msg);
                end
                gl = double(gl);
        end
    end
end

