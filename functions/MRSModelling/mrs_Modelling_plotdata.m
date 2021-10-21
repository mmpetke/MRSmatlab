function mrs_Modelling_plotdata(gui, mdata, kdata)

scaleV = 1e9;
scaleB = 1e15;
scaleT = 1e0;
weight = repmat(kdata.model.Dz,size(kdata.K,1),1);

%% kernel figure
figure(gui.fig_graphs)
    fs=10;
    clf
    subplot(1,6,1:2)
    switch kdata.loop.shape
        case {7}
            kplt = pcolor(kdata.measure.pm_vec, kdata.model.z, (real(kdata.K)./(weight./scaleV)).');
        case {8}
            kplt = pcolor(kdata.measure.pm_vec, kdata.model.z, (imag(kdata.K)./(weight./scaleB)).');
        otherwise
            if size(kdata.K,1) == 1
                kplt = plot((abs(kdata.K)./(weight./scaleV)).',kdata.model.z);
            else
                kplt = pcolor(kdata.measure.pm_vec, kdata.model.z, (abs(kdata.K)./(weight./scaleV)).');
            end
    end
    if size(kdata.K,1) == 1
        xlabel('amplitude [nV/m]', 'Fontsize', fs)
    else
        shading flat
        xlabel('pulse moment q [As]', 'Fontsize', fs)
    end
    axis ij    
    box on
    grid on
    set(gca, 'layer', 'top')
    title('kernel', 'FontSize', fs)    
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
    title('T_1/T_2', 'FontSize', fs)
    axis ij
    box on
    grid on
    set(gca, 'layer', 'top')
    xlim(scaleT*[0 ceil(max(mdata.mod.T1)+0.05)])
    xlabel('[s]', 'Fontsize', fs)


%% sounding figure
figure(gui.fig_soundings)
switch kdata.measure.pulsesequence
    case 1%'FID'
        clf
        subplot(141)
        hold on
        switch kdata.loop.shape
            case {7}
                plot(real(mdata.dat.v0)*scaleV, kdata.measure.pm_vec, 'bx')
                plot(real(mdata.dat.V0fit)*scaleV, kdata.measure.pm_vec, 'ro')
                xlabel('real/nV')
            case {8}
                plot(imag(mdata.dat.v0)*scaleB, kdata.measure.pm_vec, 'bx')
                plot(imag(mdata.dat.V0fit)*scaleB, kdata.measure.pm_vec, 'ro')
                xlabel('imag/fT')
            otherwise
                plot(abs(mdata.dat.v0)*scaleV, kdata.measure.pm_vec, 'bx')
                plot(abs(mdata.dat.V0fit)*scaleV, kdata.measure.pm_vec, 'ro')
                xlabel('amplitude/nV')
        end        
        ylabel('q/A.s');        
        legend('true initials', 'monofit','Location','SouthWest')
        axis ij
        grid on
        box on

        subplot(142)
        hold on
        plot(scaleT*mdata.dat.T2sfit, kdata.measure.pm_vec, 'ro')
        xlabel('T2*/ms')
        axis ij
        grid on
        box on

        subplot(143)
        hold on
        plot(angle(mdata.dat.v0), kdata.measure.pm_vec, 'bx')
        plot(angle(mdata.dat.V0fit), kdata.measure.pm_vec, 'ro')
        xlabel('phase/ rad')
        axis ij
        grid on
        box on

        subplot(144)
        hold on
        plot([0 1 1 0], [1 0 1 0])
        % axis ij
        % grid on
        box on
    case 2%'T2'
        clf
        subplot(1,4,[1:2])
            imagesc(mdata.mod.tau,kdata.measure.pm_vec,mdata.dat.V0echofit'.*scaleV)
            axis ij; shading flat
            title('Detected Echos')
            xlabel('pulse moment Q [As]')
            ylabel('time [s]')
        subplot(143)
            plot(abs(mdata.dat.v0)*scaleV, kdata.measure.pm_vec, 'bx')
            hold on
            plot(abs(mdata.dat.V0fit)*scaleV, kdata.measure.pm_vec, 'ro')
            legend('true initials', 'first echo','Location','SouthWest')
            ylabel('q/A.s');
            xlabel('amplitude/nV')
            axis ij
            grid on
            box on
        subplot(144)
            hold on
            plot(scaleT*mdata.dat.T2sfit, kdata.measure.pm_vec, 'ro')
            xlabel('T2*/ms')
            axis ij
            grid on
            box on
end

%%
% qt-figure
figure(gui.fig_qtcube)
clf
switch kdata.measure.pulsesequence
    case 1%'FID'
        subplot(121)
        if size(kdata.K,1) == 1
            plot(mdata.mod.tfid1,real(mdata.dat.fid1).*scaleV)
        else
            pcolor(mdata.mod.tfid1,kdata.measure.pm_vec,real(mdata.dat.fid1).*scaleV)
            xlabel('pulse moment Q [As]')
            colorbar
        end
        axis ij; shading flat
        set(gca,'yscale','log','xscale','log')
        ylabel('time [s]')
        title('real [nV]')
        subplot(122)
        if size(kdata.K,1) == 1
            plot(mdata.mod.tfid1,imag(mdata.dat.fid1).*scaleV)
        else
            pcolor(mdata.mod.tfid1,kdata.measure.pm_vec,imag(mdata.dat.fid1).*scaleV)
            xlabel('pulse moment Q [As]')
            colorbar
        end        
        axis ij; shading flat
        set(gca,'yscale','log','xscale','log')
        ylabel('time [s]')
        title('imag [nV]')
    case 'T2'
        pcolor(mdata.mod.tfid1 - mdata.mod.tfid1(1) ,kdata.measure.pm_vec,real(mdata.dat.fid1).*scaleV)
        axis ij; shading flat
        set(gca,'yscale','log','xscale','lin')
        colorbar
        xlabel('pulse moment Q [As]')
        ylabel('time [s]')
        title('rotated [nV]')
end
    
    
%% qt-figure old style
% figure(gui.fig_qtcube)
% clf
% [Q,T] = meshgrid(kdata.measure.pm_vec, mdata.mod.tfid1);
% fitresult = zeros(size(Q));
% for iq = 1:length(mdata.dat.V0fit)
%     fitresult(:,iq) = mdata.dat.V0fit(iq) * exp(-mdata.mod.tfid1' ./ mdata.dat.T2sfit(iq));
% end
% subplot(121)
% plot3(Q,T,real(mdata.dat.fid1).'*scaleV, 'k.','MarkerSize',1)
% hold on
% plot3(Q,T,real(fitresult) * scaleV, 'r-')
% hold off
% xlim([min(kdata.measure.pm_vec) max(kdata.measure.pm_vec)])
% ylim([min(mdata.mod.tfid1) max(mdata.mod.tfid1)])
% grid on
% xlabel('pulse moment Q [As]')
% ylabel('time [s]')
% zlabel('real [nV]')
% subplot(122)
% plot3(Q,T,imag(mdata.dat.fid1).'*scaleV, 'k.','MarkerSize',1)
% hold on
% plot3(Q,T,imag(fitresult) * scaleV, 'r-')
% hold off
% xlim([min(kdata.measure.pm_vec) max(kdata.measure.pm_vec)])
% ylim([min(mdata.mod.tfid1) max(mdata.mod.tfid1)])
% grid on
% xlabel('pulse moment Q [As]')
% ylabel('time [s]')
% zlabel('imag [nV]')