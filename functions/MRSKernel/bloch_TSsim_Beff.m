function [flip, phase,Mxy, MM, alpha_Beff, Factor_adiabatic] = bloch_TSsim_Beff(t, B1, df, RDP)
%[flip, phase, MM, alpha_Beff, ID_adiabatic] = bloch_TSsim_Beff(t, B1, df, flag_T, T1, T2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   - simulates spin dynamics in a rotating frame at actual frq(t) (rf)
%   - allows for accounting for T1, T2 and dephasing at df
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        
% Input:
%   t           : time vector [s]
%   B1          : pulse amplitude at time vector [T]
%   diff_phase  : phase difference to rf pulse [rad]
%   flag_T      : flag to account for T1, T2 and dephasing at df
%                   1: on
%                   2: off
%   T1          : T1-relaxation time [s]
%   T2          : T2-relaxation time [s]
%   
% Output:
%   flip        : flip angle [rad]
%   phase       : phase angle [rad]
%   MM          : vector of the magnetisation [x y z]
%   alpha_Beff  : vector of the flip angle of Beff (rotation about the y-axis starts at z-axis) [rad]
%   ID_adiabatic: check if under adiabatic condition
%                   1: adiabatic condition;         abs(gamma*Beff) > dalpha_Beff;
%                   0: non adiabatic condiction ;   abs(gamma*Beff) < dalpha_Beff;


t       = t(:);
dt      = diff(t);
dt      = [dt(1); dt];
B1      = B1(:);
df      = df(:);
fgrad   = 0; %Allows to simulate the impact of dephasing dependent on off resonance frequency fgrad


gamma   = 267.513e6; % gyromagnetic ratio proton [rad s-1 T-1]
rf      = gamma.*B1(:).*dt; % Rotation in radians. per timestep dT

% calculate Beff
Bz          = 2*pi*df./gamma;
XYZBeff     = [B1, zeros(size(B1)), Bz]; % XYZ coordianted of Beff
Beff        = sqrt(B1.^2+Bz.^2); % amplitude of effective B in RF frame

alpha_Beff  = atan((gamma.*B1) ./ (2*pi*df) ); % flip angle of Beff in RF frame
% dalpha_Beff = diff([alpha_Beff; alpha_Beff(end)])./dt;
dalpha_Beff = diff([0; alpha_Beff])./dt;
% epsilon     = atan((dalpha_Beff/gamma)./(Beff));

% calculation of a factor to describe if the adiabatic condition is true
% for every time step (adiabatic condition after tannus 1997)
% x = 2; % X >>1
% ID_adiabatic = abs(gamma*Beff) > X*abs(dalpha_Beff); % adiabatic condition after tannus 1997
Factor_adiabatic = abs(gamma*Beff) ./ abs(dalpha_Beff); %

%% Simulation the bloch equation
M   = [0;0;1];
MM  = zeros(3,length(rf));

M   = Nrot(-Beff(1)*gamma*dt(1),XYZBeff(1,:)) * M; % first nutation about Beff
MM(:,1) = M;
for k = 2:length(rf)
    if RDP.flag==1 % precession and T relaxation 
        [A,B]   = freeprecess(dt(k),RDP.T1,RDP.T2,fgrad);   % consider to remove T if faster!!!
        M       = A*M+B;                                    % Propagate to next pulse.
    end
    M   = Nrot(-Beff(k)*gamma*dt(k),XYZBeff(k,:)) * M; % nutation about Beff is negativ for protons
    MM(:,k) = M;
end;

%% Output 

flip        = atan2( sqrt(M(1)^2+M(2)^2), M(3) );
phase       = atan2(M(2),M(1));
Mxy         = M(2) + i*M(1); % Complex M in x-y plane; Pulse parallel to x- axis; on res pulse leads to real signal!!!
MM          = MM;
alpha_Beff  = alpha_Beff;
ID_adiabatic= ID_adiabatic;
end