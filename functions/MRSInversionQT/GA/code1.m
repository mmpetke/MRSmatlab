function iarray=code1(array,nparam,ig2,g0,g1)
%  This routine codes a parameter into a binary string.
%       common / ga2   / nparam,nchrome
%       common / ga5   / g0,g1,ig2
% c  First, establish the beginning location of the parameter string of
% c  interest.
for k=1:nparam
    istart=1;
    for i=1:k-1
        istart=istart+ig2(i);
    end

    % c  Find the equivalent coded parameter value, and back out the binary
    % c  string by factors of two.
    m=ig2(k)-1;
    if g1(k)==0.0d0
        return;
    end;
    iparam=round((array(k)-g0(k))/g1(k));
    for i=istart:istart+ig2(k)-1;
        iarray(i)=0;
        if (iparam+1)>(2^m)
            iarray(i)=1;
            iparam=iparam-2^m;
        end
        m=m-1;
    end
end
