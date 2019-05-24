function instrument = mrs_checkinstrument(sounding_path)
% function instrument = mrs_checkinstrument(sounding_path)
% 
% Only required in MRSImport to check which load is called on menu
% selection. Later, the device is stored in proclog.device.
% 
% 26jan2011
% ed. 13jun2012 JW
% =========================================================================

if isdir([sounding_path, 'RawData'])
    instrument = 'numis';
else
    if ~isempty(dir([sounding_path 'FID_*.dat'])) || ...
        isdir([sounding_path 'fids'])
        instrument = 'midi';
    elseif ~isempty(dir([sounding_path '*.txt']))   % may be ambiguous...
        instrument = 'LIAGNoiseMeter';
    elseif ~isempty(dir([sounding_path 'acqu.par']))   % may be ambiguous...
        instrument = 'terranova';
    elseif ~isempty(dir([sounding_path '*.dat']))   % may be ambiguous...
        instrument = 'mini';
    elseif ~isempty(dir([sounding_path '*.lvm']))
        instrument = 'gmr';
    end
end

