% List patient biopsy and prostatectomy results for each of the training
% dataset


masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'PT.idx.tif');

pipelines = [env.base_dir '/pipelines/'];

pipeline_dir = [pipelines 'test01_130929_17-11/'];

%% Patient outcomes from annotated images .. 

patient_outcomes = {length(masks), 1};

for i = 1:length(masks)
   
    mask_path = masks{i};
    mask = imread(mask_path);
    
    [first, remain] = strtok(fliplr(strtok(fliplr(mask_path), '/')), '_');
    [second, remain] = strtok(remain, '-');
    
    patient_ID = second(2:end);
    
    [third, remain] = strtok(remain, '_');
    
    if isempty(strfind(third, 'WS'))
        tissue_type = 'biopsy';
    else
        tissue_type = 'prostatectomy';
    end
    
    stats = calculateGleason(mask);
    
    stats.patient_ID = patient_ID;
    stats.tissue_type = tissue_type;
    stats.image_path = mask_path;
    
    patient_outcomes{i} = stats;
    
end

save('patient_outcomes_annotated.mat', 'patient_outcomes'); 

%% Patient outcomes from system images

dataset_path = '/pcrc/eval1/training_set.arff';
training_set = wekaLoadArff(dataset_path);

% classifier_type = 'trees.RandomForest';
% classifier_options = '-I 50 -K 7 ' ;
% classifier_identifier = 'rf1';

classifier_type = 'bayes.NaiveBayes';
classifier_options = '-O' ;
classifier_identifier = 'nb1';

% Save model using type, options and identifier
model_path = [env.data_dir '/models/eval1_'  classifier_identifier '-' classifier_type '.model'];

fprintf('\tTraining classifier .. \n');
fprintf('Model: %s \n', classifier_type);
fprintf('Options: %s \n', classifier_options);
model = wekaTrainModel(training_set, classifier_type, classifier_options);
disp('Completed!');

wekaSaveModel(model_path, model, true);

% Get image datasets
image_datasets = getFiles('/pcrc/eval1/image_datasets/', 'Suffix', 'arff');
image_files = getFiles(env.image_dir, 'Suffix', 'tif', 'Wildcard', '.8.');

cmap = jet(7); 
cmap(1, :) =[1 1 1]; % NON values in index 1
cmap(2, :) =[1 0.75 1];% TIS values in index 2

patient_outcomes = {length(image_datasets), 1};

for i = 1:length(image_datasets)

    % Get image information
    
    image_path = image_files{i};
    
    image_info = imfinfo(image_path);
    
    numBlocks = ceil( (image_info.Width) / 256 ) * ceil( (image_info.Height) / 256);

    blocksWidth = ceil( image_info.Width / 256);
    blocksHeight = ceil( image_info.Height / 256);
    
    % Get dataset
    
    image_dataset_path = image_datasets{i};
    
    ID = wekaLoadArff(image_dataset_path);
    
    % Classify dataset 
    [classPreds classProbs confusionMatrix] = wekaClassify(ID, model);
    
    % Reshape to classified image .. 
    I = reshape(classPreds, blocksHeight, blocksWidth);
    
    Imed = medfilt2(I, [3 3]);
    
    [first, remain] = strtok(fliplr(strtok(fliplr(image_path), '/')), '_');
    [second, remain] = strtok(remain, '-');
    
    patient_ID = second(2:end);
    
    [third, remain] = strtok(remain, '_');
    
    if isempty(strfind(third, 'WS'))
        tissue_type = 'biopsy';
    else
        tissue_type = 'prostatectomy';
    end
    
    stats = calculateGleason(I);
    
    stats.patient_ID = patient_ID;
    stats.tissue_type = tissue_type;
    stats.image_path = image_path;
    
    FV = calculateDirectPredictionVector(I);
    
    FVmed  = calculateDirectPredictionVector(Imed);
    
    stats.FV = FV;
    stats.FVmed = FVmed;
    
    patient_outcomes{i} = stats;
    
end

save('patient_outcomes_system.mat', 'patient_outcomes'); 


%%

fid = fopen('PCRC_patient_outcomes.csv', 'w+');

headers = 'PCRC_ID,tissue_type,cancer_tissue_ratio,primary_grade,secondary_grade,gleason_score,num_tumour_regions \n';

fprintf(fid, headers);

for i = 1:length(patient_outcomes);
    
    d = patient_outcomes{i};
    
    id = d.patient_ID;
    tt = d.tissue_type;
    ctr = d.cancer_tissue_ratio;
    pg = d.PRIMARY_grade;
    sg = d.SECONDARY_grade;
    gs = d.GLEASON_score;
    ntr = d.num_tumour_regions;
    
    row = fprintf(fid, '%s,%s,%s,%s,%s,%s,%s\n', num2str(id), num2str(tt), num2str(ctr),num2str(pg), num2str(sg), num2str(gs), num2str(ntr));
    
end

fclose(fid);