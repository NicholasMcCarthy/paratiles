function im_rgb = rgb2cielab( im_lab )
% Converts input RGB image to CIEL*a*b* colorspace

C = makecform('lab2srgb');

im_rgb = applycform(im_lab, C);
