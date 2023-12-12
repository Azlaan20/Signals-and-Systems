function [x] = IDTFT(X, N)
 syms w
 for n = 0:N-1
 x(n+1) = 1/(2.*pi) .* int(X .* exp(1i .* w .* n), w, 0, 2*pi);
 end
end