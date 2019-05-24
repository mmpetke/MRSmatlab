function [J,dd] = AmplitudeJacobian(G,mj)

    if nargin<2, mj=ones(size(G,2),1); end
    
    J=zeros(size(G));
    dd = G*mj;
    for m=1:size(G,2)
         J(:,m) = (real(G(:,m)).*real(dd) + imag(G(:,m)).*imag(dd))./abs(dd); 
    end
