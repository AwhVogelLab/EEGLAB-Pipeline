%% Read Me
% This script runs the automatic preprocessing and artifact rejection
% pipeline of EEG data from the AwhVogelLab.
%
% Contributors: William Thyer, Henry Jones, William XQ Ngiam.
%
% Last edit: WXQN added support for ignoring known noisy electrodes.

%% Setup
clearvars
eeglab

%% Options

subjectParentDir = 'test_data';
subjectDirectories = {'6'};  % optionally {} for recursive search
noEyetracking = {};  %list all subjects who don't have ET data
doEogRejection = {}; %no EOG rejection by default, add subjects to do EOG rejection (usually those who don't have ET data).

lowboundFilterHz = 0.01;
highboundFilterHz = 30;

rerefType = 'mastoid'; % 'none', 'average', or 'mastoid' 
rerefExcludeChans = {'HEOG', 'VEOG', 'StimTrak'};
noisyElectrodes = {}; % add channel names of noisy electrodes to be ignored in artifact rejection (e.g. {'FC2'})
customEquationList = '';  % optional

EYEEEGKeyword = 'sync';
startEvent = 21;
endEvent = 21;
eyeRecorded = 'left';  % 'both', 'left', or 'right'

binlistFile = '';  % if empty, will create one for you
timelockCodes = [11 12 13 14];  % codes to timelock to
trialStart = -200;
trialEnd = 1250;
baselineStart = -200;
baselineEnd = 0;
rejectionStart = -200;
rejectionEnd = 1250;

eegResampleRate = 500; %hz
eegResample = true;

distFromScreen = 738; %mm
monitorWidth = 532;  %mm
monitorHeight = 300;  %mm
screenResX = 1920;  %px
screenResY = 1080;  %px

eyeDistThresh = 1;  %deg
eyeSaccadeThresh = .5;  %deg
eyeSaccadeWindow = 80; %ms
eyeSaccadeStep = 10; %ms

eogThresh = 50; %microv
eogSaccadeThresh = 20;  %microv
eogSaccadeWindow = 150; %ms
eogSaccadeStep = 10; %ms

eegAbsThresh = 100; %microv
eegNoiseThresh = 75; %microv 
eegStepThresh = 60; % microvolts
eegStepWin = 250; %ms
eegStepShift = 20; % ms
eegMinSlope = 75; %minimal absolute slope of the linear trend of the activity for rejection
eegMinR2 = 0.3; %minimal R^2 (coefficient of determination between 0 and 1)

rejFlatline = true; %remove trials with any flatline data
%% Setup 

% Find all .vhdr files recursively if subjectDirectories is empty
if isempty(subjectDirectories)
    dirs = dir(subjectParentDir);
    for i=1:numel(dirs)
        d = dirs(i).name;
        if strcmp(d, '.') ||  strcmp(d, '..')
            continue
        end
        
        if ~isempty(dir(fullfile(subjectParentDir, d, '*.vhdr')))
            subjectDirectories{end+1} = d; %#ok<SAGROW>
        end
    end
end

log = fopen('log.txt', 'a+t');
fprintf(log, ['Run started: ', datestr(now), '\n\n']);

[GazeDistThresh_x, GazeDistThresh_y] = calcdeg2pix(eyeDistThresh, distFromScreen, monitorWidth, monitorHeight, screenResX, screenResY);
[GazeSaccadeThresh_x, GazeSaccadeThresh_y] = calcdeg2pix(eyeSaccadeThresh, distFromScreen, monitorWidth, monitorHeight, screenResX, screenResY);
%% Main loop

for subdir=1:numel(subjectDirectories)
    subject_number = subjectDirectories{subdir};
    subdirPath = fullfile(subjectParentDir, subject_number);
    
    disp(['Running ', subdirPath])
    fprintf(log, ['Running ', subdirPath, '\n\n']);
    
    vhdrDir = dir(fullfile(subdirPath, '*.vhdr'));
    
    if numel(vhdrDir) == 0
        warning(['Skipping ', subjectDirectories{subdir}, '. No vhdr file found.'])
        fprintf(log, ['Skipping ', subjectDirectories{subdir}, '. No vhdr file found.\n\n']);
        continue
    elseif numel(vhdrDir) > 1
        warning(['Skipping ', subjectDirectories{subdir}, '. More than one vhdr file found.'])
        fprintf(log, ['Skipping ', subjectDirectories{subdir}, '. More than one vhdr file found.\n\n']);
        continue
    end
    
    vhdrFilename = vhdrDir(1).name;
    
    ascDir = dir(fullfile(subdirPath, '*.asc'));
    
    if numel(ascDir) == 0
        warning(['Skipping ', subjectDirectories{subdir}, '. No asc file found.'])
        fprintf(log, ['Skipping ', subjectDirectories{subdir}, '. No vhdr file found.\n\n']);
        continue
    elseif numel(ascDir) > 1
        warning(['Skipping ', subjectDirectories{subdir}, '. More than one asc file found.'])
        fprintf(log, ['Skipping ', subjectDirectories{subdir}, '. More than one asc file found.\n\n']);
        continue
    end
    
    ascFullFilename = fullfile(subdirPath, ascDir(1).name);

    EEG = pop_loadbv(subdirPath, vhdrFilename);
    
    EEG.setname = vhdrFilename(1:end-5);
    
    if eegResample
        EEG = pop_resample(EEG,eegResampleRate);
    end
    
    if lowboundFilterHz ~= 0 && highboundFilterHz ~= 0
        fprintf(log, sprintf('Bandpass filtering with lowboundFilterHz = %f and highboundFilterHz=%f\n\n', lowboundFilterHz, highboundFilterHz));
        EEG = pop_basicfilter(EEG, 1:EEG.nbchan, 'Boundary', 'boundary', 'Cutoff', [lowboundFilterHz highboundFilterHz], 'Design', 'butter', 'Filter', 'bandpass', 'Order', 2);
    elseif highboundFilterHz ~= 0
        fprintf(log, sprintf('Lowpass filtering with highboundFilterHz=%f\n\n', highboundFilterHz));
        EEG = pop_basicfilter(EEG, 1:EEG.nbchan, 'Boundary', 'boundary', 'Cutoff', highboundFilterHz, 'Design', 'butter', 'Filter', 'lowpass', 'Order', 2);
    elseif lowboundFilterHz ~= 0
        fprintf(log, sprintf('Highpass filtering with lowboundFilterHz = %f\n\n', lowboundFilterHz));
        EEG = pop_basicfilter(EEG, 1:EEG.nbchan, 'Boundary', 'boundary', 'Cutoff', lowboundFilterHz, 'Design', 'butter', 'Filter', 'highpass', 'Order', 2);
    end
    
    if ~strcmp(rerefType, 'none')
        if ~strcmp(customEquationList, '')
            equationList = customEquationList;
        else
            equationList = get_chan_equations(EEG, rerefType, rerefExcludeChans);
        end
        
        fprintf(log, 'Rereferencing with following equation list:\n');
        fprintf(log, strjoin(equationList, '\n'));
        fprintf(log, '\n\n');
        
        EEG = pop_eegchanoperator( EEG, equationList);
    else
        fprintf(log, 'Skipping rereferencing because rerefType = "none"\n\n');
    end
    
    EYEEEGMatFilename = [ascFullFilename(1:end-4) '_eye.mat'];
    
    fprintf(log, sprintf('Parsing asc file: %s\n\n', ascFullFilename));
    parseeyelink(ascFullFilename, EYEEEGMatFilename, EYEEEGKeyword);

    diary 'log.txt'
    if strcmp(eyeRecorded, 'both')
        EEG = pop_importeyetracker(EEG, EYEEEGMatFilename, [startEvent endEvent], [2 3 5 6], {'L_GAZE_X' 'L_GAZE_Y' 'R_GAZE_X' 'R_GAZE_Y'}, 0, 1, 0, 0);
    else
        EEG = pop_importeyetracker(EEG, EYEEEGMatFilename, [startEvent endEvent], [2 3], {'GAZE-X' 'GAZE-Y'}, 0, 1, 0, 0);
    end
    diary off

    EEG = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'}, 'Warning', 'off');
    
    if isempty(binlistFile)
        make_binlist(subdirPath, timelockCodes)
        binlistFile = fullfile(subdirPath, 'binlist.txt');
    end
    
    EEG = pop_binlister(EEG, 'BDF', binlistFile);
    EEG = pop_epochbin(EEG, [trialStart, trialEnd], sprintf('%d %d', baselineStart, baselineEnd));

    % Perform artifact rejection
    allChanNumbers = 1:EEG.nbchan;
    
    %EYETRACKING ARTIFACT REJECTION
    if ~any(strcmp(noEyetracking,subject_number)) %if the subject has eyetracking
        if strcmp(eyeRecorded, 'both')
            % CHECKING FOR DRIFT IN BOTH EYES
            % x-direction
            EEG_x_left = pop_artextval(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'L_GAZE_X'})), 'Flag',  1, 'Threshold', [-GazeDistThresh_x GazeDistThresh_x], 'Twindow', [rejectionStart rejectionEnd]);
            EEG_x_right = pop_artextval(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'R_GAZE_X'})), 'Flag',  1, 'Threshold', [-GazeDistThresh_x GazeDistThresh_x], 'Twindow', [rejectionStart rejectionEnd]);
            x_drift_reject = EEG_x_left.reject.rejmanual .* EEG_x_right.reject.rejmanual;
            sprintf('x-drift rejection: %i', sum(x_drift_reject))
            % y-direction
            EEG_y_left = pop_artextval(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'L_GAZE_Y'})), 'Flag',  1, 'Threshold', [-GazeDistThresh_y GazeDistThresh_y], 'Twindow', [rejectionStart rejectionEnd]);
            EEG_y_right = pop_artextval(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'R_GAZE_Y'})), 'Flag',  1, 'Threshold', [-GazeDistThresh_y GazeDistThresh_y], 'Twindow', [rejectionStart rejectionEnd]);
            y_drift_reject = EEG_y_left.reject.rejmanual .* EEG_y_right.reject.rejmanual;
            
            sprintf('y-drift rejection: %i', sum(y_drift_reject))
            drift_reject = x_drift_reject | y_drift_reject;
            
            % CHECKING FOR SACCADES IN BOTH EYES
            % x-direction
            EEG_x_left = pop_artstep(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'L_GAZE_X'})), 'Flag',  1, 'Threshold', GazeSaccadeThresh_x, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eyeSaccadeWindow, 'Windowstep', eyeSaccadeStep);
            EEG_x_right = pop_artstep(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'R_GAZE_X'})), 'Flag',  1, 'Threshold', GazeSaccadeThresh_x, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eyeSaccadeWindow, 'Windowstep', eyeSaccadeStep);
            x_saccade_reject = EEG_x_left.reject.rejmanual .* EEG_x_right.reject.rejmanual;
            sprintf('x-saccade rejection: %i', sum(x_saccade_reject))
            % y-direction
            EEG_y_left = pop_artstep(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'L_GAZE_Y'})), 'Flag',  1, 'Threshold', GazeSaccadeThresh_y, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eyeSaccadeWindow, 'Windowstep', eyeSaccadeStep);
            EEG_y_right = pop_artstep(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'R_GAZE_Y'})), 'Flag',  1, 'Threshold', GazeSaccadeThresh_y, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eyeSaccadeWindow, 'Windowstep', eyeSaccadeStep);
            y_saccade_reject = EEG_y_left.reject.rejmanual .* EEG_y_right.reject.rejmanual;
            sprintf('y-saccade rejection: %i', sum(y_saccade_reject))
            saccade_reject = x_saccade_reject | y_saccade_reject;
            
            % COMBINE DRIFT & SACCADE REJECTIONS
            eye_reject = drift_reject | saccade_reject;
            EEG.reject.rejmanual = eye_reject;
        
            % ADD CHANNEL SPECIFIC FLAGS FOR VISUALIZING
            EEG.reject.rejmanualE(allChanNumbers(ismember({EEG.chanlocs.labels}, {'L-GAZE-X', 'R-GAZE-X'})), :) = repmat(x_drift_reject | x_saccade_reject, 2,1);
            EEG.reject.rejmanualE(allChanNumbers(ismember({EEG.chanlocs.labels}, {'L-GAZE-Y', 'R-GAZE-Y'})), :) = repmat(y_drift_reject | y_saccade_reject, 2,1);
            
        else
            % CHECKING FOR DRIFT
            EEG = pop_artextval(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'GAZE-X'})), 'Flag',  1, 'Threshold', [-GazeDistThresh_x GazeDistThresh_x], 'Twindow', [rejectionStart rejectionEnd]);
            EEG = pop_artextval(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'GAZE-Y'})), 'Flag',  1, 'Threshold', [-GazeDistThresh_y GazeDistThresh_y], 'Twindow', [rejectionStart rejectionEnd]);
            
            % CHECKING FOR SACCADES
            EEG = pop_artstep(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'GAZE-X'})), 'Flag',  1, 'Threshold', GazeSaccadeThresh_x, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eyeSaccadeWindow, 'Windowstep', eyeSaccadeStep);
            EEG = pop_artstep(EEG , 'Channel',  allChanNumbers(ismember({EEG.chanlocs.labels}, {'GAZE-Y'})), 'Flag',  1, 'Threshold', GazeSaccadeThresh_y, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eyeSaccadeWindow, 'Windowstep', eyeSaccadeStep);
        end
    end
    
    %EOG ARTIFACT REJECTION
    if any(strcmp(doEogRejection,subject_number)) %if you want to do EOG rejection
        eogIDX = allChanNumbers(ismember({EEG.chanlocs.labels}, {'HEOG','VEOG'}));    
        %flags trials where absolute EOG value is greather than eogThresh
        EEG = pop_artextval(EEG , 'Channel',  eogIDX, 'Flag',  2, 'Threshold', [-eogThresh eogThresh], 'Twindow', [rejectionStart rejectionEnd]);
        EEG = pop_artstep(EEG , 'Channel',  eogIDX, 'Flag',  2, 'Threshold', eogSaccadeThresh, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eogSaccadeWindow, 'Windowstep', eogSaccadeStep);
    end
    
    %EEG ARTIFACT REJECTION
    eegIDX = allChanNumbers(~ismember({EEG.chanlocs.labels}, {'L_GAZE_X','L_GAZE_Y','R_GAZE_X','R_GAZE_Y','GAZE-X','GAZE-Y','HEOG','VEOG','StimTrak'}));
    
    % Ignore known noisy electrodes in rejection pipeline.
    if ~isempty(noisyElectrodes)
        whichChansToExclude = find(strcmp(noisyElectrodes,{EEG.chanlocs.labels}));
        eegIDX(whichChansToExclude) = []; % Removes channel number of noisy electrode from index of to-be-analyzed channels.
    end
    
    %flags trials where absolute EEG value is greater than eegAbsThresh
    EEG = pop_artextval(EEG , 'Channel',  eegIDX, 'Flag',  3, 'Threshold', [-eegAbsThresh eegAbsThresh], 'Twindow', [rejectionStart rejectionEnd]);
    %flags trials where EEG peak to peak activity within moving window is greater than eegNoiseThresh 
    EEG  = pop_artmwppth( EEG , 'Channel',  eegIDX, 'Flag',  4, 'Threshold', eegNoiseThresh, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', 200, 'Windowstep', 100); 
    %flags trials containing step-like activity that is greater than eegStepThresh
    EEG  = pop_artstep( EEG , 'Channel',  eegIDX, 'Flag',  4, 'Threshold', eegStepThresh, 'Twindow', [rejectionStart rejectionEnd], 'Windowsize', eegStepWin, 'Windowstep', eegStepShift); 
    %flags trials where line fit to EEG has a slope above a certain threshold. Good for catching linear trends.
    EEG = pop_rejtrend(EEG, 1, eegIDX, EEG.pnts, eegMinSlope, eegMinR2, 0, 0);
    
    %flags trials where any channel has flatlined completely (usually eyetracking)
    if rejFlatline
        if ~any(strcmp(noEyetracking,subject_number)) %if sub has eyetracking, reject flatline eyetracking
                flatlineIDX = allChanNumbers(~ismember({EEG.chanlocs.labels}, {'StimTrak','HEOG','VEOG'}));
                EEG  = pop_artflatline(EEG , 'Channel', flatlineIDX, 'Duration',  200, 'Flag', 5, 'Threshold', [0 0], 'Twindow', [rejectionStart rejectionEnd]);
            % Ignore known noisy electrodes in rejection pipeline
            if ~isempty(noisyElectrodes)
                whichChansToExclude = find(strcmp(noisyElectrodes,{EEG.chanlocs.labels}));
                flatlineIDX(whichChansToExclude) = [];  % Removes channel number of noisy electrode from index of to-be-analyzed channels.
            end
        end
        if any(strcmp(noEyetracking,subject_number)) %if sub does not have eyetracking, don't reject flatline eyetracking
            flatlineIDX = allChanNumbers(~ismember({EEG.chanlocs.labels}, {'StimTrak','HEOG','VEOG','GAZE-X','GAZE-Y'}));
            % Ignore known noisy electrodes in rejection pipeline
            if ~isempty(noisyElectrodes)
                whichChansToExclude = find(strcmp(noisyElectrodes,{EEG.chanlocs.labels}));
                flatlineIDX(whichChansToExclude) = [];  % Removes channel number of noisy electrode from index of to-be-analyzed channels.
            end
            EEG  = pop_artflatline(EEG , 'Channel', flatlineIDX, 'Duration',  200, 'Flag', 5, 'Threshold', [0 0], 'Twindow', [rejectionStart rejectionEnd]);
        end    
    end
    
    %syncs rejection flags for ERPLAB and EEGLAB functions
    EEG = pop_syncroartifacts(EEG,'Direction' ,'bidirectional');
    
    EEG = pop_saveset(EEG, 'filename', fullfile(subdirPath, [vhdrFilename(1:end-5) '_unchecked.set']));
end

%% Clean up
eeglab redraw;


fclose(log);

%% Helper Functions

function equationList = get_chan_equations(EEG, rerefType, excludes)
    if ~any(strcmp({'mastoid', 'average'}, rerefType))
        error('rerefType must be "mastoid" or "average"')
    end

    baseEquation = 'ch%d = ch%d - (%s) Label %s';
    
    allLocs = {EEG.chanlocs.labels};
    
    includedChanLabels = allLocs;
    includedChanLabels(ismember(allLocs, excludes)) = [];
    [~, includedChanIndexes] = ismember(includedChanLabels, allLocs);
    
    equationList = {};
  
    if strcmp(rerefType, 'average')
        equationString = sprintf('avgchan(%s)', mat2colon(includedChanIndexes));
    else
        refIdx = find(strcmp({EEG.chanlocs.labels}, 'TP9'));
        equationString = sprintf('.5 * ch%d', refIdx);
    end
    
    for i=includedChanIndexes
        equationList{end + 1} = sprintf(baseEquation, i, i, equationString, allLocs{i}); %#ok<AGROW>
    end
    
end

function make_binlist(subdirPath, timelockCodes)
    % creates a simple binlist  (needed for epoching)

    binfid = fopen(fullfile(subdirPath, 'binlist.txt'), 'w');

    for i=1:numel(timelockCodes)
        fprintf(binfid, sprintf('bin %d\n', i));
        fprintf(binfid, sprintf('%d\n', timelockCodes(i)));
        fprintf(binfid, sprintf('.{%d}\n\n', timelockCodes(i)));
    end
end

function [xPix, yPix] = calcdeg2pix(eyeMoveThresh, distFromScreen, monitorWidth, monitorHeight, screenResX, screenResY)
    % takes a visual angle and returns the (rounded) horizontal and vertical number of
    % pixels from fixation that would be

    pixSize.X = monitorWidth/screenResX; %mm
    pixSize.Y = monitorHeight/screenResY; %mm

    mmfromfix = (2*distFromScreen) * tan(.5 * deg2rad(eyeMoveThresh));

    xPix = mmfromfix/pixSize.X;
    yPix = mmfromfix/pixSize.Y;
end