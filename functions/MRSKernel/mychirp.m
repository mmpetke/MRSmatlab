function [I, df]=mychirp(t, fmod, Imod)
% function [I, dphase, phase, df, f, y]=mychirp(t, f_low, f_high, Iend, fmod_shape, Imod_shape, phase0, flag_plot)
%[I, dphase, phase, f, y]=mychirp(t, f_low, f_high, Iend, song, phase0, flag_plot)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   - generates a frequency and I sweep for the time vector t.
%   - frequency sweeps from f_low (t = 0) to f_high (t = end)
%   - I sweeps from 0 (t = 0) to Iend (t = end)
%   - Allows for constant, linear, sin/cos and tangent sweeps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        
% Input:
%   t       : time vector [s]
%   f_low   : lower frq [1/s]
%   f_high  : high frq (Larmor) [1/s]
%   Iend  : pulse strengt [T]
%   fmod_shape   : shape of freq modulation: 1: constant; 2: linear; 3: tanh
%   Imod_shape   : shape of current modulation 1: constant; 2: linear; 3: tanh
% % % %             old song d1.efinition!!!
% % % %              1: constant B and f
% % % %              2: linear sweep of B and f
% % % %              3: CHIRP: linear sweep of f and constant B
% % % %              4: sin I / cos f after Bendall 1986
% % % %              5: tangent f and constant B after Hardy 1986
% % % %              6: HS: sech B and tanh f after Tannus and Garwood 1997
% % % %              7: HSn: sech(tau^n) for B and sech^2(tau^n) for f after Tannus and Garwood 1997
% % % %              8: Sin40: 1-sin^40 for B and int(1-sin^40) for f after Tannus and Garwood 1997
%   phase0  : Phase of pulse at the beginning [rad]
%   flag_plot: flag for plotting I, dphase, phase, f, y vs t
%   
% Output:
%   I       : vector of the relative amplitude of I(t)[A]
%   dphase  : vector of phase shift (t) compared to f_high [rad]
%   phase   : vector of phase(t) [rad]
%   df      : vector of frequency diff (f0-f(t)) [Hz]
%   f       : vector of frequency(t) [Hz]
%   y       : vector of I(t)[T]

% gamma   = 267.513e6; % gyromagnetic ratio proton [rad s-1 T-1]

% if nargin==3
%     flag_plot = 0;
% end

%%
% free current modulation 
I      = FunImod(t, Imod.startI, Imod.endI, Imod.shape, Imod.A, Imod.B);

% free frequency modulation 
df      = Funfmod(t, fmod.startdf, fmod.enddf, fmod.shape, fmod.A, fmod.B);


% current modulation using Q
if Imod.flag_Q == 1 & Imod.Q > 0 % no modulation for Q = 0
    switch 3  % check which is best!
        case 1
            Lwidth = Imod.Qf0 / (Imod.Q*(sqrt(2)-1))/2;   % linewidth of Lorentz function (after grunewald 2016); /2 due to Lwidth/2 in Cauchy eq
        case 2
            Lwidth = Imod.Qf0 / (sqrt((4*Imod.Q^2-1)*(sqrt(2)-1))); % Bandwidth after wiki (Breit-Wigner-Formel)
        case 3            
            Lwidth = Imod.Qf0 / Imod.Q;                          % simple Bandwidth for bandpass filter
    end
    
    L = 1/pi *  (Lwidth) ./ (((df+Imod.Qdf)).^2 + (Lwidth).^2);   % Breit-Wigner-Formel (wiki)
                                                                  % siehe auch Cauchy-Lorentz Verteilung
    L = L.*(pi*Lwidth); % normalize amplitude to max = 1
    I = I.*L;
end   

 

%I      = I;
%df     = df;



end