%% Read Me

%% Setup
clearvars
eeglab

%% Options

eeglabFolder = '/Applications/eeglab2019_1/';

subjectParentDir = 'test_data';
subjectDirectories = {'6'};

lowboundFilterHz = 0.01;
highboundFilterHz = 30;

rerefChanLabels = {'TP9', 'TP10'};
rerefExcludeChans = {'HEOG', 'VEOG', 'StimTrak'};

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
fprintf(log, ['Run started: ', datestr(now), '\n']);

chanLocsFile = fullfile(eeglabFolder, 'plugins/dipfit/standard_BESA/standard-10-5-cap385.elp');
%% Main loop

for subdir=1:numel(subjectDirectories)
    subdirpath = fullfile(subjectParentDir, subjectDirectories{subdir});
    
    disp(['Running ', subdirpath])
    fprintf(log, ['Running ', subdirpath, '\n']);
    
    vhdr_dir = dir(fullfile(subdirpath, '*.vhdr'));
    
    if numel(vhdr_dir) == 0
        warning(['Skipping ', subdirpath, '. No vhdr file found.'])
        continue
    elseif numel(vhdr_dir) > 1
        warning(['Skipping ', subdirpath, '. More than one vhdr file found.'])
        continue
    end
    
    vhdr_filename = vhdr_dir(1).name;

    EEG = pop_loadbv(subdirpath, vhdr_filename);
    
    EEG.setname = vhdr_filename(1:end-5);
    
    if lowboundFilterHz ~= 0 && highboundFilterHz ~= 0
        EEG = pop_basicfilter(EEG, 1:EEG.nbchan, 'Boundary', 'boundary', 'Cutoff', [lowboundFilterHz highboundFilterHz], 'Design', 'butter', 'Filter', 'bandpass', 'Order', 2);
    elseif highboundFilterHz ~= 0
        EEG = pop_basicfilter(EEG, 1:EEG.nbchan, 'Boundary', 'boundary', 'Cutoff', highboundFilterHz, 'Design', 'butter', 'Filter', 'lowpass', 'Order', 2);
    elseif lowboundFilterHz ~= 0
        EEG = pop_basicfilter(EEG, 1:EEG.nbchan, 'Boundary', 'boundary', 'Cutoff', lowboundFilterHz, 'Design', 'butter', 'Filter', 'highpass', 'Order', 2);
    end
    
    rerefChanIndexes = find(ismember({EEG.chanlocs(:).labels}, rerefExcludeChans));
    
    %EEG = pop_chanedit(EEG, 'append', 10, 'changefield', {11 'labels' 'TP10'}, 'lookup', chanLocsFile, 'rplurchanloc', 1);
    %EEG = pop_reref(EEG, [], 'exclude', rerefChanIndexes, 'keepref', 'on');  % temporarily reref to average
    
    if ~isempty(rerefChanLabels)
        %EEG = pop_reref(EEG, rerefChanLabels, 'exclude', rerefChanIndexes);
    end


% pull in eye data and sync

% do erplab binning

% epoch

% do general noise rejection on eeg channels

% do EOG rejection based on muscle movements

% do eye tracking rejection based on degrees

% save data to .set file

end

%% Clean up
eeglab redraw;


fclose(log);

%% Helper Functions

