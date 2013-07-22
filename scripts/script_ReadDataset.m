% A script to read a csv dataset generated by script_GenerateDataset
% This is necessary because matlab is a P.O.S

%% Setup dataset vars

dataset_name = 'G3-G4_CICM-HIST';

dataset_path = [env.dataset_dir dataset_name '.csv'];
label_path  = [env.dataset_dir dataset_name '.class-labels.csv'];


%% Import datasets

fprintf('Importing data .. ');

mydata = importdata(dataset_path); % importing the data matrix. Surprisingly, matlab actually recognises and separates the columnheaders
                                                          % although for some reason it also provides them as a separate text row                          

mylabels = importdata(label_path); % Import the labels column separately
mylabels = mylabels(2:end);         % Since matlab is fucking useless and we have to manually remove the header 

fprintf(' .. done!\n');

%% Crossvalidation, etc

disp('Performing cross-validation.')

y = mylabels;
x = mydata.data;

order = unique(y);
cp = cvpartition(y, 'k', 15);
classfunc = @(xtrain, ytrain, xtest)  classify(xtest, xtrain, ytrain);

cvMCR = crossval('mcr', x, y, 'predfun', classfunc, 'partition', cp);

fprintf('Accuracy is: %0.3f \n', 1- cvMCR);


