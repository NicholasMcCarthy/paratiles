function ret = rdown( x, q )
%RDOWN Rounds down to nearest specified increment.
% 
% Y = rdown(X, increment) rounds X down to the nearest increment.
% 
%   E.g.
%      Rounds down to nearest 0.2 increment [1.0, 1.2, 1.4, 1.6, 1.8, 2.0 ..]
%         rdown(1.3, 0.2); 
%             ans = 1.2
%
%      Rounds down to nearest 0.5 increment [1.0, 1.5, 2.0 .. ]
%         rdown(1.1, 0.5)
%             ans = 1

ret = floor(x) + floor( (x - floor(x)) / q) * q;

end

