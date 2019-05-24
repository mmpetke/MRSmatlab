%import of MRS-MIDI raw data
function [data,info]=import_MIDIdata(filename,modus)
file=fopen(filename,'r');
a=1;
while a~=0
    line=fgets(file);
     if (length(line)>=8)&&(strcmp(line(1:15),'[Data Rate /Hz]'))
       info.sample_freq=sscanf(line(16:end),'%f');
     end
     if (length(line)>=8)&&(strcmp(line(1:15),'[FID+REF/3 FID]'))
       info.mode=sscanf(line(16:end),'%f');
    end
     if (length(line)>=8)&&(strcmp(line(1:15),'[Dead time /ms]'))
       info.dead_time=sscanf(line(16:end),'%f')/1000;
    end
     if (length(line)>=8)&&(strcmp(line(1:8),'[q /Ams]'))
       info.pulse_moment=sscanf(line(9:end),'%f')/1000;
     end
     if (length(line)>=8)&&(strcmp(line(1:12),'[q Phase /°]'))
       info.pulse_phase=sscanf(line(13:end),'%f')/180*pi;
     end
    if (length(line)>=8)&&(strcmp(line(1:7),'[Gains]'))
       info.gains=sscanf(line(8:end),'%f%f%f');
    end
    if (length(line)>=8)&&(strcmp(line(1:7),'[Turns]'))
       info.turns=sscanf(line(8:end),'%f%f%f');
    end
    if (length(line)>=8)&&(strcmp(line(1:12),'[A/Turn /m2]'))
       info.loop_area=sscanf(line(13:end),'%f%f%f');
    end
     if (length(line)>=26)&&(strcmp(line(1:26),'[Excitation frequency /Hz]'))
       info.f_larmor=sscanf(line(27:end),'%f');
     end
     if (length(line)>=4)&&(strcmp(line(1:4),'[P1]'))
       info.duty_cycles=sscanf(line(5:end),'%f');
     end
    if (length(line)>=4)&&(strcmp(line(1:11),'[Delay /ms]'))
       info.delay=sscanf(line(12:end),'%f')/1000;
    end
    if (length(line)>=4)&&(strcmp(line(1:4),'[P2]'))
       info.duty_cycles2=sscanf(line(5:end),'%f');
     end
    if strcmp(line,['[Begin Data] ',char(13,10)'])
        a=0;
    elseif line==-1
        disp('wrong file!');
        a=0;
    end
end
%disp(fgets(file));
if modus==1%MRS data with reference channels
    [A]=fscanf(file,'%f',[5 inf]);
    fclose(file);
    info.pulse_length = info.duty_cycles/info.f_larmor;
    info.pulse_length2 = info.duty_cycles2/info.f_larmor;
elseif modus==2%noise data with reference channels
    [A]=fscanf(file,'%f',[4 inf]);
    fclose(file);
end

A=A';
[dummy,index_t]=max(A(:,1)>=info.dead_time);

data.t = A(index_t:end,1)-A(index_t,1);

if modus == 1
    info.dead_time = info.dead_time-info.pulse_length;
    [dummy,index_end] = max(data.t>=info.pulse_length);
    data.pulse = A(index_t:index_t+index_end,5);
end

data.ch1 = A(index_t:end,2)*info.gains(1);
data.ch2 = A(index_t:end,3)*info.gains(2);
data.ch3 = A(index_t:end,4)*info.gains(3);


