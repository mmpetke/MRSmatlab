function YC=fwdc1(XY,P,C)

N=length(P);
L=(N+1)/2.;
ND=length(XY);
IQ=28;
IIF=19;
ZM=6.0;
X=.13072093886;
EE=exp(2.3025850929/ZM);
YC=zeros(1,ND);
for J=1:ND
    UU=XY(J);
    U=UU*exp(-IIF*2.3025850929./ZM-X);
    RL=0.0;
    for  I=1:IQ
        V=P(L);
        IW=L;
        for m=IW-1:-1:1
            FC=V/P(m);
            if FC>1.0
                AC=P(m)./V;
            else
                AC=FC;
            end
            AF=log((1+AC)./(1-AC))/2;
            AA=P(m+L)./U+AF;
            
            if abs(AA)>5.0
                V=P(m);
            else
                BB=exp(AA);
                CC=exp(-AA);
                DD=(BB-CC)./(BB+CC);
                if FC>=1.0
                    V=P(m)./DD;
                else
                    V=P(m).*DD;
                end
            end
        end
        RL=RL+C(I).*V;
        U=U*EE;
    end
    YC(J)=RL;
end



