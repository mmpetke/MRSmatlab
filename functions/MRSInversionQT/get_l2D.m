function [Lx,Ly] = get_l2D(n1,n2)

Ax=get_l(n1,1);
Bx=eye(n2);
%Lx=full(kron(Bx,Ax));
Lx=kron(Bx,Ax);

Ay=eye(n1);
By=get_l(n2,1);
%Ly=full(kron(By,Ay));
Ly=kron(By,Ay);