function [m,e,J] = mrs_MonoComplexExpFitCGLSCDP(y,t,ini,lb,ub)

V = [real(y) imag(y)];


%% CGLSCDP
m = ini;

for it=1:20
    d_est      = ForwardSignal(m,t);
    G          = GetJacobi(m,t);
    dD         = (V - [real(d_est) imag(d_est)]).';
    %misfit(it) = norm(dD)/sqrt(length(dD));
    dm         = inv(G'*G + 10/sqrt(it)*eye(4))*G'*dD;
%     dm         = cglscdp(G,dD,10/sqrt(it));
    m          = linesearch(m,dm,V,t);
    % apply bounds
    m(m<lb) = lb(m<lb);
    m(m>ub) = lb(m>ub);
end

e = dD;
J = G;


end


%% subfunctions

function D = ForwardSignal(x,t)
    D = x(1)*exp(-t/x(2)).*complex(cos(2*pi*x(3).*t+x(4)),sin(2*pi*x(3).*t+x(4)));
end

function J = GetJacobi(x,t)
    J(:,1) = [exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4)) ...
              exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4))];
    J(:,2) = [x(1)/x(2)^2*t.*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4)) ...
              x(1)/x(2)^2*t.*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4))];
    J(:,3) = [-x(1)*2*pi*t.*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4)) ...
              x(1)*2*pi*t.*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4))];
    J(:,4) = [-x(1)*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4)) ...
              x(1)*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4))];
end


% function x = cglscdp(A,b,lam,C,D,P,dx,x0)
% 
%     if nargin<3, error('Too less input arguments!'); end
%     [m,n] = size(A);
%     if nargin<3, lam=1; end
%     if nargin<4, C=1; end %speye(n); end
%     if nargin<5, D=1; end %ones(m,1); end
%     if nargin<6, P=1; end
%     if (nargin<7)||(isequal(dx,0)), dx=zeros(n,1); end
%     if (nargin<8)||(isequal(x0,0))
%         x0=zeros(n,1); 
%     end
%     if min(size(D))==1, D=spdiags(D(:),0,length(D)); end
%     L=C;
%     % Prepare for CG iteration.
%     %     PI = P\speye(size(P,1));
%     PI     = P';
%     su     = sum(P,1);
%     for i=1:length(su),
%         if su(i)>0, PI(i,:)=PI(i,:)/su(i); end
%     end
%     x      = PI*x0;
%     z      = D*(b - (A*(P*x))); % residuum of unregularized equation
%     p      = (z'*D*A*P)';
%     acc    = 1e-7;
%     abbr   = p'*p*acc;             % goal for norm(r)^2
%     p      = p-PI*(L*(x0+dx))*lam; % residuum of normal equation
%     r      = p;
%     normr2 = r'*r;
%     % Iterate.
%     j=0;
% 
%     while(normr2>abbr)
%         j         = j+1;
%         q         = D*(A*(P*p));   % Zeile 1
%         normr2old = normr2;
%         Pp        = P*p;
%         alpha     = normr2/(q'*q+Pp'*(L*Pp)*lam); % Zeile 2
%         x         = (x + alpha*p);   % Zeile 3
%         z         = z - alpha*q;   % Zeile 4
%         r         = (z'*D*A*P)'-PI*(L*(P*x+dx))*lam;
%         normr2    = r'*r;
%         beta      = normr2/normr2old;
%         p         = r + beta*p;
%     end
%     x=P*x;
% end

function x = linesearch(X,dx,V,t)

    density  = 5;
    step     = [2,.5];
    dDD      = zeros(density,1);
    mc       = .1;

    for rr=1:length(step)
        ms   = logspace(log10(10^(log10(mc)-step(rr))),...
                        log10(10^(log10(mc)+step(rr))),density);
        for kk=1:density
            x        = X + dx.'*ms(kk);
            d_est    = ForwardSignal(x,t);
            dDD(kk)  = norm(V - [real(d_est) imag(d_est)]);
        end
        [dummy,index] = min(abs(dDD));
        mc        = ms(index);
    end
    x        = X + dx.'*mc;
end

