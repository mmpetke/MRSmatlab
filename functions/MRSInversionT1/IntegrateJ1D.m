function J = IntegrateJ1D(measure,earth, Bcomps, dh, dz, nturns)
% calculate jacobian matrix, i.e. derivation of the kernel with respect to
% T1
%========================================================
% Curie Formula: M0 = [N*gamma^2*hq^2/(4*K*T)]*B0 = CF*B0
% gamma = 0.267518*1e9;
% N     = 6.692*1e+28;         % [/m^3]
% hq    = 1.054571628*1e-34;   % Planck's constant/2*pi [J.s]
% K     = 1.3805*1e-23;        % Boltzmann's constant  [J/K]
% T     = 293;                 % absolute temperature  [K]
% CF = N*gamma^2*hq^2/(4*K*T);
%=========================================================

gamma           = 0.267518*1e9;
pm_vec          = measure.pm_vec*nturns;
pm_vec_2ndpulse = measure.pm_vec_2ndpulse*nturns;

J = zeros(length(pm_vec)*length(measure.taud),1);
for n = 1:length(pm_vec) % loop pulse moments
    flip1 = 0.5 * gamma * pm_vec(n) * (Bcomps.alpha - Bcomps.beta);
    flip2 = 0.5 * gamma * pm_vec_2ndpulse(n) * (Bcomps.alpha - Bcomps.beta);
    for td=1:length(measure.taud) % loop tau
        kern = -(measure.taud(td)/earth.T1cl^2) * gamma * earth.erdt^2 * 3.29e-3 * Bcomps.e_zeta.^2 .* ...
            (Bcomps.alpha + Bcomps.beta) .* ...
            sin(flip2).*((1-cos(flip1))*exp(-measure.taud(td)/earth.T1cl));
        J((td-1)*length(pm_vec) + n,:) = sum(sum(kern.*dh*dz));
    end
end



return