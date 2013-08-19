function ret_coords = scaleCoordinates( coords, scaleFactor  )
%SCALECOORDINATES Scales a set of image coordinates by a given scale
%factor.
%   Given a pair of (x,y) coordinates in an image that define a bounding box, this function
%   will scale the values by the parameter scaleFactor.
% Input: coords: [x1 y1 x2 y2] 
%        scaleFactor: the scaling factor (e.g 0.5, 2, 16..)
% Output: scaled coords: [sx1 sy1 sx2 sy2]

% Assuming RegionProps format:
%  [x1 y1 x2 y2]

ret_coords = coords .* scaleFactor;

ret_coords = [floor(ret_coords(1:2)) ceil(ret_coords(3:4))] % Figures need rounding, but lets be inclusive with the size of the box .. 

end

