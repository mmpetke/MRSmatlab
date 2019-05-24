function X = mrs_getX(id,info,iq)
% function X = mrs_getX(id,info,iq)
% 
% Function to fill the dropdown menus (q&rec) in MRSmatlab.
% Determines the available pulsemoments (id='Q') / recordings (id='REC') 
% from input-structure info (either fdata.info or proclog). If input 
% id='REC' then iq can be used to find out the recordings for the specific 
% Index iq.
% 
% Input: 
%   id     - 'Q' or 'REC'
%   info   - proclog or fdata.info from MRSmatlab (requires info.path and
%            info.device)
%   iq     - optional: Q index
% 
% Output: 
%   X      - vector containing the available Q's or REC's
% 
% 26jan2011
% ed. 10jun2011 JW
% =========================================================================

if nargin < 3
    iq = -1;
end

switch id
    case 'Q'    % determine min & max Q (index) from filenames
        switch info.device
            
            case 'MRSModelling'
                Q = zeros(1,length(info.Q));
                for n=1:length(info.Q)
                    Q(n) = info.Q(n).q;
                end
                
            case {'NUMISpoly', 'NUMISplus'}
                allQ = dir([info.path,'*.0*']);
                Q = zeros(1,length(allQ));
                for iallQ = 1:length(allQ)
                    idot = find(allQ(iallQ).name == '.');
                    if length(idot) > 1; error('bad filename - contains two dots (.)'); end
                    Q(iallQ) = str2double(allQ(iallQ).name(idot+2:end)); % +2 to delete the ".0" in ".016"
                end
                Q = sort(unique(Q), 'ascend');
                if isempty(Q)
                    Q = 1:length(info.Q);
                end
            
            case 'MIDI'
                if isdir([info.path 'fids'])                % after rename
                    fid_str = ['fids' filesep '*_fid_*'];
                    q_str   = 'q';
                elseif ~isempty(dir([info.path 'FID_*']))   % Software rev.
                    fid_str = 'FID_*';
                    q_str   = 'Q';
                else
                    error('Unknown filename format. Probably old unsupported MIDI version')
                end
                allQ = dir([info.path fid_str]);        % raw data files
                Q    = zeros(1,length(allQ)); 
                for iallQ = 1:length(allQ)
                    iQ = find(allQ(iallQ).name == q_str);                    
                    if length(iQ) > 1; error('bad filename - contains two Q'); end
                    q = allQ(iallQ).name(iQ+1:iQ+2);
                    if strcmp(q(end),'_'); q(end) = []; end
                    Q(iallQ) = str2double(q);
                end
                Q = sort(unique(Q), 'descend'); % Q=0 is the largest pulsemoment
           
            case 'MINI'
                Q = 1;
            
            case 'Jilin';
                Q = 1:length(info.Q);
                
            case 'TERRANOVA'
                Q = zeros(1,length(info.Q));
                for n=1:length(info.Q)
                    Q(n) = info.Q(n).q;
                end

            case 'GMR'
                if isdir([info.path, 'converted'])
                    allREC = dir([info.path,'converted',filesep,'Q*']);
                    REC = zeros(1,length(allREC));
                    for iallREC = 1:length(allREC)
                        ihash = find(allREC(iallREC).name == '#');
                        idot  = find(allREC(iallREC).name == '.');
                        if length(ihash) > 1; error('bad filename - contains two hashes (#)'); end
                        if length(idot) > 1; error('bad filename - contains two dots (.)'); end
                        REC(iallREC) = str2double(allREC(iallREC).name(2:ihash-1));
                    end
                    Q = sort(unique(REC), 'ascend');
                else
                   Q = 1:length(info.Q);
%                    for iQ=1:length(info.Q)
%                         Q(iQ) = info.Q(iQ).q; 
%                    end
                   
                   %uival = mrs_read_gmruserinfo([info.path 'userinfo.gmr']);
                   %Q = 1:uival{11};
                end                
        end
        X = Q;
        
    case 'REC'
        switch info.device
            case {'NUMISpoly', 'NUMISplus'}
                allREC = dir([info.path,'RawData',filesep,'Q',num2str(iq),'#*']);
                REC = zeros(1,length(allREC));
                for iallREC = 1:length(allREC)
                    ihash = find(allREC(iallREC).name == '#');
                    idot  = find(allREC(iallREC).name == '.');
                    if length(ihash) > 1; error('bad filename - contains two hashes (#)'); end
                    if length(idot) > 1; error('bad filename - contains two dots (.)'); end
                    REC(iallREC) = str2double(allREC(iallREC).name(ihash+1:idot-1));
                end
                REC = sort(unique(REC), 'ascend');

            case 'MIDI'
                if isdir([info.path 'fids'])                % after rename
                    rec_str = ['fids' filesep '*_fid_*'];
                    r_str   = 'r';
                elseif ~isempty(dir([info.path 'FID_*']))   % Software rev.
                    rec_str = 'FID_*';
                    r_str   = 'R';
                else
                    error('Unknown filename format. Probably old unsupported MIDI version')
                end                
                allREC = dir([info.path rec_str]);      % raw data files
                REC    = zeros(1,length(allREC)); 
                for iallREC = 1:length(allREC)
                    iR = find(allREC(iallREC).name == r_str);
                    if length(iR) > 1; error('bad filename - contains two R'); end
                    r = allREC(iallREC).name(iR+1:iR+2);
                    if strcmp(r(end),'_'); r(end) = []; end
                    REC(iallREC) = str2double(r);
                end
                REC = sort(unique(REC), 'ascend');
                
            case 'MINI'
                allREC = dir([info.path, '*.dat']);      % raw data files
                if ~isnan(str2double(allREC(1).name(end-6)))
                    ir = 6;
                elseif ~isnan(str2double(allREC(1).name(end-5)))
                    ir = 5;
                else
                    ir = 4;
                end
                REC    = zeros(1,length(allREC)); 
                for iallREC = 1:length(allREC)
                    REC(iallREC) = str2double(allREC(iallREC).name(end-ir:end-4));
                end
                REC = sort(unique(REC), 'ascend');                
                
            case 'GMR'                
                if isdir([info.path, 'converted'])
                    allREC = dir([info.path,'converted',filesep,'Q',num2str(iq),'#*']);
                    REC = zeros(1,length(allREC));
                    for iallREC = 1:length(allREC)
                        ihash = find(allREC(iallREC).name == '#');
                        idot  = find(allREC(iallREC).name == '.');
                        if length(ihash) > 1; error('bad filename - contains two hashes (#)'); end
                        if length(idot) > 1; error('bad filename - contains two dots (.)'); end
                        REC(iallREC) = str2double(allREC(iallREC).name(ihash+1:idot-1));
                    end
                    REC = sort(unique(REC), 'ascend');
                else
                   uival = mrs_read_gmruserinfo([info.path 'userinfo.gmr']);
                   REC   = 1:uival{10};
                end      
        end        
        X = REC;
end


