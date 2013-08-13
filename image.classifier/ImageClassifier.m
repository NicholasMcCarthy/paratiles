classdef ImageClassifier
    % ImageClassifier object.
    % Constructor takes as input a TileClassifier object. 
    % Predict method takes as input a large image
    
    %   Detailed explanation goes here

    properties(GetAccess = public, SetAccess = private);
        Model,
        FeatureExtractor,
        Tilesize,
        Description,
        SortIndex,
        FeatureNames,
    end
    
    methods
            
        function this = ImageClassifier(varargin)

            p = inputParser;
            p.addRequired('Model', @(x) regexpi(class(x), 'weka.classifiers'));
            p.addRequired('FeatureExtractor', @(x) isa(x, 'FeatureExtractor'));
            p.addOptional('Description', 'ImageClassifier object', @(x) ischar(x));
            p.parse(varargin{:});
            
            this.Model = p.Results.Model;
            this.FeatureExtractor = p.Results.FeatureExtractor;
            this.Tilesize = 256;
            
            % Data matrix columns need to be resorted before prediction
            [this.FeatureNames this.SortIndex] = sort(this.FeatureExtractor.Features);
            
        end

        % Function predict:
        % Input: A path to an image, optional path to output location.
        % Output: Heatmap / Index map of likely locations
        function pred_map = predictionMap(this, ImageFilePath);

            if exist(ImageFilePath, 'file') ~= 0;
                try
                    image_info = imfinfo(ImageFilePath);
                    msg = sprintf('Successfully read image: %s', ImageFilePath);
                    disp(msg);
                catch err
                    msg = sprintf('Unable to read image info: %s', ImageFilePath);
                    error('MATLAB:ImageClassifier:preditionMap', msg);
                end
            else
                msg = sprintf('File not found: %s', ImageFilePath);
                error('MATLAB:ImageClassifier:preditionMap', msg);
            end
             
            % Get blockproc handle for FeatureExtraction function 
            fe_handle = this.FeatureExtractor.BlockProcHandle;
            
            % Perform feature extraction using blockproc
            FV = blockproc(ImageFilePath, [this.Tilesize this.Tilesize], fe_handle);
            
            % Dimensions for probability map
            [Xd Yd Zd] = size(FV);
            
            % Reshape FV from map to feature vector matrix
            FV = reshape(FV, Xd * Yd, Zd);   
    
            % Re-sort columns of FV by SortIndex
            FV = FV(:,this.SortIndex);
            
            % Convert matlab matrix to weka Instances class
            FV = matlab2weka('ImageFilePath', this.FeatureNames, FV)
            
            numClasses = length(model.distributionForInstance(FV.instance(1)));
            CP = zeros(Xd*Yd);
            
            % For each instance / tile .. 
            for t = 0:FV.numInstances-1
                
                % Check if it's a zero-vector (i.e. skipped)
                if (any(FV.instance(t).toDoubleArray))
                    classProbs(t+1,:) = zeros(1, numClasses+1);
                    disp('-');
                else
                    classProbs(t+1,:) = [0 (model.distributionForInstance(FV.instance(t)))'];
                end
            end
            
            [prob,predictedClass] = max(classProbs,[],2);
            
            predictedClass = predictedClass - 1;
            
        end
        
        % Creates a handle for blockproc (i.e. will classify a single tile)
       function func_handle = BlockProcHandle(this);
       
           
           func_handle = @(block_struct) shiftdim(this.ExtractFeatures(block_struct.data), -1);
            
       end
        
    end     % End of methods
    
end     % End of classdef

