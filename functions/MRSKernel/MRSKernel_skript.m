% skript to load MRSKernel settings and run without graphics
% can be looped for variable parameter

function MRSkernel_skript(infile, outfile)

load(infile, '-mat')

if license('test','Distrib_Computing_Toolbox')
    matlabpool
    parma = 1
end

data.K = MakeKernel(data.loop, data.model, data.measure, data.earth);

if parma
    matlabpool close
end

save(outfile, 'data');