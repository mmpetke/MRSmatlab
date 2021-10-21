function [K] = IntegrateK1DDipole(measure,earth,B_comps_Tx,B_comps_RxX,B_comps_RxY,B_comps_RxZ,Px,dh,dz,nturns,Btype)
%========================================================
% Curie Formula: M0 = [N*gamma^2*hq^2/(4*K*T)]*B0 = CF*B0
% gamma = 0.267518*1e9;
% N     = 6.692*1e+28;         % [/m^3]
% hq    = 1.054571628*1e-34;   % Planck's constant/2*pi [J.s]
% K     = 1.3805*1e-23;        % Boltzmann's constant  [J/K]
% T     = 293;                 % absolute temperature  [K]
% CF = N*gamma^2*hq^2/(4*K*T);
%=========================================================

gamma = 0.267518*1e9;
pm_vec = measure.pm_vec*nturns;
pm_vec_2ndpulse = measure.pm_vec_2ndpulse*nturns;

Imax_vec = measure.Imax_vec*nturns; % used for off-res excitation instead of pm_vec

inkl = earth.inkl/360.0*2.0*pi;
decl = earth.decl/360.0*2.0*pi;

% Umrechnung von Kugelkoordinaten in kartesische
B0.x = cos(inkl) * cos(-decl);
B0.y = cos(inkl) * sin(-decl);
B0.z = + sin(inkl); % z positiv nach unten!

switch measure.pulsesequence
    case 1 %'FID' % single pulse kernel
        switch measure.pulsetype
            
            case 0 % single standard pulse (without off-resonance) NOT USED
                K = zeros(length(pm_vec),1);
                for n = 1:length(pm_vec)
                    % excitation
                    m = sin(0.5 * gamma * measure.pm_vec(n) * (B_comps_Tx.alpha - B_comps_Tx.beta));
                    % magnetization
                    switch Btype
                        case 7 % dB/dt
                            mag = gamma * earth.erdt^2 * 3.29e-3;
                        case 8 % B
                            mag = -1i * earth.erdt * 3.29e-3;
                    end
                    K_part1 = mag * Px .* B_comps_Tx.e_zeta .* m;
                    
                    K_part2 = B_comps_Rx.e_zeta .* (B_comps_Rx.alpha + B_comps_Rx.beta);
                    
                    K_part3 = ((B_comps_Rx.b_1 .* B_comps_Tx.b_1 + B_comps_Rx.b_2 .* B_comps_Tx.b_2 + B_comps_Rx.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_Rx.b_2 .* B_comps_Tx.b_3 - B_comps_Rx.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_Rx.b_3 .* B_comps_Tx.b_1 - B_comps_Rx.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_Rx.b_1 .* B_comps_Tx.b_2 - B_comps_Rx.b_2 .* B_comps_Tx.b_1))));                    
                    
                    K(n,:)   = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
                end
                
            case 1 % single standard pulse (including off-resonance)
                K = zeros(length(pm_vec),1);
                taup = measure.taup1;
                df = measure.df;
                
                for n = 1:length(pm_vec)
                    % excitation
                    theta = atan2(0.5*gamma*pm_vec(n)/taup*(B_comps_Tx.alpha - B_comps_Tx.beta),(2*pi*df));
                    flip_eff = sqrt((0.5*gamma*pm_vec(n)*(B_comps_Tx.alpha - B_comps_Tx.beta)).^2 + ...
                        (2*pi*df*taup).^2 );
                    % m     = sin(theta) .* cos(theta) .* (1-cos(flip)) + ...
                    %         1i*(sin(theta) .* sin(flip));
                    m = sin(flip_eff) .* sin(theta) + ...
                        1i*(-1)*sin(theta).*cos(theta) .* (cos(flip_eff) - 1);
                    
                    % magnetization
                    switch Btype
                        case 7 % dB/dt
                            mag = gamma * earth.erdt^2 * 3.29e-3;
                        case 8 % B
                            mag = -1i * earth.erdt * 3.29e-3;
                    end
                    K_part1 = mag * Px .* B_comps_Tx.e_zeta .* m;

                    %% x
                    K_part2 = B_comps_RxX.e_zeta .* (B_comps_RxX.alpha + B_comps_RxX.beta);
                    
                    K_part3 = ((B_comps_RxX.b_1 .* B_comps_Tx.b_1 + B_comps_RxX.b_2 .* B_comps_Tx.b_2 + B_comps_RxX.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_RxX.b_2 .* B_comps_Tx.b_3 - B_comps_RxX.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_RxX.b_3 .* B_comps_Tx.b_1 - B_comps_RxX.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_RxX.b_1 .* B_comps_Tx.b_2 - B_comps_RxX.b_2 .* B_comps_Tx.b_1))));
                    
                    K(n,:,1) = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
                    
                    %% y
                    K_part2 = B_comps_RxY.e_zeta .* (B_comps_RxY.alpha + B_comps_RxY.beta);
                    
                    K_part3 = ((B_comps_RxY.b_1 .* B_comps_Tx.b_1 + B_comps_RxY.b_2 .* B_comps_Tx.b_2 + B_comps_RxY.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_RxY.b_2 .* B_comps_Tx.b_3 - B_comps_RxY.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_RxY.b_3 .* B_comps_Tx.b_1 - B_comps_RxY.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_RxY.b_1 .* B_comps_Tx.b_2 - B_comps_RxY.b_2 .* B_comps_Tx.b_1))));
                    
                    K(n,:,2) = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
                    
                    %% z
                    K_part2 = B_comps_RxZ.e_zeta .* (B_comps_RxZ.alpha + B_comps_RxZ.beta);
                    
                    K_part3 = ((B_comps_RxZ.b_1 .* B_comps_Tx.b_1 + B_comps_RxZ.b_2 .* B_comps_Tx.b_2 + B_comps_RxZ.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_RxZ.b_2 .* B_comps_Tx.b_3 - B_comps_RxZ.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_RxZ.b_3 .* B_comps_Tx.b_1 - B_comps_RxZ.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_RxZ.b_1 .* B_comps_Tx.b_2 - B_comps_RxZ.b_2 .* B_comps_Tx.b_1))));
                    
                    K(n,:,3) = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
                    
                end
                
            case 2 % single adiabatic pulse using Bloch-modeled B
                K = zeros(length(Imax_vec),1);
                for n = 1:length(Imax_vec )
                    % excitation
                    A = 0.5 * Imax_vec (n) * (B_comps_Tx.alpha - B_comps_Tx.beta);
                    m = interp1([0, measure.adiabatic_B], [0, measure.adiabatic_Mxy], A);
                    m(isnan(m)) = 0; % set all NaN to 0 -> Check!!!!
                    % m = 1;
                    
                    % magnetization
                    switch Btype
                        case 7 % dB/dt
                            mag = gamma * earth.erdt^2 * 3.29e-3;
                        case 8 % B
                            mag = -1i * earth.erdt * 3.29e-3;
                    end
                    K_part1 = mag * Px .* B_comps_Tx.e_zeta .* m;
                    
                    %% x
                    K_part2 = B_comps_RxX.e_zeta .* (B_comps_RxX.alpha + B_comps_RxX.beta);
                    
                    K_part3 = ((B_comps_RxX.b_1 .* B_comps_Tx.b_1 + B_comps_RxX.b_2 .* B_comps_Tx.b_2 + B_comps_RxX.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_RxX.b_2 .* B_comps_Tx.b_3 - B_comps_RxX.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_RxX.b_3 .* B_comps_Tx.b_1 - B_comps_RxX.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_RxX.b_1 .* B_comps_Tx.b_2 - B_comps_RxX.b_2 .* B_comps_Tx.b_1))));
                    
                    K(n,:,1) = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
                    
                    %% y
                    K_part2 = B_comps_RxY.e_zeta .* (B_comps_RxY.alpha + B_comps_RxY.beta);
                    
                    K_part3 = ((B_comps_RxY.b_1 .* B_comps_Tx.b_1 + B_comps_RxY.b_2 .* B_comps_Tx.b_2 + B_comps_RxY.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_RxY.b_2 .* B_comps_Tx.b_3 - B_comps_RxY.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_RxY.b_3 .* B_comps_Tx.b_1 - B_comps_RxY.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_RxY.b_1 .* B_comps_Tx.b_2 - B_comps_RxY.b_2 .* B_comps_Tx.b_1))));
                    
                    K(n,:,2) = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
                    
                    %% z
                    K_part2 = B_comps_RxZ.e_zeta .* (B_comps_RxZ.alpha + B_comps_RxZ.beta);
                    
                    K_part3 = ((B_comps_RxZ.b_1 .* B_comps_Tx.b_1 + B_comps_RxZ.b_2 .* B_comps_Tx.b_2 + B_comps_RxZ.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_RxZ.b_2 .* B_comps_Tx.b_3 - B_comps_RxZ.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_RxZ.b_3 .* B_comps_Tx.b_1 - B_comps_RxZ.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_RxZ.b_1 .* B_comps_Tx.b_2 - B_comps_RxZ.b_2 .* B_comps_Tx.b_1))));
                    
                    K(n,:,3) = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
                end
                
            case 3 % Mp after imperfect PP-ramp switch-off
				% EXPERIMENTAL
                K = zeros(length(pm_vec),1);
                for n = 1:length(pm_vec)
                    m = complex(measure.Mp.x1,measure.Mp.y1);
                    
                    % magnetization
                    switch Btype
                        case 7 % dB/dt
                            mag = gamma * earth.erdt^2 * 3.29e-3;
                        case 8 % B
                            mag = -1i * earth.erdt * 3.29e-3;
                    end
                    K_part1 = mag .* m;
                    
                    %% x
                    K_part2 = B_comps_RxX.e_zeta .* (B_comps_RxX.alpha + B_comps_RxX.beta);
                    
                    K(n,:,1) = sum(sum(K_part1 .* K_part2 .*dh*dz));
                    
                    %% y
                    K_part2 = B_comps_RxY.e_zeta .* (B_comps_RxY.alpha + B_comps_RxY.beta);
                    
                    K(n,:,2) = sum(sum(K_part1 .* K_part2 .*dh*dz));
                    
                    %% z
                    K_part2 = B_comps_RxZ.e_zeta .* (B_comps_RxZ.alpha + B_comps_RxZ.beta);
                    
                    K(n,:,3) = sum(sum(K_part1 .* K_part2 .*dh*dz));
                end
        end
        
    case 2 %'T1' % (double pulse) T1 kernel        
        switch measure.pulsetype
            
            case 1
				% EXPERIMENTAL
                K = zeros(length(pm_vec)*length(measure.taud),1);
                for n = 1:length(pm_vec) % loop pulse moments
                    flip1 = 0.5 * gamma * pm_vec(n) * (B_comps_Tx.alpha - B_comps_Tx.beta);
                    
                    for td = 1:length(measure.taud) % loop tau
                        
                        % for tau --> infinity (>50s) in T1 inversion first FID is used,
                        % i.e. first pulse
                        if measure.taud(td) < 50
                            flip2 = 0.5 * gamma * pm_vec_2ndpulse(n) * (B_comps_Tx.alpha - B_comps_Tx.beta);
                        else
                            flip2 = 0.5 * gamma * pm_vec(n) * (B_comps_Tx.alpha - B_comps_Tx.beta);
                        end
                        
                        m = sin(flip2).*(1-(1-cos(flip1))*exp(-measure.taud(td)/earth.T1cl));
                        
                        % magnetization
                        switch Btype
                            case 7 % dB/dt
                                mag = gamma * earth.erdt^2 * 3.29e-3;
                            case 8 % B
                                mag = -1i * earth.erdt * 3.29e-3;
                        end
                        
                        K_part1 = mag.* Px .* B_comps_Tx.e_zeta .* m;
                        
                        %% x
                        K_part2 = B_comps_RxX.e_zeta .* (B_comps_RxX.alpha + B_comps_RxX.beta);
                        
                        K_part3 = ((B_comps_RxX.b_1 .* B_comps_Tx.b_1 + B_comps_RxX.b_2 .* B_comps_Tx.b_2 + B_comps_RxX.b_3 .* B_comps_Tx.b_3) + (...
                            (1i * B0.x * (B_comps_RxX.b_2 .* B_comps_Tx.b_3 - B_comps_RxX.b_3 .* B_comps_Tx.b_2)) + ...
                            (1i * B0.y * (B_comps_RxX.b_3 .* B_comps_Tx.b_1 - B_comps_RxX.b_1 .* B_comps_Tx.b_3)) + ...
                            (1i * B0.z * (B_comps_RxX.b_1 .* B_comps_Tx.b_2 - B_comps_RxX.b_2 .* B_comps_Tx.b_1))));
                        
                        K((td-1)*length(pm_vec) + n,:,1) = sum(sum(K_part1 .* K_part2 .* K_part3 .* dh*dz));
                        
                        %% y
                        K_part2 = B_comps_RxY.e_zeta .* (B_comps_RxY.alpha + B_comps_RxY.beta);
                        
                        K_part3 = ((B_comps_RxY.b_1 .* B_comps_Tx.b_1 + B_comps_RxY.b_2 .* B_comps_Tx.b_2 + B_comps_RxY.b_3 .* B_comps_Tx.b_3) + (...
                            (1i * B0.x * (B_comps_RxY.b_2 .* B_comps_Tx.b_3 - B_comps_RxY.b_3 .* B_comps_Tx.b_2)) + ...
                            (1i * B0.y * (B_comps_RxY.b_3 .* B_comps_Tx.b_1 - B_comps_RxY.b_1 .* B_comps_Tx.b_3)) + ...
                            (1i * B0.z * (B_comps_RxY.b_1 .* B_comps_Tx.b_2 - B_comps_RxY.b_2 .* B_comps_Tx.b_1))));
                        
                        K((td-1)*length(pm_vec) + n,:,2) = sum(sum(K_part1 .* K_part2 .* K_part3 .* dh*dz));
                        
                        %% z
                        K_part2 = B_comps_RxZ.e_zeta .* (B_comps_RxZ.alpha + B_comps_RxZ.beta);
                        
                        K_part3 = ((B_comps_RxZ.b_1 .* B_comps_Tx.b_1 + B_comps_RxZ.b_2 .* B_comps_Tx.b_2 + B_comps_RxZ.b_3 .* B_comps_Tx.b_3) + (...
                            (1i * B0.x * (B_comps_RxZ.b_2 .* B_comps_Tx.b_3 - B_comps_RxZ.b_3 .* B_comps_Tx.b_2)) + ...
                            (1i * B0.y * (B_comps_RxZ.b_3 .* B_comps_Tx.b_1 - B_comps_RxZ.b_1 .* B_comps_Tx.b_3)) + ...
                            (1i * B0.z * (B_comps_RxZ.b_1 .* B_comps_Tx.b_2 - B_comps_RxZ.b_2 .* B_comps_Tx.b_1))));
                        
                        K((td-1)*length(pm_vec) + n,:,3) = sum(sum(K_part1 .* K_part2 .* K_part3 .* dh*dz));
                    end
                    
                end
                
            case 2
                msgbox('not yet implemented');
                
            case 3
                msgbox('This should not have happened');
        end
        
    case 3 %'T2' % double pulse T2 Kernel
        msgbox('not yet implemented');
end

return