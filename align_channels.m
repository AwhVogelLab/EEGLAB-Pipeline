function [EEG] = align_channels(EEG, transform)
    
    % Realign channels for inspection.  

    if transform 
        flip_bool= 1;
    else
        flip_bool = -1;
    end
    
    % Move EOG channels above EEG
    eog_idx = ismember({EEG.chanlocs.labels},{'EOG','VEOG','HEOG'});
    EEG.data(eog_idx,:,:) = EEG.data(eog_idx,:,:) + 200*flip_bool;
    
    % Move eyetracking channels below EEG
    eye_idx = ismember({EEG.chanlocs.labels},{'GAZE-Y','GAZE-X','L_GAZE_X','L_GAZE_Y','R_GAZE_X','R_GAZE_Y'});
    EEG.data(eye_idx,:,:) = EEG.data(eye_idx,:,:) - 300*flip_bool;
    
    % Move stimtrak to the top
    stim_idx = ismember({EEG.chanlocs.labels},{'StimTrak'});
    EEG.data(stim_idx,:,:) = EEG.data(stim_idx,:,:) + 300*flip_bool;
    
end