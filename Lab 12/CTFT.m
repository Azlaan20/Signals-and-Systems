function X = CTFT(x)
    syms w t
    X = int(x * exp(-1i * w * t), t, -Inf, Inf);
end
