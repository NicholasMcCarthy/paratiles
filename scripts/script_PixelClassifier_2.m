% Duplicates a lot of script_PixelClassifer.m, but set up to show
% combinations of pixels, etc .. 


%% LOAD DATA
% This .mat file has the cleaned up pixel values selected for each class 
loaded = load('pixel.classifier/data/pixeldata-5.pp1.mat'); 
data = loaded.data; clear('loaded');

%% SAMPLE DATA

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

% Reshape pixeldata to image channel form 
pixeldata = reshape(pixeldata, size(pixeldata, 1), 1, size(pixeldata, 2));

%% CONVERT DATA TO SEPARATE COLOURSPACES 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert RGB pixeldata to feature vector ..

rgb_pixeldata = squeeze(pixeldata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert RGB values to CIELAB
lab_pixeldata = rgb2cielab(pixeldata);

% Squeeze to feature vector 
lab_pixeldata = squeeze(lab_pixeldata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert RGB values to H&E 
% Perform colour deconvolution on pixeldata
OD_HE = [0.18 0.20 0.08 ; 0.01 0.13 0.01 ; 0 0 0];

he_pixeldata = ColourDeconvolve(pixeldata, OD_HE);
he_pixeldata = he_pixeldata(:,:,1:2); % Drop the empty channel (non H&E)

% Squeeze colour-deconvolved pixel data back to feature vector form
he_pixeldata = squeeze(he_pixeldata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert RGB values to HSV
hsv_pixeldata = squeeze(rgb2hsv(pixeldata));     % Convert to HSV and squeeze

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert RGB values to YCBCR
ycbcr_pixeldata = squeeze(rgb2ycbcr(pixeldata)); % Convert to YCBCR and squeeze

pixel_values = { struct('name', 'RGB', 'data', rgb_pixeldata), ...
                struct('name', 'LAB', 'data', lab_pixeldata), ...
                struct('name', 'HE', 'data', he_pixeldata), ...
                struct('name', 'HSV', 'data', hsv_pixeldata), ...
                struct('name', 'YCBCR', 'data', ycbcr_pixeldata)};

%% PLOT EACH PIXELDATA COLOURSPACE 

figure;

for i = 1:length(pixel_values);
    
    name = pixel_values{i}.name;
    data = pixel_values{i}.data;
    
    subplot(2,3,i), plot(data), title(name);
end

%% CONCATENATE ALL PIXEL VALUES AND PERFORM INFORMATION GAIN ON THEM .. 

all_headers = {'rgb_R', 'rgb_G', 'rgb_B', 'lab_L', 'lab_A', 'lab_B', 'he_H', 'he_E', 'hsv_H', 'hsv_S', 'hsv_V', ...
                'ycbcr_Y', 'ycbcr_Cb', 'ycbcr_Cr', 'label'};
            
all_pixeldata = double([]);

for i = 1:length(pixel_values);
    data = double(pixel_values{i}.data);
    all_pixeldata = [all_pixeldata data];
end

% Add class index 
all_pixeldata = [all_pixeldata sampled_labels];

% Create WEKA instances from data
weka_data = matlab2weka('pixeldata', all_headers, all_pixeldata, 15);

% Convert numeric class to nominal
weka_filter = wekaFilter('weka.filters.unsupervised.attribute.NumericToNominal', '-R last');
weka_filter.setInputFormat(weka_data);
weka_data = weka.filters.Filter.useFilter(weka_data, weka_filter); 

% Save arff data 
wekaSaveArff('pixeldata_intensity-values.arff', weka_data);

% Perform information gain
% attributeEvaluatorType = 'InfoGainAttributeEval';
% attributeEvaluatorOptions = '';
% 
% attribute_evaluator = wekaAttributeEvaluator(weka_data, attributeEvaluatorType);
% Fuck it, just 


%% LINEAR COMBINATIONS OF PIXEL VALUES AND VALIDATE

cmbns = nchoosek(1:5, 3);   % Every possible fold of the image set

classLabels = sampled_labels;

for i = 1:size(cmbns, 1);
    
    data = [];
    name = '';
    
    for d = 1:length(cmbns(i,:))
        name = strcat(name, [ '_' pixel_values{d}.name ]);
        data = [data pixel_values{d}.data];
    end
    
    fprintf('Adding %s \n', name);
    
end

%% CROSS_VALIDATE

D = all_pixeldata;
classLabels = sampled_labels;


% Account for within-class variance by altering single obs 
D(1, 7) = 254;

NB = NaiveBayes.fit(D, classLabels);

classPreds = NB.predict(all_pixeldata);

confusion_matrix = confusionmat(classPreds, classLabels);
errorRate = sum(classLabels~=classPreds)/(length(classPreds));    %mis-classification rate
accuracyRate  = sum(classLabels==classPreds)/(length(classPreds));   %mis-classification rate

fprintf('Accuracy rate: %0.2f\nConfusion Matrix:\n', accuracyRate*100);

disp(confusion_matrix);

%% For every superset of pixels join them and check cross-validation 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Join LAB and HE values horizontally

helab_pixeldata = [he_pixeldata lab_pixeldata];

% Cast uint8 to double (needed for NaiveBayes model)
helab_pixeldata = double(helab_pixeldata);

lab_pixeldata = double(lab_pixeldata);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Train model 

class_labels = sampled_labels; % to be clear .. 

helab_pixeldata(1,1) = 254; % Otherwise, no within-class variance for class 1, feature 1 ...

NB = NaiveBayes.fit(helab_pixeldata, class_labels);

NB2= NaiveBayes.fit(lab_pixeldata, class_labels);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Look at confusion matrices and accuracy for each .. 

cpred = NB.predict(helab_pixeldata);

confusion_matrix = confusionmat(cpred, sampled_labels);
err_rate = sum(sampled_labels~=cpred)/(length(cpred));    %mis-classification rate
acc_rate  = sum(sampled_labels==cpred)/(length(cpred));   %mis-classification rate

fprintf('Accuracy rate: %0.2f\nConfusion Matrix:\n', acc_rate*100);

disp(confusion_matrix);

cpred2 = NB2.predict(lab_pixeldata);
confusion_matrix2 = confusionmat(cpred2, sampled_labels);
err_rate2 = sum(sampled_labels~=cpred2)/(length(cpred2)); %mis-classification rate
acc_rate2= sum(sampled_labels==cpred2)/(length(cpred2)); %mis-classification rate
fprintf('Accuracy rate: %0.2f\nConfusion Matrix:\n', acc_rate2*100);

disp(confusion_matrix2);

% Save model .. 

modelname = 'NB-PixelClassifier-HELAB.mat';

save(['pixel.classifier/models/' modelname], 'NB');

%% Generate images of Nuclei segmentation

PC = PixelClassifier();
test_images = getFiles([env.root_dir '/test.image.tiles/'], 'Suffix', 'tif');

figure;

for i = 1:length(test_images);
    
   I = imread(test_images{i}); 
   CI = PC.ClassifyImage(I);
   
   M = PC.ProcessImage(CI);
   
   Mn = PC.GetProcessedMask(CI, 'NUCLEI');
   Ms = PC.GetProcessedMask(CI, 'STROMA');
   Mc = PC.GetProcessedMask(CI, 'CYTOPLASM');
   
   Msa = Mn & imfill(imdilate(imfill(Ms, 8, 'holes'), strel('disk', 3)) , 8, 'holes');               % STROMA ^ NUCLEI
   Msa = bwareaopen(Msa, 100);    % Remove small areas
   Msn =  Mn & Msa;
   Msn = bwareaopen(Msn, 50);
   Msn = imfill(Msn, 8, 'holes');
      
   Mca = Mn & imfill(imdilate(imfill(Mc, 8, 'holes'), strel('disk', 3)) , 8, 'holes');       % (Dilated CYTOPLASM) ^ NUCLEI
   Mca = bwareaopen(Mca, 100);                                           % Remove small areas
   Mcn = Mn & Mca;                                                       % (Cytoplasm & Nuclei) & NUCLEI)
   Mcn = bwareaopen(Mcn, 50);
   Mcn = imfill(Mcn, 8, 'holes');                                        % Imfill 
      
   subplot(241), imshow(I), title('Original Image');
   subplot(242), imshow(CI, jet(5)), title('CI image');
   subplot(243), imshow(Ms), title('Segmented Stroma');
   subplot(244), imshow(Mc), title('Segmented Cytoplasm');
   subplot(245), imshow(Mn), title('Segmented Nuclei');
   subplot(246), imshow(Msn), title('Segmented Nuclei in Stroma');
   subplot(247), imshow(Mcn), title('Segmented Nuclei in Cytoplasm');
   
   userinput = input('Enter [Y] to STOP', 's');
   
   if strcmpi(userinput, 'y')
       fprintf('Stopped at image %d \n', i);
       break;
   end
end

