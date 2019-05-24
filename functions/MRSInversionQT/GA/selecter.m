function parents=selecter(misfit,npopsiz)
% Only available option is tournament selection
    %choose the players
    nplayers=2;%the size of tournament
    players = ceil(length(misfit) * rand(npopsiz,nplayers));

    % look up the outcomes
    scores = misfit(players);

    % pick the winners
    [unused,m] = min(scores');

    %m is now the index of the winners;
    parents = zeros(1,npopsiz);
    for i = 1:npopsiz
        parents(i) = players(i,m(i));
    end

