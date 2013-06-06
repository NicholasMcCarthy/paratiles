% Function that returns handles to some utility functions.
function [ func1 func2 ] = UtilityFunctions()

func1 = @TileToFeatureVector;
func2 = @FeatureVectorToTile;


function T = FeatureVectorToTile(FV, X, Y);

[~, Z] = size(FV);

T = reshape(FV, X, Y, Z);


function FV = TileToFeatureVector(tile)

[X Y Z ] = size(tile);

FV = reshape(tile, X*Y, Z);
