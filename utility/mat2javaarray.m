function java_array = mat2javaarray( mat_array )
% MAT2JAVAARRAY 
% Convert a matlab matrix to a java double array 

[X Y] = size(mat_array);


java_array = javaArray('java.lang.Double', X, Y);

for x = 1:X
    for y = 1:Y
        java_array(x,y) = java.lang.Double(mat_array(x, y));
    end
end


end