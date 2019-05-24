function [gInt,zInt] = mrs_invQTKernelIntegration(idata)

g      = idata.kernel.K;
z      = idata.kernel.z;

if length(idata.para.minThickness)==1 % hidden option for summing the kernel
    zNew = [idata.para.minThickness: idata.para.minThickness: idata.para.maxDepth max(z)];
else
    zNew               = idata.para.minThickness;
    zNew(zNew>=max(z)) = [];
    zNew               = [zNew max(z)];
end

zInd = ones(1,length(zNew));
for n=2:length(zNew)+1
    zInd(n) = find(zNew(n-1)<=z,1);
end
zInd = unique(zInd);

zInt = zeros(1,length(zInd)-1);
gInt = zeros(size(g,1),length(zInd)-1);
% calculate sum within a interval 
for n=2:length(zInd)
    gInt(:,n-1) = sum(g(:,zInd(n-1):zInd(n)-1),2);
    zInt(n-1)   = z(zInd(n)-1);
end
