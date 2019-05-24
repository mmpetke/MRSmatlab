function [ichild,nmutate]=mutate(npopsiz,nchrome,pmutate,ichild)

ras=rand(npopsiz,nchrome);
ploc=ras<pmutate;
if ichild(ploc)==0
    ichild(ploc)=1;
else
    ichild(ploc)=0;
end
nmutate=length(find(ploc));


