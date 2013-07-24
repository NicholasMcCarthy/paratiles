function L = getBorderValues( I )
%GETBORDERVALUES Returns a list of the border values of an image.

%   Given an input image I, this function returns a list of pixels in the
%   border. Starts in upper left corner of image and moves clockwise .. 

L = [ I( 1 , : , : ) ...                            % The top row
      I( 2:end , size(I, 2) , : )' ...              % Right-hand column, excluding top right pixel 
      fliplr( I( size(I, 1) , 1:end-1 , : ) )...      % Flipped bottom row, excluding bottom right pixel
      fliplr( I( 2:end-1,1,:)' )  ];                % Flipped left column, excluding top right and bottom left pixels

end

