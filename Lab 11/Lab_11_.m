N1 = 2;
n = -10:10;
x_n = (abs(n) <= N1);
N = length(n);

% Find DTFT of x[n]
X_w = DTFT(x_n, N);

% Find IDFT of X(w)
x_reconstructed = IDTFT(X_w, N);

% Plotting
figure;

% Plot input signal x[n]
subplot(3,1,1);
stem(n, x_n, 'b', 'LineWidth', 1.5);
title('Input Signal x[n]');
xlabel('n');
ylabel('x[n]');

%Plot of DTFT function output
subplot(3,1,2)
ezplot(abs(X_w));
title('Discrete Time Fourier Transform');

% Plot output of IDTFT function
subplot(3,1,3);
stem(n, abs(x_reconstructed), 'r', 'LineWidth', 1.5);
title('Output of IDTFT function');
xlabel('n');
ylabel('IDTFT(X[\omega])');

% Adjust subplot layout
sgtitle('Rectangular Pulse DTFT and IDTFT');

% Ensure the plots are on the same scale
axis tight;

grid on;

x = [1 0 1 0 1];
N1 = length(x);
y = [1 1 0 1 0];
N2 = length(y);

figure;
% LHS
LHS = conv(x,y);
subplot(2,1,1);
stem(abs(LHS));
title('Convolution of Two Discrete Time Signals');

% RHS
A = DTFT(x,N1);
B = DTFT(y,N2);
C = A .* B;
RHS = IDTFT(C, length(LHS));

subplot(2,1,2);
stem(abs(RHS));
title('IDTFT of Product of DTFTs of Two Discrete Time Signals');

grid on;

x = [1 2 3 1 3];
N1 = length(x);
y = [3 4 3 3 2];
N2 = length(y);

figure;
% LHS
LHS = x .* y;
subplot(2,1,1);
stem(abs(LHS));
title('Product of Two Discrete Time Signals');

% RHS
syms w theta
A = DTFT(x, N1);
C = DTFT(y, N2);
B = subs(A, w, theta);
D = subs(C, w, w-theta);
E = B * D;
F = 1/(2.*pi) .* int(E, theta, 0, 2*pi);
RHS = IDTFT(F,length(LHS));

subplot(2,1,2);
stem(abs(RHS));
title('Periodic Convolution of DTFT of Two Discrete Time Signals');
grid on;