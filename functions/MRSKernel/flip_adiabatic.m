function [flip, phase, Mxy, pulse] = flip_adiabatic(tp, B1_end, fmod, Imod, RDP, flag_loadAHP, flag_plot)
% [flip, phase, pulse] = flip_adiabatic(tp, B1_end, f_end, f_start, sweeptype,T1, T2, Q, method, flag_plot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   - create (adiabatic) pulse from pulse length, frq shift and B field
%   strength (start, end)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        
% Input:
%   tp          : pulse length [s]
%   B1_end      : pulse amplitude at end of pulse [T]
%   f_end       : Larmor frq [1/s]
%   f_start       : low frq for adiabatic pulse [1/s]
%   fmod_shape   : shape of freq modulation: 1: constant; 2: linear; 3: tanh
%   Imod_shape   : shape of current modulation 1: constant; 2: linear; 3: tanh
%   flag_loadAHP : 1: for real I(t)
% % % %             old song definition!!!
% % % %              1: constant B and f
% % % %              2: linear sweep of B and f
% % % %              3: CHIRP: linear sweep of f and constant B
% % % %              4: sin B1 / cos f after Bendall 1986
% % % %              5: tangent f and constant B after Hardy 1986
% % % %              6: HS: sech B and tanh f after Tannus and Garwood 1997
% % % %              7: HSn: sech(tau^n) for B and sech^2(tau^n) for f after Tannus and Garwood 1997
% % % %              8: Sin40: 1-sin^40 for B and int(1-sin^40) for f after Tannus and Garwood 1997
%   T1          : T1-relaxation time
%   T2          : T2-relaxation time
%   Q           : Quality factor of ressonance circuit for addiational
%                   amplitude modulation (set to 0 if not desired)
%   method      : method to calculate the M development
%              1: prefered Beff method -> frame rotates at actual frq(t)
%              2: otional Brot method -> frame rotates at constant larmor frq
%   flagplot    : 
%              1: track M on bloch sphere
%              2: plot pulse shape
%   
% Output:
%   flip        : flip angle [rad]
%   phase       : phase angle [rad]
%   pulse       : summarize pulse properties
%       pulse.B1        : B1 vector [T]
%       pulse.df        : df vector (f0-f(t)) [Hz]
%       pulse.t         : time vector [s]
%       pulse.flag_adiabatic: flag if pulse is adiabatic (Hardy et al. 1986)
%                       1: pulse is adiabatic:      f_B1/T2 << df/dt << f_B1^2  
%                       2: pulse is NOT adiabatic:  f_B1/T2 >  df/dt
%                       3: pulse is NOT adiabatic:             df/dt >  f_B1^2
%       pulse.Lbound    : lower bound: f_B1/T2 
%       pulse.Mbound    : middle bound: df/dt
%       pulse.Ubound    : upper bound: f_B1^2


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 


% sweeplabel = {'constant B and f','B(lin.) and f(lin.)','CHIRP: B(const.) and f(lin.)',...
%                'B(sin) and f(cos)','B(const.) and f(tan.)','HS: B(sech) and f(tanh)',...
%                'HSn: B(sech(tau^n)) and f(sech^2(tau^n))','Sin40: B(1-sin^40) and f(int(B))'};
           
    
gamma       = 267.513e6; % gyromagnetic ratio proton [rad s-1 T-1]

% simulate vector input of t, B1 and diffphase from pulse readout
% define time vector 

if flag_loadAHP == 1 % check if real I(t) was loaded (necessary for AHP)
    nQ = size(Imod.I,1);
else  % only calculate once 
    nQ = 1;
end

%for q = 1:nQ % --> activate this loop (and belwo) if all pulses should be handled on
%its own otherwise largest pulse is taken to calculate adiabatic flips
q = 1; 
    switch flag_loadAHP
        case 0
            % make pulse
            % [B1, dphase,  ~, df, f, y] = mychirp(t, fmod, Imod);
            dt          = 1/20e3; % sampling rate % in s.
            t           = 0:dt:tp;  % in s.
            t           = t(:);
            [I, df] = mychirp(t, fmod, Imod);
            B1 = I.*B1_end; % convert relative I change to B1
            
        case 1 % real I(t)
            t  = Imod.t_pulse(end,:); 
            df = fmod.df(end,:);
            %[~, df] = mychirp(t, fmod, Imod);
            I = Imod.InormImax(end,:); % use normalized I to calculate the flip angel
            % t  = Imod.t_pulse(q,:); % if all pulses on its own uncomment
            % df = fmod.df(q,:);
            % [~, df] = mychirp(t, fmod, Imod);
            % I = Imod.InormImax(q,:); % use normalized I to calculate the flip angel
            B1 = I.*B1_end; % convert relative I change to B1(calculated for 1A) !!!!!!!!!! CHECK!!!!!
    end

    %% calculate spin movement
    % B1 parallel to x-axis!
    method = 1;
    switch method
        case 1 % in freq modulated frame at actuall f(t) using Beff
            % prefered methode: faster; more accurat per time step dt; better visualisation
            % % -> rot Beff about y axis; Mx(t=tp) = 1
            [flip(q,:), phase(q,:), Mxy(q,:), MM{q}, alpha_Beff{q}, Factor_adiabatic{q}] = bloch_TSsim_Beff(t, B1, df, RDP);

        case 2  % old method
            % in constant frame at larmor Frq
            % -> nutation is counterclockwise due to df!!!
            [flip(q,:), phase(q,:), Mxy(q,:), MM{q}] = bloch_TSsim_Brot(t, B1, -dphase, RDP.flag, RDP.T1, RDP.T2);

                % check adiabatic % after Hardy 1985
            %       pulse.flag_adiabatic2: flag if pulse is adiabatic (Hardy et al. 1986)
            %                       1: pulse is adiabatic:      f_B1/T2 << df/dt << f_B1^2  
            %                       2: pulse is NOT adiabatic:  f_B1/T2 >  df/dt
            %                       3: pulse is NOT adiabatic:             df/dt >  f_B1^2
                Lbound = (B1(2:end-2).*gamma)/T2;
                Mbound = diff(f_end-f(2:end-1))./diff(t(2:end-1));
                Ubound = (B1(2:end-2).*gamma).^2;
                if all(Lbound < Mbound) & all(Mbound < Ubound)
                    flag_adiabatic = 1;  % adiabatic condition is true
                    Mbound = mean(Mbound);    
                else
                     if any(Lbound > Mbound)
                        flag_adiabatic = 2; % adiabatic condition is true
                        Mbound = min(Mbound);
                    end
                    if any(Mbound > Ubound)
                        flag_adiabatic = 3;
                        Mbound = max(Mbound);        
                    end 
                end
    end
%end


%% plotting
% plot Bloch-sphere
if flag_plot == 1
      figure
%     clf
%     sphere(20); hold on % Einheitskugel
%     alpha(.2); hold on
    plot3([-1 1], [0 0], [0 0], 'k-', 'linewidth',3); hold on
    plot3([0 0], [-1 1], [0 0], 'k-', 'linewidth',3); hold on
    plot3([0 0], [0 0], [-1 1], 'k-', 'linewidth',3); hold on
    plot3([0 1], [0 0], [0 0], 'm-', 'linewidth',3); hold on
%     plot3(MM(1,(Factor_adiabatic>1)), MM(2,(Factor_adiabatic>1)), MM(3,(Factor_adiabatic>1)), 'g-', 'linewidth',3); hold on
%     plot3(MM(1,(Factor_adiabatic<=1)), MM(2,(Factor_adiabatic<=1)), MM(3,(Factor_adiabatic<=1)), 'ro', 'linewidth',3); hold on
%     plot3(MM(1,1), MM(2,end), MM(3,end), 'rx', 'linewidth', 2); hold on
    plot3(MM{1,1}(1,1:end), MM{1,1}(2,1:end), MM{1,1}(3,1:end), 'r.', 'linewidth', 2); hold on    
%     plot3(MM{1,50}(1,1:end), MM{1,50}(2,1:end), MM{1,50}(3,1:end), 'c.', 'linewidth', 2); hold on        
%     blochplot(MM(:,end), 'b', 'o');
    if method == 2 % plot Beff in Brot frame
        [Eff(1,:), Eff(2,:), Eff(3,:)] = sph2cart(pi+dphase,pi/2-alpha_Beff,1);
        [Eff2(1,:), Eff2(2,:), Eff2(3,:)] = sph2cart(0,pi/2-alpha_Beff,1);    
        plot3(Eff(1,(Factor_adiabatic>1)),Eff(2,(Factor_adiabatic>1)),Eff(3,(Factor_adiabatic>1)),'yo');
        plot3(Eff(1,(Factor_adiabatic<=1)),Eff(2,(Factor_adiabatic<=1)),Eff(3,(Factor_adiabatic<=1)),'mo');
    end
%     legend('Bloch sphere', 'adiabatic', 'non-adiabatic', 'M0', 'M0', 'Mfinal', 'Mfinal', 'Phasefinal', 'Phasefinal')
    view([1,1,1]);
%     camroll(-90);
    xlabel('x'); ylabel('y')
    tt = sprintf('B1: %1.1e T',B1(end));
    title(tt); hold on
    
    figure
%     plot((t.*gamma.*B1)/pi,MM(1,:),'b-', 'linewidth',3);hold on
    plot((t.*gamma.*B1)/pi,MM{1,1}(1,:),'r-', 'linewidth',3);hold on   
    plot((t.*gamma.*B1)/pi,MM{1,1}(2,:),'g-', 'linewidth',3);hold on  
    plot((t.*gamma.*B1)/pi,MM{1,1}(3,:),'b-', 'linewidth',3);hold on      
%     plot((t.*gamma.*B1)/pi,MM{1,50}(1,:),'c-', 'linewidth',3);hold on        
%      plot((t.*gamma.*B1),MM(2,:),'b-', 'linewidth',3);hold on   
    
end

if flag_plot == 2
    subplot(221)
    plot(t, B1, 'g-', 'linewidth',2); hold on
%     plot(t, y, 'k-'); hold on
    xlabel('t in s'); ylabel('B1 in T'); 
%     legend('B1 amplitude', 'B1 signal', 2);
    legend('B1 amplitude', 2);    
    ylim([0 1.1*max(B1)]);
    title('Amplitude'); 
    subplot(223)
    plot(t, df, 'g-', 'linewidth',2); hold on
%     plot(t, f, 'k-'); hold on
%     hline(f_end,'k--')
    xlabel('t in s'); ylabel('(f0-f) in Hz'); 
%     legend('\Delta f', 'f', 2);
    legend('\Delta f', 2);
    title('Frequency'); 
end

%% Output

flip            = flip;
phase           = phase;
Mxy             = Mxy;
pulse.B1        = B1;
pulse.df        = df;
pulse.t         = t;
pulse.Factor_adiabatic   = Factor_adiabatic;
% if method == 2
%     pulse.Lbound    = max(Lbound);
%     pulse.Mbound    = Mbound;
%     pulse.Ubound    = min(Ubound);
% end
end