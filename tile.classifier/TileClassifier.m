classdef TileClassifier
    % TileClassifier object. Takes an image tile as an input, extracts
    % features using the supplied featureextractor and returns a prediction
    % using the supplied model.
    
    % Author: Nicholas McCarthy
    % Date created: 21/06/13
    % Date updated: 08/07/2013
    
    % Private fields
    properties(GetAccess = private, SetAccess = private);
        ModelFilePath,           % Path to model being used
        Model,                       % The model itself
        FeatureExtractor,       % Feature extractor 
        SortIndex,              % Work around for dislocated feature extraction process
    end
    
    % Public fields
    properties(GetAccess = public, SetAccess = private);
        Description,               % Description of where/why/how/what this is doing 
    end
    
    methods
        
        function this = TileClassifier(varargin)
           
            p = inputParser;
            p.addRequired('Model', @(x) regexpi(class(x), 'weka.classifiers'));
            p.addRequired('FeatureExtractor', @(x) isa(x, 'FeatureExtractor'));
            p.addOptional('Description', @ischar);
            p.parse(varargin{:});
            
            this.FeatureExtractor = p.Results.FeatureExtractor;
            this.Model = p.Results.Model;
            
            this.Description = 'TileClassifier: default settings';
            
            [S s_idx] = sort(this.FeatureExtractor.Features);
            this.SortIndex = s_idx;
            
        end
        
        function pred = predict(I)
            
            % Extract features from tile
            FV = this.FE.ExtractFeatures(I);
            
            % Re-sort extracted features by character sort (easiest way to
            % bridge feature extraction stage and classification stage)
            FV = FV(this.SortIndex);
            
            % Convert FV to java array .. 
            FV = mat2javaarray(FV);
            W = java.lang.Double(1);
            
            instance = weka.core.Instance(W, FV);
            
            % Classify tile
            pred = this.Model.predict(instance);
            
        end
        
    end
    
end

