function ichild=xover(nchrome,mate1,mate2,iparent,npopsiz,type,pcross)
switch type
    case 'single'
        xover10=rand(1,npopsiz);
        ichild=iparent(:,mate1);
        xoverp = ceil(rand * (nchrome - 1));
        loc=find(xover10<pcross);
        ichild(xoverp:end,loc)=iparent(xoverp:end,mate2(loc));
    case 'two'
        xover10=rand(1,npopsiz);
        ichild=iparent(:,mate1);
        xoverp1 = ceil(rand * (nchrome - 1));
        xoverp2 = ceil(rand * (nchrome - 1));
        ind=xoverp1>xoverp2;
        temp=xoverp1(ind);
        xoverp1(ind)=xoverp2(ind);
        xoverp2(ind)=temp;
        loc=find(xover10<pcross);
        ichild(xoverp1:xoverp2,loc)=iparent(xoverp1:xoverp2,mate2(loc));
    case 'scattered'
    n             =  1:nchrome;
    ichild        =  iparent(n,mate1);
    ras           =  rand(1,nchrome);
    loc           =  find(ras<=pcross);
    ichild(loc,1:npopsiz)=iparent(loc,mate2);
end
    
    