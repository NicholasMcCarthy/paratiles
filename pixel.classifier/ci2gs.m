function G = ci2gs( I )
% Takes as input a class index image of the type returned by
% PixelClassifier
% Values in this image will have range [1 5]

G = I.*(255/5);

end

