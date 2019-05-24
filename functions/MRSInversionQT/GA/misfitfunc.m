function mfit=misfitfunc(d_obs,d_est,E,dataType,instPhase)
%% Function to calculate the data misfit
switch dataType
    case 1 % amp
        ErrorW = (d_obs - abs(d_est))./E;
    case 2 % rot amp, i.e. real
        ErrorW = (d_obs - abs(d_est))./E;
    case 3 % complex
        d_est  = abs(d_est).*exp(1i*(angle(d_est) - instPhase));
        ErrorW = ([real(d_obs) imag(d_obs)] - [real(d_est) imag(d_est)])./[E E];
end


mfit = sqrt(sum(sum(ErrorW.^2)))/sqrt(numel(ErrorW));


