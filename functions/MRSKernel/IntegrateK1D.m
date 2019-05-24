function K = IntegrateK1D(measure, earth, Bcomps, Px, dh, dz, nturns)
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

Imax_vec        = measure.Imax_vec*nturns; % used for off-res excitation instead of pm_vec

switch measure.pulsesequence
    case 1 %'FID' % single pulse kernel
        switch measure.pulsetype
            case 0 % single standard pulse without off-res.
                K = zeros(length(pm_vec),1);
                for n = 1:length(pm_vec)
                    kern = gamma * earth.erdt^2 * 3.29e-3 * Px .* Bcomps.e_zeta.^2 .* ...
                        (Bcomps.alpha + Bcomps.beta) .* ...
                        sin(0.5 * gamma * pm_vec(n) * (Bcomps.alpha - Bcomps.beta));
                    K(n,:) = sum(sum(kern.*dh*dz));
                    % uncomment for full 3D fig8 kernel
                    %               K(n,:) = kern;
                end
            case 1 % single standard pulse (including off-resonance)
                K     = zeros(length(pm_vec),1);
                taup  = measure.taup1;
                df    = measure.df;
                for n = 1:length(pm_vec)
                    theta    = atan2(0.5*gamma*pm_vec(n)/taup*(Bcomps.alpha - Bcomps.beta),(2*pi*df));
                    flip_eff = sqrt((0.5*gamma*pm_vec(n)*(Bcomps.alpha - Bcomps.beta)).^2 + ...
                        (2*pi*df*taup).^2 );
                    %             m     = sin(theta) .* cos(theta) .* (1-cos(flip)) + ...
                    %                     1i*(sin(theta) .* sin(flip));
                    m     = sin(flip_eff) .* sin(theta) + ...
                        1i*(-1)*sin(theta).*cos(theta) .* (cos(flip_eff) - 1);
                    kern = gamma * earth.erdt^2 * 3.29e-3 * Px .* Bcomps.e_zeta.^2 .* ...
                        (Bcomps.alpha + Bcomps.beta) .* m;
                    K(n,:) = sum(sum(kern.*dh*dz));
                end
            case 2 % single-pulse adiabatic kernel using Bloch-modelled B
                K     = zeros(length(Imax_vec),1);
                for n = 1:length(Imax_vec )
                    A = 0.5 * Imax_vec (n) * (Bcomps.alpha - Bcomps.beta);
                    m = interp1([0, measure.adiabatic_B], [0, measure.adiabatic_Mxy], A);
                    m(isnan(m)) = 0; % set all NaN to 0 -> Check!!!!
%                     m = 1;
                    kern = gamma * earth.erdt^2 * 3.29e-3 * Px .* Bcomps.e_zeta.^2 .* ...
                        (Bcomps.alpha + Bcomps.beta) .* m;
                    K(n,:) = sum(sum(kern.*dh*dz));
                end
        end
    case 2 %'T1' % double pulse T1 kernel
        K = zeros(length(pm_vec)*length(measure.taud),1);
        for n = 1:length(pm_vec) % loop pulse moments            
            flip1 = 0.5 * gamma * pm_vec(n) * (Bcomps.alpha - Bcomps.beta);  
            for td=1:length(measure.taud) % loop tau
                % for tau --> infinity (>50s) in T1 inversion first fid is used,
                % i.e. first pulse
                if measure.taud(td) < 50;
                    flip2 = 0.5 * gamma * pm_vec_2ndpulse(n) * (Bcomps.alpha - Bcomps.beta);
                else
                    flip2 = 0.5 * gamma * pm_vec(n) * (Bcomps.alpha - Bcomps.beta);  
                end
                kern = gamma * earth.erdt^2 * 3.29e-3 * Px .* Bcomps.e_zeta.^2 .* ...
                    (Bcomps.alpha + Bcomps.beta) .* ...
                    sin(flip2).*(1-(1-cos(flip1))*exp(-measure.taud(td)/earth.T1cl));
                K((td-1)*length(pm_vec) + n,:) = sum(sum(kern.*dh*dz));
            end
        end
        
    case 3 %'T2' % double pulse T2 Kernel
        K = zeros(length(pm_vec)*length(measure.taud),1);
        for n = 1:length(pm_vec) % loop pulse moments    
            if pm_vec(n) == pm_vec_2ndpulse(n) % then q's come from kernel qui 
               pm_vec_2ndpulse(n) = 2*pm_vec(n); % and need to multiplied by 2
            end
            flip1 = 0.5 * gamma * pm_vec(n) * (Bcomps.alpha - Bcomps.beta);
            flip2 = 0.5 * gamma * pm_vec_2ndpulse(n) * (Bcomps.alpha - Bcomps.beta);
            
            kern = gamma * earth.erdt^2 * 3.29e-3 * Px .* Bcomps.e_zeta.^2 .* ...
                (Bcomps.alpha + Bcomps.beta) .* ...
                sin(flip1).*sin(flip2/2).^2;
            K(n,:) = sum(sum(kern.*dh*dz));
        end
end

end


