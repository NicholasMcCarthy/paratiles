% Main script for showing colour deconvolution 


% Author: Nicholas McCarthy
% Date created: 10/07/13
% Last updated: 


%% 

images=  getFiles('test.images', 'Suffix', '.tif', 'Wildcard', 'PCRC');

output_dir = 'colour.normalisation/test.output/';


for i = 1:length(images);
    
    fprintf('Reading %s \n', images{i});
    
    I = imread(images{i});
    
    I = I(:,:,1:3);
    
    G = ColourDeconvolve(I);
    
    
    figure;
    subplot(211), imshow(I), title('Original Image');
    subplot(212), imshow(G), title('Colour deconvolved image');
    
    output_path = [output_dir images{i}];
%     imwrite(G, output_path);
    
end