function mrs_ModellingT1_plotdata(gui, mdataTau, kdata)

scaleV = 1e9;
scaleT = 1e0;
weight = repmat(kdata.model.Dz,size(kdata.K,1),1);
mdata  = mdataTau(end);
nTau   = length(mdata.mod.tau);

%% kernel figure
figure(gui.fig_graphs)
    fs=10;
    clf
    subplot(1,6,1:2)
    kplt = pcolor(kdata.measure.pm_vec, kdata.model.z, (abs(kdata.K)./weight).');
    axis ij
    shading flat
    box on
    grid on
    set(gca, 'layer', 'top')
    title('kernel', 'FontSize', fs)
    xlabel('pulse moment q [As]', 'Fontsize', fs)
    ylabel('depth [m]', 'Fontsize', fs)

    subplot (1,6,3)
    stairs([1./kdata.earth.sm(1) 1./kdata.earth.sm],[0 kdata.earth.zm max(kdata.model.z)])
    title('resistivity', 'FontSize', fs)
    axis ij
    box on
    set(gca,'xscale','log')
    grid on
    set(gca, 'layer', 'top')
    xlim([floor(min(1./kdata.earth.sm))/2 ceil(max(1./kdata.earth.sm))*2])
    xlabel('[Ohm m]', 'Fontsize', fs)
    % ylabel('depth [m]', 'Fontsize', fs)

    subplot(1,6,4)
    stairs([mdata.mod.f(1) mdata.mod.f], mdata.mod.zlayer)
    title('water content', 'FontSize', fs)
    axis ij
    box on
    grid on
    set(gca, 'layer', 'top')
    xlim([0 floor(max(mdata.mod.f*10))/10+0.1])
    xlabel('[m^3/m^3]')

    subplot(1,6,5)
    stairs(scaleT*[mdata.mod.T2s(1) mdata.mod.T2s], mdata.mod.zlayer)
    title('T_2^*')
    axis ij
    box on
    grid on
    set(gca, 'layer', 'top')
    xlim(scaleT*[0 ceil(max(mdata.mod.T2s*100))/100+0.05])
    xlabel('[s]', 'Fontsize', fs)


    subplot(1,6,6)
    stairs(scaleT*[mdata.mod.T1(1) mdata.mod.T1],mdata.mod.zlayer)
    title('T_1', 'FontSize', fs)
    axis ij
    box on
    grid on
    set(gca, 'layer', 'top')
    xlim(scaleT*[0 ceil(max(mdata.mod.T1*100))/100+0.05])
    xlabel('[s]', 'Fontsize', fs)


%% sounding figure
figure(gui.fig_soundings)
    clf
    for iTau = 1:nTau
        subplot(141)
        hold on
        plot(abs(mdataTau(iTau).dat.v0fid2)*scaleV, kdata.measure.pm_vec, 'bx')
        plot(abs(mdataTau(iTau).dat.V0fid2fit)*scaleV, kdata.measure.pm_vec, 'ro')
        ylabel('q/A.s');
        xlabel('amplitude/nV')
        legend('true initials', 'monofit','Location','SouthWest')
        axis ij
        grid on
        box on

        subplot(142)
        hold on
        plot(scaleT*mdataTau(iTau).dat.T2sfid2fit, kdata.measure.pm_vec, 'ro')
        xlabel('T2*/ms')
        axis ij
        grid on
        box on

        subplot(143)
        hold on
        plot(angle(mdataTau(iTau).dat.v0fid2), kdata.measure.pm_vec, 'bx')
        plot(angle(mdataTau(iTau).dat.V0fid2fit), kdata.measure.pm_vec, 'ro')
        xlabel('phase/ rad')
        axis ij
        grid on
        box on
    end
    
        subplot(144)
        t   = mdata.mod.tau;
        ini = [100 1]';
        lb  = [0   0.01]';
        ub  = [1e6 3]';
        for iq = 1:length(kdata.measure.pm_vec)
            for iTau = 1:nTau
                d(iTau) = abs(mdataTau(iTau).dat.v0fid2(iq));
            end
            x = T1MonoExpFit(t-t(1),(d-min(d))*1e9,ini,lb,ub);
%             x = T1MonoExpFit(t,d*1e9,ini,lb,ub);
            T1(iq) = x(2);
        end
        plot(scaleT*T1,kdata.measure.pm_vec, 'bx')
        axis ij
        grid on
        box on
        xlabel('T1/s')
    
%% qt-figure
figure(gui.fig_qtcube)
clf
cl = abs([0 1.1*max(max(mdataTau(end).dat.fid2))]);
for iTau = 1:nTau
    subplot(2,nTau,iTau)
        pcolor(mdata.mod.tfid2,kdata.measure.pm_vec,real(mdataTau(iTau).dat.fid2))
        axis ij; shading flat;
        set(gca,'Xscale','log','Yscale','log');
        ylabel('q/A.s');xlabel('t/s');title(['tau = ' num2str(mdata.mod.tau(iTau))])
        set(gca,'CLim',cl)
    subplot(2,nTau,iTau + nTau)
        pcolor(mdata.mod.tfid2,kdata.measure.pm_vec,imag(mdataTau(iTau).dat.fid2))
        axis ij; shading flat;
        set(gca,'Xscale','log','Yscale','log');
        ylabel('q/A.s');xlabel('t/s');
        set(gca,'CLim',cl)
end

