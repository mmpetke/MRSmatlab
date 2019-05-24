function [odata] = mrs_readgmr_binary(pname,fname,N_rec)
% function [data] = mrs_readgmr_binary(pname,fname,N_rec)
% 
% Read binary data from single GMR binary file (*.lvm binary file)
%
% Input options:
% 	pname            - full path to binary file 
% 	fname            - name of binary data file
%   N_rec            - # recordings in data file (get from header)
% Output: 
%  data.
%
% Vista Clara, 9 Apr 2012
%   JW  9 Apr 2012
% =========================================================================

% Open for reading and set to big-endian binary format
fid   = fopen([pname fname],'r','ieee-be');  
 
% read 8-bit dimension data at start of file
temp1  = fread(fid,4);
temp2  = fread(fid,4);
siz    = [2^32 2^16 2^8 1]'; % calculate dimensions based on 4 bits
dim1   = sum(siz.*temp1);
dim2   = sum(siz.*temp2);
N_chan = dim1;
N_samp = dim2;
 
data = zeros(N_samp*N_rec,N_chan+1);
fs   = 50000;   % 1/50000;
 
% build clock vector with known 200us phase shift from current/voltage monitor
% t = (0:1/fs:1/fs*(N_samp-1))-.0002;
t = (0:1/fs:1/fs*(N_samp-1));   % time shift is moved to signal timing phase in data.Q(iQ).rec(irec).info.phases.phi_timing(1)
 
for i_rec = 1:N_rec
    
    rowidx_start = (i_rec-1)*N_samp+1;
    if i_rec > 1  % for subsequent stacks read past 8-bit dimension identifier
        temp1 = fread(fid,4);
        temp2 = fread(fid,4);
    end
 
    i_chan = 1; % write clock channel
    data(rowidx_start:rowidx_start+N_samp-1,i_chan) = t;    % time vector starts at 0 for all rec!
%     data(rowidx_start:rowidx_start+N_samp-1,i_chan) = t + (i_rec-1)*5;  % shift for display
 
    for i_chan=2:N_chan+1  % put data channels after clock channel
        data(rowidx_start:rowidx_start+N_samp-1,i_chan) = fread(fid,N_samp,'single',0,'ieee-be')';
    end
 
end

fclose(fid); % Close the file

% reassemble output to make it conform with textscan (output when reading gmr ascii files)
odata = cell(1,size(data,2));
for ic = 1:size(data,2)
    odata{ic} = data(:,ic);
end

