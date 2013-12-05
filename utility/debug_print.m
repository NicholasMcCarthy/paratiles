function debug_print( input_str, debug_flag )
%DEBUG_PRINT Function for only displaying print statements if debug flag is
%set to true. Best accessed by an anonymous function:
%
%   debug_flag = true;
%   debugprint = @(x) debug_print(x, debug_flag);
%   
%   debugprint('This will display since debug_flag is set to true.');

if debug_flag
    disp(input_str);
end

end

