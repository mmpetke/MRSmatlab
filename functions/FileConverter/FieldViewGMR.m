function FieldViewGMR(gui,fdata,fileID)

  

%% read in one file containing all pulse moments/stacks (depends on fdata.header.Qsampling)
    mrs_setguistatus(gui,1,'load data')
    rec   = fdata.filenumber(fileID);
    data  = openGMRRawData(fdata, rec); 

    fdata.refChannel=[];
    fdata.decChannel=[];

%% q distribution
figure(200)
plot(data.q1,'o')
xlabel('# pulse moment')
ylabel('q in As')

%% do processing    
figure(201);    

    % get filter coefficient from precalculation
    LPfilter = load('coefficient.mat');
    fW       = 500;
    fS       = fdata.header.fS;
    fT       = fdata.header.fT;
    
    mrs_setguistatus(gui,1,'processing')
     
    ic=0; % get total number of channels to display
    for nC = 1:fdata.header.nrx % check channel
        if ~fdata.UserData(nC).looptask==0
        ic=ic+1;
        end
    end
    icc=0;
    for nC = 1:fdata.header.nrx % check channel
        if ~fdata.UserData(nC).looptask==0
            icc=icc+1;
        for nS=1:length(data.q1) % number of either stacks or pulses
            switch nC
                case 1
                    v(nS,:) = data.recordC1{nS}.sig2*sign(data.q1phase(nS));
                case 2
                    v(nS,:) = data.recordC2{nS}.sig2*sign(data.q1phase(nS));
                case 3
                    v(nS,:) = data.recordC3{nS}.sig2*sign(data.q1phase(nS));
                case 4
                    v(nS,:) = data.recordC4{nS}.sig2*sign(data.q1phase(nS));
                case 5
                    v(nS,:) = data.recordC5{nS}.sig2*sign(data.q1phase(nS));
                case 6
                    v(nS,:) = data.recordC6{nS}.sig2*sign(data.q1phase(nS));
                case 7
                    v(nS,:) = data.recordC7{nS}.sig2*sign(data.q1phase(nS));
                case 8
                    v(nS,:) = data.recordC8{nS}.sig2*sign(data.q1phase(nS));
            end
        end
        
        t = (0:size(v,2)-1)/fS;
        V = sum(v,1)/nS;
        % do QD
        U = mrsSigPro_QD(V,t,fT,fS,fW,LPfilter);
        U(t<5e-3)=0;
        U(isnan(U)==1)=0;
        
        % plot
%         subplot(fdata.header.nrx,2,2*nC-1) % data
        subplot(ic,2,2*icc-1) % data
        plot(t,real(U)*1e9,'b',t,imag(U)*1e9,'r')       
        xlim([0 max(t)])
        xlabel('t/s');ylabel('amp/nV');
        grid on;
        
%         subplot(fdata.header.nrx,2,2*nC) % FFT
        subplot(ic,2,2*icc) % FFT
        a = mod(length(U),2); % check for even number of samples for fft
        [freq_range,spec] = mrs_sfft(t(1:end-a),U(1:end-a));
        MinMax = [min(abs(spec(freq_range > -1000 & freq_range < 1000)))...
            max(abs(spec(freq_range > -1000 & freq_range < 1000)))];
        xl = [-1000 1000];   % xlimits

        Ncolor = ['rgbmrgbm'];
        Nline  = ['----::::'];
        oldplot = gcf;
        
        figure(202)
        plot(freq_range,abs(spec),[Ncolor(nC) Nline(nC)]); hold on
        set(gca,'xlim',xl,'yscale','log')
        ylim(MinMax);
        xlim(xl/10);
        xlabel('f/Hz');ylabel('amp');
        grid on;
        legend('channel 1', 'channel 2', 'channel 3', 'channel 4');
                
        figure(oldplot)
        plot(freq_range,abs(spec),'r')
        set(gca,'xlim',xl,'yscale','log')
        ylim(MinMax)
        grid on; 
        xlabel('f/Hz');ylabel('amp');title(['channel ' num2str(nC)]);
        
        switch fdata.UserData(nC).looptask % check task
            case 0 % unconnected
            case {1,2} % signal receiver 
                fdata.signal{nC}.v    = v;
                fdata.decChannel      = [fdata.decChannel nC];
            case 3 % noise receiver
                fdata.signal{nC}.v    = v;
                fdata.refChannel      = [fdata.refChannel nC];
        end
        end
    end
    
    icc=0;
    for nC = 1:fdata.header.nrx % check channel
        switch fdata.UserData(nC).looptask % check task
            case {1,2} % signal receiver
                icc=icc + 1;
                if ~isempty(fdata.refChannel)% do nc
                    mrs_setguistatus(gui,1,'do nc')
                    for nS=1:length(data.q1)
                        detection(nS).P1 =  fdata.signal{nC}.v(nS,:);
                        for rc=1:length(fdata.refChannel)
                            reference(nS).R1(rc,:) =  fdata.signal{fdata.refChannel(rc)}.v(nS,:);
                        end
                    end
                    transfer = mrsSigPro_FFTMultiChannelTransfer(reference,detection);
                    
                    for nS=1:length(data.q1)
                        transReference=zeros(size(fdata.signal{nC}.v(nS,:)));
                        for nc=1:length(fdata.refChannel)
                            transReference = transReference + ifft((transfer(:,nc).').*fft(fdata.signal{fdata.refChannel(nc)}.v(nS,:)));
                        end
                        v1(nS,:) = fdata.signal{nC}.v(nS,:) - transReference;
                    end
                    
                else
                    v1 = fdata.signal{nC}.v;
                end
                
                t = (0:size(v,2)-1)/fS;
                V  = sum(fdata.signal{nC}.v,1)/nS;
                V1 = sum(v1,1)/nS;
                % do QD
                U = mrsSigPro_QD(V,t,fT,fS,fW,LPfilter);
                U(t<5e-3)=0;
                U(isnan(U)==1)=0;
                U1 = mrsSigPro_QD(V1,t,fT,fS,fW,LPfilter);
                U1(t<5e-3)=0;
                U1(isnan(U1)==1)=0;
                %
                % do fitting
                mrs_setguistatus(gui,1,'fitting')
                lb  = [1e-10 0.01 -5 -pi];
                ini = [1e-7  0.1   0   0];
                ub  = [1e-5  1     5  pi];
                fit = mrs_fitFID(t(t>5e-3),U1(t>5e-3),lb,ini,ub);
                f   = fit(1) * exp(-t/fit(2) + 1i*(2*pi*fit(3)*t + fit(4)));
                
%                 subplot(fdata.header.nrx,2,2*nC-1) % data
                subplot(ic,2,2*icc-1) % data
                plot(t,real(U)*1e9,'--k',t,imag(U)*1e9,'--k')
                hold on
                plot(t,real(U1)*1e9,'b',t,imag(U1)*1e9,'r')
                plot(t,real(f)*1e9,'k',t,imag(f)*1e9,'k')
                grid on
                title(['E_0 = '       num2str(abs(fit(1)*1e9),4) ...
                    'nV; T_2^* = ' num2str(fit(2),2) ...
                    's; df = '     num2str(fit(3),2) ...
                    'Hz (f_L = '   num2str(fT + fit(3),4) ...
                    'Hz) STD = '    num2str(std(real(U1)-real(f))*1e9,3) 'nV']);
                %ylim([-1.1 1.1]*abs(fit(1)*1e9));
                
%                 subplot(fdata.header.nrx,2,2*nC) % FFT
                subplot(ic,2,2*icc) % FFT
                hold on
                [freq_range,spec] = mrs_sfft(t(1:end-a),U1(1:end-a));
                plot(freq_range,abs(spec),'k')
        end
    end
    mrs_setguistatus(gui,0);


