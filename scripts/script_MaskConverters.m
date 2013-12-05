% This script will read in the existing mask images and convert them to
% indexed images.

% NON : 0
% TIS : 1
% G3  : 2
% G34 : 3
% G4  : 4
% G45 : 5
% G5  : 6

masks = getFiles(env.image_dir, 'Wildcard', 'mask-PT.gs.tif');


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
    mask(INF) = 1;
    mask(ART) = 1;
   
%     mask_rgb = index2rgb_direct(mask+1, cmap);
%     new_mask_path = regexprep(masks{m}, 'PT.gs.tif', 'PT.col.png');
%     imwrite(mask_rgb, new_mask_path);
    
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
