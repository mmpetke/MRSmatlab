function I      = FunImod(t, startI, endI, shape, A, B)
% current modulation
t       = t(:);
T       = t(end)-t(1);  
I_diff  = endI  - startI;

switch shape
    case 1          % 2: linear
        I       = startI + (I_diff/T*t);                       
    case 2          % 3: tanh GMR
        tau     = pi*t./T;  % pi is arbitrary. Ask Grunewald
        I       = startI + (I_diff * tanh(tau));     
    case 3          % 3: tanh MIDI
        CC      = tanh(2*A*(t-B*t(end)/2)*pi/t(end)); 
        I       = startI + (I_diff *(CC-min(CC))/(max(CC)-min(CC)));
    case 4          % 1: constant
        I       = ones(size(t)).*endI;      
end 
end