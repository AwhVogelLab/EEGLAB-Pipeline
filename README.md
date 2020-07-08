# StandardizedPipeline
A standardized pipeline for first pass EEG artifact rejection using EEGLAB

## Installation

1. Install EEGLAB using the instructions [here](https://sccn.ucsd.edu/eeglab/downloadtoolbox.php/download.php).
2. Add the eeglab directory to your path using "Set Path > Add Folder..." (you do not need to add with subfolders).
3. Install ERPLAB with the EEGLAB plugin manager using the instructions [here](https://github.com/lucklab/erplab/wiki/Installation).
4. Install EYE-EEG with the EEGLAB plugin manager.
5. Install bva-io with the EEGLAB plugin manager.
6. `git clone` this repo (or download as a zip) into your desired folder.
7. Optionally, download the test_data with `source get_test_data.sh`

## Usage

This script is essentially a template which you can copy and edit per project.

## Options
lowboundFilterHz: lower range for bandpass filtering of EEG
highboundFilterHz: upper range for bandpass filtering of EEG

rerefType: what type of referencing to do on EEG
rerefExcludeChans: which, if any, channels to exclude from rereferencing (e.g. you shouldn't rereference EOG channels)

EYEEEGKeyword: keyword sent with eyetracking messages to sync events to portcodes
startEvent: portcode to signal beginning of session (can be the first instance of many)
endEvent: portcode to signal end of session (can be the last instance of many)
eyeRecorded: which eyes were tracked

binlistFile:
timelockCodes: portcodes to timelock to (will become time 0 in epoch)
trialStart: how many milliseconds to grab before timelocked event 
trialEnd: how many milliseconds to grab after timelocked event
baselineStart: beginning of baseline period of epoch
baselineEnd: ending of baseline period of epoch
rejectionStart: beginning of artifact rejection period of epoch (useful if you only want to reject based on a portion of epoch)
rejectionEnd: ending of artifact rejection period of epoch

eyeMoveThresh: eye movement rejection threshold in degrees 
distFromScreen: how many millimeters from screen subject sits
monitorWidth: monitor width in mm
monitorHeight: monitor height in mm
screenResX: monitor resolution width in pixels
screenResY: monitor resolution height in pixels
(the previous 5 parameters are necessary for calculating degrees of eye movement)

eogThresh: eog rejection threshold in microvolts

eegThresh: eeg rejection threshold in microvolts
eegNoiseThresh: eeg noise rejection threshold in microvolts (see pop_artmwppth in ERPLAB)

eegResampleRate: optional sampling rate to resample EEG at
eegResample: set to true to resample EEG

rejFlatline: remove trials with flatline data 
