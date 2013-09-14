function ret = rup( x, q )
%RUP Rounds up to nearest specified increment.
% 
% Y = rup(X, increment) rounds X up to the nearest increment.
% 
%   E.g.
%      Rounds up to nearest 0.2 increment [1.0, 1.2, 1.4, 1.6, 1.8, 2.0 ..]
%         rup(1.3, 0.2); 
%             ans = 1.4
%
%      Rounds up to nearest 0.5 increment [1.0, 1.5, 2.0 .. ]
%         rup(1.1, 0.5)
%             ans = 1.5


ret = floor(x) +  ceil( (x - floor(x)) / q) * q;

end

