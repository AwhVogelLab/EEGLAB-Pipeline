%% Read Me

%% Setup
clearvars
eeglab

%% Options

subjectParentDir = 'test_data';
subjectDirectories = {'6'};  % optionally {} for recursive search

lowboundFilterHz = 0.01;
highboundFilterHz = 30;

rerefType = 'mastoid'; % 'none', 'average', or 'mastoid' 
rerefExcludeChans = {'HEOG', 'VEOG', 'StimTrak'};
customEquationList = '';  % optional

EYEEEGKeyword = 'sync';
startEvent = 21;
endEvent = 21;
eyeRecorded = 'left';  % 'both', 'left', or 'right'

binlistFile = '';  % if empty, will create one for you
timelockCodes = [11 12 13 14];  % codes to timelock to
trialStart = -200;
trialEnd = 1000;
baselineStart = -200;
baselineEnd = 0;


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
%% Main loop

for subdir=1:numel(subjectDirectories)
    subdirPath = fullfile(subjectParentDir, subjectDirectories{subdir});
    
    disp(['Running ', subdirPath])
    fprintf(log, ['Running ', subdirPath, '\n\n']);
    
    vhdrDir = dir(fullfile(subdirPath, '*.vhdr'));
    
    if numel(vhdrDir) == 0
        warning(['Skipping ', subdirPath, '. No vhdr file found.'])
        fprintf(log, ['Skipping ', subdirPath, '. No vhdr file found.\n\n']);
        continue
    elseif numel(vhdrDir) > 1
        warning(['Skipping ', subdirPath, '. More than one vhdr file found.'])
        fprintf(log, ['Skipping ', subdirPath, '. More than one vhdr file found.\n\n']);
        continue
    end
    
    vhdrFilename = vhdrDir(1).name;
    
    ascDir = dir(fullfile(subdirPath, '*.asc'));
    
    if numel(ascDir) == 0
        warning(['Skipping ', subdirPath, '. No asc file found.'])
        fprintf(log, ['Skipping ', subdirPath, '. No vhdr file found.\n\n']);
        continue
    elseif numel(ascDir) > 1
        warning(['Skipping ', subdirPath, '. More than one asc file found.'])
        fprintf(log, ['Skipping ', subdirPath, '. More than one asc file found.\n\n']);
        continue
    end
    
    ascFullFilename = fullfile(subdirPath, ascDir(1).name);

    EEG = pop_loadbv(subdirPath, vhdrFilename);
    
    EEG.setname = vhdrFilename(1:end-5);
    
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
        EEG = pop_importeyetracker(EEG, EYEEEGMatFilename, [startEvent endEvent], [2 3], {'GAZE_X' 'GAZE_Y'}, 0, 1, 0, 0);
    end
    diary off

    EEG = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'}, 'Warning', 'off');
    
    if isempty(binlistFile)
        make_binlist(subdirPath, timelockCodes)
        binlistFile = fullfile(subdirPath, 'binlist.txt');
    end
    
    EEG = pop_binlister(EEG, 'BDF', binlistFile);
    EEG = pop_epochbin(EEG, [trialStart, trialEnd], sprintf('%d %d', baselineStart, baselineEnd));

% do general noise rejection on eeg channels

% do EOG rejection based on muscle movements

% do eye tracking rejection based on degrees

% save data to .set file

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