function U = mrs_signalphasecorrection(u,phases,isig,device)
% function U_corr = mrs_signalphasecorrection(u,phases,isig)
% 
% Correct for instrument phases to determine true phase of NMR signal:
% U = u*exp(1i*(-phases.phi_gen-phases.phi(isig)));
% 
% Called during stacking in MRSFit and MRSNoisereduction (stackrecordings) 
% 
% Currently, this correction yields the best estimate of the true signal 
% phase. But there is still an offset in phase which is most likely related
% to the amplifier phase phi_ampl. But it also seems to be related to the
% conductivity of the subsurface (see Skive 3), so the impedance? Unclear
% yet. See MRSmatlab documentation.
% 
% Input:
%   u      - voltage (complex, after QD)
%   phases - info from fielddata structure
%   isig   - which signal: 1 - noise, 2 - fid1, 3 - fid2, 4 - echo
% 
% Output:
%   U - phase corrected voltage
% 
% Jan Walbrecker, 23nov2010
% JW 16aug2011
% =========================================================================

switch device
    case 'NUMISpoly'
        U = u*exp(1i*(-phases.phi_gen(isig) - phases.phi_timing(isig)));      % see "FID phase correction.pdf" in MRSmatlab documentation
        % MMP: phi_amp seems to be corrupt? --> Jan?
    case 'NUMISplus'
        U = u*exp(1i*(-phases.phi_gen(isig) - phases.phi_amp));
    case 'MIDI'
        U = u;
    case 'MINI'
        U = u;
    case 'TERRANOVA';
        U = u;
    case 'Jilin';
        U = u;
    case 'GMR'
        % some riddle --> what the true transmitter phase?
        % current + or - (+/- is pi difference)
        %   JW: the two columns do not have a phase shift of pi, but some
        %   uncontrolled phase correlation (they are not the in- and
        %   out-of-phase components), according to Vista Clara.
        % voltage + or - (+/- is pi difference) voltage/current is pi/2
        % any additional phase of -pi,-pi/2,pi/2 or pi is possible
        % some dataset are best(small q with zero phase) with +pi 
        U = u*exp(1i*(-phases.phi_gen(isig) - phases.phi_timing(isig) + pi));
        % for GMR phi_amp = 0; untuned reviever circuit!
end

