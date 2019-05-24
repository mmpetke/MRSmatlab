function [B1mod] = ampmodQ(B1,f, f_larmor, Q)


s = f_larmor/(sqrt((4*Q^2-1)*(sqrt(2)-1)));

A = 1/pi * s./(s^2+(f-f_larmor).^2);
Again = A./max(A);

B1mod = B1 .* Again;

end