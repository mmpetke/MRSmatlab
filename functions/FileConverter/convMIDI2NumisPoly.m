function convMIDI2NumisPoly(gui,fdata)

%% create directory for converted data
filedir       = [fdata.convpath 'converted']; 
mkdir(filedir);

%% import raw data and save as proton files
q1=[];q2=[];q1p=[];q2p=[];
for irec = 1:length(fdata.pulsemoments)
    mrs_setguistatus(gui,1,['Importing ' num2str(irec) ' out of ' num2str(length(fdata.pulsemoments)) ' pulse moments'])
    
    rec = irec;
    %  read in all files containing single stacks of one pulse moment:
    data  = openMIDIRawData(fdata, rec); 

    % write in poly structure --> what is done there
    % writePolyData(data,fdata,iq,irec,nq)
    % data.recordC1{iq}
    % fopen([filedir filesep 'Q' num2str(nq) '#' num2str(irec) '.Pro'], 'w');

% user specified; one file contains all stacks
% separate this one file into single stacks and write in Poly format
% data is structured as --> data.record{stacks}
            
            for n=1:length(data.q1)
                mrs_setguistatus(gui,1,['Converting ' num2str(n) ' out of ' num2str(length(data.q1)) ' stacks'])
                % irec is now pulse moment, n are stacks which are sorted
                sampleFrequency = writePolyData(data,fdata,n,n,irec);
                %sampleFrequency = writePolyData_no_decimating(data,fdata,n,n,irec);
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
% % BUILDING .inp FILE --> Not the same as NUMIS
inpfile  = fopen([fdata.convpath 'GMRdata.inp'], 'w'); 
fprintf(inpfile, '#CH = %d \n', fdata.header.connectedchannels);
fprintf(inpfile, ' CH\t task \t looptype \t loopsize \t nturns \n');
for irx=1:fdata.header.connectedchannels
    fprintf(inpfile, '%d\t %d\t %d\t %5.1f\t %d\n', ...
            irx, fdata.UserData(irx).looptask, fdata.UserData(irx).looptype, fdata.UserData(irx).loopsize, fdata.UserData(irx).nturns);
end
fprintf(inpfile, '#fs = %d \n', sampleFrequency);
fprintf(inpfile, '#q = %d \n', size(q1,2));
fprintf(inpfile, '#stacks = %d \n', size(q1,1));
fprintf(inpfile, 'q index\t  q1 [As] \t  q2 [As] \n');
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

mrs_setguistatus(gui,0);


