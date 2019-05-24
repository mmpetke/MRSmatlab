function uival = mrs_read_gmruserinfo(infofile)
% function mrs_read_gmruserinfo(infofile)
%
% Read information from GMR info file created by MRSmatlab.
%
% Output:
%   uival{1}  = headerfile
%   uival{2}  = sample_frequency
%   uival{3}  = prepulse_delay
%   uival{4}  = dead_time
%   uival{5}  = currentgain
%   uival{6}  = voltagegain
%   uival{7}  = looptype
%   uival{8}  = loopsize
%   uival{9}  = loopturns
%   uival{10} = receivertask
%   uival{11} = transmitterchannel
%
% 10jun2011
% mod. 30mar2012 JW
% =========================================================================
    
% open .gmr-file
fid = fopen(infofile,'r');
hdl = 3;    % headerlines

% count # lines
nlines  = 0;
while fgets(fid)~= -1
    nlines = nlines+1;
end
frewind(fid);
npar = nlines - hdl;

% read file-content linewise
ct = cell(nlines,1);
for n = 1:nlines
    ct{n} = fgetl(fid);
end

% assign uival
uival = cell(1,npar);
for ival = 1:npar  % read all parameters
    iequal = find(ct{ival+hdl} == '=', 1, 'first');   % ival+hdl because of hdl headerlines
    if ival == 1 % first entry is a string (name of headerfile)
        uival{ival} = (ct{ival+hdl}(iequal+1:end));
    else         % other entries are numbers
        uival{ival} = str2num(ct{ival+hdl}(iequal+1:end)); %#ok<ST2NM>
    end
end

fclose(fid);


