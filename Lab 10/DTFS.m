function ak = DTFS(x, N)
ak = zeros(1,N);
for k = 1:N
    for n = 1:N
        ak(k) = ak(k) + (1/N) * x(n) * exp(-1i*2*pi*(k)*(n)/N);
    end
end
end