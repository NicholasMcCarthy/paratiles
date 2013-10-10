% Tile-pixel classifier
% This script is used to build a pixel classifier. 

% Most of the data used here is present in the 'pixel.classifier' folder.

% Author: Nicholas McCarthy
% Created: 10-05-2013
% Updated: 18-09-2013

%% SETUP

test_images = getFiles([env.root_dir '/test.image.tiles/'], 'Suffix', 'tif');

% Where to put the pixel classified images
output_dir = [env.root_dir '/pixel.classifier/output.images/'];

%% Data preparation (i.e. load data, choose colour space, transforms, etc)

% This .mat file has the cleaned up pixel values selected for each class 
loaded = load('pixel.classifier/data/pixeldata-5.pp1.mat'); 
data = loaded.data;
clear('loaded');



% Sample data (i.e. balance classes .. )
N = 10000;

labels = data.labels;
U = unique(labels);

idx_samples = [];

% Sample with replacement from each class
for i = 1:length(U)
    idx_samples = [idx_samples ; randsample(find(labels==U(i)), N, true)];
end

sampled_labels = labels(idx_samples);


% Select data .. 
pixeldata = data.RGBMS(idx_samples,:); % The RGB mean-shifted pixel values

 % Assumes pixeldata is X rows with 3 columns for each channel (i.e. in
 % feature vector format). This reshapes it to an image format that is a
 % long single line.
pixeldata = reshape(pixeldata, size(pixeldata, 1), 1, size(pixeldata, 2));

% Perform colour deconvolution on pixeldata
cd_pixeldata = ColourDeconvolve(pixeldata);

% And then convert values to LAB colourspace .. 
cd_pixeldata = applycform(cd_pixeldata, makecform('srgb2lab'));   % Convert image to LAB colourspace. (Presuming the model used it originally)
      
% Squeeze colour-deconvolved pixel data back to feature vector form
cd_pixeldata = squeeze(cd_pixeldata);

% Cast uint8 to double (needed for NaiveBayes model)
cd_pixeldata = double(cd_pixeldata);

% Reshaping pixeldata to an image (can safely ignore for model training)
[X, Y, Z] = size(pixeldata);
new_xdim = floor(sqrt(X));
diff = X - (new_xdim^2); % Can't reshape it with extra pixels .. 
img_pixeldata = pixeldata(1:end-diff, :, :);
img_pixeldata = reshape(img_pixeldata, new_xdim, new_xdim, Z);
img_cd_pixeldata = ColourDeconvolve(img_pixeldata);
figure;
subplot(121), imshow(img_pixeldata);
subplot(122), imshow(img_cd_pixeldata);

%% Plot samples in colour space

A = cd_pixeldata;

grp_colors = jet(5);
plot_colors = zeros(size(A));

for i = 1:length(A)
    plot_colors(i,:) = grp_colors(sampled_labels(i),:);
end

A_col = A ./ 255;

figure;
scatter3(A(:,1), A(:, 2), A(:, 3), 100, A_col, '.'); %, 100, A, '.');
xlim([0 255]);
ylim([0 255]);
zlim([0 255]);

%% Getting cluster distances ..

cluster_means = zeros(5, 3);

cluster_means2 = zeros(5, 3);

for i = 1:5;
   sel_ind = find(sampled_labels==i);
   cluster_means(i,:) = mean(cd_pixeldata(sel_ind,:));   
   cluster_means2(i,:) = mean(pixeldata(sel_ind,:));   
end

CM = cluster_means;
CM2 = cluster_means2;

cluster_dists = zeros(5);
cluster_dists2 = zeros(5);

for i = 1:5
    for j = 1:5
        cluster_dists(i,j) = sqrt( (CM(i,1) - CM(j,1))^2 + (CM(i,2) - CM(j,2))^2 + (CM(i,3) - CM(j,3))^2   )        ;
        cluster_dists2(i,j) = sqrt( (CM2(i,1) - CM2(j,1))^2 + (CM2(i,2) - CM2(j,2))^2 + (CM2(i,3) - CM2(j,3))^2   )  ;      
    end
end

disp('Colour deconvolved cluster distances ');
disp(cluster_dists);
disp('RGB cluster distances ');
disp(cluster_dists2);



%% Train (NaiveBayes) classifier .. 

NB = NaiveBayes.fit(cd_pixeldata, sampled_labels);

pixeldata = squeeze(double(pixeldata));
NB2= NaiveBayes.fit(pixeldata, sampled_labels);
%% Make  sure it's working .. 

cidx = NB.predict(cd_pixeldata);
confusion_matrix = confusionmat(cidx, sampled_labels);
err_rate = sum(sampled_labels~=cidx)/(length(cidx)); %mis-classification rate
acc_rate  = sum(sampled_labels==cidx)/(length(cidx)); %mis-classification rate
fprintf('Accuracy rate: %0.2f\nConfusion Matrix:\n', acc_rate*100);

disp(confusion_matrix);

cidx2 = NB2.predict(pixeldata);
confusion_matrix2 = confusionmat(cidx2, sampled_labels);
err_rate2 = sum(sampled_labels~=cidx2)/(length(cidx2)); %mis-classification rate
acc_rate2= sum(sampled_labels==cidx2)/(length(cidx2)); %mis-classification rate
fprintf('Accuracy rate: %0.2f\nConfusion Matrix:\n', acc_rate2*100);

disp(confusion_matrix2);

% Check class distributions?

%% Save model .. 

modelname = 'NB-PixelClassifier-CD.mat';

save(['pixel.classifier/models/' modelname], 'NB');

%% GET TEST IMAGES, COLOURMAPS

PC1 = PixelClassifier(); % Uses default RGB values ..
PC2 = PixelClassifier(['models/' modelname]);

for i = 1:length(test_images);
    
    image_path = test_images{i};
    
    I = imread(image_path);
    
    I = I(:,:, 1:3);
    
    I_cd = ColourDeconvolve(I);
    
    G = PC1.ClassifyImage(I);
    H = PC2.ClassifyImage(I_cd);
    
    Gp = PC1.ProcessImage(G);
    Hp = PC2.ProcessImage(H);
    
    cmap = jet(5);
    
    subplot(321), imshow(I);
    subplot(322), imshow(I_cd);
    subplot(323), imshow(G, cmap);
    subplot(324), imshow(H, cmap);
    subplot(325), imshow(Gp, cmap);
    subplot(326), imshow(Hp, cmap);
    
    image_name = fliplr(strtok(fliplr(image_path), '/'));
    outfile = [output_dir regexprep(image_name, '.tif', '_derp.png')];
    saveas(gcf, outfile);
    
end















%% TEST OUTPUT OF MODELS ON SAMPLE IMAGES (smaller, doesn't batch process)

% This is older roughwork, keeping it in case there's anything I need to
% look over, but basically ignore this and use the section above. 

for i = 1:size(tileset, 1);

    %%%%%%%%%%%%%%%%%
    % READING IMAGE %
    %%%%%%%%%%%%%%%%%
    
    fprintf('Reading test image: %s\n', tileset(i).name);
    
    base_image = imread(tileset(i).name); % Reference tile
        
    [X Y Z] = size(base_image); % Get image dimensions
    
    % Drop the alpha channel from sRGB 
    if Z == 4 
        Z = 3; 
        base_image = base_image(:,:,1:3);
    end;
    
    fprintf('Image Size: %dx%d \n', X, Y); % And some image info
    fprintf('Num Pixels: %d \n', X*Y);
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PIXEL CLASSIFICATION (LAB COLOURSPACE) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    lab_image = rgb2cielab(base_image); 
    
    FV = TileToFeatureVector(lab_image);
    
    % Predict all rows of the feature vector
    [lpost, lcpred, llogp] = posterior(models.NBL, double(FV));
    
    % Classified Tile - Reshape tile to feature vector, drop A channel
    lctile = TileToFeatureVector(uint8(zeros(X, Y, Z)));
        
    % For each pixel in feature vector
    for p = 1:size(lctile,1)
        
       % The predicted class
       pred = lcpred(p);
       
       % Assign the mapped colour
       if (strcmp(pred, '"CYTOPLASM"'))
           lctile(p,:) = colourmap.CYTOPLASM;
       elseif (strcmp(pred, '"FIXATIVE"'))          % Not included in model!
           lctile(p,:) = colourmap.FIXATIVE;
       elseif (strcmp(pred, '"INFLAMMATION"'))
           lctile(p,:) = colourmap.INFLAMMATION;
       elseif (strcmp(pred, '"INTRALUMINAL"'))      % Not included in model!
           lctile(p,:) = colourmap.INTRALUMINAL;
       elseif (strcmp(pred, '"LUMEN"'))
           lctile(p,:) = colourmap.LUMEN;
       elseif (strcmp(pred, '"NUCLEI"'))
           lctile(p,:) = colourmap.NUCLEI;
       elseif (strcmp(pred, '"STROMA"'))
           lctile(p,:) = colourmap.STROMA;
       end;    
    end;
    
    % Reshape feature vector to image
    lctile = FeatureVectorToTile(lctile, X, Y);
    
    % Post-processing on binary class masks
    
    % get binary mask for each class 
    
    % lumen: erosion to remove anything too small
    
    % nuclei: erosion to remove small tiles, opening to regain
    
    % cytoplasm: dilation
    
    % stroma: ????
    
    % Writing disk to image
    image_name = regexp(tileset(i).name, '/', 'split');
    image_name = image_name(end);
    
    outfile = strcat(outputdir, char(regexprep(image_name, '.tif', '.LAB.NB-classified.tif')));
    fprintf('Writing LAB classified image to: %s \n', outfile);
    imwrite(lctile, outfile, 'Compression', 'packbits');
    
end;





