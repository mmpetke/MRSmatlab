function [iparent,gamicrostate]=gamicro(npopsiz,nchrome,iparent,ibest)
gamicrostate=0;
icount=0;
for j=1:npopsiz
    for n=1:nchrome
        if iparent(n,j)~=ibest(n)
            icount=icount+1;
        end
    end
end
%   If icount less than 5% of number of bits, then consider population
%   to be converged.  Restart with best individual and random others.
diffrac=(icount)/((npopsiz-1)*nchrome);

if  diffrac<.05
    %     for
    n=1:nchrome;
    iparent(n,1)=ibest(n);
    %     end
    for j=2:npopsiz
        for n=1:nchrome
            ras=rand;
            iparent(n,j)=1;
            if ras<0.5
                iparent(n,j)=0;
            end
        end
    end
    gamicrostate=1;

end