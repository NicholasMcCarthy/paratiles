% im2glcm
%   Returns GLCM of input image with num_levels gray_levels.
%   GLCMs computed in 4 directions [0, 45, 90, 135 degree angles] with symmetric
%   pixel pairings. Each directional GLCM is then summed and returned.

function GLCM = im2glcm( im, num_levels, offsets)

glcm = graycomatrix(im, 'NumLevels', num_levels, 'Offset', offsets, 'Symmetric', true);

GLCM = (glcm(:,:,1) + glcm(:,:,2) + glcm(:,:,3) + glcm(:,:,4));

end

