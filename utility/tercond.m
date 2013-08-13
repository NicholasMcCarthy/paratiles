function ret = tercond( COND, A, B )
% TERCOND Ternary conditional assignment
%   If COND is true, returns A
%   If COND is false, returns B
%   If something else, idk just do it

if COND
    ret = A;
else
    ret = B;
end
