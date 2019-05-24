function LPfilter = build_LPfilter(Fs,type)           
            Fpass = 500;   % Passband Frequency
            Fstop = 2000;  % Stopband Frequency
            Apass = 1;     % Passband Ripple (dB)
            
            
            switch type
                case '1'
                    Astop = 50;    % Stopband Attenuation (dB)
                    % Calculate the order from the parameters using BUTTORD.
                    [N,Fc] = buttord(Fpass/(Fs/2), Fstop/(Fs/2), Apass, Astop);
                    % using standard filter tht allows for filtfilt
                    [b,a]       = butter(N, Fc);
                    LPfilter    = [b;a];
                    %         f_filt      = filter(LPfilter(1,:),LPfilter(2,:),f);
                case '2'
                    Astop = 50;    % Stopband Attenuation (dB)
                    % Calculate the order from the parameters using BUTTORD.
                    [N,Fc] = buttord(Fpass/(Fs/2), Fstop/(Fs/2), Apass, Astop);
                    % using digital filter object
                    % Calculate the zpk values using the BUTTER function.
                    [z,p,k] = butter(N, Fc);
                    [sos_var,g] = zp2sos(z, p, k);
                    LPfilter    = dfilt.df2sos(sos_var, g);
                    %         f_filt      = filter(LPfilter,f);
            end
            
        end