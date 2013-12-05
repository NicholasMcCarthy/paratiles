% This script will be used to classify the validation image set.

% Also, it will be a roughwork area to check everything is alright with
% those images, etc .. 


%% Setup

images = getFiles(env.validation_image_dir, 'Suffix', 'tiff', 'Wildcard', 'HE.tiff');


% if matlabpool('size') == 0
%     matlabpool local 4;
% end

%% .TIFF format .. 

image_IFDs = 1:12;

image_IFD_desc = {'40x', '20x', '10x', '5x', '2.5x', ...
                  '1.75x', 'thumbnail0', 'thumbnail1', 'thumbnail2', 'thumbnail3', ...
                  'thumbnail2', 'thumbnail1', 'thumbnail0', 'ROI_boundingbox', 'slide_label'  };

%% 

black_pixel_mask = @(I) repmat(all(~I, 3), [1 1 3]);


for i = 1:length(images);
   
    image_info = imfinfo(images{i});
    
    for j = 1:length(image_info);
        fprintf('%i x %i \n', image_info(j).Width, image_info(j).Height);
    end
    
    I4 = imread(images{i}, 4);
    I5 = imread(images{i}, 5);
    I6 = imread(images{i}, 6);
    
    M = black_pixel_mask(I6);
    I6(M) = 255;

    
end