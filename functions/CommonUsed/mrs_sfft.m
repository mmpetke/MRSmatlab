%%%%%%%%%%%%%%
% sorted fft %
%%%%%%%%%%%%%%

function [freq_range,spec]=mrs_sfft(t,sig)


samples                                  = length(sig);
dft                                      = fft(sig,samples)/length(sig);
spec                                     = zeros(size(dft));
spec(1:int32(length(dft)/2))             = dft(int32(length(dft)/2)+1:length(dft)); 
spec(int32(length(dft)/2)+1:length(dft)) = dft(1:int32(length(dft)/2));

dt         = t(2)-t(1);
freq_sampl = 1/dt;                   % sampling-frequency
nyquist    = 0.5*freq_sampl;         % nyquist-frequency
df         = freq_sampl/(samples);
freq_range = -nyquist:df:nyquist-df; % frequency-axis



