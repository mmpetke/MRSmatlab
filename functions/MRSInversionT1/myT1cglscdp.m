function x = myT1cglscdp(A,b,e,L,lam)
    [m,n]  = size(A);
    dx     = zeros(n,1);
    x0     = zeros(n,1);
    D      = diag(e);
    P      = 1;
    PI     = P';
    su     = sum(P,1);
    for i=1:length(su),
        if su(i)>0, PI(i,:)=PI(i,:)/su(i); end
    end
    x      = PI*x0;
    z      = D*(b - (A*(P*x))); % residuum of unregularized equation
    p      = (z'*D*A*P)';
    acc    = 1e-7;
    abbr   = p'*p*acc;             % goal for norm(r)^2
    p      = p-PI*(L*(x0+dx))*lam; % residuum of normal equation
    r      = p;
    normr2 = r'*r;
    % Iterate.
    j=0;
    fprintf(1,'%.1f',0.0)
    fort=0;oldf=0;
    while(normr2>abbr)
        j         = j+1;
        q         = D*(A*(P*p));   % Zeile 1
        normr2old = normr2;
        Pp        = P*p;
        alpha     = normr2/(q'*q+Pp'*(L*Pp)*lam); % Zeile 2
        x         = (x + alpha*p);   % Zeile 3
        z         = z - alpha*q;   % Zeile 4
        r         = (z'*D*A*P)'-PI*(L*(P*x+dx))*lam;
        normr2    = r'*r;
        beta      = normr2/normr2old;
        p         = r + beta*p;
        fort      = 1+log10(normr2/abbr)/log10(acc);
        if fort>oldf+0.05,
            fprintf(1, '\b\b\b');
            fprintf(1,'%.1f',round(10*fort)/10)
            oldf = fort;
        end
    end
    fprintf(1, '\b\b\b');
    x = P*x;
end
