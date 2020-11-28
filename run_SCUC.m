clear; clc; close all;

%% Run SCUC for the revised ACTIVSg200 system (`case_ACTIVSg200r.m`)
%   Using GUROBI as solver
%   See https://github.com/xb00dx/ACTIVSg200r for more infor about ACTIVSg200r.
%   Created by X. Geng (03/14/2020)

define_constants;
casename = 'case_ACTIVSg200r';
casepath = './';

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
% mpopt = mpoption(mpopt, 'gurobi.opts.timeLimit',60*20); % time-limit = 20 minutes
mpopt = mpoption(mpopt,'most.uc.run',1); % perform UC regardless of mdo.UC.CommitKey
mpopt = mpoption(mpopt,'most.dc_model', 1); % consider DC line flow constraints

f_uc = figure;
for day = 1:ns
    % generate load profiles
    indices = (1:nt*na) + (day-1)*nt*na;
    load_data = scenarios(indices, end); % last column: loads of 6 areas
    area_load = reshape(load_data, na, nt)'; % nt-by-na matrix
    profiles = struct( ...
        'type', 'mpcData', ...
        'table', CT_TAREALOAD, ...
        'rows', area_ind, ...
        'col', CT_LOAD_ALL_P, ...
        'chgtype', CT_REP, ...
        'values', [] );
    profiles.values(:, 1, :) = area_load;
    
    % Construct MOST struct
%     mdi = loadmd(mpc, transmat, xgd, [], 'ex_contab', profiles); % WITHOUT contingency
    mdi = loadmd(mpc, nt, xgd, [], 'contab_ACTIVSg200.m', profiles); % WITH contingency, warning: super slow to construct the problem structure
    
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
%         disp(['sth wrong on day ',num2str(day)]);
%     end
end

