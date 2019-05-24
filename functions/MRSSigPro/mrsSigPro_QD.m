function [V] = mrsSigPro_QD(v,t,fT,fS,fW,LPfilter)
% function [V] = mrs_SigProQD(v,t,fT)
% 
% IS THE HILBERT + FILTFILT APPROACH PHASE PRESERVING? --> YES
% IS THE SIGN OF THE COMPLEX COMPONENT NEGATIVE? --> DEPENDS ON THE SIGNAL PHASE, see test below
% IS THERE A LEAKAGE EFFECT IN THE HILBERT APPROACH? --> I know Marian and
% Fabian did some testing in Fabian masters thesis.
% They prefered multiplication with sin and cos compared to HILBERT since results where more stable.
% But they compared HILBERT without filtering while sin/cos was of cause filtered. 
% Keep in mind: to get complex envelope with sin/cos you need filter for Hilbert not (Hilbert is the more
% general approach for complex envelope). But if you compare 
% stability under noise condition you should use the same filter for both.
% If you do so both are the same. 
% HILBERT is the state-of-art in digital NMR signal processing as far as I
% know.
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
%   fS - sampling
%   fW - filterwidth
% 
% Output:
%   V - voltage (complex) = v0*( cos[(wL-wT)*t + phi] - 1i*sin[(wL-wT)*t + phi] )
% 
% Jan Walbrecker, 27oct2010
% MMP 08 Apr 2011
% JW  19 aug 2011
% =========================================================================

if isstruct(LPfilter.coeff)
%     if ~exist('buttord') % get coefficients from file
% Since we use mrs_makefilter for either loading or calculating the coefficients there is no
% need to check here again.
        [dummy,ipass]   = find(LPfilter.passFreq <= fW,1,'last');
        [dummy,istop]   = find(LPfilter.stopFreq <= 3*fW,1,'last'); %<-- this might be checked if this is a good default, I think so.
        [dummy,isample] = find(LPfilter.sampleFreq <= fS,1,'last');
        a = LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).a;
        b = LPfilter.coeff.passFreq(ipass).stopFreq(istop).sampleFreq(isample).b;
%     else
%         % filter definition
%         Apass       = 1;     % Passband Ripple (dB)
%         Astop       = 50;    % Stopband Attenuation (dB)
%         Fpass       = [fW];   % Passband Frequency
%         Fstop       = [3*fW];  % Stopband Frequency
%         % Calculate the order from the parameters using BUTTORD.
%         [N,Fc] = buttord(Fpass/(fS/2), Fstop/(fS/2), Apass, Astop);
%         % using standard filter that allows for filtfilt
%         [b,a]       = butter(N, Fc);
%     end

    % Synchronous detection via hilbert, low-pass and filtfilt
    hv          = mrs_hilbert(v);
    ehv         = hv.*exp(-1i*2*pi*fT.*t);
    V           = mrs_filtfilt(b,a,ehv);
    
    % eliminate spikes that can be modeled as a spike response
    if 0
        xspike  = zeros(1000,1); xspike(500)=1;
        fx      = mrs_filtfilt(b,a,xspike);
        [ix,ipR] = max(abs(xcorr(real(V),fx)));
        [ix,ipI] = max(abs(xcorr(imag(V),fx)));
        
        xspikeR  = zeros(size(ehv)); xspikeR(ipR+500-length(t)) = 1;
        fxR      = mrs_filtfilt(b,a,xspikeR);
        vxR      = fxR.'\real(V).';
        vxI      = fxR.'\imag(V).';
        
        xsR = zeros(size(ehv)); xsR(ipR+500-length(t)) = vxR;
        xsI = zeros(size(ehv)); xsI(ipI+500-length(t)) = vxI;
        
        fxR = mrs_filtfilt(b,a,xsR);
        fxI = mrs_filtfilt(b,a,xsI);
        
        V = complex(real(V)-fxR, imag(V)-fxI);
    end
    % Check for transients at the beginning and end of time series due to
    % filter artefact --> use spike test to determine 
    % I would set to zero here for display purposes 
    % and delete afterwards when save the stacked data
    xspike = zeros(size(ehv)); xspike(1)=1;
    fx     = mrs_filtfilt(b,a,xspike);
    index  = length(xspike) - find(fliplr(abs(fx)) > 0.01, 1 );
    V(1:index) = nan;
    V(end-index:end)=nan;
    
else    % data are already quadrature (NUMISpoly)
    V = v;
end
            

%% testing hilbert and filtfilt phase preservation
% figure
% T    = 0.00;
% dt   = 1/50000;
% t    = [0:dt:.1];
% f    = 2000;
% 
% y = 1.*cos(2*pi*f*t - 0*pi/2).*exp(-t/0.2);
% y = y + 0.05*randn(size(y));
% 
% Fs          = 1/diff(t(1:2));
% Fpass       = [500];   % Passband Frequency
% Fstop       = [1500];  % Stopband Frequency
% Apass       = 1;     % Passband Ripple (dB)
% Astop       = 50;    % Stopband Attenuation (dB)
% [N,Fc]      = buttord(Fpass/(Fs/2), Fstop/(Fs/2), Apass, Astop);
% [b,a]       = butter(N, Fc);
% 
% hy          = hilbert(y);
% ehy         = hy.*exp(-1i*2*pi*f.*t);
% fy          = filtfilt(b,a,ehy);
% 
% plot(t,real(fy),'b')
% hold on
% plot(t,imag(fy),'r')
% hold off
% title(num2str(mean(angle(fy))))