% caller for forward calculation of the surface NMR signal for
% arbitrary loop configurations
% B1-field calculation -> ellp. decomposition -> kernel integration
%
% [K, model] = MakeKernel(loop, model, measure, earth)
% INPUT
% structures loop, model measure earth from MRSKernel gui or script
% 
% OUTPUT
% K: kernel function as a function of z and pm_vec
% J: jacobian for T1 Inversion
% postCalcB1: b-fields
% 

function [K J postCalcB1] = MakeKernel(loop, model, measure, earth, preCalcB1)

if nargin < 5
    calcB1 = 1;
else
    calcB1 = 0;
    postCalcB1 = 0;
end

screensz = get(0,'ScreenSize');
tmpgui.panel_controls.figureid = figure( ...
    'Position', [5 screensz(4)-120 350 100], ...
    'Name', 'Info', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'HandleVisibility', 'on');
tmpgui.panel_controls.edit_status = uicontrol(...
    'Position', [0 0 350 100], ...
    'Style', 'Edit', ...
    'Parent', tmpgui.panel_controls.figureid, ...
    'Enable', 'off', ...
    'BackgroundColor', [0 1 0], ...
    'String', 'Idle...');

K      = zeros(length(measure.pm_vec)*length(measure.taud), model.nz);
J      = zeros(length(measure.pm_vec)*length(measure.taud), model.nz);

modelz        = model.z;
modelDz       = model.Dz;
loopshape     = loop.shape;
loopsize      = loop.size;
earthf        = earth.f;
earthsm       = earth.sm;
earthzm       = earth.zm;
earthres      = earth.res;
measurepm_vec = measure.pm_vec;

%% Bloch simulation  --  precalc B for interpolation for adiabatic pulses
if measure.pulsetype == 2  % use Bloch simulation
    disp('Bloch simulation activated. Please be patient ;)')
    tic
    [measure.adiabatic_flip, measure.adiabatic_Mxy, measure.adiabatic_B] = make_adiabatic_flip(measure);
    toc
end


% run loop over all layers
set(tmpgui.panel_controls.edit_status,'String',...
        ['start calculating ' num2str(model.nz) ' layers']);
drawnow

tic

for n = 1:model.nz;    
    
    if calcB1 % calculate new B1 field and save as postCalcB1
        switch loopshape
            case 1 % circular loop
                if measure.PX
                    [r1, Dr1] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [r2, Dr2] = MakeXvec(loop.PXsize, modelz(n), modelDz(n), 3*loop.PXsize);
                    r_all     = unique(sort([r1; r2]));
                    r         = (r_all(2:end)+r_all(1:end-1))/2;
                    Dr        = r_all(2:end)-r_all(1:end-1);
                    [B1,dh]   = B1cloop_v2(loopsize/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    [Bpre,dh] = B1cloop_v2(loop.PXsize/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], 1);
                else
                    [r, Dr] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B1,dh] = B1cloop_v2(loopsize/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
%                     [B1, dh] = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                end
                
            case 2 % square loop
                % square loop implementation not stable yet
                % [B1, dh] = B1sloop(loopsize, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                % replace by circular loop with equivalent face
                if measure.PX
                    disp('not ready yet')
                else
                    aqface  = sqrt(loopsize^2/pi);
                    [r, Dr] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B1,dh] = B1cloop_v2(aqface, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    %                 [B1, dh] = B1cloop(aqface, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                end
            case {3} % circular eigth
                if measure.PX
                    disp('not ready yet')
                else
                    [r, Dr]      = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B01, Tmpdh] = B1cloop_v2(loopsize/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    %                 [B01, Tmpdh]  = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                    % get trianglation only once and use afterwards
                    if n==1
                        [dh,ic]    = FigureOfEightTriangulation(B01,loop);
                    end
                    B1         = FigureOfEight(B01,loop,ic);
                    B1.Br      = B01.Br;
                    B1.Bz      = B01.Bz;
                    B1.r       = B01.r;
                    B1.phi     = B01.phi;
                    B1.dh      = dh;
                    B1.ic      = ic;
                end
            case {4} % square eight
                if measure.PX
                    disp('not ready yet')
                else
                    aqface = sqrt(loopsize^2/pi);
                    [r, Dr]      = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B01, Tmpdh] = B1cloop_v2(aqface, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    %                 [B01, Tmpdh]  = B1cloop(aqface, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                    % get trianglation only once and use afterwards
                    if n==1
                        [dh,ic]    = FigureOfEightTriangulation(B01,loop);
                    end
                    B1         = FigureOfEight(B01,loop,ic);
                    B1.Br      = B01.Br;
                    B1.Bz      = B01.Bz;
                    B1.r       = B01.r;
                    B1.phi     = B01.phi;
                    B1.dh      = dh;
                    B1.ic      = ic;
                end
            case {5} % separated tx/rx in inloop (centered) setup --> fast calculation possible
                if measure.PX
                    [r1, Dr1] = MakeXvec(loopsize(1), modelz(n), modelDz(n), 3*max(loopsize));
                    [r2, Dr2] = MakeXvec(loopsize(2), modelz(n), modelDz(n), 3*max(loopsize));
                    [r3, Dr3] = MakeXvec(loop.PXsize, modelz(n), modelDz(n), 3*loop.PXsize);
                    r_all     = unique(sort([r1; r2; r3]));
                    r         = (r_all(2:end)+r_all(1:end-1))/2;
                    Dr        = r_all(2:end)-r_all(1:end-1);
                    [B1,dh]   = B1cloop_v2(loopsize(1)/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    [B2,dh]   = B1cloop_v2(loopsize(2)/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    [Bpre,dh] = B1cloop_v2(loop.PXsize/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], 1);
                else
                    [r1, Dr1] = MakeXvec(loopsize(1), modelz(n), modelDz(n), 3*max(loopsize));
                    [r2, Dr2] = MakeXvec(loopsize(2), modelz(n), modelDz(n), 3*max(loopsize));
                    r_all     = unique(sort([r1; r2]));
                    r         = (r_all(2:end)+r_all(1:end-1))/2;
                    Dr        = r_all(2:end)-r_all(1:end-1);
                    [B1,dh]   = B1cloop_v2(loopsize(1)/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    [B2,dh]   = B1cloop_v2(loopsize(2)/2, r, Dr, modelz(n), earthf, earthsm, [0 earthzm], earthres);
                    %                 [B1, dh, B2] = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                end
            case {6} % separated tx/rx in arbitary setup --> only slow calculation
                if measure.PX
                    disp('not ready yet')
                else
                    [B01, Tmpdh, B02] = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                    % get trianglation only once and use afterwards
                    if n==1
                        [dh,ic]    = SepLoopTriangulation(B01,B02,loop);
                    end
                    [B1, B2]        = SepLoop(B01,B02,loop,ic);
                    B1.dh      = dh;
                    B1.ic      = ic;
                end
            case {7} % eigth as transmitter, each single part of eight as receiver
                    [B01, Tmpdh, B02] = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                    if n==1
                        [dh,ic]    = SepLoopTriangulation(B01,B02,loop);
                    end
                   [B1, B2]  = SepLoop(B01,B02,loop,ic);
                    B1.x     = B1.x-B2.x;
                    B1.y     = B1.y-B2.y;
                    B1.z     = B1.z-B2.z;
                    B2.x     = -B2.x;
                    B2.y     = -B2.y;
                    B2.z     = -B2.z;
                    B1.dh    = dh;
                    B1.ic    = ic;
        end
        
        switch loopshape % calculate co- and counterrotating components 
            case {1,2,3,4}
                [Bcomps, B0] = EllipDecomp(earth, B1);
                if measure.PX
                    % calculate additional magnetization as a factor 
                    pre = loop.PXcurrent*loop.PXturns;
                    Pxfactor = abs(sqrt((earth.erdt*B0.x + pre*Bpre.x).^2 + (earth.erdt*B0.y + pre*Bpre.y).^2 + (earth.erdt*B0.z + pre*Bpre.z).^2)./earth.erdt); 
%                     [Bprepol] = calcBprepol(B1.r,modelz(n),loop.PXcurrent*loop.PXturns,loop.PXsize/2,loop.PX8dir);
%                     Pxfactor = Bprepol.magn_cart/abs(earth.erdt);
                else
                    Pxfactor = ones(size(Bcomps.alpha));
                end
                postCalcB1(n).Br     = B1.Br;
                postCalcB1(n).Bz     = B1.Bz;
                postCalcB1(n).r      = B1.r;
                postCalcB1(n).phi    = B1.phi;
                postCalcB1(n).dh     = dh;
            case {5,6,7}
                [B_comps_Tx, B0] = EllipDecompInLoop(earth, B1);
                [B_comps_Rx, B0] = EllipDecompInLoop(earth, B2);
                if measure.PX
                    pre = loop.PXcurrent*loop.PXturns;
                    Pxfactor = abs(sqrt((earth.erdt*B0.x + pre*Bpre.x).^2 + (earth.erdt*B0.y + pre*Bpre.y).^2 + (earth.erdt*B0.z + pre*Bpre.z).^2)./earth.erdt); 
%                     [Bprepol] = calcBprepol(B1.r,modelz(n),loop.PXcurrent*loop.PXturns,loop.PXsize/2,loop.PX8dir);
%                     Pxfactor = Bprepol.magn_cart/abs(earth.erdt);
                else
                    Pxfactor = ones(size(B_comps_Tx.alpha));
                end
                
        end
        
    else % use pre-calculated B-fields preCalcB1
        switch loopshape
            case {1,2}
                dh       = preCalcB1(n).dh;
                B1.x     = cos(preCalcB1(n).phi')*preCalcB1(n).Br;
                B1.y     = sin(preCalcB1(n).phi')*preCalcB1(n).Br;
                B1.z     = repmat(preCalcB1(n).Bz, length(preCalcB1(n).phi), 1);
                [Bcomps] = EllipDecomp(earth, B1);
            case {3,4}
                %msgbox('no double pulse with Fig8 available')
                B01.x    = cos(preCalcB1(n).phi')*preCalcB1(n).Br;
                B01.y    = sin(preCalcB1(n).phi')*preCalcB1(n).Br;
                B01.z    = repmat(preCalcB1(n).Bz, length(preCalcB1(n).phi), 1);
                B01.Br   = preCalcB1(n).Br;
                B01.Bz   = preCalcB1(n).Bz;
                B01.r    = preCalcB1(n).r;
                B01.phi  = preCalcB1(n).phi;
                if n==1
                    [dh,ic]    = FigureOfEightTriangulation(B01,loop);
                end
                B1       = FigureOfEight(B01,loop,ic);
                B1.dh    = dh;
                B1.ic    = ic;
                [Bcomps] = EllipDecomp(earth, B1);
            case {5} %inloop
                msgbox('no yet implemented')
        end
    end
    % if T1 for double pulse kernel is given
    if  measure.pulsesequence == 2
        if isfield(earth,'T1')
            earth.T1cl  = earth.T1(n);
        else
            earth.T1cl  = 0.1;
        end
    end
    
    %% get the kernel
    switch loopshape
        case {1,2,3,4}
            K(:,n)      = IntegrateK1D(measure, earth, Bcomps, Pxfactor, dh, modelDz(n), loop.turns(1))*loop.turns(2)*293/earth.temp;
            % uncomment next line for full 3D fig8 kernel, also uncomment in
            % IntegrateK1D function
            % K(:,:,n) = IntegrateK1D(measure, earth, Bcomps, dh, modelDz(n), loop.turns(1))*loop.turns(2)*293/earth.temp;
            %% get the jacobian for T1
            if  measure.pulsesequence==2 % T1 kernel
                J(:,n)   = IntegrateJ1D(measure, earth, Bcomps, dh, modelDz(n), loop.turns(1))*loop.turns(2)*293/earth.temp;
            else
                J(:,n) = 0;
            end
        case {5,6,7}
            K(:,n)      = IntegrateK1DInLoop(measure, earth, B_comps_Tx, B_comps_Rx, Pxfactor, dh, modelDz(n), loop.turns(1), B1)*loop.turns(2)*293/earth.temp;
            postCalcB1  = [];
            J           = [];               
    end
    
    set(tmpgui.panel_controls.edit_status,'String',...
        ['Calculation of layer ' num2str(n) ' out of ' num2str(model.nz) ' finished in ' num2str(toc) 's']);
    drawnow
end
close(tmpgui.panel_controls.figureid)
