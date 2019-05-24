function iparent=newgen(ibest,npopsiz,ichild,elit)
kelite=0;
iparent=ichild;
if elit
    for j=1:npopsiz
        kelit(j)=isequal(iparent(:,j),ibest);
    end

    if any(kelit)
        kelite=1;
    else
        kelite=0;
    end


    if kelite==0
        ras=rand;
        irand=1d0+fix((npopsiz)*ras);
        iparent(:,irand)=ibest;
    end
end