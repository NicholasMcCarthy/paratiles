classdef PixelClassifier
  
    properties(GetAccess = public, SetAccess = private);
        ModelFilepath,
        Model,
        ClassIndexImage,
        Key = {'LUMEN', 'STROMA', 'CYTOPLASM', 'NUCLEI', 'INFLAMMATION', 'FIXATIVE', 'INTRALUMINAL'}
    end
    
    methods
        
        %%%%%%%%%%%%%%%%%%%%%%
        % Constructor method %
        %%%%%%%%%%%%%%%%%%%%%%
        function this = PixelClassifier()
            
            filepath = 'models/NB-PixelClassifier.LAB.ind.mat';
            
            this.ModelFilepath = filepath;
            
            loaded = load(filepath);
            this.Model = loaded.NB;
            
            clear('loaded', 'filepath');    % Removes the loaded var 
        end
        
        %%%%%%%%%%%%%%%%%%%  % Input: a colour image
        % ClassIndexImage %  % Output: Class index image 
        %%%%%%%%%%%%%%%%%%%
        function cicm = ClassifyImage(this, img)
            
            if (~size(img, 3) == 3)                         % If parameter image does not have 3 channels ..
                if (size(img, 3) == 4)                      % Check if it's just an alpha channel ..
                   img = img(:,:,1:3);                      % Remove alpha channel 
                else                                        % Otherwise it's a gray-scale image 
                    error('PixelClassifier:Classify', 'Parameter image must be a colour image.');
                end
            end
           
            img = applycform(img, makecform('srgb2lab'));   % Convert image to LAB colourspace. (Presuming the model used it originally)
            
            [X Y Z] = size(img);                            % Get image dimensions
            
            img = reshape(img, X*Y, Z);                     % Reshape image to feature vector form
            cicm = this.Model.predict(double(img));         % Predict labels of pixels
            cicm = uint8(reshape(cicm, X, Y));              % Reshape to original image size and cast to uint8
        end
           
        %%%%%%%%%%%%%%%%  % Input: Class index image
        % ProcessImage %  % Output: Processed class index image 
        %%%%%%%%%%%%%%%%
        function PI = ProcessImage(this, CI)
           
            Cl = this.GetProcessedMask(CI, 'LUMEN');
            Cs = this.GetProcessedMask(CI, 'STROMA');
            Cc = this.GetProcessedMask(CI, 'CYTOPLASM');
            Cn = this.GetProcessedMask(CI, 'NUCLEI');
            Ci = this.GetProcessedMask(CI, 'INFLAMMATION');
            
            % Stack masks to produce final processed class index image
            % Order is important here .. 
            PI = uint8(zeros(size(CI)));
            
            PI(Cs) = 2; % Start with stroma
            PI(Cc) = 3; % Add cytoplasm
            PI(Cl) = 1; % Then lumen
            PI(Cn) = 4; % Throw in some nuclei
            PI(Ci) = 5; % And add inflammation for seasoning
            
            PI(PI==0) = CI(PI==0); % Fill in gaps with pixels from unprocessed image
            
            PI = medfilt2(PI, [5 5]); % Stir with median filter.
        end
        
        %%%%%%%%%%%%%%%%%%%%%%% % Input: an RGB image
        % Obtain All Features % % Output: Feature vector of all features
        %%%%%%%%%%%%%%%%%%%%%%%
        function FV = GetAllFeatures(this, I)
           
            CI = this.ClassifyImage(I);
            PI = this.ProcessImage(CI);
            
            fv_CI = this.GetCICMFeatures(CI);
           
            fv_PI = this.GetCICMFeatures(PI);
            
            fv_shape = this.GetShapeFeatures(PI);
            
            FV = [fv_CI fv_PI fv_shape];
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%% % Input: none
        % Obtain All Features % % Output: Cell array of feature labels 
        %%%%%%%%%%%%%%%%%%%%%%% %          taken from GetAllFeatures()
        function FV_labels = GetAllFeatureLabels(this);
            
            CI_labels = this.GetCICMFeatureLabels();
            
            % Add P_ to start of features from processed image
            PI_labels = cellfun(@(x) strcat('P_', x), CI_labels, 'UniformOutput', false);
           
            shape_labels = this.GetShapeFeatureLabels();
            
            FV_labels = [CI_labels PI_labels shape_labels];
                        
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%% % Input: Class index image
        % Obtain CICM Features % % Output: Novel CICM features 
        %%%%%%%%%%%%%%%%%%%%%%%% %       
        function [FV HIST GLCM] = GetCICMFeatures(this, CI)
            
            % Simpler than using imhist .. 
            HIST = zeros(1, 5);
            for h = 1:5
                HIST(h) = sum(sum(CI(:) == (h)));
            end
            
%           offsets = [0 1; 1 1 ; 1 0 ; -1 1
            
            offsets =  [ 0 1 ; 1 1 ; 1 0 ; -1 1 ];    % Offsets for 0, 45, 90, 135 degree angles
            graylimits = [1 5];                  % Graylimits and numlevels set so binning doesn't 
            numlevels = 5;                       % change assigned pixel classes.
            
             % Dont think symmetric is necessary here but should check both
            glcm = graycomatrix(CI, 'Offset', offsets, 'NumLevels', numlevels, 'GrayLimits', graylimits); 
            
            % Sum matrices for total-adjacency matrix
            GLCM = (glcm(:,:,1) + glcm(:,:,2) + glcm(:,:,3) + glcm(:,:,4));

            % Normalize? NOTE: Unnormalized values should be fine.
            
            FV = zeros(1, 25); % Preallocate feature vector
            i = 1;
            for h = 1:5
                for g = 1:5
                  FV(i) = HIST(h) / ( GLCM(h, g) + 1); % + 1 to account for divide-by-zero error
                  i = i+1;
                end
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%% % Input: Class index image
        % Obtain Shape Features % % Output: Traditional shape features
        %%%%%%%%%%%%%%%%%%%%%%%%% %       
        function [FV HIST] = GetShapeFeatures(this, CI)
           
            % Initially used just the processed classified masks, but
            % switching to fully processed image
%             Pc = this.GetProcessedMask(CI, 'CYTOPLASM');    %
%             Pn = this.GetProcessedMask(CI, 'NUCLEI');       %  This assumes that the input CI is the base classified image not the processed one. Rectify.
%             Ps = this.GetProcessedMask(CI, 'STROMA');       %  
            
            PI = this.ProcessImage(CI);
            
            % Uses indices of Key properties
            Pc = PI == find(strcmp(this.Key, 'CYTOPLASM'));
            Pn = PI == find(strcmp(this.Key, 'NUCLEI'));
            Ps = PI == find(strcmp(this.Key, 'STROMA'));
            
            [X Y] = size(PI);
            
            % Simpler than using imhist .. 
            HIST = zeros(1, 5);
            for h = 1:5
                HIST(h) = sum(sum(PI(:) == (h)));
            end
            
            % Area features
            lumen_area = HIST(strcmp(this.Key, 'LUMEN')) / (X * Y); 
            stroma_area = HIST(strcmp(this.Key, 'STROMA')) / (X * Y); 
            cytoplasm_area = HIST(strcmp(this.Key, 'CYTOPLASM')) / (X * Y); 
            
             % Ratio features
            lumen_stroma_ratio = HIST(strcmp(this.Key, 'LUMEN')) / HIST(strcmp(this.Key, 'STROMA'));
            lumen_cytoplasm_ratio = HIST(strcmp(this.Key, 'LUMEN')) / HIST(strcmp(this.Key, 'CYTOPLASM'));
            stroma_cytoplasm_ratio = HIST(strcmp(this.Key, 'STROMA')) / HIST(strcmp(this.Key, 'CYTOPLASM'));
            
            if isnan(lumen_stroma_ratio) || isinf(lumen_stroma_ratio)
                lumen_stroma_ratio = 0;
            end
            
            if isnan(lumen_cytoplasm_ratio) || isinf(lumen_cytoplasm_ratio)
                lumen_cytoplasm_ratio = 0;
            end
            
            if isnan(stroma_cytoplasm_ratio) || isinf(stroma_cytoplasm_ratio)
                stroma_cytoplasm_ratio = 0;
            end
            
            % # Nuclei in stroma features
            
            Ns = Pn & imfill(imdilate(Ps, strel('disk', 2)) , 8, 'holes');               % STROMA ^ NUCLEI
            Ns = bwareaopen(Ns, 50);    % Remove small areas
            
            
            CCs = bwconncomp(Ns);                                       % Get connected components (i.e. nuclei)
            
            CCs.AverageArea = mean(cellfun(@length, CCs.PixelIdxList));       % Get areas of each components
            CCs.StdDev = std(cellfun(@length, CCs.PixelIdxList));              % Standard deviation of areas
                                
            if (isnan(CCs.AverageArea))                                       % If there are no CCs, account for NaN values
                CCs.AverageArea = 0;
            end
            
            if(isnan(CCs.StdDev))
                CCs.StdDev = 0;
            end
            
            nuclei_in_stroma = CCs.NumObjects;                                      % Number of nuclei 
            nuclei_in_stroma_average_area = CCs.AverageArea;                        % Average area of nuclei
            nuclei_in_stroma_disorder = 1 / (1 + (CCs.StdDev / (1 + CCs.AverageArea)));   % Disorder of nuclei 
           
            
            % Nuclei in cytoplasm features
            
            Nc = Pn & imfill(imdilate(Pc, strel('disk', 2)) , 8, 'holes');               % CYTOPLASM ^ NUCLEI
            Nc = bwareaopen(Nc, 100);    % Remove small areas
            Nc = imfill(Nc, 8, 'holes');
            
            CCc = bwconncomp(Nc);
            CCc.AverageArea = mean(cellfun(@length, CCc.PixelIdxList));
            CCc.StdDev = std(cellfun(@length, CCc.PixelIdxList));              
            
            if (isnan(CCc.AverageArea))                                       % If there are no CCs, account for NaN values
                CCc.AverageArea = 0;
            end
            if(isnan(CCc.StdDev))
                CCc.StdDev = 0;
            end
            
            nuclei_in_cytoplasm = CCc.NumObjects;
            nuclei_in_cytoplasm_average_area = CCc.AverageArea;
            nuclei_in_cytoplasm_disorder = 1 / (1 + (CCc.StdDev / (1 + CCc.AverageArea)));
      
            FV = [lumen_area stroma_area cytoplasm_area ... 
                lumen_stroma_ratio lumen_cytoplasm_ratio stroma_cytoplasm_ratio ...
                nuclei_in_stroma nuclei_in_stroma_average_area nuclei_in_stroma_disorder ...
                nuclei_in_cytoplasm nuclei_in_cytoplasm_average_area nuclei_in_cytoplasm_disorder];
            
            % Gland features (not applicable to tiles, but worth
            % considering)
            
            % A 'gland' is considered to be the lumen, encompassing
            % cytoplasm and nuclei. i.e. no stroma
            
            % Gland Area, Perimeter    
            % Gland circularity, concavity, convexity
            % Gland perimeter irregularity
            % Ratio - Total Gland Area : Gland Lumen Area
            % Ratio - Gland Cytoplasm : Gland Lumen Area
            % Ratio - Gland Area : Gland Perimeter
            % # Nuclei in Gland Cytoplasm
            % # Nuclei : gland perimeter overlap

        end
        
        %%%%%%%%%%%%%%%%%% % Input: Class index image, class (str)
        % Get Class Mask % % Output: Binary mask of selected class
        %%%%%%%%%%%%%%%%%%    
        function mask = GetMask(this, CI, class)
    
            idx = find(strcmp(this.Key, class));
            
            if (isempty(idx)) error('PixelClassifier::GetMask', 'Incorrect class value supplied.'); end;
            
            mask = false(size(CI));    % Create output logical image
            mask(CI == idx) = 1;       % Map selected class
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%% % Input: Class index image, class (str)
        % Get Processed Class Mask % % Output: Processed binary mask of selected class
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        function pmask = GetProcessedMask(this, img, class)
            
             pmask = this.GetMask(img, class);
             
             if     strcmp(class, 'LUMEN')
                 
                 % do something to lumen
                 
             elseif strcmp(class, 'STROMA')
                 
                 pmask = imopen(pmask, strel('disk', 2));
                 pmask = bwareaopen(pmask, 400);
                 pmask = imfill(pmask, 8, 'holes');
                 
             elseif strcmp(class, 'CYTOPLASM')
                 
                 pmask = bwareaopen(pmask, 800);
                 pmask = imclose(pmask, strel('disk', 2));
                 pmask = imfill(pmask, 8, 'holes');
                 
             elseif strcmp(class, 'NUCLEI')
                 
                 pmask = bwareaopen(pmask, 100);
                 pmask = imopen(pmask, strel('disk', 2));
                 pmask = imdilate(pmask, strel('disk', 2)); % Not sure if necessary
                 pmask = imfill(pmask, 8, 'holes');
                 
             elseif strcmp(class, 'INFLAMMATION') % Inflammation may be removed from model
                 
                 % I think the best way currently is to treat inflammation
                 % as nuclei areas (albeit smaller)
                 
                 pmask = bwareaopen(pmask, 20);
                 
             else
                  error('PixelClassifier::GetProcessedMask - Invalid class submitted!'); 
             end
        end
       
        %%%%%%%%%%%%%%%%%%%%%%% Input: colour image, binary mask
        % Highlight Mask ROIs % Output: colour image, with mask edges
        %%%%%%%%%%%%%%%%%%%%%%%         highlighted
        function himg = MaskHighlight(this, img, mask)
            
            mask = imdilate(edge(mask), strel('disk', 2)); % Edge-dilation of mask 
            
            himg = img;       %  
            r = himg(:,:,1);  % There has to be an easier way to do this?
            r(mask) = 0;      %
            himg(:,:,1) = r;  %
        end
            
        %%%%%%%%%%%%%%%%%% % Returns cell array of labels for CICM features
        % Feature Labels % 
        %%%%%%%%%%%%%%%%%%
        function FV_labels = GetCICMFeatureLabels(this)
            
            FV_labels = cell(1,25); % Pre-allocate cell array
            
            i = 1;
            for h = 1:5
                for g = 1:5
                    FV_labels{i} = strcat(this.Key{h}, '_', this.Key{g});
                    i = i + 1;
                end
            end
            
        end 
        
        %%%%%%%%%%%%%%%%%% % Returns cell array of labels for traditional features
        % Feature Labels % 
        %%%%%%%%%%%%%%%%%% % hard-coded (dur)
        function FV_labels = GetShapeFeatureLabels(this)
          
            FV_labels = {'lumen_area' 'stroma_area' 'cytoplasm_area' 'lumen_stroma_ratio' ...
                'lumen_cytoplasm_ratio' 'stroma_cytoplasm_ratio' ...
                'nuclei_in_stroma' 'nuclei_in_stroma_average_area' 'nuclei_in_stroma_disorder' ...
                'nuclei_in_cytoplasm' 'nuclei_in_cytoplasm_average_area' 'nuclei_in_cytoplasm_disorder'};
            
        end 
    end
    
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%  
    % Utility/Misc Functions %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods(Static, Access = 'public')
       
        % Reshapes a colour image to feature vector format
        function FV = TileToFeatureVector(tile)
            [X Y Z ] = size(tile);
            FV = reshape(tile, X*Y, Z);
        end
        % Reshapes feature vector back to colour image.
        function T = FeatureVectorToTile(FV, X, Y);
            [~, Z] = size(FV);
            T = reshape(FV, X, Y, Z);
        end
        
      
       
    end
end

