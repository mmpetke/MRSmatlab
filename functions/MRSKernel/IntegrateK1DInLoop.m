function [K] = IntegrateK1DInLoop(measure, earth, B_comps_Tx, B_comps_Rx, Px, dh, dz, nturns, B1)
%========================================================
% Curie Formula: M0 = [N*gamma^2*hq^2/(4*K*T)]*B0 = CF*B0
% gamma = 0.267518*1e9;
% N     = 6.692*1e+28;         % [/m^3]
% hq    = 1.054571628*1e-34;   % Planck's constant/2*pi [J.s]
% K     = 1.3805*1e-23;        % Boltzmann's constant  [J/K]
% T     = 293;                 % absolute temperature  [K]
% CF = N*gamma^2*hq^2/(4*K*T);
%=========================================================

% Inloop configuration demands separated loop kernel calculation 
% toDo: implement all other parameter such as frequency offset, T1

gamma           = 0.267518*1e9;
pm_vec          = measure.pm_vec*nturns;
pm_vec_2ndpulse = measure.pm_vec_2ndpulse*nturns;

Imax_vec        = measure.Imax_vec*nturns; % used for off-res excitation instead of pm_vec

inkl = earth.inkl/360.0*2.0*pi;
decl = earth.decl/360.0*2.0*pi;

% Umrechnung von Kugelkoordinaten in kartesische
B0.x =   cos(inkl) * cos(-decl);
B0.y =   cos(inkl) * sin(-decl);
B0.z = + sin(inkl); %z positiv nach unten !


switch measure.pulsesequence
    case 1 %'FID' % single pulse kernel
        switch measure.pulsetype
%             case 0
%                 K = zeros(length(pm_vec),1);
%                 for n = 1:length(pm_vec)
%                     K_part1 = gamma * earth.erdt^2 * 3.29e-3 * B_comps_Tx.e_zeta .* sin(0.5 * gamma * measure.pm_vec(n) * (B_comps_Tx.alpha - B_comps_Tx.beta));
%                     
%                     K_part2 = B_comps_Rx.e_zeta .* (B_comps_Rx.alpha + B_comps_Rx.beta);
%                     
%                     K_part3 = ((B_comps_Rx.b_1 .* B_comps_Tx.b_1 + B_comps_Rx.b_2 .* B_comps_Tx.b_2 + B_comps_Rx.b_3 .* B_comps_Tx.b_3) + (...
%                         (1i * B0.x * (B_comps_Rx.b_2 .* B_comps_Tx.b_3 - B_comps_Rx.b_3 .* B_comps_Tx.b_2)) + ...
%                         (1i * B0.y * (B_comps_Rx.b_3 .* B_comps_Tx.b_1 - B_comps_Rx.b_1 .* B_comps_Tx.b_3)) + ...
%                         (1i * B0.z * (B_comps_Rx.b_1 .* B_comps_Tx.b_2 - B_comps_Rx.b_2 .* B_comps_Tx.b_1))));
%                     
%                     
%                     K(n,:)   = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));
%                 end
            case 1 % single standard pulse (including off-resonance)
                K     = zeros(length(pm_vec),1);
                taup  = measure.taup1;
                df    = measure.df;
                for n = 1:length(pm_vec)
                    theta    = atan2(0.5*gamma*pm_vec(n)/taup*(B_comps_Tx.alpha - B_comps_Tx.beta),(2*pi*df));
                    flip_eff = sqrt((0.5*gamma*pm_vec(n)*(B_comps_Tx.alpha - B_comps_Tx.beta)).^2 + ...
                        (2*pi*df*taup).^2 );
                    %             m     = sin(theta) .* cos(theta) .* (1-cos(flip)) + ...
                    %                     1i*(sin(theta) .* sin(flip));
                    m     = sin(flip_eff) .* sin(theta) + ...
                        1i*(-1)*sin(theta).*cos(theta) .* (cos(flip_eff) - 1);
                    K_part1 = gamma * earth.erdt^2 * 3.29e-3 * Px .* B_comps_Tx.e_zeta .* m;
                    
                    K_part2 = B_comps_Rx.e_zeta .* (B_comps_Rx.alpha + B_comps_Rx.beta);
                    
                    K_part3 = ((B_comps_Rx.b_1 .* B_comps_Tx.b_1 + B_comps_Rx.b_2 .* B_comps_Tx.b_2 + B_comps_Rx.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_Rx.b_2 .* B_comps_Tx.b_3 - B_comps_Rx.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_Rx.b_3 .* B_comps_Tx.b_1 - B_comps_Rx.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_Rx.b_1 .* B_comps_Tx.b_2 - B_comps_Rx.b_2 .* B_comps_Tx.b_1))));
                    
                    
                    K(n,:)   = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));

                    %KPart3.KP1 = K_part1;
                    %KPart3.KP2 = K_part2;
                    %KPart3.KP3 = K_part3;
                    %KPart3.K = K_part1 .* K_part2 .* K_part3 .*dh*dz;
                    %KPart3.B1r = B1.r;
                    %KPart3.B1phi = B1.phi;
                end    
            case 2 % single-pulse off-resonance kernel
                K     = zeros(length(Imax_vec),1);
                for n = 1:length(Imax_vec )
                    A = 0.5 * Imax_vec (n) * (B_comps_Tx.alpha - B_comps_Tx.beta);
                    m = interp1([0, measure.adiabatic_B], [0, measure.adiabatic_Mxy], A);
                    m(isnan(m)) = 0; % set all NaN to 0 -> Check!!!!
%                     m = 1;
                    K_part1 = gamma * earth.erdt^2 * 3.29e-3 * Px .* B_comps_Tx.e_zeta .* m;
                    
                    K_part2 = B_comps_Rx.e_zeta .* (B_comps_Rx.alpha + B_comps_Rx.beta);
                    
                    K_part3 = ((B_comps_Rx.b_1 .* B_comps_Tx.b_1 + B_comps_Rx.b_2 .* B_comps_Tx.b_2 + B_comps_Rx.b_3 .* B_comps_Tx.b_3) + (...
                        (1i * B0.x * (B_comps_Rx.b_2 .* B_comps_Tx.b_3 - B_comps_Rx.b_3 .* B_comps_Tx.b_2)) + ...
                        (1i * B0.y * (B_comps_Rx.b_3 .* B_comps_Tx.b_1 - B_comps_Rx.b_1 .* B_comps_Tx.b_3)) + ...
                        (1i * B0.z * (B_comps_Rx.b_1 .* B_comps_Tx.b_2 - B_comps_Rx.b_2 .* B_comps_Tx.b_1))));
                    
                    
                    K(n,:)   = sum(sum(K_part1 .* K_part2 .* K_part3 .*dh*dz));

                    %KPart3.KP1 = K_part1;
                    %KPart3.KP2 = K_part2;
                    %KPart3.KP3 = K_part3;
                    %KPart3.K = K_part1 .* K_part2 .* K_part3 .*dh*dz;
                    %KPart3.B1r = B1.r;
                    %KPart3.B1phi = B1.phi;
                        
                end
        end
    case 2 %'T1'  % double pulse T1 kernel
        msgbox('not yet implemented')
    case 3 %'T2' % double pulse T2 Kernel
        msgbox('not yet implemented')
end


return
