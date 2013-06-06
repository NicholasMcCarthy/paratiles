

for i = 1:100

    t = 0:pi/i:2*pi;
    % t = t*5;
    [x,y] = meshgrid(t);

    % colordef black;

    figure;

    set(gca, 'ColorOrder', hsv(10));

    subplot(331), plot(t, (sin(x).^2)+(cos(y).^2), 'LineWidth', 2);
    title('sin(x)^2 + cos(y)^2');
    axis([0 2*pi -1 1])
    colormap(jet);


    subplot(332), plot(t, sin(x)+cos(y), 'LineWidth', 2);
    title('sin(x)+ cos(y)' );
    axis([0 2*pi -2 2])

    subplot(333), plot(t, cos(x).*sin(y), 'LineWidth', 2);
    title('cos(x) .* sin(y)');
    axis([0 2*pi -1 1])

    subplot(334), plot(t, (sin(x).^2)-(cos(y).^2), 'LineWidth', 2);
    title('sin(x)^2 - cos(y)^2');
    axis([0 2*pi -1 1])

    subplot(335), plot(sin(t), cos(t), 'c', 'LineWidth', 2);
    title('sin(t) , cos(t)');
    axis equal;

    subplot(336), plot(t, (cos(x).^2).*(sin(y).^3), 'LineWidth', 2);
    title('cos(x)^2 + sin(y)^3');
    axis([0 2*pi -1 1])

    subplot(337), plot(t, (sin(x).^3).*(cos(y).^3), 'LineWidth', 2);
    title('sin(x)^3 .* cos(y)^3');
    axis([0 2*pi -1 1])

    subplot(338), plot(t, (sin(x)/2) .*(cos(y).^(1/12)), 'LineWidth', 2);
    title('sin(x)/2 .* cos(y)^(1/2)');
    axis([0 2*pi -1 1])

    subplot(339), plot(t, (sin(x).^2).*(cos(y).^2), 'LineWidth', 2);
    title('sin(x)^2 .* cos(y)^2');
    axis([0 2*pi -1 1])

    filename = strcat( 'calcfun_', num2str(i), '.png')
    saveas(gcf, filename);
    
end