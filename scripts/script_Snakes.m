%% Script for active contours implementation

% Author: Nicholas Mccarthy
% Date: 01/11/2013

% N = 50;
% sigma = 20;
% 
% [x y] = meshgrid(round(-N/2):round(N/2), round(-N/2):round(N/2));
% f = exp(-x.^2/(2*sigma^2) - y.^2/(2*sigma^2));
% f = f./sum(f(:));
% 


A = imread('coins.png');
crop_coords = [200 140 70 70];
A = imcrop(A,crop_coords);
A = imnoise(A, 'gaussian');

x = round(40+15*cos(0:0.4:2*pi));
y = round(40+20*sin(0:0.4:2*pi));

figure;
imshow(A);
hold on;
plot([x(:); x(1)],[y(:); y(1)]);


%% Snakes parameters

alpha = 0.001;
beta = 0.4;
gamma = 100;
iterations = 200;

%% Matrix inversion 

N = length(x);
a = gamma * (2*alpha + 6*beta)+1;
b = gamma * (-alpha-4*beta);
c = gamma*beta;

%%
P = diag(repmat(a,1,N));

P = P + diag(repmat(b,1,N-1), 1) + diag(   b, -N+1);
P = P + diag(repmat(b,1,N-1),-1) + diag(   b,  N-1);
P = P + diag(repmat(c,1,N-2), 2) + diag([c,c],-N+2);
P = P + diag(repmat(c,1,N-2),-2) + diag([c,c], N-2);

% http://www.cb.uu.se/~cris/blog/index.php/archives/217/comment-page-1#comm
% ent-2267


%% active contours demo

alpha = 0.01;
beta = 0.8;
gamma = 100;
kappa = 5;
wl = 0.2;
we = 0.2;
wt = 0.2;

iterations = 500;

smth = interate(A, x, y, alpha, beta, gamma, kappa, wl, we, wt, iterations)

disp('Done')

