%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% build the kernel matrix for 
% mono-exponential T2* within one layer
%
% kernel function now depends on the current T2 
%
% mmp 07.02.2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function G = QTIMonoKernelComplex(g,t,T2,w)

% % separate real and imaginary part
%g        = [real(g); imag(g)]; 
% extend g by the number of time samples
gM       = repmat(g,length(t),1);

% extend the T2 depth dist. to match the gM
T2M      = repmat(repmat(T2.',size(g,1),1),length(t),1);
tM       = kron(t,ones(size(g.'))).';
T2expM   = exp(-tM./T2M);

G        = gM.*T2expM;

