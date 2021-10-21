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

function [K, J, postCalcB1] = MakeKernel(loop, model, measure, earth, preCalcB1)

if nargin < 5
    calcB1 = 1;
else
    calcB1 = 0;
    postCalcB1 = 0;
end

% Thomas ->
% on / off switch to export B-fields
export_Bfields = false;
zoffsetTx = 0.00;
zoffsetRx = 0.00;
zoffsetPx = 0.00;
if isfield(loop,'dipolePosition')
    dipolePos = loop.dipolePosition;
else
    dipolePos = [0 0 -0.05];
end
% <- Thomas

screensz = get(0,'ScreenSize');
% check if there is already a figure window open
isfig = findobj('Type','Figure','Name','Info');
if isempty(isfig)
    tmpgui.panel_controls.figureid = figure( ...
        'Position', [5 screensz(4)-150 350 100], ...
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
else
    % reset info box;
    tmpgui.panel_controls.figureid = isfig;
    tmpgui.panel_controls.edit_status = get(isfig,'Children');
    set(tmpgui.panel_controls.edit_status,'String', 'Idle...');
end

switch loop.shape
    case {7,8} %circular Tx loop + Bfield sensor
        K = zeros(length(measure.pm_vec)*length(measure.taud), model.nz,3);
        J = zeros(length(measure.pm_vec)*length(measure.taud), model.nz,3);
    otherwise
        K = zeros(length(measure.pm_vec)*length(measure.taud), model.nz);
        J = zeros(length(measure.pm_vec)*length(measure.taud), model.nz);
end

% local variables
modelz = model.z;
modelDz = model.Dz;
loopshape = loop.shape;
loopsize = loop.size;
PXSign = loop.PXsign;
earthf = earth.f;
earthsm = earth.sm;
earthzm = earth.zm;
earthres = earth.res;
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

for n = 1:model.nz
    
    if calcB1 % calculate new B1 field and save as postCalcB1
        switch loopshape
            case 1 % circular loop
                if measure.PX
                    [r1, Dr1] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [r2, Dr2] = MakeXvec(loop.PXsize, modelz(n), modelDz(n), 3*loop.PXsize);
                    % Thomas ->                    
                    if numel(r1)==numel(r2) && all(r1 == r2)
                        % if both loops are basically identical just keep one
                        % of them
                        r = r1;
                        Dr = Dr1;
                    else
                        % otherwise make a merged r vector
                        ro1 = r1+Dr1/2;
                        ro2 = r2+Dr2/2;
%                         r_all = unique(sort([r1; r2])); % ORG
                        r_all = [0; unique(sort([ro1; ro2]))];
                        r = (r_all(2:end)+r_all(1:end-1))/2; % ORG
                        Dr = r_all(2:end)-r_all(1:end-1); % ORG
                        r(Dr<1e-6) = [];
                        Dr(Dr<1e-6) = [];
                    end
                    % <- Thomas                    
                    [B1,dh] = B1cloop_v2(loopsize/2   , r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    [Bpre,dh] = B1cloop_v2(loop.PXsize/2, r, Dr, modelz(n)+zoffsetPx, 0, earthsm, [0 earthzm], 1);
                    Bpre.Br = PXSign.*Bpre.Br;
                    Bpre.Bz = PXSign.*Bpre.Bz;
                    Bpre.x = PXSign.*Bpre.x;
                    Bpre.y = PXSign.*Bpre.y;
                    Bpre.z = PXSign.*Bpre.z;
                else
                    [r, Dr] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B1,dh] = B1cloop_v2(loopsize/2, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    % [B1, dh] = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                end                
            case 2 % square loop
                % square loop implementation not stable yet
                % [B1, dh] = B1sloop(loopsize, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                % replace by circular loop with equivalent face
                if measure.PX
                    disp('not ready yet')
                else
                    aqface = sqrt(loopsize^2/pi);
                    [r, Dr] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B1,dh] = B1cloop_v2(aqface, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    %                 [B1, dh] = B1cloop(aqface, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                end
            case {3} % circular eigth
                if measure.PX
                    disp('not ready yet')
                else
                    [r, Dr] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B01, ~] = B1cloop_v2(loopsize/2, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    % [B01, Tmpdh]  = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                    % get trianglation only once and use afterwards
                    if n == 1 || (numel(r) ~= numel(r_old))
                        [dh,ic] = FigureOfEightTriangulation(B01,loop);
                        r_old = r;
                    end
                    disp([num2str(n),' ',num2str(numel(r))]);
                    B1 = FigureOfEight(B01,loop,ic);
                    B1.Br = B01.Br;
                    B1.Bz = B01.Bz;
                    B1.r = B01.r;
                    B1.phi = B01.phi;
                    B1.dh = dh;
                    B1.ic = ic;
                end
            case {4} % square eight
                if measure.PX
                    disp('not ready yet')
                else
                    aqface = sqrt(loopsize^2/pi);
                    [r, Dr] = MakeXvec(loopsize, modelz(n), modelDz(n), 3*loopsize);
                    [B01, ~] = B1cloop_v2(aqface, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    %                 [B01, Tmpdh]  = B1cloop(aqface, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                    % get trianglation only once and use afterwards
                    if n==1
                        [dh,ic] = FigureOfEightTriangulation(B01,loop);
                    end
                    B1 = FigureOfEight(B01,loop,ic);
                    B1.Br = B01.Br;
                    B1.Bz = B01.Bz;
                    B1.r = B01.r;
                    B1.phi = B01.phi;
                    B1.dh = dh;
                    B1.ic = ic;
                end
            case {5} % separated tx/rx in inloop (centered) setup --> fast calculation possible
                if measure.PX
                    [r1, ~] = MakeXvec(loopsize(1), modelz(n), modelDz(n), 3*max(loopsize));
                    [r2, ~] = MakeXvec(loopsize(2), modelz(n), modelDz(n), 3*max(loopsize));
                    [r3, ~] = MakeXvec(loop.PXsize, modelz(n), modelDz(n), 3*loop.PXsize);
                    r_all = unique(sort([r1; r2; r3]));
                    r = (r_all(2:end)+r_all(1:end-1))/2;
                    Dr = r_all(2:end)-r_all(1:end-1);
                    [B1,dh] = B1cloop_v2(loopsize(1)/2, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    [B2,dh] = B1cloop_v2(loopsize(2)/2, r, Dr, modelz(n)+zoffsetRx, earthf, earthsm, [0 earthzm], earthres);
                    [Bpre,dh] = B1cloop_v2(loop.PXsize/2, r, Dr, modelz(n)+zoffsetPx, 0, earthsm, [0 earthzm], 1);
                    Bpre.Br = PXSign.*Bpre.Br;
                    Bpre.Bz = PXSign.*Bpre.Bz;
                    Bpre.x = PXSign.*Bpre.x;
                    Bpre.y = PXSign.*Bpre.y;
                    Bpre.z = PXSign.*Bpre.z;
                else
                    [r1,~] = MakeXvec(loopsize(1), modelz(n), modelDz(n), 3*max(loopsize));
                    [r2,~] = MakeXvec(loopsize(2), modelz(n), modelDz(n), 3*max(loopsize));
                    r_all = unique(sort([r1; r2]));
                    r = (r_all(2:end)+r_all(1:end-1))/2;
                    Dr = r_all(2:end)-r_all(1:end-1);
                    [B1,dh] = B1cloop_v2(loopsize(1)/2, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    [B2,dh] = B1cloop_v2(loopsize(2)/2, r, Dr, modelz(n)+zoffsetRx, earthf, earthsm, [0 earthzm], earthres);
                    %  [B1, dh, B2] = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                end
            case {6} % separated tx/rx in arbitary setup --> only slow calculation
                if measure.PX
                    disp('not ready yet')
                else
                    [B01, Tmpdh, B02] = B1cloop(loopsize/2, modelz(n), modelDz(n), earthf, earthsm, [0 earthzm], earthres);
                    % get trianglation only once and use afterwards
                    if n==1
                        [dh,ic] = SepLoopTriangulation(B01,B02,loop);
                    end
                    [B1, B2] = SepLoop(B01,B02,loop,ic);
                    B1.dh = dh;
                    B1.ic = ic;
                end
            case {7,8} % circular Tx loop + Bfield sensor
                if measure.PX
                    [r1, ~] = MakeXvec(loopsize(1), modelz(n), modelDz(n), 3*max(loopsize));
                    [r2, ~] = MakeXvec(loop.PXsize, modelz(n), modelDz(n), 3*loop.PXsize);
                    r_all = unique(sort([r1; r2]));
                    r = (r_all(2:end)+r_all(1:end-1))/2;
                    Dr = r_all(2:end)-r_all(1:end-1);
                    [B1,dh] = B1cloop_v2(loopsize(1)/2, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    [B2x,~] = B1dipole(r, Dr, modelz(n), dipolePos,[1 0 0]);
                    [B2y,~] = B1dipole(r, Dr, modelz(n), dipolePos,[0 1 0]);
                    [B2z,~] = B1dipole(r, Dr, modelz(n), dipolePos,[0 0 1]);
                    [Bpre,dh] = B1cloop_v2(loop.PXsize/2, r, Dr, modelz(n)+zoffsetPx, 0, earthsm, [0 earthzm], 1);
                    Bpre.Br = PXSign.*Bpre.Br;
                    Bpre.Bz = PXSign.*Bpre.Bz;
                    Bpre.x = PXSign.*Bpre.x;
                    Bpre.y = PXSign.*Bpre.y;
                    Bpre.z = PXSign.*Bpre.z;
                else
                    [r, Dr] = MakeXvec(loopsize(1), modelz(n), modelDz(n), 3*max(loopsize));
                    [B1,dh] = B1cloop_v2(loopsize(1)/2, r, Dr, modelz(n)+zoffsetTx, earthf, earthsm, [0 earthzm], earthres);
                    [B2x,~] = B1dipole(r, Dr, modelz(n), dipolePos,[1 0 0]);
                    [B2y,~] = B1dipole(r, Dr, modelz(n), dipolePos,[0 1 0]);
                    [B2z,~] = B1dipole(r, Dr, modelz(n), dipolePos,[0 0 1]);
                end
        end
        switch loopshape
            case {1,2,3,4}
                [Bcomps, B0] = EllipDecomp(earth, B1);
                if measure.PX
                    % calculate additional magnetization as a factor
                    if loop.usePXramp
                        rampopts.name = loop.PXramp;
                        rampopts.time = loop.PXramptime;
                        [Pxfactor,measure.Mp,~] = getMfromLookupFull(earth,loop,B0,Bpre,rampopts);
                    else                        
                        pre = loop.PXcurrent*loop.PXturns;
                        Pxfactor = abs(sqrt((earth.erdt*B0.x + pre*Bpre.x).^2 + (earth.erdt*B0.y + pre*Bpre.y).^2 + (earth.erdt*B0.z + pre*Bpre.z).^2)./earth.erdt);
                    end
                else
                    Pxfactor = ones(size(Bcomps.alpha));
                end
                postCalcB1(n).Br = B1.Br;
                postCalcB1(n).Bz = B1.Bz;
                postCalcB1(n).r = B1.r;
                postCalcB1(n).phi = B1.phi;
                postCalcB1(n).dh = dh;
            case {5,6}
                [B_comps_Tx, B0] = EllipDecompInLoop(earth, B1);
                [B_comps_Rx, ~] = EllipDecompInLoop(earth, B2);
                if measure.PX
                    % calculate additional magnetization as a factor
                    if loop.usePXramp
                        rampopts.name = loop.PXramp;
                        rampopts.time = loop.PXramptime;
                        [Pxfactor,measure.Mp,~] = getMfromLookupFull(earth,loop,B0,Bpre,rampopts);
                    else
                        pre = loop.PXcurrent*loop.PXturns;
                        Pxfactor = abs(sqrt((earth.erdt*B0.x + pre*Bpre.x).^2 + (earth.erdt*B0.y + pre*Bpre.y).^2 + (earth.erdt*B0.z + pre*Bpre.z).^2)./earth.erdt);
                    end
                else
                    Pxfactor = ones(size(B_comps_Tx.alpha));
                end
            case {7,8}
                [B_comps_Tx, B0] = EllipDecompInLoop(earth, B1);
                [B_comps_RxX, ~] = EllipDecompInLoop(earth, B2x);
                [B_comps_RxY, ~] = EllipDecompInLoop(earth, B2y);
                [B_comps_RxZ, ~] = EllipDecompInLoop(earth, B2z);
                if measure.PX
                    % calculate additional magnetization as a factor
                    if loop.usePXramp
                        rampopts.name = loop.PXramp;
                        rampopts.time = loop.PXramptime;
                        [Pxfactor,measure.Mp,~] = getMfromLookupFull(earth,loop,B0,Bpre,rampopts);
                    else
                        pre = loop.PXcurrent*loop.PXturns;
                        Pxfactor = abs(sqrt((earth.erdt*B0.x + pre*Bpre.x).^2 + (earth.erdt*B0.y + pre*Bpre.y).^2 + (earth.erdt*B0.z + pre*Bpre.z).^2)./earth.erdt);
                    end
                else
                    Pxfactor = ones(size(B_comps_Tx.alpha));
                end
        end

        if export_Bfields
            Bfields.B0{n} = B0;
            Bfields.B1{n} = B1;
            if exist('B2','var')
                Bfields.B2{n} = B2;
            end
            Bfields.dh{n} = dh;
            if measure.PX
                Bfields.Bpre{n} = Bpre;
                Bfields.PxFactor{n} = Pxfactor;
                if isfield(measure,'Mp')
                    Bfields.Mp{n} = measure.Mp;
                end
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
                    [dh,ic] = FigureOfEightTriangulation(B01,loop);
                end
                B1       = FigureOfEight(B01,loop,ic);
                B1.dh    = dh;
                B1.ic    = ic;
                [Bcomps] = EllipDecomp(earth, B1);
            case {5,6,7,8} % inloop
                msgbox('no yet implemented')
        end
    end
    % if T1 for double pulse kernel is given
    if  measure.pulsesequence == 2
        if isfield(earth,'T1')
            earth.T1cl = earth.T1(n);
        else
            earth.T1cl = 0.1;
        end
    end
    
    %% get the kernel
    switch loopshape
        case {1,2,3,4}
            K(:,n) = IntegrateK1D(measure, earth, Bcomps, Pxfactor, dh, modelDz(n), loop.turns(1))*loop.turns(2)*293/earth.temp;
            % uncomment next line for full 3D fig8 kernel, also uncomment in
            % IntegrateK1D function
            % K(:,:,n) = IntegrateK1D(measure, earth, Bcomps, dh, modelDz(n), loop.turns(1))*loop.turns(2)*293/earth.temp;
            % get the jacobian for T1
            if  measure.pulsesequence == 2 % T1 kernel
                J(:,n) = IntegrateJ1D(measure, earth, Bcomps, dh, modelDz(n), loop.turns(1))*loop.turns(2)*293/earth.temp;
            else
                J(:,n) = 0;
            end
        case {5,6}
            K(:,n)      = IntegrateK1DInLoop(measure, earth, B_comps_Tx, B_comps_Rx,...
                Pxfactor, dh, modelDz(n), loop.turns(1), B1)*loop.turns(2)*293/earth.temp;
            postCalcB1  = [];
            J           = [];
        case {7,8}
            if measure.pulsesequence == 2 && measure.pulsetype == 3 % T1 & Px switch-off
                K(:,n,:) = IntegrateK1DDipoleMagnetics(loop, measure, earth,...
                    B0, Bpre, dh, modelz(n), modelDz(n), loopshape, dipolePos);
            else % all other dipole related code
                K(:,n,:) = IntegrateK1DDipole(measure, earth, B_comps_Tx, B_comps_RxX, B_comps_RxY, B_comps_RxZ,...
                    Pxfactor, dh, modelDz(n), loop.turns(1), loopshape)*loop.turns(2)*293/earth.temp;
            end
            postCalcB1 = [];
            J = [];
    end
    
    set(tmpgui.panel_controls.edit_status,'String',...
        ['Calculation of layer ' num2str(n) ' out of ' num2str(model.nz) ' finished in ' num2str(toc) 's']);
    drawnow;
end
close(tmpgui.panel_controls.figureid);

% Thomas ->
if export_Bfields
    Bfields.loop = loop;
    Bfields.model = model;
    Bfields.measure = measure;
    Bfields.earth = earth;
    if measure.PX
        Bfname = ['Bfields_Px_',datestr(now,'yyyymmdd_HHMMSS'),'.mat'];
    else
        Bfname = ['Bfields_',datestr(now,'yyyymmdd_HHMMSS'),'.mat'];
    end
    save(Bfname,'Bfields');
end
% <- Thomas
