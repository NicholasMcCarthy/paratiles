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
    end
    
    % Public fields
    properties(GetAccess = public, SetAccess = private);
        Description,               % Description of where/why/how/what this is doing 
    end
    
    methods
        
        function this = TileClassifier(varargin)
           
            p = inputParser;
            p.addRequired('Model', @(x) isa(x, 'NaiveBayes'));
            p.addRequired('FeatureExtractor', @(x) isa(x, 'FeatureExtractor'));
            p.addOptional('Description', @ischar);
            p.parse(varargin{:});
            
            this.FeatureExtractor = p.Results.FeatureExtractor;
            this.Model = p.Results.Model;
            
            this.Description = 'TileClassifier: default settings';
            
        end
        
        function pred = predict(I)
            
            % Extract features from tile
            FV = this.FE.ExtractFeatures(I);
            % Classify tile
            pred = this.Model.predict(FV);
            
        end
        
    end
    
end

