% TileToFeatureVector
 
%   Takes as input MxNxP image matrix (i.e. pixels with RGB[a] values)
%   Returns (M*N)xP feature vector 

function FV = TileToFeatureVector(tile)

[X Y Z ] = size(tile);

FV = reshape(tile, X*Y, Z);

end


function FV = TileToFeatureVector(tile)

[X Y Z ] = size(tile);

FV = reshape(tile, X*Y, Z);

end
