function [Bxt Byt Bzt] = SLoop(size, x0, y0, z, f, sm, zm, res)

m0    = 4*pi*1.0e-7;
if 1%res
    [Bxt Byt Bzt] = Primary(size,x0,y0,z);
else
    Bzt = dblquad(@vmdz, size/2, -size/2, size/2, -size/2, 1e-10);
    Bxt = dblquad(@vmdx, size/2, -size/2, size/2, -size/2, 1e-10);
    Byt = 0;
end

    function Bz = vmdz(x, y)
        if y~=y0
            y0 = y0+eps;
        end
        r  = sqrt((x-x0).^2 + (y-y0)^2);
        Bz = zeros(length(x),1);
        if 0%res
            Bz(x~=x0)  = 3/4*z^2*m0 ./ r(x~=x0).* (r(x~=x0).^2+z^2).^(-2.5);
        else
            for m = 1:length(x)
                if x(m)~=x0 && y~=y0
                    [w,k] = digHT('J0','long');
                    k     = k/r(m);
                    [Fz]  = PhiTE(sm, zm, z, f, k, 1);
                    Bz(m) = Fz*w' * m0 /(2*pi*r(m));
                end
            end
        end
    end

    function [Bx] = vmdx(x, y)
        r   = sqrt((x-x0).^2 + (y0-y)^2);
        phi = atan2(y-y0, x-x0);
        Bx  = zeros(length(x),1);
        if 0%res
            Bx(x~=x0) = 3/4*z* m0 * (r(x~=x0).^2+z^2).^(-2.5).*sin(-phi(x~=x0));
        else
            for m = 1:length(x)
                if x(m)~=x0 && y~=y0
                    [w,k] = digHT('J1','long');
                    k     = k/r(m);
                    [Fr]  = PhiTE(sm, zm, z, f, k, 2);
                    Bx(m) = Fr*w' * m0 * sin(-phi(m))/(2*pi*r(m));
                end
            end
        end
    end

end

function [F] =	PhiTE(sm, zm, z, f, k, comp)

m0 = 4*pi*1.0e-7;
w  = 2*pi*f;
ns = length(sm);

% intrinsic layer imedance of the underlying halfspace
alpha(ns,:) = sqrt(1i*w*m0*sm(end)+k.^2);
Bm(ns,:)    = alpha(ns,:);

% strata impedances by Wait's recurrence relation
for	n	    = ns-1:-1:1
    alpha(n,:) = sqrt(1i*w*m0*sm(n)+k.^2);
    Bm(n,:)    = alpha(n,:) .* (Bm(n+1)+alpha(n,:).*tanh(alpha(n,:)*(zm(n+1)-zm(n))))./(alpha(n,:)+Bm(n+1,:).*tanh(alpha(n,:)*(zm(n+1)-zm(n))));
end

% in which layer is the point to compute
z_in = find(z>zm, 1, 'last');

% TE-Potential at all boundaries down to the target layer
switch comp
    case 1 % z-component
        Fm(1,:)		=	k .^3 ./(k+Bm(1,:));
    case 2 % r-component
        Fm(1,:)		=	Bm(1,:) .* k.^2 ./ (k+Bm(1,:));
end
for	n =	1:z_in-1
    Fm(n+1,:) =	Fm(n,:) .* ((alpha(n,:)+Bm(n,:))./(alpha(n,:)+Bm(n+1,:))).* exp(-alpha(n,:)*(zm(n+1)-zm(n)));
end

% TE-Potential from the boundary to the target point
if z_in == length(sm)
    F  = Fm(z_in,:) .* (exp(-alpha(z_in,:) .* (z - zm(z_in))));
else
    t1 = ((Bm(z_in+1,:)-alpha(z_in,:)) ./ (Bm(z_in+1,:)+alpha(z_in,:)));
    t2 = exp(-alpha(z_in,:) .* (2*(zm(z_in+1)) - zm(z_in)-z));
    t3 = exp(-alpha(z_in,:) .* (z - zm(z_in)));
    t4 = (1 + (Bm(z_in,:) ./ alpha(z_in,:)))./2.0;
    
    switch comp
        case 1
            F    =                       Fm(z_in,:) .* t4 .* (t3 - t1 .* t2);
        case 2
            F    = alpha(z_in,:) ./ k .* Fm(z_in,:) .* t4 .* (t3 + t1 .* t2);
    end
end
end


function [bx,by,bz] = Primary(a,x,y,z)
%*******************************************************************************
%     MATLAB script to compute the primary field from a piecewise linear transmitter loop
%     measured at any point in the subsurface.
%     The transmitter loop apexes do not need to lie in a plane.
%
% --- July 2008 / NBC
%*******************************************************************************

%-------------------------------------------------------------------------------
% --- Enter apex coordinates of the piecewise linear transmitter loop.
% --- The sequence of apices defines the direction of the current.
%-------------------------------------------------------------------------------

h = a/2;
RTx = [
    h  -h  0.00
    h   h  0.00
    -h   h  0.00
    -h  -h  0.00
    ];
% 8 square
% RTx = [
%     a   -a   0
%     0   -a   0
%     0    0   0
%     -a    0   0
%     -a    a   0
%     0    a   0
%     0    0   0
%     a     0   0
%     ];

% --- Repeat the first apex point of the transmitter loop.
nTx = length(RTx);
RTx = [RTx;RTx(1,:)];

mu0 = 4*pi*1.e-7;

r = [x y z];

B = 0;
for n=1:nTx % --- Loop over the number of Tx elements.
    
    RTx1 = RTx(n,:);
    RTx2 = RTx(n+1,:);
    
    rr   = RTx2-RTx1;
    l    = norm(rr);
    e    = rr/l;
    rR1  = r-RTx1;
    lrR1 = norm(rR1);
    Bdir = cross(e,rR1);
    a    = lrR1*lrR1;
    b    = -2*dot(e,rR1);
    
    sq1  = sqrt(a + b*l + l*l);
    sq2  = sqrt(a);
    
    dB   = Bdir*2*l*(l+b)/(sq1*sq2*((2*l+b)*sq2+b*sq1));
    
    B = B + dB;
    
end % END: loop over Tx segments.

B = B*mu0/(4*pi);
bx = B(:,1);
by = B(:,2);
bz = B(:,3);
end