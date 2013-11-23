% This script is for finding and removing tiles from the background of an
% image. 

%% Temp workspace for colour deconvolve ..

I = imread('hestain.png');

OD_Preset1 = [0.18 0.20 0.08 ; 0.01 0.13 0.01 ; 0.10 0.21 0.29];
OD_Preset2 = [0.18 0.20 0.08 ; 0.01 0.13 0.01 ; 0 0 0];

IC1 = ColourDeconvolve(I, OD_Preset1);

IC2 = ColourDeconvolve(I, OD_Preset2);

IC3 = imabsdiff(IC1, IC2);

subplot(4,4,1), imshow(I); title('RGB');
subplot(4,4,5), imshow(I(:,:,1)); title('R');
subplot(4,4,9), imshow(I(:,:,2)); title('G');
subplot(4,4,13), imshow(I(:,:,3)); title('B');

subplot(4,4,2), imshow(IC1); title('Ruifrok Preset 1');
subplot(4,4,6), imshow(IC1(:,:,1)); title('Ruifrok Preset 1 C1');
subplot(4,4,10), imshow(IC1(:,:,2)); title('Ruifrok Preset 1 C2');
subplot(4,4,14), imshow(IC1(:,:,3)); title('Ruifrok Preset 1 C3');

subplot(4,4,3), imshow(IC2); title('Ruifrok Preset 2 C1');
subplot(4,4,7), imshow(IC2(:,:,1)); title('Ruifrok Preset 2 C2');
subplot(4,4,11), imshow(IC2(:,:,2)); title('Ruifrok Preset 2 C2');
subplot(4,4,15), imshow(IC2(:,:,3)); title('Ruifrok Preset 2 C2');

subplot(4,4,4), imshow(IC3); title('Correlation Image');
subplot(4,4,8), imshow(IC3(:,:,1)); title('Correlation Image C2');
subplot(4,4,12), imshow(IC3(:,:,2)); title('Correlation Image C2');
subplot(4,4,16), imshow(IC3(:,:,3)); title('Correlation Image C2');


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
%     
%     subplot(131), imshow(Is);
%     subplot(132), imshow(Bs);
%     subplot(133), imshow(Ws);

    %% Active contour segmentation of selected ROIS, using bounded box
    % coords as initial contour
    
    for bb = 1:CC.NumObjects
        
        if (length(CC.PixelIdxList{bb}) > 100) % Remove objects smaller than 100 pixels ..
            
%             Ws(CC.PixelIdxList{bb}) = 0;

            bb_coords = round(RP(bb).BoundingBox);
            
            x1 = bb_coords(1);
            y1 = bb_coords(2);
            x2 = bb_coords(1) + bb_coords(3);
            y2 = bb_coords(2) + bb_coords(4);
            
            
            coords_list = [ x1 y1 ; x1 y2 ; x2 y1 ; x2 y2];
            
        end
        
    end
    
    Options = struct;
    Options.Verbose = true;
    Options.Iterations = 200;
    Options.Wedge = 2;
    Options.Wline = 0;
    Options.Wterm = 0;
    Options.Kappa = 4;
    Options.Sigma1 = 8;
    Options.Sigma2 = 8;
    Options.Alpha = 0.1;
    Options.Beta = 0.1;
    Options.Mu = 0.2;
    Options.Delta = -0.1;
    Options.GIterations = 600;
    
    [O J] = Snake2D(Is, coords_list, Options);
    
    %%

    P = coords_list
    
    O(:,1) = [P(end-3,1):10:P(end,1)]
    
    O(:,1)=interp1( [ P(end-3:end,1) ; P(:,1) ; P(:,1) ; P(1:4,1) ] , 10)
    O(:,2)=interp1( [ P(end-3:end,2) ; P(:,2) ; P(:,2) ; P(1:4,2) ] , 10)
    
    
   %%
    % Scale coordinates
    
%     I = imread(
    
end

