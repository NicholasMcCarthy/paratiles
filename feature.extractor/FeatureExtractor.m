% Class for encapsulating feature extraction.
% Set features to be extracted:
%      Haralick GLCM features (+ parameters)
%      Gabor filters (+ parameters)
%      CICM features (+ model)
%      

classdef FeatureExtractor
    
    properties(GetAccess = public, SetAccess = private);
        Functions,
        LastImage,
        LastFeatures
        % what features can be extracted
        
    end
    
    
    methods
        
        function this = FeatureExtractor(varargin)
            
               
            % Validate inputs are function handles .. 
            cellfun(@(x) validateattributes(x, {'function_handle'}, {'row'}), varargin)
            
            this.Functions = varargin';
            
%           this.Features.Labels = {};
%           this.LastImage = '';
            this.LastFeatures = [];
            
        end
        
        function FV = ExtractFeatures(this, I)
           
            FV = [];
            
            for i = 1:length(this.Functions)
                
            end
            
        end
        
        function SetFeatures(this, varargin)
           
%             p = inputParser;
            
%             hl = {'Haralick', [1 2 3], [4 5 6], 2}
%             gab = {'Gabor', [7/8*pi, pi/2], [0.5 1 2]};
%              
            
            % Features are set in cell arrays, with the first being the
            % name of the feature type
            
            if nargin < 2
                error('No input arguments!');
            end
         
        
            
            
        end % function end
        
    
    end
    
end

