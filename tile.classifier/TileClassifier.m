classdef TileClassifier
    %TILECLASSIFIER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ModelFilePath,       % Path to model being used
        Model,               % The model itself
        FeatureExtractor,    % Feature extractor 
        Description, 
    end
    
    methods
        
        function this = TileClassifier(varargin)
           
            p = inputParser;
            p.addRequired('FeatureExtractor', @(x) isa(x, 'FeatureExtractor'));
            p.addOptional('ModelPath', 'models/model.mat', @(x) ischar(x) && exist(x, 'file'));
            
            p.parse(varargin{:});
            
            this.ModelFilePath = p.Results.ModelPath;
            this.FeatureExtractor = p.Results.FeatureExtractor;
            disp(this.ModelFilePath);
            loaded = load(this.ModelFilePath);
            
            this.Model = loaded.NB;         % Using NaiveBayes classifier as a _placeholder_ 
            
            this.Description = 'TileClassifier: default settings';
            
        end
        
        function pred = predict(I)
            
            FV = this.FE.ExtractFeatures(I);
            pred = this.Model.predict(FV);
            
        end
        
        
    end
    
end

