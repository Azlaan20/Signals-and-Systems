function xn = IDTFS(ak,N)
xn = zeros(1,N);
for n = 1:N
    for k = 1:N
        xn(n) = xn(n) + ak(k)*exp(1i*2*pi*(k)*(n)/N);
    end
end
end