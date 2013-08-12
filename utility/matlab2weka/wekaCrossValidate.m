function averageError = wekaCrossValidate( data, classifierString, numFolds, randomSeed )
% WEKACROSSVALIDATE Performs cross-validation on the input data using the
% specified classifier.
% Input:
%       data :
%               The data (dur)
%       classifierString : 
%               The classifier as a weka string (e.g. 'bayes.NaiveBayes')
%       numFolds :
%               The number of folds to use
%       randomSeed :
%               The seed for the randomizer.

% Create a java Random object for randomizing the data
rand = java.util.Random(1988);

% Randomize the data 
data.randomize(rand); 

errorVector = zeros(1, numFolds);

% Perform CV
for n = 0:numFolds-1      % 0 for first fold ..
    
   fprintf('Fold %d:\n', n+1);
   
   train = data.trainCV(numFolds, n); 
   test = data.testCV(numFolds, n);           
   
   fprintf('Training classifier ..\n'); 
   
   classifier = trainWekaClassifier(train, classifierString);   
   
   predicted = wekaClassify(test,classifier);

   actual = test.attributeToDoubleArray(data.classIndex); %java indexes from 0

   errorRate = sum(actual ~= predicted)/test.numInstances;
   
   fprintf('Error rate: %f\n', errorRate);
   errorVector(n+1) = errorRate;
   
end

averageError = mean(errorVector);

fprintf('Average error for %d folds: %f \n', numFolds, averageError);

end

