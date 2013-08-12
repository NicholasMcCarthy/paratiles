function G = im2thumb( I, tilesize )
% IM2THUMB 
% Given a (very large) image or image path, create a thumbnail using mean
% colour values in the specified tilesize area.

if isa(I, 'uint8') || isa(I, 'double')
    [X Y Z] = size(I);
elseif exist(I, 'file') ~= 0
    info = imfinfo(I);
    X = info.Width;
    Y = info.Height;
    Z = info.BitDepth/8;
end

if Z == 3
    thumb_func = @(I) shiftdim([round(mean2(I.data(:,:,1))) round(mean2(I.data(:,:,2))) round(mean2(I.data(:,:,3)))], -1);
elseif Z == 1
    thumb_func = @(I) shiftdim(round(mean2(I.data)));
else
    msg = sprintf('Invalid dimensions in parameter image.');
    error('MATLAB:im2thumb', msg);
end

G = blockproc(I, [tilesize tilesize], thumb_func);

G = uint8(G);

end

