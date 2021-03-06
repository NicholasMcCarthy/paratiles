function out = Pipeliner(pl, ds, mdl, flt, ic)

% Pipeliner
%
% This is basically an extended script, intended for running through 
% several batches of analyses with varying parameters. 
% 
% When Pipeliner is run, it makes a copy of itself into a numbered/dated/specified
% directory, which contains all data relating to that run.
% 
% Author: Nick McCarthy <nicholas.mccarthy@gmail.com>
% Created: 12-09-13
% Updated: 26-09-13
%
% Input Parameters:
%
% pl struct:
%   'base'              -	the base pipelines/ directory
%   'ver'               -	(optional) pipeline version string
%
% mdl struct:
%   'classifier_type'   -   WEKA classifier string (e.g. bayes.NaiveBayes)
%   'classifier_options'-   WEKA classifier option string, will throw error
%                           when training if invalid.
%   'name'              -   (optional) Name for saving model
%
% ds struct:
%   'dataset_dir'       -   Root directory of dataset folders
%   'label_path'        -   Path to CSV containing row labels
%   'dataset_name'      -   (optional) name for dataset generated
%   'feature_dirs'      -   Cell array of paths to folders of feature sets
%   'classes'           -   Dataset classes (must be present in labels file)
%   'spec_limit'        -   (optional) Limit the number of obs. for any class [Default: no limit]
%   'output_type'       -   Output type of dataset (arff | csv) [Default: arff]
%   'output_path'       -   (optional) path to write dataset to
%
%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 1. Setup 
%               Set pipeline vars
%               Set pipeline data folders, etc
%               Generate datasets 
%                                               
%             Save: vars (struct) with details         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic
disp('Stage 1. Setup');

% Assert pl struct has a base field specified 
assert( isfield(pl, 'root') , 'Pipeliner Error: Missing ''base'' field.');

% If no 'ver' field given that use the default 'pl' 
if ~isfield(pl, 'ver');
    pl.ver = 'pl';
end;

% Generate rest of pl fields
% pl.base         = [pl.root '/pipelines/'];                      % Base pipeline directory
% pl.run          = [pl.ver '_' datestr(now, 'yymmdd_HH-MM')];    % Pipeline version string
% pl.dir          = [pl.base pl.run '/'];                         % Pipeline working directory
pl.data_dir     = [pl.dir 'data/'];                             % Pipeline data directory
pl.model_dir    = [pl.dir 'models/'];                           % Pipeline model directory
pl.log          = [pl.dir 'output.log'];

disp('Creating pipeline directory structure.');
% Generate pipeline directory layout
if ~mkdir(pl.dir);       error('Pipeliner Error: Could not create %s base directory.', pl.dir); end;
if ~mkdir(pl.data_dir);  error('Pipeliner Error: Could not create %s data directory.', pl.data_dir); end;
if ~mkdir(pl.model_dir); error('Pipeliner Error: Could not create %s model directory.', pl.model_dir); end;

% Model parameters 
assert( isfield(mdl, 'classifier_type') , 'Pipeliner Error: Missing ''classifier_type'' field.');
assert( isfield(mdl, 'classifier_options') , 'Pipeliner Error: Missing ''classifier_options'' field.');

if ~isfield(mdl, 'name'); mdl.name = [pl.run]; end
mdl.mdl_path = [pl.model_dir mdl.name '.mdl'];

% Dataset parameters
assert( isfield(ds, 'dataset_dir') ,   'Pipeliner Error: Missing ''dataset_dir'' field.');
assert( isfield(ds, 'feature_dirs') ,  'Pipeliner Error: Missing ''feature_dirs'' field.');
assert( isfield(ds, 'label_path') ,    'Pipeliner Error: Missing ''label_path'' field.');
assert( isfield(ds, 'filename_path') ,'Pipeliner Error: Missing ''filename_path'' field.');
assert( isfield(ds, 'classes') ,       'Pipeliner Error: Missing ''classes'' field.');

% Set default values for optional inputs / set up values if present
if ~isfield(ds, 'dataset_name'); ds.dataset_name = ['dataset' pl.run]; end;
if ~isfield(ds, 'output_type'); ds.output_type = 'arff'; end;
if ~isfield(ds, 'output_path'); ds.output_path = [pl.data_dir ds.dataset_name '.' ds.output_type]; end;
if ~isfield(ds, 'spec_limit'); ds.spec_limit = -1; end;

% Filter options
assert( isfield(flt, 'filter_type') ,    'Pipeliner Error: Missing ''filter_type'' field.');
assert( isfield(flt, 'filter_options') , 'Pipeliner Error: Missing ''filter_options'' field.');

% Import weka thingies, just in case
import weka.*;

% Start matlabpool
if matlabpool('size') == 0
    matlabpool local 4
end

% Debug print
debug_flag = true;
debugprint = @(x) debug_print(x, debug_flag); 

% % Copy this version of script to pipeline dir
% thisfile = [mfilename('fullpath') '.m'];
% thisfilename = fliplr(strtok(fliplr(thisfile), '/'));
% 
% destfile = [pl.dir thisfilename '.bak'];
% copyfile(thisfile, destfile);

% Save pipeline info and parameters 
pipeline_info = struct('pipeline_setup', pl, 'model_parameters', mdl, 'dataset_gen', ds);
pipeline_info_path = [pl.dir 'pipeline_info.mat'];

save(pipeline_info_path, 'pipeline_info');
toc
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 2. Pre-processing 
%               Generate dataset -> D
%               Load dataset
%               Filter dataset -> E
%
%             Save: dataset details, filter details
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('Stage 2. Dataset generation & Pre-processing');

%
% Dataset Generation
%
% 
% ds.output_path  = [pl.data_dir ds.dataset_name '.' ds.output_type];        % Path to write the dataset
% ds.ds_path = [pl.dir 'dataset_gen.mat'];                                  % Path to save this struct (ds)

[status cmdout] = GenerateDataset( pl.root, 'Type', ds.output_type, ...
                        'Directory', ds.feature_dirs, 'Labels', ds.label_path, ...
                        'Filenames', ds.filename_path, ...
                        'Classes', ds.classes, 'Output', ds.output_path, ...
                        'Limit', ds.spec_limit, 'AssignZeros', 0);
%
% Loading dataset
%

fprintf('Loading dataset: %s \n', ds.output_path);

D = wekaLoadArff(ds.output_path);

fprintf('Original dataset: %i features, %i instances \n', D.numAttributes, D.numInstances);

fprintf('Removing ''filenames'' attribute..');

% Get index of attribute 'filename' .. Remove it .. 
% D = wekaApplyFilter(D, 'weka.filters.unsupervised.attribute.Remove', '-R 



%
% Filtering dataset 
%

fprintf('Applying filter to dataset.');

E = wekaApplyFilter(D, flt.filter_type, flt.filter_options);

fprintf('Reduced dataset: %i features, %i instances \n', E.numAttributes, E.numInstances);

toc
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 3. Training 
%               Train model
%
%             Save: model details, model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('Stage 3. Model Training');

disp('Training classifier on reduced dataset.')

model = wekaTrainModel(E, mdl.classifier_type, mdl.classifier_options);
% model.setProbabilityEstimates(true);

wekaSaveModel(mdl.mdl_path, model);
toc
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 4. Evaluate classifier
%               Cross-validation on full dataset -> D
%               
%             Save: cross-validation results / confusion matrix  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('Stage 4. Model Evaluation');

disp('Testing classifier on larger dataset.');

tic
[classPreds classProbs confusionMatrix] = wekaClassify(D, model);
toc

errorRate = sum(D.attributeToDoubleArray(D.classIndex) ~= classPreds)/D.numInstances;

results = struct('classPreds', classPreds, 'classProbs', classProbs, 'confusionMatrix', confusionMatrix, 'errorRate', errorRate);

results_path = [pl.dir 'results.mat'];

save(results_path, 'results');

sendmail('nicholas.mccarthy@gmail.com', ['Pipeline: ' pl.run], 'Appears to be done ..');
toc

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 5. Image Classification 
%               Create ImageClassifier object with model
%               Classify each image in set -> image-name_cls-data.mat
%               
%              Save: classifier results, imageclassifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('Stage 5. Image Classification')

tilesize = ic.tilesize;
images = ic.images;

feature_dirs = ds.feature_dirs;
label_path = ds.label_path;
filenames_path = ds.filenames_path;
    
for i = 15:size(images, 1);

    % Get image info 
    image_path = images{i};

    ifd_paths = unpackTiff(image_path, 8, 1);       % Unpack image
    imageinfo = imfinfo(ifd_paths{1});              % Get big layer info
    repackTiff(image_path);                         % Repack image 
    
    width = imageinfo.Width; height = imageinfo.Height;

    numBlocks = ceil( (width) / tilesize ) * ceil( (height) / tilesize);
    
    % Generate image dataset .. 
    sel_path = fliplr(strtok(fliplr(image_path), '/'));

    [dataset_name status cmdout] = GenerateImageDataset( pl.root, 'Directory', feature_dirs, 'Image', sel_path, ... 
                            'Labels', label_path, 'Filenames', filenames_path, 'AssignIDs', 0, 'AssignClasses', 1);
    
    dataset_path = [pl.root '/' dataset_name];  
    
    image_data = wekaLoadArff(dataset_path);
    
    % Classify image 
    [classPreds classProbs confusionMatrix] = wekaClassify(image_data, model);

    errorRate = sum(image_data.attributeToDoubleArray(image_data.classIndex) ~= classPreds)/image_data.numInstances;

    accuracy = 1 - errorRate;
    
    % Reshape classPreds to image dimensions .. 
    numXtiles = ceil(width / 256);
    numYtiles = ceil(height / 256);
    cls_image = reshape(classPreds, numYtiles, numXtiles);
    
    % Save data
    image_cls_data = struct('classPreds', classPreds, 'classProbs', classProbs, 'confusionMatrix', confusionMatrix, 'error', errorRate, 'accuracy', accuracy, 'image', cls_image);
    
    image_cls_data_path = [pl.data_dir regexprep(sel_path, '.scn', '_cls-data.mat')];
    
    save(image_cls_data_path, 'image_cls_data');
    
end

out = 1;
toc
%%


sendmail('nicholas.mccarthy@gmail.com',' Can it be!?', 'Appears to be done ..');

end