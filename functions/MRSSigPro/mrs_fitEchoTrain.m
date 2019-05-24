function [fitpar,signal,errorpar] = mrs_fitEchoTrain(t,v,echotimes,lb,ini,ub)

%% Rescaling V to nV 
sscale = 1e9;   
ini(2:end) = ini(2:end)*sscale;
lb(2:end)  = lb(2:end) *sscale;
ub(2:end)  = ub(2:end) *sscale;


%% rotate 
ph = [-pi:.01:pi];
for iP = 1:length(ph)
    s(iP) =  sum(imag(v*exp(-1i*ph(iP))));
end
[tmp1,tmp2] = max(1./s);
rotPhase    = ph(tmp2);
if sum(v*exp(-1i*rotPhase)) < 0
    rotPhase = rotPhase - pi;
end
v           = v*exp(-1i*rotPhase);
%rotPhase=0;

%% Reshaping input if required
if size(v,1) > 1
    v = v.';
end
if size(t,1) > 1
    t = t.';
end
para = [t,echotimes,length(echotimes)]; 
V    = [real(v) imag(v)]*sscale;   % only real part is used

%% Set fit options
options = optimset('Display','none',...
                   'MaxFunEvals',10^6,...
                   'LargeScale','on',...
                   'MaxIter',100,...
                   'TolFun',1e-6,...
                   'TolX',1e-6);
%% fitting               
if 1
    [fitpar,resnorm,residual,exitflag,output,lambda,jacobian] = lsqcurvefit(@minfun_2, ini, para, V, lb, ub, options);

    s_i = std(residual)^2;
    gtg = inv(jacobian.'*jacobian);
    cov = sqrt(diag(s_i*gtg));
end

%% average top of the echo
if 0
    fitpar(1)   = 0;
    cov(1) = 0;
    for iE=1:length(echotimes)
        fitpar(iE+1) = mean(real(V(find(t > echotimes(iE)-5e-3 & t < echotimes(iE)+5e-3))));
        cov(iE+1) = std(real(V(find(t > echotimes(iE)-5e-3 & t < echotimes(iE)+5e-3))));
    end
end

%% rearange for output
s               = minfun_2(fitpar,para)./sscale;
s               = s*exp(1i*rotPhase);
fitpar(2:end)   = fitpar(2:end)/sscale;
% signal          = complex(s(1:length(t)),s(length(t)+1:end));
signal          = s(1:length(t));
errorpar(1)     = full(cov(1)); 
errorpar(2:length(cov))   = full(cov(2:end))./sscale;
end

%% Minimization function
% go for a mono-T2 fit
% function [F] = minfun(x,para)
%     nE = para(end);
%     echotimes = para(end-nE:end-1);
%     t   = para(1:end-1-nE);
%     sigR = zeros(size(t));
%     sigI = zeros(size(t));
%     
%     for iE=1:nE
%         t_echo = t - echotimes(iE);
%         sigR = max(sigR,x(1)*exp(-echotimes(iE)/x(3)).*exp(-(t_echo.^2)/x(2)^2));
%         sigI = zeros(size(t));%max(sig,x(1)*exp(-echotimes(iE)/x(3)).*exp(-(t_echo.^2)/x(2)^2));
%     end
%     F = [sigR sigI];
% end

%go for a single amplitude for each echo
function [F] = minfun_2(x,para)
    nE = para(end);
    echotimes = para(end-nE:end-1);
    t   = para(1:end-1-nE);
    sigR = zeros(size(t));
    sigI = zeros(size(t));
    
    for iE=1:nE
        t_echo = t - echotimes(iE);
        sigR = max(sigR,x(1+iE).*exp(-(t_echo.^2)/x(1)^2));
        sigI = zeros(size(t));%max(sig,x(1)*exp(-echotimes(iE)/x(3)).*exp(-(t_echo.^2)/x(2)^2));
    end
    F = [sigR sigI];
end