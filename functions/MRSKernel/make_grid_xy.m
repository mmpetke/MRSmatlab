%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to create a regular cartesian grid for the nmr forward 
% modelling, i.e. interpolation. Dimensions for 
% separated loops are considered
% INPUT
% sruct of model parameters, positions and configuration
% OUTPUT
% 2D-Grid (x-y) for nmr interpolation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MH 04/2002 MM 10/20005


function [grid, model] = make_grid_xy(model, measure, loop, TxRx)

x     = model.dh/2:model.dh:model.hmax-model.dh/2;
y     = x;


switch measure.mes_conf
	case 1
		switch loop.spec
			case 1
						x_pos =  model.dh/2: model.dh: model.hmax - model.dh/2;
						x_neg = -model.dh/2:-model.dh:-model.hmax + model.dh/2;
						x1    = [fliplr(x_neg) x_pos];
						x2    = 0;
						
						y_pos =  model.dh/2: model.dh: model.hmax - model.dh/2;
						y_neg = -model.dh/2:-model.dh:-model.hmax + model.dh/2;
						y1    = [fliplr(y_neg) y_pos];
						y2    = 0;
						grid.eight = 0;				
				
			case 2
						x_pos =  model.dh/2: model.dh: model.hmax - model.dh/2;
						x_neg = -model.dh/2:-model.dh:-model.hmax + model.dh/2;
						x1    = [fliplr(x_neg) x_pos];
						x2    = [fliplr(x_neg) x_pos];
						
						y_pos =  model.dh/2: model.dh: model.hmax - model.dh/2;
						y_neg = -model.dh/2:-model.dh:-model.hmax + model.dh/2;
						y1    = [fliplr(y_neg) y_pos];
						y2    = [fliplr(y_neg) y_pos];
						grid.eight = 0;
		end % TxRx
    
    case {2,3,4,5}
		switch loop.spec
			case 1
						x_pos =  model.dh/2: model.dh: model.hmaxx - measure.tx_xpos - model.dh/2;
						x_neg = -model.dh/2:-model.dh:-model.hmaxx - measure.tx_xpos + model.dh/2;
						x1    = [fliplr(x_neg) x_pos];
                        x2    = 0;
						
						y_pos =  model.dh/2: model.dh: model.hmaxy - measure.tx_ypos - model.dh/2;
						y_neg = -model.dh/2:-model.dh:-model.hmaxy - measure.tx_ypos + model.dh/2;
						y1    = [fliplr(y_neg) y_pos];
						y2    = 0;
						grid.eight = 0;
				
			case 2
						x_pos =  model.dh/2: model.dh: model.hmaxx - measure.rx_xpos - model.dh/2;
						x_neg = -model.dh/2:-model.dh:-model.hmaxx - measure.rx_xpos + model.dh/2;
						x1    = [fliplr(x_neg) x_pos];
						x2    = [];
						
						y_pos =  model.dh/2: model.dh: model.hmaxy - measure.rx_ypos - model.dh/2;
						y_neg = -model.dh/2:-model.dh:-model.hmaxy - measure.rx_ypos + model.dh/2;
						y1    = [fliplr(y_neg) y_pos];
						y2    = [];
						grid.eight = 0;
				
		end % TxRx
end % mes_conf

grid.x1m  = repmat(x1',  [1 size(y1,2)]);
grid.x2m  = repmat(x2',  [1 size(y2,2)]);
grid.y1m  = repmat(y1,   [size(x1,2) 1]);
grid.y2m  = repmat(y2,   [size(x2,2) 1]);

switch measure.dim
    case 2
        x_pos =  model.dh/2: model.dh: model.hmaxx - model.dh/2;
		x_neg = -model.dh/2:-model.dh:-model.hmaxx + model.dh/2;
		x1    = [fliplr(x_neg) x_pos];
        model.x_vec = x1;
    case 3
        x_pos =  model.dh/2: model.dh: model.hmaxx - model.dh/2;
		x_neg = -model.dh/2:-model.dh:-model.hmaxx + model.dh/2;
		x1    = [fliplr(x_neg) x_pos];
        model.x_vec = x1;
        y_pos =  model.dh/2: model.dh: model.hmaxy - model.dh/2;
		y_neg = -model.dh/2:-model.dh:-model.hmaxy + model.dh/2;
		y1    = [fliplr(y_neg) y_pos];
        model.y_vec = y1;
end

return