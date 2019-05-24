function [B1, dh] = B1sloop(sloop, z, Dz, f, sm, zm, res)

[x0, dx]   = MakeXvec(sloop, z, Dz);
y0   = x0;

dx2 = [flipud(dx); dx];

Bx = zeros(length(x0));
By = zeros(length(x0));
Bz = zeros(length(x0));
for m = 1:length(x0)
    for n = 1:length(x0)
        [Bx(n,m) By(n,m) Bz(n,m)] = SLoop(sloop, x0(n), y0(m), z, f, sm, zm, res);
    end
end

dummy = [-fliplr(Bx) Bx];
B1.x   = [flipud(dummy); dummy];
B1.y   = B1.x.';
dummy  = [fliplr(Bz) Bz];
B1.z   = [flipud(dummy); dummy];

% plot fields for debugging
% x02 = [flipud(x0); x0];
% figure; pcolor(x02, x02, (real(B1.x))); axis equal; axis tight;
% figure; pcolor(xv2, xv2, (real(Byt))); axis equal; axis tight;
% figure; pcolor(xv2, xv2, (real(Bzt))); axis equal; axis tight;
% figure; pcolor(xv2, xv2, sqrt(abs(Bx.^2+By.^2))); axis equal; axis tight;
dh = dx2*dx2';
end