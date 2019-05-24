function [fitpar,errorpar] = fitFID_af(t,v,lb,ini,ub)
% function [fitpar,ci] = mrs_fitFID(t,v,lb,ini,ub)
% 
% 4-parameter fit to the complex FID voltage (given in V).
% 
% Input: 
%   t   - time vector [s]
%   v   - complex FID voltage (cos + i*sin) [V]
%   lb  - lower fit bounds (4 parameters, see output)
%   ini - initial guess (4 parameters, see output)
%   ub  - upper fit bounds (4 parameters, see output)
% 
% Output:
%   fitpar(1) - FID amplitude [V]
%         (2) - T2* decay time [s]
%         (3) - Frequency offset, df = fL - fT [Hz] 
%         (4) - FID phase [rad]
%   errorpar  
%   errorpar.e  - fitting resiudals 
%   errorpar.ci - confidence interval for each fitpar; CURRENTLY DISABLED
% 
% Calls: 
%   lsqcurvefit
%
% TUB, 2007
% ed. 29aug2011 Jan Walbrecker
% ed. nov2011 Mike
% =========================================================================

%% Rescaling V to nV 
% lsqcurvefit obviously does not handle relative amps. 
% buuh! -> downscaling amps from [V] to [nV] internally
% Output to handles in [V]
sscale = 1e9;   
ini(1) = ini(1)*sscale;
lb(1)  = lb(1) *sscale;
ub(1)  = ub(1) *sscale;
ini(5) = ini(5)*sscale;
lb(5)  = lb(5) *sscale;
ub(5)  = ub(5) *sscale;
ini(6) = ini(6)*sscale;
lb(6)  = lb(6) *sscale;
ub(6)  = ub(6) *sscale;


%% Reshaping input if required
if size(v,1) > 1
%     v = reshape(v,1,numel(v));
    v = v.';
end
if size(t,1) > 1
    t = t.';
end
V = [real(v) imag(v)]*sscale;   % rearrange for complex fitting



%% Fit FID

% Check if curve fitting toolbox is available
cft = max([license('test', 'Curve_Fitting_Toolbox'),...
           license('test', 'Optimization_Toolbox')]);

switch cft
    case 1 % Curve fitting toolbox available
        % Set fit options
        options = optimset('Display','none',...
                           'MaxFunEvals',10^6,...
                           'LargeScale','on',...
                           'MaxIter',100,...
                           'TolFun',1e-6,...
                           'TolX',1e-6, ...
                           'Jacobian','on');
        [fitpar, resnorm, residual, exitflag, output, lambda, jacobian] = ...
            lsqcurvefit(@minfun, ini, t, V, lb, ub, options);
    case 0 % Curve fitting toolbox not available
        % alternative fitting avoiding matlabs optimization toolbox 
        [fitpar1,residual1,jacobian] = mrs_MonoComplexExpFitCGLSCDP_CoF(v*sscale,t,ini,lb,ub);

        % get alternative start values by mono-exp. amplitude fit
        ite = round(length(t)/2);
        p = polyfit(t(1:ite),log10(abs(v(1:ite))),1);
        ini(1) = 10^p(2)*sscale;
        ini(2) = -1/p(1);
        [fitpar2,residual2,jacobian] = mrs_MonoComplexExpFitCGLSCDP_CoF(v*sscale,t,ini,lb,ub);
        if norm(residual1) < norm(residual2)
            fitpar   = fitpar1;
            residual = residual1;
        else
            fitpar   = fitpar2;
            residual = residual2;
        end
end


%% Calculate confidence intervals
%     ci = nlparci(fitpar,residual,'jacobian',jacobian)';    % 95% confidence interval for fitparameters; dim (2,4) == (lower & upper ci, 4 fitparameters)
% MMP Whats the problem calculating covariances this way? It is  not
% nonlinear erros but better than nothing?
    s_i = std(residual)^2;
    gtg = inv(jacobian.'*jacobian);
    cov = sqrt(diag(s_i*gtg));
    
%     % map phase into [-pi,pi]
%     if abs(fitpar(4)) > pi
%         fitpar(4) = fitpar(4) - sign(fitpar(4))*2*pi;
%     end
%         if abs(ci(1,4)) > pi
%             ci(1,4) = ci(1,4) - sign(ci(1,4))*2*pi;
%         end
%         if abs(ci(2,4)) > pi
%             ci(2,4) = ci(2,4) - sign(ci(2,4))*2*pi;
%         end

%% Rescale output
fitpar(1)   = fitpar(1)/sscale;
fitpar(5)   = fitpar(5)/sscale;
fitpar(6)   = fitpar(6)/sscale;
errorpar.E  = norm(residual)/sqrt(length(residual))/sscale;
errorpar.ci = cov; errorpar.ci(1)= errorpar.ci(1)/sscale;

%             fitpar = [x(1)/sscale x(2) x(3) x(4)];
%             handles.para(iq).ci        = ci;
%             handles.para(iq).ci(:,1)   = handles.para(iq).ci(:,1)/sscale;
%             handles.flags.fitted(iq,1) = 1;
%             handles.para(iq).covmtx    = sqrt(diag(s_i*gtg));

end % function mrs_fitFID


%% Minimization function
function [F,J] = minfun(x,t)
% Fit function: 
% v(t) = v0 * exp(-t/T2*) * [cos(2pi*fL*t+phi)-i*sin(2pi*fL*t+phi)]
% With the QD definition in mrs_quadraturedetection, the imaginary part is 
% the NEGATIVE sine.
% MMP: muss ich nochmal checken aber das -imagpart stimmt denke ich nicht,
% zumindest der numerische test siehe mrsSigPro_QD spricht dagegen
    realpart =  x(1)*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4))+x(5);
%     imagpart = -x(1)*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4)); 
    imagpart = x(1)*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4))+x(6); 
    F        = [realpart imagpart];
    if nargout > 1
%         J = zeros(2*length(t),4);
%         J(:,1) = [ exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4)) ...
%                   -exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4))];
%         J(:,2) = [ x(1)/x(2)^2*t.*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4)) ...
%                   -x(1)/x(2)^2*t.*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4))];
%         J(:,3) = [-x(1)*2*pi*t.*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4)) ...
%                   -x(1)*2*pi*t.*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4))];
%         J(:,4) = [-x(1)*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4)) ...
%                   -x(1)*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4))];
              
              J(:,1) = [exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4)) ...
                  exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4))];
              J(:,2) = [x(1)/x(2)^2*t.*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4)) ...
                  x(1)/x(2)^2*t.*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4))];
              J(:,3) = [-x(1)*2*pi*t.*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4)) ...
                  x(1)*2*pi*t.*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4))];
              J(:,4) = [-x(1)*exp(-t/x(2)).*sin(2*pi*x(3)*t+x(4)) ...
                  x(1)*exp(-t/x(2)).*cos(2*pi*x(3)*t+x(4))];
              J(:,5) = [ones(size(t)) zeros(size(t))];
              J(:,6) = [zeros(size(t)) ones(size(t))];
    end
end