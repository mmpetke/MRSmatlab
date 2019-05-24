function [array]=decode1(nparam,ig2,g0,g1,iparent)

%  This routine decodes a binary string to a real number.
%       common / ga2   / nparam,nchrome
%       common / ga5   / g0,g1,ig2
[a,b]=size(iparent);
for i=1:b
    l=1;
    for k=1:nparam
        iparam=0;
        m=l;
        for j=m:m+ig2(k)-1
            l=l+1;
            iparam=iparam+iparent(j,i)*(2^(m+ig2(k)-1-j));
        end
        array(i,k)=g0(k)+g1(k)*iparam;
    end
end