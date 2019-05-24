function fdata = mrsSigPro_ImportGMR(sounding_path,gui)

%% GET SOUNDING PATH ------------------------------------------------------
fdata.info.path   = sounding_path;
fdata.info.device = 'GMR';

%% READ HEADER FILE -------------------------------------------------------
[fdata.headerfilename,fdata.headerpath] = uigetfile({'*.*; *.*','pick header for GMR'},...
                'MultiSelect','off',...
                'Open GMR Header File',...
                [sounding_path]);

fdata.header          = openGMRheader(fullfile(fdata.headerpath,fdata.headerfilename)); 
fdata.header.filename = fdata.headerfilename;
fdata.header.path     = fdata.headerpath;
fdata.info.sequence   = fdata.header.sequenceID;

%% REQUEST MISSING SURVEY INFORMATION -------------------------------------
% check if information has been entered previously
chk = exist([sounding_path 'GMRdata.inp'],'file');
if chk ~= 2 % no info exist --> open request dialog
    para = Request_userinfo(fdata);
    irx = 0;
    for iCh=1:fdata.header.nrx
        if para{3,1+iCh}==1 % transmitter and receiver
            irx = irx + 1;
            fdata.info.rxinfo(irx).channel   = iCh;
            fdata.info.rxinfo(irx).task      = 1;
            fdata.info.rxinfo(irx).looptype  = para{4,1+iCh};
            fdata.info.rxinfo(irx).loopsize  = para{5,1+iCh};
            fdata.info.rxinfo(irx).loopturns = para{6,1+iCh};
            fdata.info.txinfo.channel   = iCh;
            fdata.info.txinfo.looptype  = para{4,1+iCh};
            fdata.info.txinfo.loopsize  = para{5,1+iCh};
            fdata.info.txinfo.loopturns = para{6,1+iCh};
            % kind of double information but necessary to use the same functions as for GMRconverter
            fdata.UserData(iCh).looptask = 1; 
        elseif para{2,1+iCh}==1 % %only receiver
            irx = irx + 1;
            fdata.info.rxinfo(irx).channel   = iCh;
            fdata.info.rxinfo(irx).task      = 1;
            fdata.info.rxinfo(irx).looptype  = para{4,1+iCh};
            fdata.info.rxinfo(irx).loopsize  = para{5,1+iCh};
            fdata.info.rxinfo(irx).loopturns = para{6,1+iCh};
            fdata.UserData(iCh).looptask = 2;
        elseif para{2,1+iCh}==2 % %only reference
            irx = irx + 1;
            fdata.info.rxinfo(irx).channel   = iCh;
            fdata.info.rxinfo(irx).task      = 2;
            fdata.info.rxinfo(irx).looptype  = para{4,1+iCh};
            fdata.info.rxinfo(irx).loopsize  = para{5,1+iCh};
            fdata.info.rxinfo(irx).loopturns = para{6,1+iCh};
            fdata.UserData(iCh).looptask = 3;
        else
            fdata.UserData(iCh).looptask = 0;
        end
    end 
    if fdata.info.sequence==8
        fdata.info.txinfo.Fmod.shape    = para{12,2};
        fdata.info.txinfo.Fmod.startdf  = para{12,3};    
        fdata.info.txinfo.Fmod.enddf    = para{12,4}; 
        fdata.info.txinfo.Fmod.A        = para{12,5};
        fdata.info.txinfo.Fmod.B        = para{12,6};          
    end
    
else % inp file exist --> use these info
    fidinp = fopen([sounding_path, 'GMRdata.inp'],'r');
    nchannels = fscanf(fidinp, '%*s %*s %d \n',1);
    itable = textscan(fidinp,'%*f\t %f\t %f\t %f\t %f \n',nchannels,'Headerlines',1);
    
    if fdata.info.sequence==8 % mod RD
        ptable = textscan(fidinp,'%f\t %f\t %f\t %f\t %f \n',nchannels,'Headerlines',4);
        fdata.info.txinfo.Fmod.shape    = ptable{1};
        fdata.info.txinfo.Fmod.startdf  = ptable{2};    
        fdata.info.txinfo.Fmod.enddf    = ptable{3}; 
        fdata.info.txinfo.Fmod.A        = ptable{4};
        fdata.info.txinfo.Fmod.B        = ptable{5};          
    end
    
    tmp = zeros(nchannels,4);
    for n=1:4
        tmp(1:nchannels,n)=cell2mat(itable(n));
    end
    
    irx = 0;
    for iCh=1:nchannels     % JW: This means that one irx is the transmitter, right? MMP:Yes
        if tmp(iCh,1)==1  % Tx/Rx
            irx = irx + 1;
            fdata.info.rxinfo(irx).channel   = iCh;
            fdata.info.rxinfo(irx).task      = 1;
            fdata.info.rxinfo(irx).looptype  = tmp(iCh,2);
            fdata.info.rxinfo(irx).loopsize  = tmp(iCh,3);
            fdata.info.rxinfo(irx).loopturns = tmp(iCh,4);
            fdata.info.txinfo.channel   = iCh;
            fdata.info.txinfo.looptype  = tmp(iCh,2);
            fdata.info.txinfo.loopsize  = tmp(iCh,3);
            fdata.info.txinfo.loopturns = tmp(iCh,4);
            % kind of double information but necessary to use the same functions as for GMRconverter
            fdata.UserData(iCh).looptask = 1;
        elseif tmp(iCh,1)==2 % Rx
            irx = irx + 1;
            fdata.info.rxinfo(irx).channel   = iCh;
            fdata.info.rxinfo(irx).task      = 1;
            fdata.info.rxinfo(irx).looptype  = tmp(iCh,2);
            fdata.info.rxinfo(irx).loopsize  = tmp(iCh,3);
            fdata.info.rxinfo(irx).loopturns = tmp(iCh,4);
            fdata.UserData(iCh).looptask = 2;
        elseif tmp(iCh,1)==3 % NC
            irx = irx + 1;
            fdata.info.rxinfo(irx).channel   = iCh;
            fdata.info.rxinfo(irx).task      = 2;
            fdata.info.rxinfo(irx).looptype  = tmp(iCh,2);
            fdata.info.rxinfo(irx).loopsize  = tmp(iCh,3);
            fdata.info.rxinfo(irx).loopturns = tmp(iCh,4);
            fdata.UserData(iCh).looptask = 3;
        else    % unconnected
            fdata.UserData(iCh).looptask = 0;
        end
    end
end


%% import raw data --------------------------------------------------------
q1=[];q2=[];q1p=[];q2p=[];
for irec = 1:length(fdata.header.fileID)
    mrs_setguistatus(gui,1,['Importing ' num2str(irec) ' out of ' num2str(length(fdata.header.fileID)) ' files'])
    
    rec = fdata.header.fileID(irec);
    % read in one file containing all pulse moments/stacks (depends on fdata.header.Qsampling)
    data  = openGMRRawData(fdata, rec); 
    
    switch fdata.header.Qsampling
        case 0 % standard GMR, one file contains all pulse moments
            % separate this one file into single pulse moments 
            % sometime GMR pulse moments are reverse ordered or anything else
            [dummy,index]  = sort(data.q1); 
            for n=1:length(data.q1)
                % fdata = GMRRawData2MRSmatlab(data,fdata,iq,irec,nq)
                fdata = GMRRawData2MRSmatlab(data,fdata,index(n),irec,n);
            end
            q1 = [q1; data.q1(index)];q1p = [q1p; data.q1phase(index)];
            q2 = [q2; data.q2(index)];q2p = [q2p; data.q2phase(index)];
        case 1 % user specified; one file contains all stacks
            % separate this one file into single stacks 
            % data is structured as --> data.record{stacks}
            disp('NOT YET DEBUGGED - HANDLE WITH CARE')        
            for n=1:length(data.q1)
                % irec is now pulse moment, n are stacks which are sorted
                % fdata = GMRRawData2MRSmatlab(data,fdata,iq,irec,nq)
                fdata = GMRRawData2MRSmatlab(data,fdata,n,n,irec);
            end
            if  size(q1,1) < length(data.q1') % check for changed number of stacks
                tmp                              = zeros(length(data.q1'),size(q1,2));
                tmp(1:size(q1,1),1:size(q1,2))   = q1; 
                q1                               = tmp;
                tmp(1:size(q1p,1),1:size(q1p,2)) = q1p;
                q1p                              = tmp;
                tmp(1:size(q2,1),1:size(q2,2))   = q2;
                q2                               = tmp;
                tmp(1:size(q2p,1),1:size(q2p,2)) = q2p;
                q2p                              = tmp;
            else
                tmp                            = zeros(1,size(q1,1));
                tmp(1,1:length(data.q1'))      = data.q1;
                data.q1                        = tmp;
                tmp(1,1:length(data.q1phase')) = data.q1phase;
                data.q1phase                   = tmp;
                tmp(1,1:length(data.q2'))      = data.q2;
                data.q2                        = tmp;
                tmp(1,1:length(data.q2phase')) = data.q2phase;
                data.q2phase                   = tmp;
            end
            q1 = [q1 data.q1'];q1p = [q1p data.q1phase'];
            q2 = [q2 data.q2'];q2p = [q2p data.q2phase'];
            
            index = [1:1:size(q1,2)]; % not necessary for case 2 but for case 1 and later for inp file
    end
end
mrs_setguistatus(gui,0)

fdata.header.fS = fdata.Q(1).rec(1).info.fS;

%% BUILDING .inp FILE --> Not the same as NUMIS
if chk ~= 2 % inp file already exists no rewrite
    inpfile  = fopen([sounding_path 'GMRdata.inp'], 'w'); 
    fprintf(inpfile, '#CH = %d \n', fdata.header.nrx);
    fprintf(inpfile, ' CH\t task \t looptype \t loopsize \t nturns \n');
    for irx=1:fdata.header.nrx
        fprintf(inpfile, '%d\t %d\t %d\t %5.1f\t %d\n', ...
                irx, fdata.UserData(irx).looptask, para{4,1+irx}, para{5,1+irx}, para{6,1+irx});
    end
    fprintf(inpfile, '#fs = %d \n', fdata.header.fS);
    fprintf(inpfile, '#q = %d \n', size(q1,2));
    fprintf(inpfile, '#stacks = %d \n', size(q1,1));

    if fdata.info.sequence==8 % save Frq mod for AHP
        fprintf(inpfile,' F-mod shape\t F-mod startdf\t F-mod enddf\t F-mod A\t F-mod B\n');        
        fprintf(inpfile, '%d\t %5.1f\t %5.1f\t %5.1f\t %5.1f\n', ...
                        fdata.info.txinfo.Fmod.shape, fdata.info.txinfo.Fmod.startdf, fdata.info.txinfo.Fmod.enddf, fdata.info.txinfo.Fmod.A, fdata.info.txinfo.Fmod.B);
    end
    
    if fdata.info.sequence==8
        fprintf(inpfile, 'Imax index\t  I1 [A] \t  I2 [A] \n');
    else
        fprintf(inpfile, 'q index\t  q1 [As] \t  q2 [As] \n');
    end
    for iq = 1:size(q1,2)
        fprintf(inpfile, '%7.0f\t%9.3f\t%9.3f \n', ... 
            iq,mean(q1(:,iq)),mean(q2(:,iq))); 
    end

    % pulse and phase in detail 
    fprintf(inpfile, 'q1 \n');
    for n=1:size(q1,1)
        for m=1:size(q1,2)
            fprintf(inpfile, '%9.3f\t', q1(n,m)); 
        end
        fprintf(inpfile, '\n'); 
    end

    fprintf(inpfile, 'q1phase \n');
    for n=1:size(q1,1)
        for m=1:size(q1,2)
            fprintf(inpfile, '%9.3f\t', q1p(n,m)); 
        end
        fprintf(inpfile, '\n'); 
    end

    fprintf(inpfile, 'q2 \n');
    for n=1:size(q2,1)
        for m=1:size(q2,2)
            fprintf(inpfile, '%9.3f\t', q2(n,m)); 
        end
        fprintf(inpfile, '\n'); 
    end

    fprintf(inpfile, 'q2phase \n');
    for n=1:size(q2,1)
        for m=1:size(q2,2)
            fprintf(inpfile, '%9.3f\t', q2p(n,m)); 
        end
        fprintf(inpfile, '\n'); 
    end

    fclose(inpfile);
end




