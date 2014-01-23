% This script will read in the existing mask images and convert them to
% indexed images.

% NON : 0
% TIS : 1
% G3  : 2
% G34 : 3
% G4  : 4
% G45 : 5
% G5  : 6

images = getFiles(env.image_dir, 'Wildcard', '8.tif');
masks = getFiles(env.image_dir, 'Wildcard', 'mask-PT.gs.tif');

cmasks = getFiles(env.image_dir, 'Wildcard', 'mask-PT.idx.tif');

%% One mask is missing .. 

missing = images{20};

m1 = regexprep(missing, '.8.', '.mask-PT.colour.');
m2 = regexprep(missing, '.8.', '.mask-PT.');

mask1 = imread(m1); mask1 = mask1(:,:,1:3);
mask2 = imread(m2); mask2 = mask2(:,:,1:3);

maskc1 = mask1(:,:,1);
A = maskc1 == 255;
ART = maskc1 == 127;
C = maskc1 == 128;
D = maskc1 == 155;

figure;
subplot(221), imshow(A);
subplot(222), imshow(B);
subplot(223), imshow(C);
subplot(224), imshow(D);

maskc2 = mask1(:,:,2);
E = maskc2 == 0;
F = maskc2 == 54;
G = maskc2 == 127;
G45 = maskc2 == 128;
I = maskc2 == 255;

G4 = GG == G45;

figure;
subplot(231), imshow(E);
subplot(232), imshow(F);
subplot(233), imshow(G);
subplot(234), imshow(H);
subplot(235), imshow(I);


maskc3 = mask1(:,:,3);

GG = maskc3 == 0;
TIS = maskc3 == 54;
L = maskc3 == 127;
M = maskc3 == 255;

figure;
subplot(221), imshow(J);
subplot(222), imshow(K);
subplot(223), imshow(L);
subplot(224), imshow(M);

M = uint8(zeros(size(mask1))); M = M(:,:, 1);
 
M(TIS) = 1;
M(G4)  = 2;
M(G45) = 3;
M(ART) = 1; % ARTIFACT -> 1

converted_mask = index2rgb_direct(M+1, cmap);
index_mask = M;

colour_mask_path = regexprep(missing, '.8.tif', '.mask-PT.col.png');
index_mask_path = regexprep(missing, '.8.tif', '.mask-PT.idx.tif');

imwrite(converted_mask, colour_mask_path);
imwrite(index_mask, index_mask_path);


%%

cmap = [1.0000    1.0000    1.0000 ;
        1.0000    0.7500    1.0000 ;
        0         1.0000    1.0000 ;
        0.5000    1.0000    0.5000 ; 
        1.0000    1.0000    0 ;
        1.0000    0.5000    0 ;
        1.0000    0         0 ];

figure;

for m = 1:length(masks)
   
    mask = imread(masks{m});
    
%     imshow(mask);
    
    NON = mask == 255;
    TIS = mask == 198;
    G3  = mask == 0;
    G34 = mask == 28;
    G4  = mask == 56;
    G45 = mask == 85;
    G5  = mask == 113;
    INF = mask == 141;
    ART = mask == 170;
    
    orig_mask = mask;
    
    mask(NON) = 0;
    mask(TIS) = 1;
    mask(G3)  = 2;
    mask(G34) = 3;
    mask(G4)  = 4;
    mask(G45) = 5;
    mask(G5)  = 6;
    mask(INF) = 1; % INFLAMMATION -> 1
    mask(ART) = 1; % ARTIFACT -> 1
   
    % Writing the colour mask image
    mask_rgb = index2rgb_direct(mask+1, cmap);
    new_mask_path = regexprep(masks{m}, 'PT.gs.tif', 'PT.col.png');
    imwrite(mask_rgb, new_mask_path);
    
    % Writing the index mask image
    mask_idx = mask;
    new_mask_idx_path =  regexprep(masks{m}, 'PT.gs.tif', 'PT.idx.tif');
    imwrite(mask_idx, new_mask_idx_path);
    
end


% %  
% idx_labelsr = regexprep(idx_labelsr, '28', 'G34');
% idx_labelsr = regexprep(idx_labelsr, '56', 'G4');
% idx_labelsr = regexprep(idx_labelsr, '85', 'G45');
% idx_labelsr = regexprep(idx_labelsr, '113', 'G5');
% idx_labelsr = regexprep(idx_labelsr, '141', 'INF');
% idx_labelsr = regexprep(idx_labelsr, '170', 'ART');
% idx_labelsr = regexprep(idx_labelsr, '198', 'TIS');
% idx_labelsr = regexprep(idx_labelsr, '255', 'NON');
% idx_labelsr = regexprep(idx_labelsr, '0', 'G3');
