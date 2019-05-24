%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% build the jacobian matrix
% dD = [dG/dw dG/dT2] [dw dT2]
% mmp 24.03.2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function J = QTIMonoJacobian(g,t,T2,w,ub,lb)

% use amplitudes
%g        = AmplitudeJacobian(g,w); 
% extend g by the number of time samples
gM       = repmat(g,length(t),1);
% extend the T2 depth dist. to match the gM
T2M      = repmat(repmat(T2.',size(g,1),1),length(t),1);
tM       = kron(t,ones(size(g.'))).';
T2expM   = exp(-tM./T2M);
%G        = gM.*T2expM;
G        = AmplitudeJacobian(gM.*T2expM,w);
% derivation wih respect to w 
dGw     = G;

% derivation wih respect to T2
dT2M    = tM./(T2M.^2);
wM      = repmat(w.',size(g,1)*length(t),1);
%dGT2    = G.*wM.*dT2M;
dGT2    = AmplitudeJacobian(G.*wM.*dT2M,w);

% complete jacobian
J = [dGw dGT2];

% transformations
mj    = [w;T2];
ubv   = [ub(1)*ones(length(w)) ub(2)*ones(length(T2))];
lbv   = [lb(1)*ones(length(w)) lb(2)*ones(length(T2))];


for m=1:size(J,2)
    J(:,m) = J(:,m).*(cos( (mj(m)/(ubv(m)-lbv(m)) -.5.*(ubv(m)+lbv(m))./(ubv(m)-lbv(m)))*pi).^2 ) ./pi/(ubv(m)-lbv(m));
end
