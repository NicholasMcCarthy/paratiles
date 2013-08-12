
function java_array = fv2javaarray( mat_array )
% MAT2JAVAARRAY 
% Convert a feature vector to a java double array 
% Assumes that the feature vector is a single row multi-column matlab
% matrix 

java_array = javaArray('java.lang.Double', length(mat_array));

for x = 1:length(mat_array)
    java_array(x) = java.lang.Double(mat_array(x));
end




