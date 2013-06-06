

%% im2roi Function
% Reads a large image from disk and gets bounding box coordinates of tissue
% in the image. These are then used to process each tissue ROI area
% separately.


G = blockproc(cell2mat(test_images(1)), [32 32], @(block_struct) round(mean(mean(block_struct.data))))
G = uint8(G); % Convert to uint8

G1 = im2

G1 = im2bw(G);


G2 = imopen(G1, strel('square', 3));

% G3 = medfilt2(G2, [3 3]);

G4 = imfill(G2, 8, 'holes');

% G1 = imclose(G, strel('disk', 2));  % Remove small holes
% 
% G2 = imdilate(G1, strel('square', 2)); % Dilation 
% G3 = imfill(G2, 8, 'holes');         % Region filling
% 
% G4 = im2bw(G3);                       % Convert to binary image

% figure;
subplot(321), imshow(G);
subplot(322), imshow(G1);
subplot(323), imshow(G2);
subplot(324), imshow(G3);
subplot(325), imshow(G4);

% CC = bwconncomp(G);
% RP = regionprops(CC, 'BoundingBox');
