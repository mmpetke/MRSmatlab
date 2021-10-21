function midiout = mrs_readmidi(midifile,skipdata)
% function midiout = mrs_readmidi(midifile,skipdata)
%
% Read in Radic MIDI data
% 
% Input: 
%   ('dir\f.dat') - read file 'f.dat' in directory 'dir'
%   skipdata      - optional flag: if 1 - only read header (fitparameter)
% 
% Output: 
%   midiout       - array with all file information
%
%      Output format:
%      radicfiles.
%          .info          % Header Info
%          .fit.          % fit parameters
%              .q         % q value
%              .V0(:,ch)  % initial amplitude, channel ch
%              .T2s(:,ch) % T2*, channel ch
%              .rms(:,ch) % rms of V0, channel ch
%          .t             % data: time (DEAD TIME IS SUBTRACTED! CAREFUL
%                           WITH FID+ DATA -> HERE THE RADIC-DEAD TIME IS 
%                           ALREADY SUBTRACTED
%          .V0(:,ch)      % data: amplitude [V]
%          .I             % data: current amplitude [A] (from start of
%                            pulse to end of radic dead time)
%
% Jan Walbrecker, 15aug2007
% ed. 26jan2011 JW
% =========================================================================

if nargin < 2
    skipdata = 0;
end

fid   = fopen(midifile, 'r');
% common fileheader
head  = textscan(fid, '%*[^]] %*1c %[^\n]', 5);
x.info.instrument = head{1}(1);
x.info.version    = head{1}(2);
x.info.filename   = midifile;
x.info.comment    = head{1}(3);
x.info.date       = head{1}(4);
x.info.time       = head{1}(5);            
            
% switch MIDI software revisions
switch x.info.version{1}(1:end-1)
     case 'Software rev. 050318'
        % read header section
        head2  = textscan(fid, '%*[^]] %*1c %[^\n]', 17);
        head = [head{1}; head2{1}];
        x.info.pause      = str2double(char(head(6)));    % [s] 
        x.info.samplfreq  = str2double(char(head(7)));    % sample frequency [Hz]
        x.info.stacks     = str2double(char(head(8)));    
        x.info.mode       = str2double(char(head(9)));
        rectype           = head(10);
            if strcmp(rectype,'0')
                x.info.rectype = {'FID+REF'};
            elseif strcmp(rectype,'1')
                x.info.rectype = {'3 FID'};
            end
        x.info.tdead      = str2double(char(head(11)))/1000;    % [s]
        x.info.q          = str2double(char(head(12)))/1000;    % [As]
        x.info.phase      = str2num(cell2mat(head(13)))*pi/180; %#ok<ST2NM> % [rad]
        x.info.gains      = str2num(cell2mat(head(14))); %#ok<ST2NM>
        x.info.turns      = str2num(cell2mat(head(15))); %#ok<ST2NM>
        x.info.area       = str2num(cell2mat(head(16))); %#ok<ST2NM>
        x.info.pxtime     = str2num(cell2mat(head(17))); %#ok<ST2NM>
        x.info.pxdelay     = str2double(char(head(18)))/1000;    % [s]what is that delay good for?
        x.info.f_ref      = str2double(cell2mat(head(19)));
        x.info.P1         = str2double(cell2mat(head(20)));
        x.info.delay     = str2double(char(head(21)))/1000;    % [s]
        x.info.P2         = str2double(cell2mat(head(22)));

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore T2* fit headerline                    

        T2sfitpar = textscan(fid, '%*[^:] %*1c %f %f %f %f', 7);       
        % read up to ], then read & ignore :, then read three f's
        % old fitparameters are not required. Repeated in q section.

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore empty line                        

        % read q parameter section, although all in this section is crap
        % in this software version
        fpos = ftell(fid);          % set file marker here
        nql = 1;                    % count # of lines in q section
        qsec{1} = fgetl(fid);       % read first line in q section
        while ~isempty(qsec{nql})   % read to empty line after q section
            nql = nql+1;
            qsec{nql} = fgetl(fid); %#ok<AGROW>
        end
        fseek(fid, fpos, 'bof');  % return to marker at q sect
        ql = 1:nql;
        line_begin = ql(strcmp(qsec,'[Begin Results]'));    % identify line
        line_end   = ql(strcmp(qsec,'[End Results]'));      % identify line
        
        qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f',...
            line_end-line_begin-1, 'headerlines', 3);
        x.fit.q       = qdata{1}/1000;             % [As]
        x.fit.delay   = qdata{2}/1000;             % [s]
        x.fit.f       = qdata{3};
        x.fit.V0  = [qdata{4} qdata{7} qdata{10} qdata{13} qdata{16} qdata{19} qdata{22}];    % [V] (gain is included)
        x.fit.T2s = [qdata{5} qdata{8} qdata{11} qdata{14} qdata{17} qdata{20} qdata{23}]; % [s]
        x.fit.rms = [qdata{6} qdata{9} qdata{12} qdata{15} qdata{18} qdata{21} qdata{24}];   % [V]
        
        fseek(fid, fpos, 'bof');        % return to marker at q sect
        for ql = 1:line_end
            fgetl(fid);                 % go to [End Results]
        end
        fgetl(fid);                     % ignore empty line
        
        if skipdata == 0
            % read data section
            T2sdata = textscan(fid, '%f %f %f %f %f %f %f %f %f',...
               'headerlines', 2, 'commentStyle', '[');
            itd      = find(abs(T2sdata{1} - x.info.tdead) == min(abs(T2sdata{1} - x.info.tdead)));    
            itd      = itd(1); %strange thing: in some noise data files zero time entries are added at end of time series
            x.t      = T2sdata{1}(itd:end) - T2sdata{1}(itd);   % cut dead time & pulse
            x.v(:,1) = T2sdata{2}(itd:end)/x.info.gains(1); % CH 1 [V]
            x.v(:,2) = T2sdata{3}(itd:end)/x.info.gains(2); % CH 2 [V]
            x.v(:,3) = T2sdata{4}(itd:end)/x.info.gains(3); % CH 3 [V]
            x.I      = T2sdata{5}(1:itd);
            x.v(:,4) = T2sdata{6}(itd:end)/x.info.gains(5); % CH 5 [V]
            x.v(:,5) = T2sdata{7}(itd:end)/x.info.gains(6); % CH 6 [V]
            x.v(:,6) = T2sdata{8}(itd:end)/x.info.gains(7); % CH 7 [V]
            x.v(:,7) = T2sdata{9}(itd:end)/x.info.gains(8); % CH 8 [V]
        end
     case 'Software rev. 310317'
        % read header section
        head2  = textscan(fid, '%*[^]] %*1c %[^\n]', 17);
        head = [head{1}; head2{1}];
        x.info.pause      = str2double(char(head(6)));    % [s] 
        x.info.samplfreq  = str2double(char(head(7)));    % sample frequency [Hz]
        x.info.stacks     = str2double(char(head(8)));    
        x.info.mode       = str2double(char(head(9)));
        rectype           = head(10);
            if strcmp(rectype,'0')
                x.info.rectype = {'FID+REF'};
            elseif strcmp(rectype,'1')
                x.info.rectype = {'3 FID'};
            end
        x.info.tdead      = str2double(char(head(11)))/1000;    % [s]
        x.info.q          = str2double(char(head(12)))/1000;    % [As]
        x.info.phase      = str2num(cell2mat(head(13)))*pi/180; %#ok<ST2NM> % [rad]
        x.info.gains      = str2num(cell2mat(head(14))); %#ok<ST2NM>
        x.info.turns      = str2num(cell2mat(head(15))); %#ok<ST2NM>
        x.info.area       = str2num(cell2mat(head(16))); %#ok<ST2NM>
        x.info.pxtime     = str2num(cell2mat(head(17))); %#ok<ST2NM>
        x.info.pxdelay     = str2double(char(head(18)))/1000;    % [s]what is that delay good for?
        x.info.f_ref      = str2double(cell2mat(head(19)));
        x.info.P1         = str2double(cell2mat(head(20)));
        x.info.delay     = str2double(char(head(21)))/1000;    % [s]
        x.info.P2         = str2double(cell2mat(head(22)));

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore T2* fit headerline                    

        T2sfitpar = textscan(fid, '%*[^:] %*1c %f %f %f %f', 7);       
        % read up to ], then read & ignore :, then read three f's
        % old fitparameters are not required. Repeated in q section.

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore empty line                        

        % read q parameter section, although all in this section is crap
        % in this software version
        fpos = ftell(fid);          % set file marker here
        nql = 1;                    % count # of lines in q section
        qsec{1} = fgetl(fid);       % read first line in q section
        while ~isempty(qsec{nql})   % read to empty line after q section
            nql = nql+1;
            qsec{nql} = fgetl(fid); %#ok<AGROW>
        end
        fseek(fid, fpos, 'bof');  % return to marker at q sect
        ql = 1:nql;
        line_begin = ql(strcmp(qsec,'[Begin Results]'));    % identify line
        line_end   = ql(strcmp(qsec,'[End Results]'));      % identify line
        
        qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f',...
            line_end-line_begin-1, 'headerlines', 3);
        x.fit.q       = qdata{1}/1000;             % [As]
        x.fit.delay   = qdata{2}/1000;             % [s]
        x.fit.f       = qdata{3};
        x.fit.V0  = [qdata{4} qdata{7} qdata{10} qdata{13} qdata{16} qdata{19} qdata{22}];    % [V] (gain is included)
        x.fit.T2s = [qdata{5} qdata{8} qdata{11} qdata{14} qdata{17} qdata{20} qdata{23}]; % [s]
        x.fit.rms = [qdata{6} qdata{9} qdata{12} qdata{15} qdata{18} qdata{21} qdata{24}];   % [V]
        
        fseek(fid, fpos, 'bof');        % return to marker at q sect
        for ql = 1:line_end
            fgetl(fid);                 % go to [End Results]
        end
        fgetl(fid);                     % ignore empty line
        
        if skipdata == 0
            % read data section
            T2sdata = textscan(fid, '%f %f %f %f %f %f %f %f %f',...
               'headerlines', 2, 'commentStyle', '[');
            itd      = find(abs(T2sdata{1} - x.info.tdead) == min(abs(T2sdata{1} - x.info.tdead)));    
            itd      = itd(1); %strange thing: in some noise data files zero time entries are added at end of time series
            x.t      = T2sdata{1}(itd:end) - T2sdata{1}(itd);   % cut dead time & pulse
            x.v(:,1) = T2sdata{2}(itd:end)/x.info.gains(1); % CH 1 [V]
            x.v(:,2) = T2sdata{3}(itd:end)/x.info.gains(2); % CH 2 [V]
            x.v(:,3) = T2sdata{4}(itd:end)/x.info.gains(3); % CH 3 [V]
            x.I      = T2sdata{5}(1:itd);
            x.v(:,4) = T2sdata{6}(itd:end)/x.info.gains(5); % CH 5 [V]
            x.v(:,5) = T2sdata{7}(itd:end)/x.info.gains(6); % CH 6 [V]
            x.v(:,6) = T2sdata{8}(itd:end)/x.info.gains(7); % CH 7 [V]
            x.v(:,7) = T2sdata{9}(itd:end)/x.info.gains(8); % CH 8 [V]
        end
        
    case 'Software rev. 141011'
        
        % read header section
        head2  = textscan(fid, '%*[^]] %*1c %[^\n]', 16);
        head = [head{1}; head2{1}];
        x.info.pause      = str2double(char(head(6)));    % [s] 
        x.info.samplfreq  = str2double(char(head(7)));    % sample frequency [Hz]
        x.info.stacks     = str2double(char(head(8)));    
        x.info.mode       = str2double(char(head(9)));
        rectype           = head(10);
            if strcmp(rectype,'0')
                x.info.rectype = {'FID+REF'};
            elseif strcmp(rectype,'1')
                x.info.rectype = {'3 FID'};
            end
        x.info.references = head(11);
        x.info.tdead      = str2double(char(head(12)))/1000;    % [s]
        x.info.q          = str2double(char(head(13)))/1000;    % [As]
        x.info.phase      = str2num(cell2mat(head(14)))*pi/180; %#ok<ST2NM> % [rad]
        x.info.gains      = str2num(cell2mat(head(15))); %#ok<ST2NM>
        x.info.turns      = str2num(cell2mat(head(16))); %#ok<ST2NM>
        x.info.area       = str2num(cell2mat(head(17))); %#ok<ST2NM>
        x.info.f_ref      = str2double(cell2mat(head(18)));
        x.info.P1         = str2double(cell2mat(head(19)));
        x.info.delay      = str2double(char(head(20)))/1000;    % [s]
        x.info.P2         = str2double(cell2mat(head(21)));

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore T2* fit headerline                    

        T2sfitpar = textscan(fid, '%*[^:] %*1c %f %f %f %f', 7);       
        % read up to ], then read & ignore :, then read three f's
        % old fitparameters are not required. Repeated in q section.

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore empty line                        

        % read q parameter section
        fpos = ftell(fid);          % set file marker here
        nql = 1;                    % count # of lines in q section
        qsec{1} = fgetl(fid);       % read first line in q section
        while ~isempty(qsec{nql})   % read to empty line after q section
            nql = nql+1;
            qsec{nql} = fgetl(fid); %#ok<AGROW>
        end
        fseek(fid, fpos, 'bof');  % return to marker at q sect
        ql = 1:nql;
        line_begin = ql(strcmp(qsec,'[Begin Results]'));    % identify line
        line_end   = ql(strcmp(qsec,'[End Results]'));      % identify line
                      
        qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f',...
            line_end-line_begin-1, 'headerlines', 3);
        x.fit.q       = qdata{1}/1000;             % [As]
        x.fit.delay   = qdata{2}/1000;             % [s]
        x.fit.f       = qdata{3};
        x.fit.V0  = [qdata{4} qdata{7} qdata{10} qdata{13} qdata{16} qdata{19} qdata{22}];    % [V] (gain is included)
        x.fit.T2s = [qdata{5} qdata{8} qdata{11} qdata{14} qdata{17} qdata{20} qdata{23}]; % [s]
        x.fit.rms = [qdata{6} qdata{9} qdata{12} qdata{15} qdata{18} qdata{21} qdata{24}];   % [V]
        
        fseek(fid, fpos, 'bof');        % return to marker at q sect
        for ql = 1:line_end
            fgetl(fid);                 % go to [End Results]
        end
        fgetl(fid);                     % ignore empty line
        
        if skipdata == 0
            % read data section
            T2sdata = textscan(fid, '%f %f %f %f %f %f %f %f %f',...
               'headerlines', 2, 'commentStyle', '[');
            itd      = find(abs(T2sdata{1} - x.info.tdead) == min(abs(T2sdata{1} - x.info.tdead)));    
            itd      = itd(1); %strange thing: in some noise data files zero times entries are added at end of time series
            x.t      = T2sdata{1}(itd:end) - T2sdata{1}(itd);   % cut dead time & pulse
            x.v(:,1) = T2sdata{2}(itd:end)/x.info.gains(1); % CH 1 [V]
            x.v(:,2) = T2sdata{3}(itd:end)/x.info.gains(2); % CH 2 [V]
            x.v(:,3) = T2sdata{4}(itd:end)/x.info.gains(3); % CH 3 [V]
            x.I      = T2sdata{5}(1:itd);
            x.v(:,4) = T2sdata{6}(itd:end)/x.info.gains(5); % CH 5 [V]
            x.v(:,5) = T2sdata{7}(itd:end)/x.info.gains(6); % CH 6 [V]
            x.v(:,6) = T2sdata{8}(itd:end)/x.info.gains(7); % CH 7 [V]
            x.v(:,7) = T2sdata{9}(itd:end)/x.info.gains(8); % CH 8 [V]
        end
        
    case 'Software rev. 291208'
        
        % read header section
        head2  = textscan(fid, '%*[^]] %*1c %[^\n]', 16);
        head = [head{1}; head2{1}];
        x.info.pause      = str2double(char(head(6)));    % [s] 
        x.info.samplfreq  = str2double(char(head(7)));    % sample frequency [Hz]
        x.info.stacks     = str2double(char(head(8)));    
        x.info.mode       = str2double(char(head(9)));
        rectype           = head(10);
            if strcmp(rectype,'0')
                x.info.rectype = {'FID+REF'};
            elseif strcmp(rectype,'1')
                x.info.rectype = {'3 FID'};
            end
        x.info.references = head(11);
        x.info.tdead      = str2double(char(head(12)))/1000;    % [s]
        x.info.q          = str2double(char(head(13)))/1000;    % [As]
        x.info.phase      = str2num(cell2mat(head(14)))*pi/180; %#ok<ST2NM> % [rad]
        x.info.gains      = str2num(cell2mat(head(15))); %#ok<ST2NM>
        x.info.turns      = str2num(cell2mat(head(16))); %#ok<ST2NM>
        x.info.area       = str2num(cell2mat(head(17))); %#ok<ST2NM>
        x.info.f_ref      = str2double(cell2mat(head(18)));
        x.info.P1         = str2double(cell2mat(head(19)));
        x.info.delay      = str2double(char(head(20)))/1000;    % [s]
        x.info.P2         = str2double(cell2mat(head(21)));

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore T2* fit headerline                    

        T2sfitpar = textscan(fid, '%*[^:] %*1c %f %f %f', 3);       
        % read up to ], then read & ignore :, then read three f's
        % old fitparameters are not required. Repeated in q section.

        fgetl(fid);     % ignore to end of current line
        fgetl(fid);     % ignore empty line
        fgetl(fid);     % ignore empty line                        

        % read q parameter section
        fpos = ftell(fid);          % set file marker here
        nql = 1;                    % count # of lines in q section
        qsec{1} = fgetl(fid);       % read first line in q section
        while ~isempty(qsec{nql})   % read to empty line after q section
            nql = nql+1;
            qsec{nql} = fgetl(fid); %#ok<AGROW>
        end
        fseek(fid, fpos, 'bof');  % return to marker at q sect
        ql = 1:nql;
        line_begin = ql(strcmp(qsec,'[Begin Results]'));    % identify line
        line_end   = ql(strcmp(qsec,'[End Results]'));      % identify line
        
        qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f',...
            line_end-line_begin-1, 'headerlines', 3);
        x.fit.q       = qdata{1}/1000;             % [As]
        x.fit.delay   = qdata{2}/1000;             % [s]
        x.fit.V0  = [qdata{3}/x.info.turns(1) ...
                     qdata{6}/x.info.turns(2)...
                     qdata{9}/x.info.turns(3)];    % [V] (gain is included)
        x.fit.T2s = [qdata{4} qdata{7} qdata{10}]; % [s]
        x.fit.rms = [qdata{5}/x.info.turns(1) ...
                     qdata{8}/x.info.turns(2) ...
                     qdata{11}/x.info.turns(3)];   % [V]
        
        fseek(fid, fpos, 'bof');        % return to marker at q sect
        for ql = 1:line_end
            fgetl(fid);                 % go to [End Results]
        end
        fgetl(fid);                     % ignore empty line
        
        if skipdata == 0
            % read data section
            T2sdata = textscan(fid, '%f %f %f %f %f',...
               'headerlines', 2, 'commentStyle', '[');
            itd      = find(abs(T2sdata{1} - x.info.tdead) == min(abs(T2sdata{1} - x.info.tdead)));           
            x.t      = T2sdata{1}(itd:end) - T2sdata{1}(itd(1));   % cut dead time & pulse
            x.v(:,1) = T2sdata{2}(itd:end)/x.info.gains(1); % CH 1 [V]
            x.v(:,2) = T2sdata{3}(itd:end)/x.info.gains(2); % CH 2 [V]
            x.v(:,3) = T2sdata{4}(itd:end)/x.info.gains(3); % CH 3 [V]
            x.I      = T2sdata{5}(1:itd);
        end
        
    case 'Software rev. 241008'
        head2  = textscan(fid, '%*[^]] %*1c %[^\n]', 16);
        head = [head{1}; head2{1}];
        x.info.pause      = str2double(char(head(6)));    % [s] 
        x.info.samplfreq  = str2double(char(head(7)));    % sample frequency [Hz]
        x.info.stacks     = str2double(char(head(8)));    
        x.info.mode       = str2double(char(head(9)));
        rectype           = head(10);
            if strcmp(rectype,'0')
                x.info.rectype = {'FID+REF'};
            elseif strcmp(rectype,'1')
                x.info.rectype = {'3 FID'};
            end
        x.info.references = head(11);
        x.info.tdead      = str2double(char(head(12)))/1000;  % [s]
        x.info.q          = str2double(char(head(13)))/1000;  % [As]
        x.info.phase      = str2num(cell2mat(head(14)))*pi/180; %#ok<ST2NM> % [rad]
        x.info.gains      = str2num(cell2mat(head(15))); %#ok<ST2NM>
        x.info.turns      = str2num(cell2mat(head(16))); %#ok<ST2NM>
        x.info.area       = str2num(cell2mat(head(17))); %#ok<ST2NM>
        x.info.f_ref      = str2double(cell2mat(head(18)));
        x.info.P1         = str2double(cell2mat(head(19)));
        x.info.delay      = str2double(char(head(20)))/1000;  % [s]
        x.info.P2         = str2double(cell2mat(head(21)));

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read empty line
        fgetl(fid);     % read T2* fit headerline                    

        T2sfitpar = textscan(fid, '%*[^:] %*1c %f %f %f', 3);       % read up to ], then read & ignore ], then read three f's

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read empty line
        fgetl(fid);     % read T1 fit headerline

        T1fitpar  = textscan(fid, '%f %f %f', 1);

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read empty line

        
        % determine number of lines in q parameter section;
        % nql will be the actual number of q lines + two header
        % lines + footer lin. Thus nql-3 needs to be read in.
        fpos = ftell(fid);  % set file marker here
        nql = 0;        % count # of lines in q section
        while ~isempty(fgetl(fid))
            nql = nql+1;
        end
        fseek(fid, fpos, 'bof');  % return to marker at q sect

        qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f',...
            nql-3, 'headerlines', 2, 'commentStyle', '[');
        x.fit.q       = qdata{1}/1000;  % [As]
        x.fit.V0  = [qdata{3}/x.info.turns(1) ...
                     qdata{6}/x.info.turns(2)...
                     qdata{9}/x.info.turns(3)];    % [V] (gain is included)
        x.fit.T2s = [qdata{4} qdata{7} qdata{10}]; % [s]
        x.fit.rms = [qdata{5}/x.info.turns(1) ...
                     qdata{8}/x.info.turns(2) ...
                     qdata{11}/x.info.turns(3)]; % [V]        

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read footer
        fgetl(fid);     % read empty line

        if skipdata == 0
            T2sdata = textscan(fid, '%f %f %f %f %f',...
               'headerlines', 2, 'commentStyle', '[');
            itd = find(abs(T2sdata{1} - x.info.tdead) == min(abs(T2sdata{1} - x.info.tdead)));
            x.t      = T2sdata{1}(itd:end) - T2sdata{1}(itd);   % cut dead time & pulse
            x.v(:,1) = T2sdata{2}(itd:end)/x.info.gains(1)/x.info.turns(1); % CH 1 [V]
            x.v(:,2) = T2sdata{3}(itd:end)/x.info.gains(2)/x.info.turns(2); % CH 2 [V]
            x.v(:,3) = T2sdata{4}(itd:end)/x.info.gains(3)/x.info.turns(3); % CH 3 [V]
            x.I      = T2sdata{5}(1:itd);
        end
        
%         % UNTESTED
%         % read q parameter section
%         fpos = ftell(fid);          % set file marker here
%         nql = 1;                    % count # of lines in q section
%         qsec{1} = fgetl(fid);       % read first line in q section
%         while ~isempty(qsec{nql})   % read to empty line after q section
%             nql = nql+1;
%             qsec{nql} = fgetl(fid); %#ok<AGROW>
%         end
%         fseek(fid, fpos, 'bof');  % return to marker at q sect
%         ql = 1:nql;
%         line_begin = ql(strcmp(qsec,'[Begin Results]'));    % identify line
%         line_end   = ql(strcmp(qsec,'[End Results]'));      % identify line
%         
%         qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f',...
%             line_end-line_begin-1, 'headerlines', 3);
%         x.fit.q       = qdata{1}/1000;             % [As]
%         x.fit.delay   = qdata{2}/1000;             % [s]
%         x.fit.V0  = [qdata{3}/x.info.turns(1) ...
%                      qdata{6}/x.info.turns(2)...
%                      qdata{9}/x.info.turns(3)];    % [V] (gain is included)
%         x.fit.T2s = [qdata{4} qdata{7} qdata{10}]; % [s]
%         x.fit.rms = [qdata{5}/x.info.turns(1) ...
%                      qdata{8}/x.info.turns(2) ...
%                      qdata{11}/x.info.turns(3)]; % [V]
%         
%         fseek(fid, fpos, 'bof');        % return to marker at q sect
%         for ql = 1:line_end
%             fgetl(fid);                 % go to [End Results]
%         end
%         fgetl(fid);                     % ignore empty line
%         
%         if skipdata == 0
%             % read data section
%             T2sdata = textscan(fid, '%f %f %f %f %f',...
%                'headerlines', 2, 'commentStyle', '[');
%             x.t      = T2sdata{1};  % time [s]
%             x.v(:,1) = T2sdata{2}/x.info.gains(1)/x.info.turns(1); % CH 1 [V]
%             x.v(:,2) = T2sdata{3}/x.info.gains(2)/x.info.turns(2); % CH 2 [V]
%             x.v(:,3) = T2sdata{4}/x.info.gains(3)/x.info.turns(3); % CH 3 [V]
%             x.I      = T2sdata{5};  % pulse current [A]
%         end        
        

    case {'Software rev. 050608','Software rev. 311007',  ...
            'Software rev. 281207', 'Software rev. 100907'}
        head2  = textscan(fid, '%*[^]] %*1c %[^\n]', 15);
        head = [head{1}; head2{1}];
        x.info.pause      = str2double(char(head(6)));    % [s] 
        x.info.samplfreq  = str2double(char(head(7)));    % sample frequency [Hz]
        x.info.stacks     = str2double(char(head(8)));    
        x.info.mode       = str2double(char(head(9)));
        rectype           = head(10);
            if strcmp(rectype,'0')
                x.info.rectype = {'FID+REF'};
            elseif strcmp(rectype,'1')
                x.info.rectype = {'3 FID'};
            end
        x.info.references = head(11);
        x.info.tdead      = str2double(char(head(12)))/1000;  % [s]
        x.info.q          = str2double(char(head(13)))/1000;  % [As]
        x.info.phase      = 0;                                % N/A!
        x.info.gains      = str2num(cell2mat(head(14))); %#ok<ST2NM>
        x.info.turns      = str2num(cell2mat(head(15))); %#ok<ST2NM>
        x.info.area       = str2num(cell2mat(head(16))); %#ok<ST2NM>
        x.info.f_ref      = str2double(cell2mat(head(17)));
        x.info.P1         = str2double(cell2mat(head(18)));
        x.info.delay      = str2double(char(head(19)))/1000;  % [s]
        x.info.P2         = str2double(cell2mat(head(20)));

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read empty line
        fgetl(fid);     % read T2* fit headerline                    

        T2sfitpar = textscan(fid, '%*[^:] %*1c %f %f %f', 3);       % read up to ], then read & ignore ], then read three f's

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read empty line
        fgetl(fid);     % read T1 fit headerline

        T1fitpar  = textscan(fid, '%f %f %f', 1);

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read empty line

        % read q parameter section
        fpos = ftell(fid);          % set file marker here
        nql = 1;                    % count # of lines in q section
        qsec{1} = fgetl(fid);       % read first line in q section
        while ~isempty(qsec{nql})   % read to empty line after q section
            nql = nql+1;
            qsec{nql} = fgetl(fid); %#ok<AGROW>
        end
        fseek(fid, fpos, 'bof');  % return to marker at q sect
        ql = 1:nql;
        line_begin = ql(strcmp(qsec,'[Begin Results]'));    % identify line
        line_end   = ql(strcmp(qsec,'[End Results]'));      % identify line
        
        qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f',...
            line_end-line_begin-1, 'headerlines', 2);
        x.fit.q       = qdata{1}/1000;             % [As]
        x.fit.delay   = nan;
        x.fit.V0  = [qdata{2}/x.info.turns(1) ...
                     qdata{5}/x.info.turns(2)...
                     qdata{8}/x.info.turns(3)];    % [V] (gain is included)
        x.fit.T2s = [qdata{3} qdata{6} qdata{9}];  % [s]
        x.fit.rms = [qdata{4}/x.info.turns(1) ...
                     qdata{7}/x.info.turns(2) ...
                     qdata{10}/x.info.turns(3)]; % [V]
        
        fseek(fid, fpos, 'bof');        % return to marker at q sect
        for ql = 1:line_end
            fgetl(fid);                 % go to [End Results]
        end
        fgetl(fid);                     % ignore empty line
        
        if skipdata == 0
            % read data section
            T2sdata = textscan(fid, '%f %f %f %f %f',...
               'headerlines', 2, 'commentStyle', '[');
            itd = find(abs(T2sdata{1} - x.info.tdead) == min(abs(T2sdata{1} - x.info.tdead)));
            x.t      = T2sdata{1}(itd:end) - T2sdata{1}(itd);   % cut dead time & pulse
            x.v(:,1) = T2sdata{2}(itd:end)/x.info.gains(1)/x.info.turns(1); % CH 1 [V]
            x.v(:,2) = T2sdata{3}(itd:end)/x.info.gains(2)/x.info.turns(2); % CH 2 [V]
            x.v(:,3) = T2sdata{4}(itd:end)/x.info.gains(3)/x.info.turns(3); % CH 3 [V]
            x.I      = T2sdata{5}(1:itd);
        end                
        
    case {'Software Rev. 120606', 'Software Rev. 150506'}
        head2  = textscan(fid, '%*[^]] %*1c %[^\n]', 13);
        head = [head{1}; head2{1}];
        x.info.pause      = str2double(char(head(6)));    % [s] 
        x.info.samplfreq  = str2double(char(head(7)));    % sample frequency [Hz]
        x.info.stacks     = str2double(char(head(8)));    
        x.info.mode       = str2double(char(head(9)));
        rectype           = head(10);
            if strcmp(rectype,'0')
                x.info.rectype = {'FID+REF'};
            elseif strcmp(rectype,'1')
                x.info.rectype = {'3 FID'};
            end
        x.info.references = head(11);
        x.info.tdead      = str2double(char(head(12)))/1000;  % [s]
        x.info.q          = str2double(char(head(13)))/1000;  % [As]                        
        x.info.gains      = str2num(cell2mat(head(14)));
        x.info.turns      = str2num(cell2mat(head(15)));
        x.info.area       = str2num(cell2mat(head(16)));
        x.info.f_ref      = str2double(cell2mat(head(17)));
        x.info.P1         = str2double(cell2mat(head(18)));

        fgetl(fid);     % read to end of current line                        
        T2sfitpar = textscan(fid, '%*[^]] %*1c %f %f %f %f %f %f %f %f %f', 1);       % read up to ], then read & ignore ], then read nine f's
        fgetl(fid);     % read to end of current line
        T1fitpar  = textscan(fid, '%*[^]] %*1c %f %f %f', 1);       % read up to ], then read & ignore ], then read nine f's                        
        fgetl(fid);     % read to end of current line

        % determine number of lines in q parameter section;
        % nql will be the actual number of q lines + two header
        % lines + footer lin. Thus nql-3 needs to be read in.
        fpos = ftell(fid);  % set file marker here
        nql = 0;        % count # of lines in q section
        while ~isempty(fgetl(fid))
            nql = nql+1;
        end
        fseek(fid, fpos, 'bof');  % return to marker at q sect

        qdata = textscan(fid, '%f %f %f %f %f %f %f %f %f %f',...
            nql-3, 'headerlines', 2, 'commentStyle', '[');
        x.fit.q       = qdata{1}/1000;  % [As]
        x.fit.U0_ch1  = qdata{2};       % [V] Vorsicht: noch durch Windungen teilen!
        x.fit.T2s_ch1 = qdata{3}/1000;  % [s]
        x.fit.rms_ch1 = qdata{4};       % [V]
        x.fit.U0_ch2  = qdata{5};       % [V]
        x.fit.T2s_ch2 = qdata{6}/1000;  % [s]
        x.fit.rms_ch2 = qdata{7};       % [V]
        x.fit.U0_ch3  = qdata{8};       % [V]
        x.fit.T2s_ch3 = qdata{9}/1000;  % [s]
        x.fit.rms_ch3 = qdata{10};      % [V]

        fgetl(fid);     % read to end of current line
        fgetl(fid);     % read footer
        fgetl(fid);     % read empty line

        if skipdata == 0
            T2sdata = textscan(fid, '%f %f %f %f %f',...
               'headerlines', 2, 'commentStyle', '[');
            x.t      = T2sdata{1};
            x.v(:,1) = T2sdata{2}/x.info.gains(1)/x.info.turns(1); % CH 1 [V]
            x.v(:,2) = T2sdata{3}/x.info.gains(2)/x.info.turns(2); % CH 2 [V]
            x.v(:,3) = T2sdata{4}/x.info.gains(3)/x.info.turns(3); % CH 3 [V]
            x.I      = T2sdata{5};
        end
        
    otherwise 
        error('Unknown software revision. Check ''Software Revision'' entry in file header line 2.')
end % switch software revision

fclose(fid);
midiout = x;
