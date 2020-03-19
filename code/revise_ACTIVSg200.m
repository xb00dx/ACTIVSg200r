clear; clc; close all; 

%% Revise the ACTIVSg200 system for multi-period analysis (dispatch or commitment)
% The following changes have been made:
% 1. assign values to BUS_AREA of mpc.bus
% 2. adding the following missing parameters
%   missing MIN-ON time, MIN-OFF time
%   missing startup/shutdown cost
%   missing ramping parameters: RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q
% range of parameters are from reference [1]
% 
% References
% [1] T. Xu, A. B. Birchfield, K. M. Gegner, K. S. Shetye, and T. J. Overbye,
%   “Application of large-scale synthetic power system models for energy 
%   economic studies,” in Proceedings of the 50th Hawaii International 
%   Conference on System Sciences, 2017.

define_constants;
casename = 'case_ACTIVSg200';

% 1 hour for each period, 24 hours
% this is for min-on and min-off, which is in the num of delta_t 
delta_t = 1; nt = 24; % 24 hours

% original Settings
mpc = loadcase(casename);

% making changes
mpcm = mpc;
% assign values to BUS_AREA of mpc.bus, otherwise there will be problems
% using apply_profiles(), scale_laod() or creating profiles for MOST (using
% the area-loads in scenarios_ACTIVSg200.m)
mpcm.bus(:, BUS_AREA) = mpc.bus(:, ZONE); 

mpcm.gen(:, GEN_STATUS) = 1;

% remove wind generators because no wind profiles were provided
wind_ind = strcmp(mpc.genfuel, 'wind');
mpcm.gen(wind_ind,:) = []; mpcm.gencost(wind_ind,:) = [];
mpcm.gentype(wind_ind,:) = []; mpcm.genfuel(wind_ind,:) = [];

% change the generator cost to linear (removing c2 in mpc.gencost)
mpcm.gencost(:,4) = 2;
mpcm.gencost(:,5) = [];

ng = size(mpcm.gen,1); % NOTE: #gen has been changed

%% adding missing parameters of generators
% simple heuristics: large generators are slower to ramp up, more
% expensive to start up and shutdown
min_on = zeros(ng,1); min_off = zeros(ng,1);
% 1. coal generators
coal_ind = find( strcmp(mpcm.genfuel, 'coal') == 1);
for i = 1:length(coal_ind)
    ig = coal_ind(i);
    if mpcm.gen(ig,PMAX) >= 400
        mpcm.gen(ig,RAMP_AGC) = 0.6/100 * mpcm.gen(ig,PMAX); % 0.6% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 250 * mpcm.gen(ig,PMAX); % 250$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 25 * mpcm.gen(ig,PMAX); % 25$/MW per shutdown
        min_on(ig,1) = 12; % hour, min on time
        min_off(ig,1) = 12; % hour, min off time
    elseif mpcm.gen(ig,PMAX) >= 200
        mpcm.gen(ig,RAMP_AGC) = 1/100 * mpcm.gen(ig,PMAX); % 1% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 150 * mpcm.gen(ig,PMAX); % 150$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 15 * mpcm.gen(ig,PMAX); % 15$/MW per shutdown
        min_on(ig,1) = 6; % hour, min on time
        min_off(ig,1) = 6; % hour, min off time
    elseif mpcm.gen(ig,PMAX) >= 100
        mpcm.gen(ig,RAMP_AGC) = 3/100 * mpcm.gen(ig,PMAX); % 3% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 100 * mpcm.gen(ig,PMAX); % 100$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 10 * mpcm.gen(ig,PMAX); % 10$/MW per shutdown
        min_on(ig,1) = 3; % 3 hour, min on time
        min_off(ig,1) = 3; % 3 hour, min off time
    elseif mpcm.gen(ig,PMAX) >= 50
        mpcm.gen(ig,RAMP_AGC) = 6/100 * mpcm.gen(ig,PMAX); % 6% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 50 * mpcm.gen(ig,PMAX); % 50$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 5 * mpcm.gen(ig,PMAX); % 5$/MW per shutdown    
        min_on(ig,1) = 2; % 2 hour, min on time
        min_off(ig,1) = 2; % 2 hour, min off time
    elseif mpcm.gen(ig,PMAX) >= 10
        mpcm.gen(ig,RAMP_AGC) = 8/100 * mpcm.gen(ig,PMAX); % 8% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 30 * mpcm.gen(ig,PMAX); % 30$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 3 * mpcm.gen(ig,PMAX); % 3$/MW per shutdown
        min_on(ig,1) = 1; % 1 hour, min-on time
        min_off(ig,1) = 1; % 1 hour, min-off time
    elseif mpcm.gen(ig,PMAX) >= 0
        mpcm.gen(ig,RAMP_AGC) = 8/100 * mpcm.gen(ig,PMAX); % 8% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 10 * mpcm.gen(ig,PMAX); % 20$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 1 * mpcm.gen(ig,PMAX); % 2$/MW per shutdown
        min_on(ig,1) = 1; % 1 hour, min-on time
        min_off(ig,1) = 1; % 1 hour, min-off time
    else
        error('something wrong with mpc.gen(ig,PMAX)!');
    end
end

% 2. natural gas
ng_ind = find( strcmp(mpcm.genfuel, 'ng') == 1);
for i = 1:length(ng_ind)
    ig = ng_ind(i);
    if mpcm.gen(ig,PMAX) >= 100
        mpcm.gen(ig,RAMP_AGC) = 5/100 * mpcm.gen(ig,PMAX); % 5% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 150 * mpcm.gen(ig,PMAX); % 150$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 15 * mpcm.gen(ig,PMAX); % 15$/MW per shutdown
        min_on(ig,1) = 2; % 2 hour, min on time
        min_off(ig,1) = 1; % 1 hour, min off time        
    elseif mpcm.gen(ig,PMAX) >= 50
        mpcm.gen(ig,RAMP_AGC) = 10/100 * mpcm.gen(ig,PMAX); % 10% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 100 * mpcm.gen(ig,PMAX); % 100$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 10 * mpcm.gen(ig,PMAX); % 10$/MW per shutdown
        min_on(ig,1) = 1; % 1 hour, min on time
        min_off(ig,1) = 0.5; % 0.5 hour, min off time    
    elseif mpcm.gen(ig,PMAX) >= 25
        mpcm.gen(ig,RAMP_AGC) = 15/100 * mpcm.gen(ig,PMAX); % 15% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 50 * mpcm.gen(ig,PMAX); % 50$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 5 * mpcm.gen(ig,PMAX); % 5$/MW per shutdown
        min_on(ig,1) = 1; % 1 hour, min on time
        min_off(ig,1) = 0.25; % 0.25 hour, min off time    
    elseif mpcm.gen(ig,PMAX) >= 10
        mpcm.gen(ig,RAMP_AGC) = 20/100 * mpcm.gen(ig,PMAX); % 20% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 25 * mpcm.gen(ig,PMAX); % 25$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 2 * mpcm.gen(ig,PMAX); % 2$/MW per shutdown    
        min_on(ig,1) = 0.5; % 0.5 hour, min on time
        min_off(ig,1) = 0.25; % 0.25 hour, min off time    
    elseif mpcm.gen(ig,PMAX) >= 5
        mpcm.gen(ig,RAMP_AGC) = 25/100 * mpcm.gen(ig,PMAX); % 25% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 20 * mpcm.gen(ig,PMAX); % 20$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 2 * mpcm.gen(ig,PMAX); % 2$/MW per shutdown
        min_on(ig,1) = delta_t; % 0 hour, min on time
        min_off(ig,1) = delta_t; % 0 hour, min off time        
    elseif mpcm.gen(ig,PMAX) >= 0
        mpcm.gen(ig,RAMP_AGC) = 30/100 * mpcm.gen(ig,PMAX); % 30% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 20 * mpcm.gen(ig,PMAX); % 20$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 2 * mpcm.gen(ig,PMAX); % 2$/MW per shutdown
        min_on(ig,1) = delta_t; % 0h (min possible value), min on time
        min_off(ig,1) = delta_t; % 0h hour (min possible value), min off time
    else
        error('something wrong with mpc.gen(ig,PMAX)!');
    end
end

% 3. nuclear
nu_ind = find( strcmp(mpcm.genfuel, 'nuclear') == 1);
for i = 1:length(nu_ind)
    ig = nu_ind(i);
    if mpcm.gen(ig,PMAX) >= 500
        mpcm.gen(ig,RAMP_AGC) = 0.5/100 * mpcm.gen(ig,PMAX); % 0.5% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 1000 * mpcm.gen(ig,PMAX); % 1000$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 1000 * mpcm.gen(ig,PMAX); % 1000$/MW per shutdown
    elseif mpcm.gen(ig,PMAX) >= 250
        mpcm.gen(ig,RAMP_AGC) = 1/100 * mpcm.gen(ig,PMAX); % 1% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 1000 * mpcm.gen(ig,PMAX); % 1000$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 1000 * mpcm.gen(ig,PMAX); % 1000$/MW per shutdown
    elseif mpcm.gen(ig,PMAX) >= 0
        mpcm.gen(ig,RAMP_AGC) = 5/100 * mpcm.gen(ig,PMAX); % 5% of PMAX(MW) per min
        mpcm.gencost(ig,STARTUP) = 1000 * mpcm.gen(ig,PMAX); % 1000$/MW per startup 
        mpcm.gencost(ig,SHUTDOWN) = 1000 * mpcm.gen(ig,PMAX); % 1000$/MW per shutdown
    else
        error('something wrong with mpc.gen(ig,PMAX)!');
    end
    min_on(ig) = nt;
    min_off(ig) = nt;
end

% 4. hydro, no hydro in this system

% all ramp rates
mpcm.gen(:,RAMP_10) = mpcm.gen(:,RAMP_AGC)*10; % AGC(MW/min)*10min
mpcm.gen(:,RAMP_30) = mpcm.gen(:,RAMP_AGC)*30; % AGC(MW/min)*30min

%% Save cases
% save mpc to .m
savecase([casename,'r.m'], mpcm);

% save min-on and min-off time 
min_on = ceil(min_on / delta_t); min_off = ceil(min_off / delta_t);
save('gendata_ACTIVSg200r.mat','min_on','min_off');
