function df = Funfmod(t, startdf, enddf, shape, A, B)
% frequency modulation

t       = t(:);
T       = t(end)-t(1);    
f_diff  = enddf - startdf;    % amplitude of frq shift

switch shape
    case 1          % 2: linear
        df      = startdf + (f_diff/T*t);        % Frq change per ad. pulse length
    case 2          % 3: tanh GMR
        A       = 3;
        tau     = A*t./T;                % factor is 3 for GMR (pers comm Grunewald 13.10.2016)
        df      = startdf + (f_diff * tanh(tau));             
    case 3          % 3: tanh MIDI 
        % MMP anpassung sonst ist df positiv obwohl startdf negativ ist!
        f_diff=-f_diff;
        CC      = tanh(2*A*(t-B*t(end)/2)*pi/t(end)); 
        if f_diff < 0
            df = (enddf+f_diff)-(f_diff)*(CC - CC(1))/(CC(end)-CC(1));
        elseif f_diff > 0
            df = (enddf)+(f_diff)*(CC - CC(end))/(CC(1)-CC(end));
        end  
    case 4          % 1: constant
        df      = ones(size(t)).*enddf;
end
end

