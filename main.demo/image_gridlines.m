M = size(I, 1);
N = size(I, 2);

V = 64;

for k = 1:V:M
    x = [1 N];
    y = [k k];    
    plot(x,y,'Color','green','LineStyle','-');
    plot(x,y,'Color','k','LineStyle',':');
end

for k = 1:V:N
    x = [k k];
    y = [1 M];
    plot(x,y,'Color','w','LineStyle','-');
    plot(x,y,'Color','k','LineStyle',':');
end

hold off