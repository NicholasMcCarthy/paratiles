function newdata = wekaJoinDatasets( varargin )
%WEKAJOINDATASETS Join two Weka Instances datasets together by merging
%horizontally (joining attributes) or vertically (joining instances).
%
%  Input:
%           dataset1    : First dataset to join
%           dataset2    : Second dataset to join
%           direction   : {'horizontal', 'vertical'}
% 
%  Output:  The dataset produced by the merge.
%           
% See also: wekaLoadArff, wekaSaveArff, wekaApplyFilter

%% Check Weka status, imports

if(~wekaPathCheck),wekaOBJ = []; return,end

% Imports
import weka.core.Instances;
import weka.core.Instance;
import weka.core.FastVector;
import weka.core.Attribute;
import java.lang.String;
import java.util.ArrayList;

%% Parse inputs

p = inputParser;

p.addRequired('Dataset1', @(x) isa(x, 'weka.core.Instances'));
p.addRequired('Dataset2', @(x) isa(x, 'weka.core.Instances'));
p.addRequired('Direction', @(x) strcmp(x, 'horizontal') | strcmp(x, 'vertical'));

p.parse(varargin{:});

D1 = p.Results.Dataset1;
D2 = p.Results.Dataset2;
direction = p.Results.Direction;

%% Main


if strcmp(direction, 'horizontal')
    % Merge datasets horizontally by joining attributes .. 
    %
    % Must have same number of instances
    
    if ~(D1.numInstances == D2.numInstances)
        error('MATLAB:wekaJoinDatasets', 'Horizontal merge not possible. Datasets must have an equal number of instances.');
    end
    
    % Using the existin weka function for horizontal merge
    newdata = Instances.mergeInstances(D1, D2);
    
elseif strcmp(direction, 'vertical')
    % Merge datasets vertically by joining instances / observations .. 
    %
    % Must have same number of attributes.  
    
    if ~(D1.numAttributes == D2.numAttributes)
        error('MATLAB:wekaJoinDatasets', 'Vertical merge not possible. Datasets must have an equal number of attributes.');
    end
    
    if ~(D1.classIndex == D2.classIndex)
       error('MATLAB:wekaJoinDatasets', 'Vertical merge not possible. Datasets have different class indices.');
    end
    
    % Merging class Attribute values ..
    classIdx = D1.classIndex;
    
    att1 = D1.attribute(classIdx);
    att2 = D2.attribute(classIdx);
        
    % Create new attribute with values from both dataset class attributes
    new_values = FastVector();
    for i = 0:att1.numValues-1; if ~new_values.contains(att1.value(i)); new_values.addElement(att1.value(i)); end; end;
    for i = 0:att2.numValues-1; if ~new_values.contains(att2.value(i)); new_values.addElement(att2.value(i)); end; end;
            
    new_name = att1.name;
    att_new = weka.core.Attribute(new_name, new_values);
    
    % Get existing D1 class values 
    instance_values = D1.attributeToDoubleArray(classIdx);
    
    % Create new Instances object
    
    class_att_list = ArrayList(1);
    class_att_list.add(att_new);
    class_instance = Instances(att1.name, class_att_list, int8(1))
    
    
    
    % Join values for nominal attributes
%     for a = 0:D1.numAttributes-1
%         
%         att1 = D1.attribute(a);
%         att2 = D2.attribute(a);
%         
%         % If both attributes are nominal, add values from second to first 
%         if (att1.isNominal && att2.isNominal)
%             
%             % Create new attribute with values from both attributes
%             new_values = FastVector();
%             for i = 0:att1.numValues-1; if ~new_values.contains(att1.value(i)); new_values.addElement(att1.value(i)); end; end;
%             for i = 0:att2.numValues-1; if ~new_values.contains(att2.value(i)); new_values.addElement(att2.value(i)); end; end;
%             
%             new_name = att1.name;
%             
%             att_new = weka.core.Attribute(new_name, new_values);
%             
%         else
%             error('MATLAB:wekaJoinDatasets', 'Incompatible attribute types: Attribute %i', a);
%         end
%     end
    
    
    
    
    % Besides concatenating ARFF files with a script I can't find a better
    % way to do this than a for loop .. 
    
    newdata = D1;
    
    for i = 0:D2.numInstances-1
        newdata.add(D2.instance(i));
    end
        
else
    % error OOPS: the inputParser is borked
    error('MATLAB:wekaJoinDatasets', 'If you are seeing this the inputParser is probably broken.');
end

end

%% Roughwork


% inst = D2.instance(0)
% 
% D1.add(inst)



