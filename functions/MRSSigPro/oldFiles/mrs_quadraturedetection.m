function [V] = mrs_quadraturedetection(v,t,fT,H,hilbertflag)
% function [V] = mrs_quadraturedetection(v,t,fT,fS)
% 
% Quadrature detection of NMR signal. The real-valued input signal,
%   v = v0*cos(wL+phi),
% is converted into its complex-valued  quadrature signal, 
%   V = v0*( cos[(wL-wT)*t + phi] - 1i*sin[(wL-wT)*t + phi] ).
% 
% Input:
%   v  - voltage (real) = v0*cos(wL+phi)
%   t  - time
%   fT - transmitter reference frequency
%   H  - high-cut filter coefficients; generated in MRSImport > build_LPfilter
% 
% Output:
%   V - voltage (complex) = v0*( cos[(wL-wT)*t + phi] - 1i*sin[(wL-wT)*t + phi] )
% 
% Jan Walbrecker, 27oct2010
% MMP 08 Apr 2011
% JW  19 aug 2011
% =========================================================================


if nargin == 4 % no hilbertflag --> using sine and cosine 
    if H == -1  % no filter - data are already quadrature; JW: sign is unclear (cos+1i*sin or cos-1i*sin)
        V = v;
    else
        % filter might designed using digital old standard filter
        % digital filter object do not allow for filtfilt
        % filtfilt preserves the phase!
        info = whos('H');
        switch info.class
            case 'dfilt.df2sos'
                V = 2*  (filter(H,v .* cos(2*pi*t*fT)) + ...
                      1i*filter(H,v .* sin(2*pi*t*fT))   );        % this is equivalent to (cos-1i*sin)
            case 'double'
                V  = 2*  (filtfilt(H(1,:),H(2,:),v .* cos(2*pi*t*fT)) + ...
                    1i*filtfilt(H(1,:),H(2,:),v .* sin(2*pi*t*fT)));
        end
    end
else % hilbertflag is given
    if hilbertflag % hilbertflag is 1 --> use hilbert
        if H == -1  % no filter - data are already quadrature
            V = v;
        else
            % an alternative via hilbert, low-pass and filtfilt
            hv          = hilbert(v);
            ehv         = hv.*exp(-1i*2*pi*fT.*t);
            info = whos('H');
            switch info.class
                case 'dfilt.df2sos'
                    V  = filter(H,ehv);
                case 'double'
                    V  = filtfilt(H(1,:),H(2,:),ehv);
            end
        end
    else % hilbertflag is 0 use sine and cosine
        if H == -1  % no filter - data are already quadrature
            V = v;
        else
            info = whos('H');
            switch info.class
                case 'dfilt.df2sos'
                    V = 2*  (filter(H,v .* cos(2*pi*t*fT)) + ...
                          1i*filter(H,v .* sin(2*pi*t*fT))   );
                case 'double'
                    V  = 2*  (filtfilt(H(1,:),H(2,:),v .* cos(2*pi*t*fT)) + ...
                        1i*filtfilt(H(1,:),H(2,:),v .* sin(2*pi*t*fT)));
            end
        end
    end
end
