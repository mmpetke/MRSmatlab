function [flip, Mxy, B] = make_adiabatic_flip(measure)

% gamma       = 267.513e6; % gyromagnetic ratio proton [rad s-1 T-1]

if 1
    nB          = 10000;
else
    nB          = 1000;  
    disp('nB is ONLY 100 for testing!; -> increase to 10k in make_adiabatic_flip!!');
end
Blimit      = 2e-6;
Ba          = logspace(-9, log10(Blimit), 500);
Bb          = linspace(Blimit, 1e-3, nB-length(Ba));
B           = [Ba(1:end-1), Bb];

% f_end       = earth.f-measure.fmod.enddf;
% f_start     = earth.f-measure.fmod.startdf;
% I_start 

% sweeptype   = 3;
%   sweeptype   : select B and frq sweep
%              1: constant B and f
%              2: linear sweep of B and f
%              3: CHIRP: linear sweep of f and constant B
%              4: sin B1 / cos f after Bendall 1986
%              5: tangent f and constant B after Hardy 1986
%              6: HS: sech B and tanh f after Tannus and Garwood 1997
%              7: HSn: sech(tau^n) for B and sech^2(tau^n) for f after Tannus and Garwood 1997
%              8: Sin40: 1-sin^40 for B and int(1-sin^40) for f after Tannus and Garwood 1997

%%

screensz = get(0,'ScreenSize');
tmpgui.panel_controls.figureid = figure( ...
    'Position', [5 screensz(4)-120 350 100], ...
    'Name', 'Info', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'HandleVisibility', 'on');
tmpgui.panel_controls.edit_status = uicontrol(...
    'Position', [0 0 350 100], ...
    'Style', 'Edit', ...
    'Parent', tmpgui.panel_controls.figureid, ...
    'Enable', 'off', ...
    'BackgroundColor', [0 1 0], ...
    'String', 'Idle...');

tic
for n = 1:length(B)    
    if n == 0   % select if you want to plot Bloch-sphere of B(n)   
%          [flip(n), phase(n), Mxy(n), pulse] = flip_adiabatic(measure.taup1, B(n), measure.fmod, measure.Imod, measure.RDP, 1);
         [flip(:,n), phase(:,n), Mxy(:,n), pulse] = flip_adiabatic(measure.taup1, B(n), measure.fmod, measure.Imod, measure.RDP, measure.flag_loadAHP, 1);
    else
%         [flip(n), phase(n), Mxy(n), pulse] = flip_adiabatic(measure.taup1, B(n), measure.fmod, measure.Imod,  measure.RDP, 0);
        [flip(:,n), phase(:,n), Mxy(:,n), pulse] = flip_adiabatic(measure.taup1, B(n), measure.fmod, measure.Imod,  measure.RDP, measure.flag_loadAHP ,0);        
    end
    % check if pulse is considered adiabatic using "abs(gamma*Beff) > Flimit * abs(dalpha_Beff)" adiabatic condition after tannus 1997

    Flimit = 1; % set 
    for q = 1:length(pulse.Factor_adiabatic)
        if min(pulse.Factor_adiabatic{q}) > Flimit         % adiabatic is true for all time steps
            flag_adiabatic.all(q,n) = 1;
        else
            flag_adiabatic.all(q,n) = 0;        
        end

        if min(pulse.Factor_adiabatic{q}(1)) > Flimit    % adiabatic is true for at start of pulse
            flag_adiabatic.start(q,n) = 1;
        else
            flag_adiabatic.start(q,n) = 0;        
        end

        if min(pulse.Factor_adiabatic{q}(2:end-51)) > Flimit  % adiabatic is true at mid of pulse 
            flag_adiabatic.mid(q,n) = 1;
        else
            flag_adiabatic.mid(q,n) = 0;        
        end

        if min(pulse.Factor_adiabatic{q}(50:end)) > Flimit  % adiabatic is true for for end of pulse
            flag_adiabatic.end(q,n) = 1;
        else
            flag_adiabatic.end(q,n) = 0;        
        end    
    end
    % shows progress
    if rem(n,100) == 0
        set(tmpgui.panel_controls.edit_status,'String',...
            ['Calculating flip angle for B1: ' num2str(n) ' out of ' num2str(nB) ' finished in ' num2str(toc) 's']);
        drawnow
    end

end
close(tmpgui.panel_controls.figureid)
%% plot
% figure(19)
% clf
% subplot(2,2,[2 4]);
% semilogy(real(Mxy),B, 'm-', 'linewidth',2); hold on
% semilogy(imag(Mxy),B, 'y-', 'linewidth',2); hold on
% semilogy(abs(Mxy),B, 'g-', 'linewidth',2); hold on
% % semilogy(abs(Mxy(flag_adiabatic.all>0)),B(flag_adiabatic.all>0), 'r.', 'linewidth',2); hold on
% xlabel('Mxy/M0');ylabel('B1 [T]');
% legend('real(Mxy)', 'imag(Mxy)', 'abs(Mxy)');
% 
% subplot(2,2,3);
% if measure.flag_loadAHP ==1
%     plot(pulse.t,measure.Imod.InormImax, 'g-', 'linewidth',2); hold on
%     ylim([0, max(max(measure.Imod.InormImax))]);
% %     plot(pulse.t,measure.Imod.I./max(measure.Imod.I), 'g-', 'linewidth',2); hold on
%     ylim([0, 1]);    
% else
% 	plot(pulse.t,pulse.B1./max(pulse.B1), 'g-', 'linewidth',2); hold on
%     ylim([0, 1]);    
% end
% xlabel('Time [s]');ylabel('I/I_{max} [ ]');
% 
% subplot(2,2,1);
% plot(pulse.t,pulse.df, 'r-', 'linewidth',2); hold on   
% xlabel('Time [s]');ylabel('df(t) [Hz]');
% 
% if 0 % show at which B strength, which part of the pulse is adiabatic.
% figure(20)
% clf
% for q = 1:length(pulse.Factor_adiabatic)
%     subplot(1,4,1);
%     semilogy(abs(Mxy(q,:)),B(q,:), 'g-', 'linewidth',2); hold on
%     semilogy(abs(Mxy(q,flag_adiabatic.all(q,:)==0)),B(q,flag_adiabatic.all(q,:)==0), 'r.', 'linewidth',2); hold on
% %     plot3(abs(Mxy(q,flag_adiabatic.all(q,:)==0)),B(flag_adiabatic.all(q,:)==0),q*ones(1,length(flag_adiabatic.all(q,:)==0)), 'r.', 'linewidth',2); hold on
%     xlabel('Mxy/M0');ylabel('B1 [T]');
% %     legend('abs(Mxy)', 'non-adiabatic');
%     title('all')
%     subplot(1,4,2);
%     semilogy(abs(Mxy),B, 'g-', 'linewidth',2); hold on
%     semilogy(abs(Mxy(q,flag_adiabatic.start(q,:)==0)),B(flag_adiabatic.start(q,:)==0), 'r.', 'linewidth',2); hold on
%     xlabel('Mxy/M0');ylabel('B1 [T]');
%     legend('abs(Mxy)', 'non-adiabatic');
%     title('start')
%     subplot(1,4,3);
%     semilogy(abs(Mxy),B, 'g-', 'linewidth',2); hold on
%     semilogy(abs(Mxy(q,flag_adiabatic.mid(q,:)==0)),B(flag_adiabatic.mid(q,:)==0), 'r.', 'linewidth',2); hold on
%     xlabel('Mxy/M0');ylabel('B1 [T]');
%     legend('abs(Mxy)', 'non-adiabatic');
%     title('mid')
%     subplot(1,4,4);
%     semilogy(abs(Mxy),B, 'g-', 'linewidth',2); hold on
%     semilogy(abs(Mxy(q,flag_adiabatic.end(q,:)==0)),B(flag_adiabatic.end(q,:)==0), 'r.', 'linewidth',2); hold on
%     xlabel('Mxy/M0');ylabel('B1 [T]');
%     legend('abs(Mxy)', 'non-adiabatic');
%     title('end')
% end
% end

end