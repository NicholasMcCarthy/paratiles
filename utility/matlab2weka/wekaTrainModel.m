function wekaClassifier = wekaTrainModel(wekaData,type,options)
% Train a weka classifier.
%
% wekaData - A weka java Instances object holding all of the training data.
%            You can convert matlab data to this format via the
%            matlab2weka() function or load existing Weka arff data using
%            the wekaLoadArff() function. 
%
% type    -  A string naming the type of classifier to train relative to
%            the weka.classifiers package. There are many options - see
%            below for a few. See the weka documentation for the rest. 
%
% options - an optional string or cell cell array of strings listing the options specific
%           to the classifier. See the weka documentation for details. 
%
% Example: 
% wekaClassifier = wekaTrainModel(data,'bayes.NaiveBayes',{'-D', '-S', '100'});
% wekaClassifier = wekaTrainModel(data,'functions.LibSVM','-B 1 -C 10 -G 1');
%
% List of a few selected weka classifiers - there are many many more:
% 
% bayes.BayesNet
% bayes.NaiveBayes
% bayes.NaiveBayesMultinomial
% bayes.HNB
% functions.GaussianProcesses
% functions.IsotonicRegression
% functions.Logistic
% functions.MultilayerPerceptron
% functions.RBFNetwork
% functions.SVMreg
% lazy.IBk
% lazy.LBR
% misc.HyperPipes
% trees.RandomForest
% ...

    if nargin < 2
        error('MATLAB:wekaTrainModel', 'Not enough input parameters \n See "help wekaTrainModel"\');
    elseif nargin > 3
        error('MATLAB:wekaTrainModel', 'Too many input parameters \n See "help wekaTrainModel"\');
    end
    
    if(~wekaPathCheck),wekaClassifier = []; return,end
    
    wekaClassifier = javaObject(['weka.classifiers.',type]);
    
    if(nargin == 3 && ~isempty(options))
        
        if ischar(options)  % If options is a string, e.g. '-Z 100 -C 10 -G 1' 
            options = stringsplit(options, ' ') % Split it by spaces into cellstring array
        end
        
        wekaClassifier.setOptions(options);
    end
    
    wekaClassifier.buildClassifier(wekaData);
    
end