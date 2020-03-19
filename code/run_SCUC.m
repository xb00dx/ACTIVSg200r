clear; clc; close all;

define_constants;
casename = 'case_ACTIVSg200r';
% casepath = '../system/ACTIVSg200/';

%% Raw Settings
% mpc = loadcase([casepath,casename]);
% xgd = loadxgendata([casepath,'xgd_ACTIVSg200r'], mpc);
% scenarios = scenarios_ACTIVSg200; % get a change table
% load([casepath,'scenarios.mat']); % exactly the same data as `scenarios_ACTIVSg200.m`

mpc = loadcase(casename);
xgd = loadxgendata('xgd_ACTIVSg200r', mpc);
load('scenarios.mat'); % exactly the same data as `scenarios_ACTIVSg200.m`

nb = size(mpc.bus, 1); nl = size(mpc.branch, 1); ng = size(mpc.gen, 1);
nt = 24; % 24 hours
ns = 365; % 365 days
area_ind = 2:7;
na = length(area_ind); % 6 areas

load_dat = reshape(scenarios(:,end),na, ns*nt);
figure;
plot(sum(load_dat,1)), hold on,
plot(1:ns*nt, sum(mpc.gen(:,PMAX))*ones(ns*nt,1),'r-')

mpopt = mpoption('out.all',1);
mpopt = mpoption(mpopt,'verbose',3); % to see the intermediate output of GUROBI
mpopt = mpoption(mpopt, 'gurobi.threads', 4);
mpopt = mpoption(mpopt, 'gurobi.opts.MIPGap', 1e-2); % gap <= 1%
% mpopt = mpoption(mpopt, 'gurobi.opts.MIPGapAbs', 0);
mpopt = mpoption(mpopt, 'most.skip_prices', 1); % no price computation for UC
% mpopt = mpoption(mpopt, 'most.grb_opt.timelimit',60); % time-limit = 60 seconds
mpopt = mpoption(mpopt,'most.uc.run',1); % perform UC regardless of mdo.UC.CommitKey
% have_linelimit = 1; % 0:w/o-network; 1:w/-network,w/o-contingecy; 2: w/-network, w/-contingency
mpopt = mpoption(mpopt,'most.dc_model', 1); % consider DC line flow constraints

f_uc = figure;
% error_list = [];
% input
settings(1).area_load = zeros(na,nt);
% output
results(1).dispatch = zeros(ng,nt); results(1).commitment = zeros(ng,nt);
% results(1).flow = zeros(nl,nt);
results(1).obj = -1;
results(1).solver_output = [];
results(1).mdo = []; % save everything just in case
for day = 1:ns
    % generate load profiles
    indices = (1:nt*na) + (day-1)*nt*na;
    load_data = scenarios(indices, end); % last column: loads of 6 areas
    area_load1 = reshape(load_data, na, nt)'; % nt-by-na matrix
    area_load1 = area_load1;
    profiles = struct( ...
        'type', 'mpcData', ...
        'table', CT_TAREALOAD, ...
        'rows', area_ind, ...
        'col', CT_LOAD_ALL_P, ...
        'chgtype', CT_REP, ...
        'values', [] );
    profiles.values(:, 1, :) = area_load1;
    
    % Construct MOST struct
    mdi = loadmd(mpc, nt, xgd, [], [], profiles);
    
    % Set initial status
    if day == 1
%         init = load('ACTIVSg200r-InitialState.mat');
%         mdi.UC.InitialState = init.InitialState;
%         mdi.InitialPg = init.InitialPg;
        assert(~isempty(mdi.UC.InitialState));
    else
        mdi.UC.InitialState = mdo.UC.CommitSched(:,end);% set initial status as the end results of last day
    end

    %% Solve SCUC
%     try
    mdo = most(mdi, mpopt);
    ms = most_summary(mdo);
    assert(mdo.results.success == 1);
    dispatch_profile = sum(mdo.results.ExpectedDispatch,1);
    test_load = sum(area_load1,2)';
    assert(norm(dispatch_profile-test_load,inf) <= 1e-3);
    plot_uc(mdo);
%     catch
%         error_list = [error_list, t];
%     end
    
    % save results
    results(day).dispatch = mdo.results.ExpectedDispatch;
    results(day).commitment = mdo.UC.CommitSched;
%     results(1).flow = zeros(nl,nt);
    results(day).obj = mdo.results.f;
    results(day).solver_output = mdo.QP.output; % all information, gap, bounds, status, itercount
    results(day).mdo = mdo;
    
    settings(day).area_load = squeeze(profiles.values)';
    settings(day).cost = mpc.gencost(:,end-1);
end


%% save results
% output
% optimal solution
    % commitment ns.(ng-nt)
    % dispatch ns.(ng-nt)
    % line flow ns.(nl-nt)
    % obj value ns.(1)
    % obj break down ns.(no-nt) (not yet)
    % critical contingency (not yet)
% quality of solution:
    % computation time, gap, lower bound
    % all in results(day).solver_output
% input
% (area)load sceanrios ns-nd-nt
% cost cofficients ns-ng-nt


% info = 'case ACTIVSg200r: no network considered, no contingencies considered. GUROBI solves till gap <= 1%';
% save('ACTIVSg200r-results-NoNetwork.mat','info', 'results','settings');

info = 'case ACTIVSg200r: DC network is being considered, no contingencies considered. GUROBI solves till gap <= 1%';
save('ACTIVSg200r-results-NoCont.mat','info', 'results','settings');
