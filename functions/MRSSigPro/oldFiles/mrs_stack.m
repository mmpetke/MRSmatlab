function [Q_out] = mrs_stack(Q_in)
% function [Q_out] = mrs_stack(Q_in)
% 
% stack MRS data
% 
% Jan Walbrecker, 27oct2010
% ed. 27oct2010
% =========================================================================

sounding_path = 'd:\Jan Home\Matlab\nmr\data\test_mrsimport_new\Sounding0005\';
q   = 1:3;
rec = 1:5;

for iQ = 1:length(q)
    for irec = 1:length(rec)
        proc.Q(iQ).rec(irec).file = [sounding_path,'RawData',filesep,'Q', ...
                        num2str(iQ),'#',num2str(irec),'.Pro'];
        polyout = mrs_readpoly(proc.Q(iQ).rec(irec).file);
        fT     = polyout.transmitter.FreqReelReg9833;   % CHECK vs LINE 107
        fS     = polyout.receiver(1).SampleFrequency;   % CHECK vs dt LINE 113        
        
        for ich  = 1:length(polyout.receiver(1))
            for isig = 1:4
                data.Q(iQ).rec(irec).ch(ich).sig(isig).t = polyout.receiver(ich).Signal(isig).t;
                data.Q(iQ).rec(irec).ch(ich).sig(isig).v = ...
                        mrs_quadraturedetection(...
                            polyout.receiver(ich).Signal(isig).v, ...
                            polyout.receiver(ich).Signal(isig).t, ...
                            fT, fS ...
                        )* exp(-1i*(0));    % [V]                        
                proc.Q(iQ).rec(irec).ch(ich).sig(isig).keep = 1;
            end
        end        
    end
end


% stack
iQ   = 2;
ich  = 1;
isig = 2;

t = data.Q(iQ).rec(1).ch(ich).sig(isig).t;
for irec = 1:length(data.Q(1).rec)
    v(irec,1:length(t)) = data.Q(iQ).rec(irec).ch(ich).sig(isig).v;
    keep(irec) = proc.Q(iQ).rec(irec).ch(ich).sig(isig).keep;
end

V = sum(v(keep==1,:),1)/size(v(keep==1,:),1);

