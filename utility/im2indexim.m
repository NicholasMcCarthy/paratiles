function G = im2indexim( I )
% IM2INDEXIM - Converts unique values in a matrix to a continuous index.
% Example:
%   Given an image I that has 10 unique values [10,20,22,26,30,150, ...]
%   this function will convert it to an output image G that has converted
%   each unique value to the range 1..10

%% Parse inputs 

% TO-DO


%% 

% Some binning should probably be done when number of unique values is
% greater than 255 as colormaps in matlab will generally not display more
% than this. 

% Also, adaptive binning when specifying the number of indexes to convert
% to.

G = I;
U = unique(I);

idx = 0;
for u = 1:length(U)
    
    G(G == U(u)) = idx;
    idx = idx + 1;
end

