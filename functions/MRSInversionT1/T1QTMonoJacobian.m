%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% build the T1 jacobian matrix for mono T2 decay times
% dD = [dG/dT1] [dT1]
% the jacaobian is already done in kernel calculation see IntegrateJ1D
%
% T2* and WC are needed since the forward response depends on T2s and WC
%
% mmp 09.03.2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function J = T1QTMonoJacobian(g,t,T1,T2,w,ub,lb)

% complete jacobian
% use amplitudes
% g       = AmplitudeJacobian(g,w);  
% extend g by the number of time samples
gM       = repmat(g,length(t),1);
% extend the by T2 depth 
tM       = kron(t,ones(size(g.'))).';
T2M      = repmat(repmat(T2.',size(g,1),1),length(t),1);
T2expM   = exp(-tM./T2M);
% extend by water content
wM      = repmat(w.',size(g,1)*length(t),1);
% jacobian
J        = AmplitudeJacobian(gM.*wM.*T2expM,w);
%J        = gM.*wM.*T2expM;


% transformations
mj    = [T1];
ubv   = [ub*ones(length(T1))];
lbv   = [lb*ones(length(T1))];


for m=1:size(J,2)
    J(:,m) = J(:,m).*(cos( (mj(m)/(ubv(m)-lbv(m)) -.5.*(ubv(m)+lbv(m))./(ubv(m)-lbv(m)))*pi).^2 ) ./pi/(ubv(m)-lbv(m));
end