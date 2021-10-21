function R = RotationFromTwoVectors(A, B)
% creates a rotation matrix R to rotate A to B
method = 4;

calcR = true;
% catch special cases where the formulas below do not work
if (A(1) == -1*B(1)) && all(A(2:3)==0) && all(B(2:3)==0)
    R = [-1 0 0;0 1 0;0 0 -1];
    calcR = false;
elseif (A(2) == -1*B(2)) && all(A([1 3])==0) && all(B([1 3])==0)
    R = [1 0 0;0 -1 0;0 0 -1];
    calcR = false;
elseif (A(3) == -1*B(3)) && all(A(1:2)==0) && all(B(1:2)==0)
    R = [-1 0 0;0 1 0;0 0 -1];
    calcR = false;
end

if calcR    
    switch method
        case 1
            % normalized column vectors
            A = A(:)./norm(A);
            B = B(:)./norm(B);
            
            d = dot(A,B);
            v = cross(A,B);
            ssc = [ 0  -v(3) v(2);
                v(3)  0  -v(1);
                -v(2) v(1)  0];
            R = eye(3) + ssc + ssc^2*(1-d)/(norm(v))^2;
        case 2
            % normalized column vectors
            A = A(:)./norm(A);
            B = B(:)./norm(B);
            
            d = dot(A,B);
            c = cross(A,B);
            
            GG = @(A,B) [ d -norm(c) 0;
                norm(c) d  0;
                0       0  1];
            
            FFi = @(A,B) [ A (B-d*A)/norm(B-d*A) cross(B,A) ];
            
            UU = @(Fi,G) Fi*G*inv(Fi); %#ok<MINV>
            
            R = UU(FFi(A,B), GG(A,B));
            
        case 3
            % normalized column vectors
            A = A(:)./norm(A);
            B = B(:)./norm(B);
            
            AB = A+B;
            ABT = (A+B)';
            I = eye(3);
            
            R = 2*(AB*ABT)/(ABT*AB)-I;
        case 4
            u = A(:)/norm(A);                   % a and b must be column vectors
            v = B(:)/norm(B);                   % of equal length
            N = length(u);
            S = reflection( eye(N), v+u );      % S*u = -v, S*v = -u
            R = reflection( S, v );             % v = R*u
            
    end
    
end

end

function v = reflection(u, n ) % Reflection of u on hyperplane n.
% u can be a matrix. u and v must have the same number of rows.
v = u - 2 * n * (n'*u) / (n'*n);
end


