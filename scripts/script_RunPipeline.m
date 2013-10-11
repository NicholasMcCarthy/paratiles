% This script is set to vary dataset features, model and pipeline
% parameters that get passed to the Pipeliner.m class .. 


%% %%%%%%%%%%%%%
% Pipeline vars %%
%%%%%%%%%%%%%%%%%%

% Should just supply single pipelines directory -> Pipeliner will
% automatically construct pipeline run, versioning-dating and directory contents
% from that .. 

pl = struct();                                                  % pipeline-data struct
pl.root         = [env.root_dir];                               % Root workspace directory. 'pipelines' directory should be in this folder.
pl.base         = [pl.root '/pipelines/'];                      % Base pipeline directory
pl.ver          = 'test02';                                     % Specify a particular pipeline version 
pl.run          = [pl.ver '_' datestr(now, 'yymmdd_HH-MM')];    % Pipeline version string
pl.dir          = [pl.base pl.run '/'];                         % Pipeline working directory

%% %%%%%%%%%%%%%%%%
% Model Parameters %%
%%%%%%%%%%%%%%%%%%%%%

% Separate out model parameters into separate struct 
mdl = struct();
% mdl.classifier_type = 'functions.LibSVM';
% mdl.classifier_options = '';

mdl.classifier_type = 'bayes.NaiveBayes';
mdl.classifier_options = '-O -D';
mdl.name = 'naivebayes-multiclass-basic';

% functions.LibSVM Options: 
% See http://www.csie.ntu.edu.tw/~cjlin/libsvm/#download

% bayes.NaiveBayes Options:
%  '-K'  Use kernel density estimator rather than normal distribution for numeric attributes
%  '-D'  Use supervised discretization to process numeric attributes
%  '-O'  Display model in old format (good when there are many classes)

% Others:
% See http://weka.sourceforge.net/doc.dev/

%% %%%%%%%%%%%%%%%%%%%%%%%%
% Dataset Filter parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

flt = struct();
flt.filter_type = 'weka.filters.unsupervised.instance.Resample';
flt.filter_options = '-S 1998 -Z 20';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Attribute Selection parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AttributeSelection parameters
atr = struct();
atr.feature_selection_type = 'test';
atr.feature_selection_options = 'options';

%% %%%%%%%%%%%%
% Dataset vars %%
%%%%%%%%%%%%%%%%%

ds = struct();     % model dataset struct
ds.dataset_dir      = [env.root_dir '/datasets/'];                       % Path to global dataset dir
ds.label_path       = [ds.dataset_dir 'class.info/labels.csv'];          % Path to labels file for datasets
ds.filenames_path   = [ds.dataset_dir '/class.info/filenames.csv'];

ds.dataset_name = 'all-classes_lab-shape-cicm';                      % Name of dataset generated
ds.feature_dirs = {'datasets/HARALICK_LAB', 'datasets/SHAPE.features',...
                   'datasets/HISTOGRAM_LAB', 'datasets/CICM-r1.features'};
               
ds.classes  = {'NON', 'TIS', 'G3', 'G34', 'G4', 'G45', 'G5'};    % Classes in generated datasets (order is important here)
ds.spec_limit   = 50000;                                             % Per-class limit of data points

%% %%%%%%%%%%%%%%%%%%
% Image Classification %
%%%%%%%%%%%%%%%%%%%%%%%%

ic = struct();
ic.images = getFiles(env.training_image_dir, 'Wildcard', 'scn');
ic.tilesize = 256;


%% %%%%%%%%%%%%
% Run Pipeline %%
%%%%%%%%%%%%%%%%%

% pipeline_info = struct('pipeline_setup', pl, 'model_parameters', mdl, 'dataset_gen', ds, 'filter_parameters', flt, 'attribute_selection', atr, 'image_classification', ic);

try 
    Pipeliner(pl, ds, mdl, flt, ic)
catch err
    
    disp(err.message);
    
%     disp('Pipeline run failed! See log file for error.')
    
    % Write error to error.log
%     error_log = [pl.dir 'error.log'];
%     fid = fopen(error_log, 'w');
%     
%     if fid ~= -1
%         fprintf(fid, '%s\n', err.message);
%         fclose(fid);
%     end
    
    % Cleanup
%     error_dir = [pl.root pl.run '_FAILED/'];  
%     movefile(pl.dir, error_dir);
    
end

%% 

PL = PipelinerClass(pl);
PL.setModelInfo(mdl);
PL.setDatasetInfo(ds);
PL.setFilterInfo(flt);
PL.setImageInfo(ic);


        

