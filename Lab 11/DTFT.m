function [X] = DTFT(x,N)
 syms w
 X = 0;
 for n = 0:N-1
 X = X + (x(n+1) .* exp(-1j .* w .* n));
 end
end