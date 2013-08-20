function bool = wekaPathCheck()
% Add this line to to the classpath.txt file and restart matlab:
%
%   'C:\path\to\Weka-X-Y\weka.jar' (Windows)
%   '/path/to/Weka-X-Y/weka.jar' (Linux)
%    
% Replace 'X-Y' as necessary depending on the version. (To edit, type 'edit classpath.txt').
% 
% Alternatively, weka can be added to the classpath in matlab scripts using:
%       
%   javaaddpath('/path/to/Weka-X-Y/weka.jar')
%
    bool = true;
    w = strfind(javaclasspath('-all'),'weka.jar');
    if(isempty([w{:}]))
        bool = false;
        fprintf('\nPlease add weka.jar to the matlab java class path.\n');
        help wekaPathCheck;
    end
end