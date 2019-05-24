function [DistValue,LayerInd] = layerToSmooth(LayerValue,LayerThk,zSmooth)


DistValue     = zeros(length(zSmooth),1);
zLayer        = 1e-2*floor([0 cumsum(LayerThk) max(zSmooth)]*1e2);
LayerInd      = 1e-2*floor(cumsum(LayerThk)*1e2);
for ilayer = 1:length(LayerThk)
    inthislayer             = find(zLayer(ilayer) <= zSmooth & zSmooth < zLayer(ilayer+1));
    DistValue(inthislayer)  = LayerValue(ilayer);
    LayerInd(ilayer)        = inthislayer(end);
end

DistValue(LayerInd(end)+1:end) = LayerValue(end);