
function [DataOut, extra] = GetStochPertData(deltaP, deltaT, deltaLowFreqP, deltaSeasonality, HistoricData, info)

	% DK: deltaRRrship input is removed; GetStochPertData(deltaP, deltaT, deltaLowFreqP, deltaSeasonality, deltaRRrship, HistoricData, info)
    % NOTE: input 'deltaRRrship' can be a single value, or a vector.  In either case the stochastic 
    % climate generation is run only once.  This reflects that the stochastic climate generation
    % tasks do not depend on deltaRRrship and thus it is a waste of effort to rerun them for each new   
    % value.  In contrast, the flow perturbation code is run either once (in the case of line 82) or 
    % multiple times in the case of a vector (once for each value in the vector).   
    
    % run stochastic climate generation and perturbation.  This also provides unperturbed flow.
	if strcmp(fieldnames(HistoricData), 'PET_monthly') == 1
		%disp('Stochastic generation & perturbation of P, T, and PET')
		[TS_P, TS_T, TS_PET, extra] = GetSingleReplicate_clim(deltaP, deltaT, deltaLowFreqP, deltaSeasonality, HistoricData, info);
		DataOut = struct('TS_P', TS_P, 'TS_T', TS_T, 'TS_PET', TS_PET); % new DataOut
	else
		disp('Stochastic generation & perturbation of P and T')
		[TS_P, TS_T, ~, extra] = GetSingleReplicate_clim(deltaP, deltaT, deltaLowFreqP, deltaSeasonality, HistoricData, info);
		DataOut = struct('TS_P', TS_P, 'TS_T', TS_T); % new DataOut
	end
	% DK: original function;
	% [TS_Q_unpert, TS_P, TS_T, TS_PET, ~, extra] = GetSingleReplicate_clim(deltaP, deltaT, deltaLowFreqP, deltaSeasonality, HistoricData, info); % Interesting that "TS_SoilMoisture" was already unused (~ = NULL).
	% TS_Q_unpert removed, as GetSingleReplicate_clim is modified.

    	
	% DK: getting rid of use of deltaRRrship and eliminate rainfall-runoff model usage.
    % now, get perturbed flow
    %if size(deltaRRrship, 2) == 1
    %    % in the case where a single deltaRRrship value is provided, just run once for this value
    %    TS_Q_pert = ChangeRRrship(TS_Q_unpert, deltaRRrship, info); % shift flow in each subarea's representative catchment
    %    TS_Q_ReachInflows = ConvertFlows(TS_Q_pert, info); % aggregate flow from different subareas up to reach scale
    %    DataOut = struct('TS_Q_ReachInflows', TS_Q_ReachInflows, 'TS_Q_ReprCatchments', TS_Q_pert, ... % note the renaming of 'TS_Q_pert' to 'TS_Q_ReprCatchments'
    %        'TS_P', TS_P, 'TS_T', TS_T, 'TS_PET', TS_PET); 
    %else
    %    % in the case where deltaRRrship is a vector, run multiple times, one for each value
    %    for i = 1:size(deltaRRrship, 2) % 1:to number of deltaRRrship values in deltaRRrship_space
    %        TS_Q_pert = ChangeRRrship(TS_Q_unpert, deltaRRrship(i), info); 
    %        TS_Q_ReachInflows = ConvertFlows(TS_Q_pert, info); 
    %        DataOut.(['deltaRRrship' num2str(i)]) = struct('TS_Q_ReachInflows', TS_Q_ReachInflows, 'TS_Q_ReprCatchments', TS_Q_pert, ... 
    %            'TS_P', TS_P, 'TS_T', TS_T, 'TS_PET', TS_PET);             
    %    end
    %end
	
    
end
