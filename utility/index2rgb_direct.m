function outMatrix = indexed2RGB_direct(imageMatrix, CMap)
% This function takes an indexed image and does a direct color mapping into
% the colormap specified by CMap.
% It assumes imageMatrix is 2-D (m-by-n) array of indeces.

    index = fix(imageMatrix);
    index(find(index>length(CMap))) = length(CMap);
    index(find(index<1)) = 1;
    outMatrix = CMap(index,:);
    s = size(imageMatrix);
    m = s(1); n=s(2);
    outMatrix = reshape(outMatrix,m,n,3);
