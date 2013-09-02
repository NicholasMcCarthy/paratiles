function ret = rnearest( x, q )
%RUP Rounds up or down to nearest specified increment (upwards bias).
%
% Y = rnearest(X, increment) rounds X up or down to the nearest increment.
% 
%   E.g.
%      Rounds up or down to nearest 0.2 increment [1.0, 1.2, 1.4, 1.6, 1.8, 2.0 ..]
%         rup(1.3, 0.2); 
%             ans = 1.4
%
%      Rounds up or down to nearest 0.5 increment [1.0, 1.5, 2.0 .. ]
%         rup(1.1, 0.5)
%             ans = 1

if (rup(x, q) - x) < (x - rdown(x, q)) 
    ret = rup(x, q);
else
    ret = rdown(x, q);
end

end

