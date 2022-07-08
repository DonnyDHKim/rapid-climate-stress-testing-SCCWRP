% Modified by Donny Kim. Last update: June, 2022
% Based on January 2021 by Keirnan Fowler, University of Melbourne, fowler.k@unimelb.edu.au

% Integrated framework for rapid climate stress testing on a monthly timestep
% by Keirnan Fowler, Natasha Ballis, Avril Horne, Andrew John, Rory Nathan and Murray Peel

% Licence: CC BY 3.0 - see https://creativecommons.org/licenses/by/3.0/au/


%clear; close all;

% add path to directories with framework code
addpath('..\framework\');
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0; % check if we are in Octave
if isOctave, addpath(genpath('..\framework\octave\')); pkg load statistics; %pkg load tablicious;
end

% start timing the code
tic;

%% load inputs including historic data

% climatic data
addpath(genpath('..\framework\octave\'));
comid_list =csv2cell('..\hist\comid_list.csv')(2:end);
%comid_list = cell2mat(comid_list)
%comid_list(:, comid_list(:,1) == 'comid_20332660')
comid = char(comid_list(1));

precip_monthly = readtable(['..\hist\precip_monthly_', comid(7:end), '.csv']);
T_monthly = readtable(['..\hist\T_monthly_', comid(7:end), '.csv']);
%PET_monthly = readtable('hist\PET_monthly.csv');



% flow data - note, this is not used directly by the framework but is used
% to produce plots that appear in the paper.  The unit of flow varies with
% context.
%flow_monthly.RepresentativeCatchments_mm = readtable('hist\flow_monthly_representative_catchments.csv');
%flow_monthly.ReachInflows_ML = readtable('hist\flow_monthly_reach_inflows.csv');

% store all this data in a single structure
%HistoricData = struct('precip_monthly', precip_monthly, 'T_monthly', T_monthly, 'PET_monthly', PET_monthly, 'flow_monthly', flow_monthly);
HistoricData = struct('precip_monthly', precip_monthly, 'T_monthly', T_monthly);


info = comid_info(comid);  % specify information and settings, including the following:
                        % info.WapabaParSets          Parameter sets for pre-calibrated WAPABA rainfall runoff model - see Supplementary Material ##
                        % info.SubareaDetails         Subarea names, areas, and weightings to use in aggregation of Intrinsic Mode Functions (IMFs) (see function AggregateIMFs)
                        % info.RepCatchDetails        Each subarea has a "representative" catchment.  This table stores the characteristics of these catchments.  See paper Section ## and Supplementary Material ##.
                        % info.FlowConversionFactors  Each reach of the Goulburn River receives inflows from multiple subareas.  This table of factors describes how.  See paper Section ## and Supplementary Material ##.
                        % info.pars                   Other general settings relevant to stochastic climate generation and the way the data is used

% aggregate all data to annual
% note, the results are appended to the existing data structure 'HistoricData'
HistoricData = AggregateToAnnual(HistoricData, info.pars);

info.isOctave = isOctave;
%clearvars -except HistoricData info

%% Split precipitation into high and low frequency using Empirical Mode Decomposition
% use the CEEMDAN algorithm (Complete Ensemble Empirical Mode Decomposition with Adaptive Noise)
% note, the results are appended to the existing data structure 'HistoricData'
disp('Finished loading data.  Starting empirical mode decomposition using CEEMDAN...')
disp('Running CEEMDAN algorithm takes A LOT of time. So be patient and wait for it...')

% set the threshold that determines which IMFs are 'low' and 'high' (see paper, Section ##)
info.LowHighThresh = 2; % IMFs 1 and 2 are high frequency, everything else is low

% run CEEMDAN
% DK: Currently getting all the annual low_freq as 0. This may be due to parameter setting OR short historic data timeperiod
HistoricData = split_high_low_using_CEEMDAN(HistoricData, info); % this step may randomly fail. I am getting LowFreq as 0 all the time.

%% Conduct pre-analysis to inform stochastic generation of the low-frequency component
disp('Done.  Starting pre-analysis for low-frequency component.');
info.LowFreq_PreAnalysis_Outputs = LowFreq_PreAnalysis(HistoricData, info);

%%% Saving HistoricData and info, before perturbation
%%% Note that this
addpath(genpath('..\framework\octave\')) % we already did it, but just to make sure.
save_IntermediateFiles_Clim(HistoricData, info, comid);%%% Loading saved intermediate .mat binary files

[HistoricData, info] = load_IntermediateFiles_Clim(comid);



timing.init = toc;


%%% testing purpose only =================================================================================================
%samples = info.SubareaList';
%temp.A = struct2table(info.LowFreq_PreAnalysis_Outputs.A);
%for i = 1:size(samples, 2);
%	temp.(samples{i}) = struct((info.LowFreq_PreAnalysis_Outputs.(samples{i})));
%  temp.(samples{i}) = struct2table(temp.(samples{i}));
%end
%temp.TS_rand = info.LowFreq_PreAnalysis_Outputs.TS_rand;
%%%%%% testing endes here===============================================================================================

tic;
%% case 2: full stochastic dataset
%  generate a full dataset of stochastic data covering the entire
%  stress testing space, as defined by the axis limits and
%  gradations specified in Table # in the paper.  Whereas the code above
%  placed all the outputs into a single structure (StochPertData), here
%  there are too many so we save them as individual .mat files.

% specify axis gradations
%deltaP_space           = [-0.40 -0.35 -0.30 -0.25 -0.20 -0.15 -0.10 -0.05 0 .05 .10 .15]; % rainfall proportional change "increase 0.1
deltaP_space           = [-0.10 -0.05 0 .05 .10];
%deltaT_space           = [0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0];                             % additional degrees of warming 2.0
deltaT_space           = [0 0.5 1.0 1.5 2.0];

%deltaLowFreqP_space    = [-0.03 -0.015 0 +0.015 +0.03 +0.045 +0.06 +0.075];               % changes n Hurst Coefficient %0
deltaLowFreqP_space    = [0];               % changes n Hurst Coefficient %0
%deltaSeasonality_space = [-0.06 -0.03 0.00 +0.03 +0.06 +0.09 +0.12 +0.15];                % changes in seasonality %0
deltaSeasonality_space = [0];                % changes in seasonality %0
%deltaRRrship_space     = [-50 -43.75 -37.5 -31.25 -25 -18.75 -12.5 -6.25 0 6.25 12.5];    % shift in rainfall runoff relationship
%deltaRRrship_space     = [-15 0];    % shift in rainfall runoff relationship


k = 1; % index to match perturbation parameter-set and TS_P & TS_T
perturbations_save = {};
TS_P_save = {};
TS_T_save = {};
%OutFile_path = ['..\out\out_data\];
%mkdir('..\out\out_data\csv');
mkdir(['..\out\results\', comid, '\']);
deltaRRrship_space = []

addpath('..\framework\');
for deltaP = deltaP_space
    for deltaT = deltaT_space
        for deltaLowFreqP = deltaLowFreqP_space
            for deltaSeasonality = deltaSeasonality_space

                DesiredNumberOfTestRuns = 25;
                if rand() < (DesiredNumberOfTestRuns / (5*5)) % DK: this controls the random sampling. What an odd way though...

                    % run the stochastic data routines
                    disp([num2str(k), " out of target number: ", num2str(DesiredNumberOfTestRuns)]);
                    DataOut = GetStochPertData(deltaP, deltaT, deltaLowFreqP, deltaSeasonality, HistoricData, info); %DonnyKim: May be we could try to get rid of deltaRRrship_space afterall.).
                    disp('Perturbation complete, saving .mat binary and CSV files');

					          % DK: Saving selected perturbation parameters with indexing. It will be a single CSV file.
					          temp = {k, deltaP, deltaT, deltaLowFreqP, deltaSeasonality};
					          perturbations_save = vertcat (perturbations_save, temp);
                    TS_P_save = [TS_P_save, table2cell(DataOut.TS_P)(:,3)];
                    TS_T_save = [TS_T_save, table2cell(DataOut.TS_T)(:,3)];


                    %SaveClimate_Octave(DataOut, deltaP, deltaT, deltaLowFreqP, deltaSeasonality, info, k, comid);

                    % save to file. DK: in our case, both .mat and .csv files (total number of files = i*2)
                    k = k+1;
                    % *note, to save disc space the user could alter this to only save one copy of the climate inputs at this point, and then
                    %  a separate file for each deltaRRrship.

                end
            end
        end
    end
end
colnames = {'Year', 'Month'};
for i = 1:k-1
  colnames = [colnames, i];
end

TS_P_save = [table2cell(DataOut.TS_P)(:,1:2), TS_P_save]; TS_P_save = vertcat(colnames, TS_P_save);
TS_T_save = [table2cell(DataOut.TS_T)(:,1:2), TS_T_save]; TS_T_save = vertcat(colnames, TS_T_save);
cell2csv (['..\out\results\', comid ,'\TS_P.csv'], TS_P_save);
cell2csv (['..\out\results\', comid ,'\TS_T.csv'], TS_T_save);
cell2csv (['..\out\results\', comid ,'\perturbations_save.csv'], perturbations_save); % Writing perturbation parameters into actual CSV.


reshape(1:25, 1, 25)
x= [{'Year', 'Month'}, reshape(1:25, 1, 25)]

timing.case2_stochgen = toc;

%% report back on timing
disp('All done.  Run times were:')
disp('Initialisation including data loading and low frequency pre-analysis: ')
disp([num2str(timing.init) ' seconds. ']);
%disp('Stochastic generation for case 1')
%disp([num2str(timing.case1_stochgen) ' seconds. ']);
%disp('Plotting for case 1')
%disp([num2str(timing.plotting) ' seconds. ']);
disp('Stochastic generation for case 2')
disp([num2str(timing.case2_stochgen) ' seconds. ']);
