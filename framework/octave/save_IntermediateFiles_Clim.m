### Written by Donny Kim (dkim8398@sdsu.edu or donnykim27@gmail.com) in June, 2022
### Gegraphy Department, San Diego State University

function save_IntermediateFiles_Clim(HistoricData, info, comid)
    
    % Determine the platform-specific directory separator
    if ispc()
        separator = '\';  % Windows uses backward slashes
    else
        separator = '/';  % Linux and macOS use forward slashes
    end

    % Set OutFile_path
    OutFile_path = ['..', separator, 'out', separator, comid, separator, 'intermediate'];
    mkdir(OutFile_path);

    
    % Saving HistoricData as .mat binary
    if strcmp(fieldnames(HistoricData), 'PET_monthly') == 1
        HistoricData2 = struct('precip_monthly', table2struct(HistoricData.precip_monthly),...
                        'T_monthly', table2struct(HistoricData.T_monthly),...
                        'PET_monthly', table2struct(HistoricData.PET_monthly),...
                        'precip_annual', table2struct(HistoricData.precip_annual),...
                        'T_annual', table2struct(HistoricData.T_annual),...
                        'PET_annual', table2struct(HistoricData.PET_annual),...
                        'precip_annual_IMFs', HistoricData.precip_annual_IMFs,...
                        'precip_ann_HighFreq', table2struct(HistoricData.precip_ann_HighFreq),...
                        'precip_ann_LowFreq', table2struct(HistoricData.precip_ann_LowFreq)
                        );
    else
        HistoricData2 = struct('precip_monthly', table2struct(HistoricData.precip_monthly),...
                        'T_monthly', table2struct(HistoricData.T_monthly),...
                        'precip_annual', table2struct(HistoricData.precip_annual),...
                        'T_annual', table2struct(HistoricData.T_annual),...
                        'precip_annual_IMFs', HistoricData.precip_annual_IMFs,...
                        'precip_ann_HighFreq', table2struct(HistoricData.precip_ann_HighFreq),...
                        'precip_ann_LowFreq', table2struct(HistoricData.precip_ann_LowFreq)
                        );
    end
        
    save([OutFile_path, separator, 'HistoricData.mat'], 'HistoricData2');
    disp('Intermediate file saved: HistoricData as .mat binary.')


    % Saving precip_ann_HighFreq, and precip_ann_LowFreq from HistoricData into csv files
    precip_ann_HighFreq = preprocess_table2csv(HistoricData.precip_ann_HighFreq, "precip_ann_HighFreq");
    precip_ann_LowFreq = preprocess_table2csv(HistoricData.precip_ann_LowFreq, "precip_ann_LowFreq");
    precip_ann_HiLoFreq = [precip_ann_LowFreq, precip_ann_HighFreq(:, 2)];
    cell2csv([OutFile_path, separator, 'HiLoFreq_Comps.csv'], precip_ann_HiLoFreq);
    %cell2csv(['..', separator, 'out', separator, 'intermediate', separator, 'PrePerturbation_Hi_Freq_Comps.csv'], precip_ann_HighFreq);
    %cell2csv(['..', separator, 'out', separator, 'intermediate', separator, 'PrePerturbation_Lo_Freq_Comps.csv'], precip_ann_LowFreq);
    disp('Intermediate file saved: precip_ann_HighFreq and precip_ann_LowFreq as single CSV.')


    % Saving info as .mat binary
    samples = info.SubareaList';
    for i = 1:size(info.SubareaList, 1);
        temp.(samples{i}) = struct(table2struct(info.LowFreq_PreAnalysis_Outputs.(samples{i})));
    end
    temp.TS_rand = info.LowFreq_PreAnalysis_Outputs.TS_rand;
    
    info2 = struct('SubAreaDetails', table2struct(info.SubAreaDetails),...
                'pars', info.pars,...
                %'SubareaList', info.SubareaList,...
                'isOctave', info.isOctave,...
                'LowHighThresh', info.LowHighThresh,...
                'LowFreq_PreAnalysis_Outputs', temp
                );
    info2.SubareaList = info.SubareaList; % I don't know why, but if you don't append like this, info becomes 7x1 struct
    %save(['..', separator, 'out', separator, 'intermediate', separator, 'preperturbation_info.mat'], 'info2')
    save([OutFile_path, separator, 'info.mat'], 'info2')
    disp('Intermediate file saved: info as .mat binary.')

    
    % Saving LowFreq_PreAnalysis_Outputs from info & precip_annual_IMFs from HistoricData into a csv file
    if size(info.SubareaList, 1) == 1
        cell2csv([OutFile_path, separator, 'LoFreq_PreAnalysis.csv'],...
        preprocess_table2csv(info.LowFreq_PreAnalysis_Outputs.(comid), (comid))
        );
        csvwrite([OutFile_path, separator, 'P_annual_IMFs.csv'], HistoricData.precip_annual_IMFs.(comid))
    else
        for i = 1:size(info.SubareaList, 1)
            cell2csv([OutFile_path, separator, 'LoFreq_PreAnalysis_', samples{i}, '.csv'],...
            preprocess_table2csv(info.LowFreq_PreAnalysis_Outputs.(samples{i}), samples{i})
            );
            csvwrite([OutFile_path, separator, 'P_annual_IMFs.csv'], HistoricData.precip_annual_IMFs.(samples{i}))
        end
    disp('Intermediate file saved: LowFreq_PreAnalysis_Outputs from info as CSV.')
    end

    
end


function output = preprocess_table2csv(table, TS_name)
    
    
    % converting table to cell, and then appending TS_name and VariableNames(colnames) on top two rows of the cell.
    x = table2cell(table);
    y = table.Properties.VariableNames;
    y2 = [repmat({TS_name}, [1, size(y, 2)])];
    output = vertcat(y2, y, x);
    
    
end
