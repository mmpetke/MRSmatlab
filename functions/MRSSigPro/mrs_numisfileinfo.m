function mrs_numisfileinfo()
% function [Q_out] = mrs_stack(Q_in)
% 
% Display info from numis files
% 
% Jan Walbrecker, 01nov2010
% ed. 01nov2010
% =========================================================================

fpath = 'd:\Jan Home\Matlab\nmr\data\test_despikeall\Sounding0005\';
Q    = [1 2 3 4 5];
iQ   = 3;
isig = 1;
irec = 3;
irx  = 1;   % missing in numisstacker


%% raw file
polyout = mrs_readpoly([fpath,'RawData',filesep,'Q', ...
                            num2str(Q(iQ)),'#',num2str(irec),'.Pro']);

polyout.receiver(irx)

return
sprintf('%s',cell2mat(polyout.header.TConfig.c7))
polyout.header.TConfig.FLarmorFreq
polyout.header.TConfig.c6
polyout.header.TConfig.c5
polyout.header.TConfig.LoopType
polyout.header.TConfig.LoopSize
polyout.header.TConfig.TurnNumber
polyout.header.TConfig.c4
polyout.header.TConfig.FlagStackMax
polyout.header.TConfig.c3
polyout.header.TConfig.PulseMoment
polyout.header.TConfig.SignalRecTime
polyout.header.TConfig.DelayTime
polyout.header.TConfig.PulseDuration
polyout.header.TConfig.NbPulse
polyout.header.TTimeConfig.TMNoise
polyout.header.TTimeConfig.TDPulse1
polyout.header.TTimeConfig.TMPulse1
polyout.header.TTimeConfig.TDSignal1
polyout.header.TTimeConfig.TMSignal1
polyout.header.TTimeConfig.TDPulse2
polyout.header.TTimeConfig.TMPulse2
polyout.header.TTimeConfig.TDSignal2
polyout.header.TTimeConfig.TMSignal2
polyout.header.TTimeConfig.TDSignal3
polyout.header.TTimeConfig.TMSignal3
polyout.header.TConfig.c0
polyout.header.TConfig.c1
polyout.header.TConfig.c2
polyout.header.TConfig.c8
polyout.header.TConfig.c9
polyout.header.TConfig.c10
polyout.header.TConfig.c11
polyout.header.TConfig.c12
polyout.header.TConfig.DirectoryName
polyout.header.TConfig.Comment
polyout.header.TConfig.c13
polyout.header.TConfig.c14
polyout.header.TConfig.c15
polyout.header.TParameter.KAmpl
polyout.header.TParameter.x0
polyout.header.TParameter.Noise
polyout.header.TParameter.PhCalib
polyout.header.TParameter.PhSignal
polyout.header.TParameter.RangeReel
polyout.header.TParameter.AdcToTension
polyout.header.TParameter.AdcToCurren
polyout.header.TParameter.UAnt
polyout.header.TParameter.Loop_Imped
polyout.header.TParameter.UGen
polyout.header.TParameter.x6
polyout.header.TParameter.StackCorrect
polyout.header.TParameter.x1
polyout.header.TParameter.PulseNumber
polyout.header.TParameter.x2
polyout.header.TParameter.x3
polyout.header.TParameter.Batterie
polyout.header.TParameter.x4
polyout.header.TParameter.x5




sprintf('%s',cell2mat(x(2)))

return
                        
%% read .inp file: get q and fit startvalues ------------------------------
fidinp = fopen([fpath, 'NumisData.inp'],'r');
lines  = 0;                  % count # lines in file
while fgets(fidinp)~= -1
    lines=lines+1;
end
fseek(fidinp,0,'bof');       % return to bof
inp_header = textscan(fidinp, '%*s %f %*1c %f %*[^\n]', 1, 'Headerlines', 1);
inp_data   = textscan(fidinp, '%f %f %f %f %f %f %f %f %*[^\n]', lines-5, 'Headerlines', 4);
fclose(fidinp);

iq = find(inp_data{2} ~= 0 & inp_data{3} ~= 0);     % delete skipped pulsemoments

Q         = inp_data{1}(iq);          % Pulse moment indices
q         = inp_data{2}(iq)/1000;     % [As]  ex pm_vec
E0_start  = inp_data{3}(iq)/1e9;      % [V]
T2_start  = inp_data{4}(iq)/1000;     % [s]
fL_start  = inp_data{7}(iq);          % [Hz]  ex Freq_start
Phi_start = inp_data{8}(iq)/180*pi;   % [rad]
Phi_start(Phi_start > pi) = Phi_start(Phi_start > pi) - 2*pi; % phase 180 -> -180
data.pm_vec  = q;

%% read .in2 file (if existent): get q and fit startvalues ----------------
fidin2 = fopen([fpath, 'NumisData.in2'],'r');
if (fidin2 ~= -1)
    lines = 0;
    while fgets(fidin2)~= -1
        lines=lines+1;
    end
    fseek(fidin2,0,'bof');
    
    in2_header = textscan(fidin2, '%*s %f %*1c %f %*[^\n]', 1, 'Headerlines', 1);
    in2_data   = textscan(fidin2, '%f %f %f %f %f %f %f %f %*[^\n]', lines-5, 'Headerlines', 4);
    fclose(fidin2);
    
    iq = find(in2_data{2} ~= 0 | in2_data{3} ~= 0);     % delete skipped pulsemoments; skipped pulsemoments are identified by the fact that neither q nor the amplitude "e2" are zero
    
    if size(Q) ~= size(in2_data{1}(iq));  % check: Q indices in inp & in2 should be the same!
        error('Error! Different missing-q-indices in .inp & .in2 file!')
    end
    q2         = in2_data{2}(iq)/1000;     % [As]
    E0_start2  = in2_data{3}(iq)/1e9;      % [V]
    T2_start2  = in2_data{4}(iq)/1000;     % [s]
    fL_start2  = in2_data{7}(iq);          % [Hz]
    Phi_start2 = in2_data{8}(iq)/180*pi;   % [rad]
    Phi_start2(Phi_start2 > pi) = Phi_start2(Phi_start2 > pi) - 2*pi; % phase 180 -> -180    
    data.pm_vec2 = q2;
end


%% 0 file
% determine f_ref, phi_ampl, phi_gen for this q
    fid0 = fopen([fpath, 'NumisData.0', num2str(Q(iQ))],'r');
    A    = textscan(fid0, '%f %f %f %*[^\n]', 1);           % A - like in prodiviner manual
    B    = textscan(fid0, '%f %f %f %f %f %f %*[^\n]', 1);  % B - like in prodiviner manual
    fclose(fid0);
    fref     = A{1};            % [Hz]
    phi_gen  = A{2}*pi/180;     % [rad]
    phi_amp  = A{3}*pi/180;     % [rad]
    tau_p    = B{3}*4/fref;     % [s]
    tau_dead = B{4}*0.25/fref;  % [s]    
    tau_d    = B{3}*4/fref + B{4}*0.25/fref + B{5}*4/fref + B{6}*0.25/fref; % [s]
    dt       = 1/(0.25*fref);
    

                        
