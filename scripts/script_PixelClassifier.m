% Tile-pixel classifier
% This script is used to build a pixel classifier. 

% Most of the data used here is present in the 'pixel.classifier' folder.

% Author: Nicholas McCarthy
% Created: 10-05-2013
% Updated: 18-09-2013

%% SETUP

test_images = getFiles([env.root_dir '/test.images/'], 'Suffix', 'tif');

% Where to put the pixel classified images
output_dir = [env.root_dir '/pixel.classification/output.images/'];

%% Data preparation (i.e. load data, choose colour space, transforms, etc)

% This .mat file has the cleaned up pixel values selected for each class 
loaded = load('pixel.classifier/data/pixeldata-5.pp1.mat'); 
data = loaded.data;
clear('loaded');

pixeldata = data.RGBMS; % The RGB mean-shifted pixel values

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
% [X, Y, Z] = size(pixeldata);
% new_xdim = floor(sqrt(X));
% diff = X - (new_xdim^2); % Can't reshape it with extra pixels .. 
% img_pixeldata = pixeldata(1:end-diff, :, :);
% img_pixeldata = reshape(img_pixeldata, new_xdim, new_xdim, Z);
% img_cd_pixeldata = ColourDeconvolve(img_pixeldata);
% figure;
% subplot(121), imshow(img_pixeldata);
% subplot(122), imshow(img_cd_pixeldata);

%% Train (NaiveBayes) classifier .. 

NB = NaiveBayes.fit(cd_pixeldata, data.labels);

%% Make  sure it's working .. 

cidx = NB.predict(cd_pixeldata);

confusion_matrix = confusionmat(cidx, data.labels);

err_rate = sum(data.labels~=cidx)/(length(cidx)); %mis-classification rate

acc_rate  = sum(data.labels==cidx)/(length(cidx)); %mis-classification rate

fprintf('Accuracy rate: %0.2f\nConfusion Matrix:\n', acc_rate*100);

disp(confusion_matrix);

% Check class distributions?

%% Save model .. 

modelname = 'NB-PixelClassifier-CD.mat';

save(['pixel.classifier/models/' modelname], 'NB');

%% GET TEST IMAGES, COLOURMAPS


for i = 1:length(test_images);
    
    image_path = test_images{i};
    
    I = imread(image_path);
    
    I = I(:,:, 1:3);
    
    I_cd = ColourDeconvolve(I);
    
    G = PC1.ClassifyImage(I);
    H = PC2.ClassifyImage(I_cd);
    
    cmap = jet(5);
    
    subplot(221), imshow(I);
    subplot(222), imshow(I_cd);
    subplot(223), imshow(G, cmap);
    subplot(224), imshow(H, cmap);
    
    


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





