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

pipeline_version = [];                % Pipeline version 
pipeline_dir = [];                    % Working directory for this version

% Global vars
dataset_dir = [];                     % Global dataset directory 

% Model stuff
classifier_type = 'bayes.NaiveBayes';
classifier_options = '-O';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 2. Pre-processing 
%               Read dataset -> D
%               Filter dataset -> D2
%
%             Save: dataset details, filter details
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 3. Training 
%               Train model
%
%             Save: model details, model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 4. Evaluate classifier
%               Cross-validation on full dataset -> D
%               
%             Save: cross-validation results / confusion matrix  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stage 5. Image Classification 
%               Create ImageClassifier object with model
%               Classify each image in set
%               
%              Save: classifier results, imageclassifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

