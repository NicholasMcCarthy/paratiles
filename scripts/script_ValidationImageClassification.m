% This script will be used to classify the validation image set.

% Also, it will be a roughwork area to check everything is alright with
% those images, etc .. 


%% Setup

images = getFiles('/home/nick/Data/PCRC_Validation_Images/', 'Suffix', 'tiff', 'Wildcard', 'HE.tiff');


if matlabpool('size') == 0
    matlabpool local 4;
end

%% .TIFF format .. 

image_IFDs = 1:12;

image_IFD_desc = {'40x', '20x', '10x', '5x', '2.5x', ...
                  '1.75x', 'thumbnail0', 'thumbnail1', 'thumbnail2', 'thumbnail3', ...
                  'thumbnail2', 'thumbnail1', 'thumbnail0', 'ROI_boundingbox', 'slide_label'  };

%% DEFINE FEATURE SETS TO BE EXTRACTED

% Haralick features
haralick_func_lab = @(I) extract_haralick_features(rgb2cielab(I), 'NumLevels', [16 64], 'Distances', [1]);
haralick_labels_lab = label_haralick_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [16 64], 'Distances', [1], 'Prefix', 'lab', 'UseStrings', true);

functions = { haralick_func_lab }; 
labels = [ haralick_labels_lab ];

FE = FeatureExtractor(functions, labels);

func_fe = FE.BlockProcHandle;

%%

tilesize = 256;

temp_dir = [env.temp_dir '/temp_VALIDATION_HARALICK'];

black_pixel_mask = @(I) repmat(all(~I, 3), [1 1 3]);

for i = 1:length(images);
   
    tiff_path = images{i};
    tiff_info = imfinfo(tiff_path);
    
    [selected_ifd_paths] = unpackTiff(tiff_path, 1);
    
    image_path = selected_ifd_paths{1};
    
    image_info = imfinfo(image_path);
    
    % Get number of blocks processed in this image
    numBlocks = ceil( (image_info.Width) / tilesize ) * ceil( (image_info.Height) / tilesize);
    
    % Pre-allocate 'data' struct
    data = zeros(numBlocks, length(FE.Features));
    
    % Blockproc
    tic
    fprintf('[%i] Blockproc on %s \n', i, tiff_path);
    FV = blockproc(image_path, [tilesize tilesize], func_fe);
    
    mytime = toc;
    % Reshape from image to feature vector
    FV = reshape(FV, size(FV, 1) * size(FV, 2), size(FV, 3));   
    
    data = FV;

    % save 'data' struct as .mat file on an image by image basis
    
    image_name = fliplr(strtok(fliplr(tiff_path), '/'));
    
    matfile = strcat(temp_dir, '/', num2str(i), '_', regexprep(image_name, '.tiff', ''), '_temp_data.mat');
    save(matfile, 'data');


    mytime = mytime / 60;
    message = sprintf('Took %f minutes to run', mytime);
    sendmail('nicholas.mccarthy@gmail.com', title, message);
    
end

%% Converting .MAT files to .ARFF (or similar)

relationName = 'wut';

loaded = load('temp_wut');
data = loaded.data; clear loaded;

featureNames = FE.Features;

D = matlab2weka(relationName, featureNames, data);

