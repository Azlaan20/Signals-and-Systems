function x = ICTFT(X)
    syms w t
    x = 1/(2*pi) * int(X * exp(1i * w * t), w, -Inf, Inf);
end
