% This script is for finding and removing tiles from the background of an
% image. 

%% SETUP 

images = getFiles(env.training_image_dir, 'Suffix', 'scn');     

tilesize = 256;

if matlabpool('size') == 0
    matlabpool local 4
end


%% Iterate / Select image and 

for i = 1:length(images)
    
    image_path = images{i};
    
    disp(image_path);
    
    % Unpack base image, get path to selected IFD
    unpacked_images = unpackTiff(image_path, [8 11], true)
    
    small_image = unpacked_images{2};  % Segmentation on this .. 
    big_image = unpacked_images{1};    % Scaling coordinates to fit .. 
    
    small_image_info = imfinfo(small_image);
    
    %%
    
    Os = imread(small_image);
    
    % Convert to intensity image
    Is = rgb2gray(Os);
    
    % Quantize image .. 
    Is = quantizeImage(Is, 16);
        
    Is = imopen(Is, strel('disk', 10));
    
    % Median filter
    Is = medfilt2(Is, [5 5]);
    
    % Convert to black and white .. 
    threshold_level = graythresh(Is);
    Bs = im2bw(Is, threshold_level);
    
    Bs = ~Bs;
    
    Bs = imdilate(Bs, strel('disk', 10));
    
    % Get connected components
    CC = bwconncomp(Bs, 8);
    
    % Get bounding box of objects
    RP = regionprops(CC, 'BoundingBox');
    
    % Draw bounding boxes over objects
    Ws = Os;
    
    x_orig = size(Is, 2);
    y_orig = size(Is, 1);
    
    for bb = 1:CC.NumObjects
        
        if (length(CC.PixelIdxList{bb}) > 100) % Remove objects smaller than 100 pixels ..
            
%             Ws(CC.PixelIdxList{bb}) = 0;

            bb_coords = round(RP(bb).BoundingBox);
            x1 = bb_coords(1);
            y1 = bb_coords(2);
            x2 = bb_coords(1) + bb_coords(3);
            y2 = bb_coords(2) + bb_coords(4);

            Ws(y1, x1:x2,:) = 0;
            Ws(y2, x1:x2,:) = 0;
            Ws(y1:y2, x1,:) = 0;
            Ws(y1:y2, x2,:) = 0;
            
        end
    end
    
    % Perform watershed segmentation -- doens't actually segment the damn
    % thing
%     Ws = watershed(Bs, 8);
    
    subplot(131), imshow(Is);
    subplot(132), imshow(Bs);
    subplot(133), imshow(Ws);
    
    %%
    
    % Scale coordinates
    
    I = imread(
    
end

