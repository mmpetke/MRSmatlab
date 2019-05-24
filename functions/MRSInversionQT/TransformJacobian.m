function J = TransformJacobian(G,mj,trafo,ub)

J  = zeros(size(G));
dd = G*mj;

switch trafo
    case 'tantan'
        for m=1:size(G,2)
            J(:,m) = G(:,m).*...
                (cos((mj(m)/ub-.5)*pi).^2)./...
                (cos((dd(:)/ub-.5)*pi).^2);
        end
    case 'tan'
        for m=1:size(G,2)
            J(:,m) = G(:,m).*(cos((mj(m)/ub-.5)*pi).^2).*(ub/pi);
        end
    case 'loglog'
        for m=1:size(G,2)
            J(:,m) = G(:,m).*((mj(m))./(dd));
        end
    case 'log'
        for m=1:size(G,2)
            J(:,m) = G(:,m)*(mj(m));
        end
end
    
    
    
