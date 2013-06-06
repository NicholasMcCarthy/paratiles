% Function to convert colour masks images to grayscale
function G = convert_image (im);

[X Y Z] = size(im);

G = uint8(ones(X, Y));

for x = 1:X
    for y = 1:Y
        
        if (    im(x, y, 1) == 255 && im(x, y, 2) == 255 && im(x, y, 3) == 0)     % GG3 (255, 255, 0)   -> 0
            G(x, y) = 0;
        elseif (im(x, y, 1) == 255 && im(x, y, 2) == 128 && im(x, y, 3) == 0)     % GG34 (255, 128, 0)  -> 28
            G(x, y) = 28;
        elseif (im(x, y, 1) == 0   && im(x, y, 2) == 255 && im(x, y, 3) == 0)     % GG4  (0, 255, 0)    -> 56
            G(x, y) = 56;
        elseif (im(x, y, 1) == 128 && im(x, y, 2) == 0   && im(x, y, 3) == 255)   % GG45 (128, 0, 255)  -> 85
            G(x, y) = 85;
        elseif (im(x, y, 1) == 0   && im(x, y, 2) == 0   && im(x, y, 3) == 255)   % GG5  (0, 0, 255)    -> 113
            G(x, y) = 113;
        elseif (im(x, y, 1) == 0   && im(x, y, 2) == 0   && im(x, y, 3) == 0)     % INF  (0,0,0)        -> 141
            G(x, y) = 141;
        elseif (im(x, y, 1) == 127 && im(x, y, 2) == 127 && im(x, y, 3) == 127)     % ART  (127, 127, 127)-> 170
            G(x, y) = 170;
        elseif (im(x, y, 1) == 155 && im(x, y, 2) == 54 && im(x, y, 3) == 54)      % TIS  (155, 54, 54)  -> 198
            G(x, y) = 198;
        elseif (im(x, y, 1) == 255 && im(x, y, 2) == 255 && im(x, y, 3) == 255)     % NON  (255,255,255)  -> 255      
            G(x, y) = 255;
        end;
        
    end; % Y loop
end; % X loop

end
