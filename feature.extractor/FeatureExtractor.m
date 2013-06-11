% Class for encapsulating feature extraction.
% Set features to be extracted:
%      Haralick GLCM features (+ parameters)
%      Gabor filters (+ parameters)
%      CICM features (+ model)
% 
%   Input: function handle or cellarray of function handles. 
%      

classdef FeatureExtractor
    
    properties(GetAccess = public, SetAccess = private);
        Functions,      % Function handles
        Features,       % Labels for features
        LastImage,      % Last image from which features were extracted
        LastFeatures    % Features extracted from last image
    end
    
    methods
        
        function this = FeatureExtractor(functions, labels)
            
            if(iscell(functions))
                cellfun(@(x) validateattributes(x, {'function_handle'}, {'scalar'}), functions);
                this.Functions = functions;
            else 
                validateattributes(functions, {'function_handle'}, {'scalar'});
                this.Functions = { functions };
            end
            
            
            validateattributes(labels, {'cell'}, {'vector'});
            
            this.Features = labels;
            this.LastImage = zeros;
            this.LastFeatures = [];
            
        end
        
        function FV = ExtractFeatures(this, I)
           
            validateattributes(I, {'double', 'uint8'}, {'finite'}, 'ExtractFeatures', 'a grayscale image');
            
            FV = zeros(1, length(this.Features));       % Pre-allocate feature vector  by length of feature labels
            idx = 1;                                    % idx counter
            
            for i = 1:length(this.Functions)            % For each function in this feature extractor
                loop_fv = feval(this.Functions{i}, I);  % extract features from I using that function
                FV(idx:idx+length(loop_fv)-1) = loop_fv;  % assign them to FV 
                idx = idx + length(loop_fv);            % increment idx counter
            end
            
            this.LastImage = I;                         % Keep last image
            this.LastFeatures = FV;                     % And extracted features .. Just in case
            
        end
        
        
        function func_handle = BlockProcHandle(this);
           
            func_handle = @(block_struct) shiftdim(this.ExtractFeatures(block_struct.data), -1);
            
        end
      
    end
    
end

