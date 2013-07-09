classdef ImageClassifier
    % ImageClassifier object.
    % Constructor takes as input a TileClassifier object. 
    % Predict method takes as input a large image
    
    %   Detailed explanation goes here
    

    properties(GetAccess = public, SetAccess = private);
        ImageFilepath
        OutputMap
        TileClassifierPath
        TileClassifierModel
        
    end
    
    methods
        
            function this = ImageClassifier(varargin)
    
                p = inputParser;
                
                p.addRequired('TileClassifierModel', 
                
                
            end
            
            % Function predict:
            % Input: A path to an image, optional path to output location.
            % Output: Heatmap / Index map of likely locations
            function predmap = predict(ImageFilePath);
                
%                 p = inputParser;
%                 p.addRequired('ImagePath', @(x) ischar(x) && exist(x, 'file')) ; % Probably need another check here to make sure its an image
%                 p.addOptional('OutputPath', @(x) ischar(x));
%                 
%                 p.parse(varargin{:});
                
                % Save the path to the currently operated on image.
%                 this.ImageFilepath = p.Results.ImageFilepath;
                
                % Blockproc the image using this objects TileClassifier
                
                this.ImageFilepath = ImageFilepath;
                
                predmap = blockproc(ImageFilepath, 
                
                
                
            end
    end
    
end

