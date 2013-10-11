classdef PipelinerClass
    %PIPELINERCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(GetAccess = public, SetAccess = private);
        PipelineInfo,          % Pipeline data struct
        ModelInfo,             % Model data struct
        DatasetInfo,           % Dataset data struct
        FilterInfo,            % Filter data
        ImageInfo,             % Image classifier data
    end
    
    properties(GetAccess = public, SetAccess = public);
        print_stage = true,     % Print general stage info
        print_debug = false,     % Print debug statements 
    end
    
    methods
        
        % Constructor class
        function this = PipelinerClass(pl)
            
            if (this.print_stage)
                disp('Constructing pipeline.');
            end
            
            % Assert pl struct has a base field specified 
            assert( isfield(pl, 'root') , 'Pipeliner Error: Missing ''base'' field.');

            % If no 'ver' field given that use the default 'pl' 
            if ~isfield(pl, 'ver');
                pl.ver = 'pl';
            end;

            
            % Generate rest of pl fields
            pl.data_dir     = [pl.dir 'data/'];                             % Pipeline data directory
            pl.model_dir    = [pl.dir 'models/'];                           % Pipeline model directory
            pl.log          = [pl.dir 'output.log'];

            if (this.print_debug)
                disp('Creating pipeline directory structure.');
            end
            
            % Generate pipeline directory layout
            if ~mkdir(pl.dir);       error('Pipeliner Error: Could not create %s base directory.', pl.dir); end;
            if ~mkdir(pl.data_dir);  error('Pipeliner Error: Could not create %s data directory.', pl.data_dir); end;
            if ~mkdir(pl.model_dir); error('Pipeliner Error: Could not create %s model directory.', pl.model_dir); end;

            % Import weka thingies, just in case
            import weka.*;

            % Start matlabpool
            if matlabpool('size') == 0
                matlabpool local 4
            end


            % % Copy this version of script to pipeline dir
            % thisfile = [mfilename('fullpath') '.m'];
            % thisfilename = fliplr(strtok(fliplr(thisfile), '/'));
            % 
            % destfile = [pl.dir thisfilename '.bak'];
            % copyfile(thisfile, destfile);

            this.PipelineInfo = pl;
                        
                            
        end
        
        function savePipelineInfo()
            
            % Save pipeline info and parameters 
            pipeline_info = struct('PipelineInfo', this.PipelineInfo, 'ModelInfo', this.ModelInfo, 'DatasetInfo', this.DatasetInfo, ...
                                    'FilterInfo', this.FilterInfo, 'ImageInfo', this.ImageInfo);
            
            pipeline_info_path = [this.PipelineInfo.dir 'pipeline_info.mat'];

            save(pipeline_info_path, 'pipeline_info');
            
        end
        
        % Set / check model parameters
        function setModelInfo(this, mdl)
           
            % Model parameters 
            assert( isfield(mdl, 'classifier_type') , 'Pipeliner Error: Missing ''classifier_type'' field.');
            assert( isfield(mdl, 'classifier_options') , 'Pipeliner Error: Missing ''classifier_options'' field.');

            if ~isfield(mdl, 'name'); mdl.name = [pl.run]; end
            mdl.mdl_path = [this.PipelineInfo.model_dir mdl.name '.mdl'];
            
            this.ModelInfo = mdl;
        end
        
        % Set / check dataset generation parameters
        function setDatasetInfo(this, ds)
           
            % Dataset parameters
            assert( isfield(ds, 'dataset_dir') ,   'Pipeliner Error: Missing ''dataset_dir'' field.');
            assert( isfield(ds, 'feature_dirs') ,  'Pipeliner Error: Missing ''feature_dirs'' field.');
            assert( isfield(ds, 'label_path') ,    'Pipeliner Error: Missing ''label_path'' field.');
            assert( isfield(ds, 'classes') ,       'Pipeliner Error: Missing ''classes'' field.');
            assert( isfield(ds, 'label_path') ,    'Pipeliner Error: Missing ''label_path'' field.');

            % Set default values for optional inputs / set up values if present
            if ~isfield(ds, 'dataset_name'); ds.dataset_name = ['dataset' pl.run]; end;
            if ~isfield(ds, 'output_type'); ds.output_type = 'arff'; end;
            if ~isfield(ds, 'output_path'); ds.output_path = [this.PipelineInfo.data_dir ds.dataset_name '.' ds.output_type]; end;
            if ~isfield(ds, 'spec_limit'); ds.spec_limit = -1; end;
            
            this.DatasetInfo = ds;
            
        end       
        
        % Set / check filter info
        function setFilterInfo(this, flt)
            % Filter options
            assert( isfield(flt, 'filter_type') ,    'Pipeliner Error: Missing ''filter_type'' field.');
            assert( isfield(flt, 'filter_options') , 'Pipeliner Error: Missing ''filter_options'' field.');
        end
        
        % Set / check image info
        function setImageInfo(this, ic)
            
            % Default tilesize .. 
            if ~isfield(ic, 'tilesize'); ic.tilesize = 256; end;
            
            % Assert images is a field
            assert ( isfield(ic, 'images') ); 
            
            this.ImageInfo = ic;
        end
        
        % Small debugprint method
        function debugprint(str)
           
            if (this.print_debug)
                disp(str);
            end
        end
        
    end
    
end

