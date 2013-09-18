% Pipeliner
%
% This is basically an extended script, intended for running through 
% several batches of analyses with varying parameters. 
% 
% When Pipeliner is run, it makes a copy of itself into a numbered/dated/specified
% directory, which contains all data relating to that run.
% 
% Author: Nick McCarthy <nicholas.mccarthy@gmail.com>
% Date: 12/09/13
% 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 1. Setup 
%               Set pipeline vars
%               Set pipeline data folders, etc
%               Generate datasets 
%                                               
%             Save: vars (struct) with details         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pipeline vars
pl = struct();      % pipeline-data struct
pl.base         =  env.root_dir;                                % Base workspace directory
pl.root_dir     = [pl.base '/pipelines/'];                      % Base pipeline directory
pl.ver          = 'test01';                                     % Specify a particular pipeline version 
pl.run          = [pl.ver '_' datestr(now, 'yymmdd_HH-MM')];    % Pipeline version string
pl.dir          = [pl.root_dir pl.run '/'];                     % Pipeline working directory
pl.data_dir     = [pl.dir 'data/'];                             % Pipeline data directory
pl.model_dir    = [pl.dir 'models/'];                           % Pipeline model directory
pl.pd_path      = [pl.dir 'pipeline_data.mat'];                 % Path for saving this pipeline-data struct (pl)

% Dataset vars
ds = struct();     % model dataset struct
ds.dataset_dir  = [env.root_dir '/datasets/'];                       % Path to global dataset dir
ds.dataset_name = 'all-classes_lab-shape-cicm';                      % Name of dataset generated
ds.feature_dirs = {'datasets/HARALICK_LAB', 'datasets/SHAPE.features',...
                   'datasets/HISTOGRAM_LAB', 'datasets/CICM-r1.features'};
ds.label_path   = [ds.dataset_dir 'class.info/labels.csv'];          % Path to labels file for datasets
ds.classlabels  = {'NON', 'TIS', 'G3', 'G34', 'G4', 'G45', 'G5'};    % Classes in generated datasets (order is important here)
ds.spec_limit   = 50000;                                             % Per-class limit of data points
ds.output_type  = 'arff';                                            % Output type of datasets 
ds.writeHeaders = false;                                             % Irrelevant for ARFF files
ds.writeLabels  = false;                                             % Irrelevant for ARFF files
ds.output_path  = [pl.data_dir dataset_name '.' output_type];        % Path to write the dataset


% Generate pipeline directory layout
if ~mkdir(pl.dir)
    disp('ERROR CREATING PIPELINE BASE DIRECTORY!');
end

if ~mkdir(pl.data_dir)
    disp('ERROR CREATING PIPELINE DATA DIRECTORY!');
end

if ~mkdir(pl.model_dir)
    disp('ERROR CREATING PIPELINE MODEL DIRECTORY!');
end



% Model Parameters
pl.classifier_type = 'bayes.NaiveBayes';
pl.classifier_options = '-O -D -K';

% functions.LibSVM Options: 
% See http://www.csie.ntu.edu.tw/~cjlin/libsvm/#download

% bayes.NaiveBayes Options:
%  '-K'  Use kernel density estimator rather than normal distribution for numeric attributes
%  '-D'  Use supervised discretization to process numeric attributes
%  '-O'  Display model in old format (good when there are many classes)

% Others:
% See http://weka.sourceforge.net/doc.dev/

% Filter parameters
pl.filter_type = 'weka.filters.unsupervised.instance.Resample';
pl.filter_options = '-S 1998 -Z 10';

% Import weka thingies, just in case
import weka.*;

% Start matlabpool
if matlabpool('size') == 0
    matlabpool local 4
end

% Debug print
debug_flag = true;
debugprint = @(x) debug_print(x, debug_flag); 

% Copy this version of script to pipeline dir
thisfile = mfilename('fullpath')

% Save pipeline data struct (pd)
save(pd_path, 'pd');


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 2. Pre-processing 
%               Generate dataset -> D
%               Load dataset
%               Filter dataset -> E
%
%             Save: dataset details, filter details
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
% Dataset Generation
%
ds.dataset_dir  = [env.root_dir '/datasets/'];                       % Path to global dataset dir
ds.dataset_name = 'all-classes_lab-shape-cicm';                      % Name of dataset generated
ds.feature_dirs = {'HARALICK_LAB', 'SHAPE.features', 'HISTOGRAM_LAB', 'CICM-r1.features'};
ds.label_path   = [ds.dataset_dir 'class.info/labels.csv'];          % Path to labels file for datasets
ds.classlabels  = {'NON', 'TIS', 'G3', 'G34', 'G4', 'G45', 'G5'};    % Classes in generated datasets (order is important here)
ds.spec_limit   = 50000;                                             % Per-class limit of data points
ds.output_type  = 'arff';                                            % Output type of datasets 
ds.writeHeaders = false;                                             % Irrelevant for ARFF files
ds.writeLabels  = false;                                             % Irrelevant for ARFF files
ds.output_path  = [pl.data_dir dataset_name '.' output_type];        % Path to write the dataset

% Prepend 'datasets/' to all feature dirs .. 
feature_dirs = cellfun(@(x) ['datasets/' x ], ds.feature_dirs, 'UniformOutput', false);
    
[status cmdout] = GenerateDataset( env.root_dir, 'Type', ds.output_type, ...
                        'Directory', ds.feature_dirs, 'Labels', ds.label_path, ...
                        'Classes', ds.classlabels, 'Output', ds.output_path, ...
                        'LabelsFile', ds.writeLabels, 'HeadersFile', ds.writeHeaders, ...
                        'Limit', ds.spec_limit, 'AssignZeros', 0);
%
% Loading dataset
%

dataset_path = [env.dataset_dir 'all-classes_lab-shape-cicm.arff'];

fprintf('Loading dataset: %s \n', dataset_path); 

D = wekaLoadArff(dataset_path); 

fprintf('Original dataset: %i features, %i instances \n', D.numAttributes, D.numInstances);

%
% Filtering dataset 
%

fprintf('Applying filter to dataset.');


E = wekaApplyFilter(D, filter_type, filter_options);

fprintf('Reduced dataset: %i features, %i instances \n', E.numAttributes, E.numInstances);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 3. Training 
%               Train model
%
%             Save: model details, model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Training classifier on reduced dataset.')

model = wekaTrainModel(E, classifier_type, options);
model.setProbabilityEstimates(true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 4. Evaluate classifier
%               Cross-validation on full dataset -> D
%               
%             Save: cross-validation results / confusion matrix  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Testing classifier on larger dataset.');
tic;
[classPreds classProbs confusionMatrix] = wekaClassify(D, model);


errorRate = sum(D.attributeToDoubleArray(D.classIndex) ~= classPreds)/D.numInstances;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 5. Image Classification 
%               Create ImageClassifier object with model
%               Classify each image in set
%               
%              Save: classifier results, imageclassifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tilesize = 256;
images = getFiles(env.training_image_dir, 'Wildcard', '.scn');

for i = [1:14 16:20]

    %
    % Get image info 
    %
    image_path = images{i};

    ifd_paths = unpackTiff(image_path, 8, 1);       % Unpack image
    imageinfo = imfinfo(ifd_paths{1});              % Get big layer info
    repackTiff(image_path);                         % Repack image 
    
    width = imageinfo.Width; height = imageinfo.Height;

    numBlocks = ceil( (width) / tilesize ) * ceil( (height) / tilesize);
    
    %
    % Generate image dataset .. 
    %
    
    feature_dirs = {'datasets/HARALICK_LAB', 'datasets/SHAPE.features', ...
                  'datasets/HISTOGRAM_LAB', 'datasets/CICM-r1.features'};

    label_path = 'datasets/class.info/labels.csv';
    filenames_path = 'datasets/class.info/filenames.csv';
    sel_path = fliplr(strtok(fliplr(image_path), '/'));

    [dataset_name status cmdout] = GenerateImageDataset( env.root_dir, 'Directory', feature_dirs, 'Image', sel_path, ... 
                            'Labels', label_path, 'Filenames', filenames_path, 'AssignIDs', 0, 'AssignClasses', 1);
    
    dataset_path = [env.root_dir '/' dataset_name];  
    
    image_data = wekaLoadArff(dataset_path);
    
    %
    % Classify image 
    %
    
    [classPreds classProbs confusionMatrix] = wekaClassify(image_data, model);

    % Reshape classPreds to image dimensions .. 
    numXtiles = ceil(width / 256);
    numYtiles = ceil(height / 256);
    cls_image = reshape(classPreds, numYtiles, numXtiles);
    
    image_cls_data = struct('classPreds', classPreds, 'classProbs', classProbs, 'confusionMatrix', confusionMatrix, 'image', cls_image);
    
    data_path = [output_dir regexprep(sel_path, '.scn', '-NaiveBayes_cls-data.mat')]
    
    save(data_path, 'image_cls_data');
    
end