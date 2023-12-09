function result = periodic_convolution(x, y)
    N = length(x);
    result = zeros(1, N);
    for n = 1:N
        for m = 1:N
            result(n) = result(n) + x(m) * y(mod((n - m), N) + 1);
        end
    end
end
