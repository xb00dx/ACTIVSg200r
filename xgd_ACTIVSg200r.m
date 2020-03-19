function xgd_table = xgd_ACTIVSg200r(mpc)
%XGD_ACTIVSg200r    Additional Generator Data for case_ACTIVSg200r
% 
%   See revise_ACTIVSg200.m for more details about settings
%   Parameters are based on [1].
%   See https://github.com/xb00dx/ACTIVSg200r for more infor about ACTIVSg200r.
% 
% References
%   [1] T. Xu, A. B. Birchfield, K. M. Gegner, K. S. Shetye, and T. J. Overbye,
%   “Application of large-scale synthetic power system models for energy 
%   economic studies,” in Proceedings of the 50th Hawaii International 
%   Conference on System Sciences, 2017.
% 
%   Created by X. Geng (03/14/2020)
% 
%   This file is created for MOST.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See https://github.com/MATPOWER/most for more info about MOST.

% get min-on (MinUp) time and min-off (MinDown) time
% in number of periods (this case delta_t = 1hour)
load('gendata_ACTIVSg200r.mat'); 
ng = size(min_on,1);
init_stat = zeros(ng,1);
init_stat( [24,25,29,30,41], 1) = 1;
%% xGenData
xgd_table.colnames = {'CommitKey','CommitSched','MinUp','MinDown','InitialState'};
xgd_table.data = [ones(ng,1), ones(ng,1), min_on, min_off, init_stat];


end
