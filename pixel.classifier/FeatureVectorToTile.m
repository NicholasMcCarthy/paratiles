% FeatureVectorToTile
%   Takes as input LxP feature vector matrix (i.e. pixels with RGB[a] values)
%   Returns XxYxZ image matrix
%   Attempts to return a square image matrix.

function T = FeatureVectorToTile(FV, X, Y);

[L Z] = size(FV);

T = reshape(FV, X, Y, Z);
