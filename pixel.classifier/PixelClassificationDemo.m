%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Demo for PixelClassifier %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get list of images in test_images folder
test_images = getAllFiles('./test.images');

% Create the Pixel Classifier object
clear PC;
PC = PixelClassifier();

%% Obtaining CICM Features

clear PC; PC = PixelClassifier();

FV_ci = zeros(length(test_images), 25);
FV_pi = zeros(length(test_images), 25);

% Iterate over the images, derive features.
for i = 1
    
    fprintf('Reading image %d\n', i);
    
    I = imread(cell2mat(test_images(i)));
    
    CI = PC.ClassifyImage(I);
    PI = PC.ProcessImage(CI);
    
    FV_ci(i,:) = PC.GetCICMFeatures(CI);
    
    FV_pi(i,:) = PC.GetCICMFeatures(PI);
end

FV_labels = PC.GetCICMFeatureLabels;

%% Obtaining shape Features

clear PC; PC = PixelClassifier();

FV_shapes = zeros(length(test_images), 10);

% Iterate over the images, derive features.
for i = 4:length(test_images);
    
    fprintf('Reading image %d\n', i);
    
    I = imread(test_images{i});
    
    CI = PC.ClassifyImage(I);
   
    FV_shapes(i,:) = PC.GetShapeFeatures(CI);
    
end

FV_labels = PC.GetShapeFeatureLabels;

mydataset =  mymat2dataset(FV_shapes, FV_labels);

%% Obtaining all features

clear PC; PC = PixelClassifier();

FV = zeros(length(test_images), 60);

% Iterate over the images, derive features.
for i = 4:length(test_images)
    
    fprintf('Reading image %d\n', i);
    
    I = imread(cell2mat(test_images(i)));
    I = I(:,:,1:3);  % Goddamn alpha channels
    
    FV(i,:) = PC.GetAllFeatures(I);
    
end

FV_labels = PC.GetAllFeatureLabels();

mydataset = mymat2dataset(FV, FV_labels);

%% Plotting image and CICM
% WARNING: CREATES A LOT OF FIGURES 

clear PC; PC = PixelClassifier();

for i = 1:length(test_images)
    
    fprintf('Reading image %d\n', i);
    
    I = imread(cell2mat(test_images(i)));
    
    if (size(I, 3) == 4)        % Some images have alpha channels (somehow, still)
        I = I(:,:,1:3);
    end
    
    CI = PC.ClassifyImage(I);    
    CI = CI.*(255/5);
    
    figure, subplot(2, 1, 1), imshow(I), subplot(2, 1, 2), imshow(CI);
    
end

%% Logical masks of each class
clear PC; PC = PixelClassifier();

I = imread(cell2mat(test_images(2)));
I = I(:,:,1:3); % Account for alpha channel

CI = PC.ClassifyImage(I);
SCI = CI .* (255/5);

Ll = PC.GetMask(CI, 'LUMEN');
Ls = PC.GetMask(CI, 'STROMA');
Lc = PC.GetMask(CI, 'CYTOPLASM');
Ln = PC.GetMask(CI, 'NUCLEI');       % Get Logical image of nuclei locations
Li = PC.GetMask(CI, 'INFLAMMATION'); % Get Logical image of inflammation locations <- 

figure;
subplot(3, 3, 1), imshow(I); title('Base Image');
subplot(3, 3, 2), imshow(SCI); title('Class Index Image');
subplot(3, 3, 3), imshow(Ll); title('Lumen Logical Mask');
subplot(3, 3, 4), imshow(Ls); title('Stroma Logical Mask');
subplot(3, 3, 5), imshow(Lc); title('Cytoplasm Logical Mask');
subplot(3, 3, 6), imshow(Ln); title('Nuclei Logical Mask');
subplot(3, 3, 7), imshow(Li); title('Inflammation Logical Mask');

%% Nuclear Density

clear PC; PC = PixelClassifier();

I = imread(cell2mat(test_images(2)));               % Read Image
I = I(:,:,1:3); % Account for alpha channel

CI = PC.ClassifyImage(I);
SCI = CI .* (255/5); % Scale class index image

L = PC.GetMask(CI, 'NUCLEI');                    % Logical image of nuclei locations
Pn = PC.GetProcessedMask(CI, 'NUCLEI');

CC = bwconncomp(L);                                % Connected components

CC.Areas = cellfun(@length, CC.PixelIdxList);       % Remove areas that are below threshold ? This should be done 
CC.AreaAvg = mean(CC.Areas);
CC.Disorder = 1 / (1 + (std(CC.Areas) / CC.AreaAvg));

RP = regionprops(CC, 'Centroid', 'Area', 'Image', 'ConvexImage', 'ConvexHull', 'ConvexArea');

%[r1 r2] = bwboundaries(L3, 'noholes');

% Get centroid coordinates
Xs = zeros(length(RP), 1); Ys = zeros(length(RP), 1);
for i = 1:length(RP)
    Xs(i) = RP(i).Centroid(1);
    Ys(i) = RP(i).Centroid(2);
end

Ys = 512-Ys; % Flip Y values for image coordinates

% Voronoi diagram 
[VX VY] = voronoi(Xs, Ys);  % More plotting options than 'voronoi(x, y)'

% Delaunay triangulation
DT = delaunay(Xs, Ys);

% figure;
subplot(3, 2, 1, 'align'), imshow(SCI);
subplot(3, 2, 2, 'align'), imshow(L);
subplot(3, 2, 3, 'align'), imshow(Pn);
subplot(3, 2, 5, 'align'), plot(Xs, Ys, 'r.', VX, VY, 'b-'), xlim([0 512]), ylim([0 512]);
subplot(3, 2, 6, 'align'), triplot(DT, Xs, Ys), xlim([0 512]), ylim([0 512]);

%% Prominent Nucleoli Detection
% Inflammation and dark nucleotide pixels have a similar colour profile. 
% Using nuclei and inflammation masks it should be possible to detect
% nuclei with prominent nucleoli


%% Removing Intraluminal content

% Lumen Mask

% Background removal (?) How to remove pixels that aren't in image ? 

% Opening operation to remove mixclassified pixels
% Closing operation to fill in intraluminal content 
% 

%% Other features

% Gland Area                % Lumen + Cytoplasm/Nuclei not in stroma
% Gland Perimeter    
% Lumen Area
% Ratio - Gland Area : Lumen Area
% Ratio - Gland Area : Gland Perimeter
% Ratio - # Nuclei : Gland Perimeter
% # Nuclei surrounding lumen (i.e. in cytoplasm)
% Total lumen area in tile
% Total stroma area in tile
% Average lumen area in tile
% Average stroma area in tile
% Lumen/stroma ratio

%% Outlining Processed Mask ROIs

clear PC; PC = PixelClassifier();

I = imread(cell2mat(test_images(2)));
I = I(:,:,1:3); % Account for alpha channel

CI = PC.ClassifyImage(I);
Lc = PC.GetMask(CI, 'CYTOPLASM');
Pc = PC.GetProcessedMask(CI, 'CYTOPLASM');

M = PC.MaskHighlight(I, Pc);
figure, 
subplot(121), imshow(I);
subplot(122), imshow(M);


%% Plot Image -> Class Index Image -> Mask -> Processed Mask

clear PC; PC = PixelClassifier();

class = 'STROMA';

figure;

idx = 1;
for i = 4:13
    
    I = imread(cell2mat(test_images(i)));
    I = I(:,:,1:3); % Account for alpha channel
    
    CI = PC.ClassifyImage(I);
    SCI = CI .* (255/5);
    
    LC = PC.GetMask(CI, class);
    
    LP = PC.GetProcessedMask(CI, class);
    
    subplot(10, 4, idx+0), imshow(I);
    subplot(10, 4, idx+1), imshow(SCI);
    subplot(10, 4, idx+2), imshow(LC);
    subplot(10, 4, idx+3), imshow(LP);
    idx = idx +4;
end;


%% Getting nuclei in cytoplasm
clear PC; PC = PixelClassifier();

I = imread(cell2mat(test_images(6)));
I = I(:,:,1:3); % Account for alpha channel

CI = PC.ClassifyImage(I);
SCI = CI .* (255/5);

Pc = PC.GetProcessedMask(CI, 'CYTOPLASM');
Pn = PC.GetProcessedMask(CI, 'NUCLEI');
Ps = PC.GetProcessedMask(CI, 'STROMA');

Ns = Pn & Ps;
Ns = bwareaopen(Ns, 50);
Nc = Pn & Pc;
Nc = bwareaopen(Nc, 50);

figure;
subplot(321), imshow(SCI), title('Class Index image');
subplot(322), imshow(Pc), title('Processed Cytoplasm mask');
subplot(323), imshow(Ps), title('Processed Stroma mask');
subplot(324), imshow(Pn), title('Processed Nuclei mask');
subplot(325), imshow(Nc), title('Nuclei within Cytoplasm');
subplot(326), imshow(Ns), title('Nuclei within Stroma');


%% Comparing base classified and processed classified images
clear PC; PC = PixelClassifier();

I = imread(cell2mat(test_images(4)));
I = I(:,:,1:3); % Account for alpha channel

CI = PC.ClassifyImage(I);

Ll = PC.GetMask(CI, 'LUMEN');
Ls = PC.GetMask(CI, 'STROMA');
Lc = PC.GetMask(CI, 'CYTOPLASM');
Ln = PC.GetMask(CI, 'NUCLEI');       % Get Logical image of nuclei locations
Li = PC.GetMask(CI, 'INFLAMMATION'); % Get Logical image of inflammation locations <- 

Pl = PC.GetProcessedMask(CI, 'LUMEN');
Ps = PC.GetProcessedMask(CI, 'STROMA');
Pc = PC.GetProcessedMask(CI, 'CYTOPLASM');
Pn = PC.GetProcessedMask(CI, 'NUCLEI');       % Get Logical image of nuclei locations
Pi = PC.GetProcessedMask(CI, 'INFLAMMATION'); % Get Logical image of inflammation locations <- 

figure;
subplot(6,2,1), imshow(I);
subplot(6,2,2), imshow(CI*(255/5));

subplot(6,2,3), imshow(Ll);
subplot(6,2,4), imshow(Pl);

subplot(6,2,5), imshow(Ls);
subplot(6,2,6), imshow(Ps);

subplot(6,2,7), imshow(Lc);
subplot(6,2,8), imshow(Pc);

subplot(6,2,9), imshow(Ln);
subplot(6,2,10), imshow(Pn);

subplot(6,2,11), imshow(Li);
subplot(6,2,12), imshow(Pi);


%% Image -> Class Index Image -> Processed Class Index Image

clear PC; PC = PixelClassifier();

I = imread(test_images{5});
I = I(:,:,1:3); % Account for alpha channel

CI = PC.ClassifyImage(I);  % Classify I -> CI
SCI = CI .* (255/5);       % Scale CI    

PI = PC.ProcessImage(CI);  % Process CI -> PI
SPI = uint8(PI * (255/5)); % Scale PI

% figure;
subplot(131), imshow(I);
subplot(132), imshow(SCI);
subplot(133), imshow(SPI);