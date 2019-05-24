function m = T1MonoExpFit(t,d,ini,lb,ub)

%% forward for test purpose
% t    = linspace(.01,1,100);
% x(1) =  1;
% x(2) = .1;
% d    = ForwardSignal(x,t);
% m    = [0.1 1]';
% ub   = [100 3]';
% lb   = [0 0]';

%% inversion
% start model

m     = ini(:);
ub    = ub(:);
lb    = lb(:);
alpha = .1;

for it=1:20
    d_est = ForwardSignal(m,t);
    dD    = [d - d_est].';
    G     = GetJacobi(m,t);
    if ~isnan(G)
        dm    = (G'*G + alpha*eye(2))\G'*dD;
        m     = linesearch(m,dm,d,t);
    else
        disp('f')
    end
     % apply bounds
    m(m<lb) = lb(m<lb);
    m(m>ub) = lb(m>ub);
end

end

function J = GetJacobi(x,t)
    J(:,1) = [1-exp(-t/x(2))];
    J(:,2) = [-x(1)/x(2)^2*t.*exp(-t/x(2))];
end
function D = ForwardSignal(x,t)
    D = x(1)*(1-exp(-t/x(2)));
end

function x = linesearch(X,dx,d,t)
    density  = 5;
    step     = [2,.5];
    dDD      = zeros(density,1);
    mc       = .1;

    for rr=1:length(step)
        ms   = logspace(log10(10^(log10(mc)-step(rr))),...
                        log10(10^(log10(mc)+step(rr))),density);
        for kk=1:density
            x        = X + dx*ms(kk);
            d_est    = ForwardSignal(x,t);
            dDD(kk)  = norm(d - d_est);
        end
        [dummy,index] = min(abs(dDD));
        mc        = ms(index);
    end
    x        = X + dx*mc;
end
