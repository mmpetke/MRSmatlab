function x = ext_roundn(x,n)
% function x = ext_roundn(x,n)
% 
% Round numbers to a power of 10 specified by n. 
% For example, if n = 2, round to the nearest hundred (10^2).
% 
% as MATLAB MAPPING TOOLBOX & FILE EXCHANGE (MMP,JW)

f = 10^(-n);
x = round(x*f)/f;