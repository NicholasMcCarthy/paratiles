function im_lab = rgb2cielab( im_rgb )
% Converts input RGB image to CIEL*a*b* colorspace

C = makecform('srgb2lab');

im_lab = applycform(im_rgb, C);