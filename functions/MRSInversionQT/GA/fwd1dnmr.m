function A  =fwd1dnmr(par,nlay,zvec,g,t)

wc    = par(1:nlay);
t2    = par(nlay+1:2*nlay);
thk   = par(2*nlay+1:3*nlay-1);
zhk   = cumsum(thk);
nzvec = length(zvec);

% find indices for z weight
izvec=0;
rzvec=zeros(nlay,1);
for i=1:length(thk),
    ii=find(zvec<zhk(i),1,'last');if isempty(ii),ii=1;end
    izvec(i+1)=ii;
    if ii<nzvec,
        rzvec(i+1)=(zhk(i)-zvec(ii))/(zvec(ii+1)-zvec(ii));
    end
end

izvec(end+1)=length(zvec)+1;
wcvec       = zeros(length(zvec),1);
A           = zeros(size(g,1),length(t));

for i=1:nlay,
    wcvec(:)=0;
    wcvec(izvec(i)+1:izvec(i+1)-1)=wc(i);
    if izvec(i+1)<nzvec, wcvec(izvec(i+1))=wc(i)*rzvec(i+1); end
    if izvec(i)>0, wcvec(izvec(i))=wc(i)*(1-rzvec(i)); end
    amps=g*wcvec;
    ett=exp(-t/t2(i));

    for j=1:length(amps),A(j,:)=A(j,:)+ett*amps(j);    end
end

