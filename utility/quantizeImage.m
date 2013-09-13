function G = quantizeImage( I, quanta)
%QUANTIZEIMAGE Quantizes an input image 

I = double(I) / 255;
I = uint8(I * quanta);
G = double(I) / quanta;

end