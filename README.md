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
lowboundFilterHz: lower range for bandpass filtering of EEG<br />
highboundFilterHz: upper range for bandpass filtering of EEG<br />

rerefType: what type of referencing to do on EEG<br />
rerefExcludeChans: which, if any, channels to exclude from rereferencing (e.g. you shouldn't rereference EOG channels)<br />

EYEEEGKeyword: keyword sent with eyetracking messages to sync events to portcodes<br />
startEvent: portcode to signal beginning of session (can be the first instance of many)<br />
endEvent: portcode to signal end of session (can be the last instance of many)<br />
eyeRecorded: which eyes were tracked<br />

binlistFile:<br />
timelockCodes: portcodes to timelock to (will become time 0 in epoch)<br />
trialStart: how many milliseconds to grab before timelocked event <br />
trialEnd: how many milliseconds to grab after timelocked event<br />
baselineStart: beginning of baseline period of epoch<br />
baselineEnd: ending of baseline period of epoch<br />
rejectionStart: beginning of artifact rejection period of epoch (useful if you only want to reject based on a portion of epoch)<br />
rejectionEnd: ending of artifact rejection period of epoch<br />

eyeMoveThresh: eye movement rejection threshold in degrees <br />
distFromScreen: how many millimeters from screen subject sits<br />
monitorWidth: monitor width in mm<br />
monitorHeight: monitor height in mm<br />
screenResX: monitor resolution width in pixels<br />
screenResY: monitor resolution height in pixels<br />
(the previous 5 parameters are necessary for calculating degrees of eye movement)<br />

eogThresh: eog rejection threshold in microvolts<br />

eegThresh: eeg rejection threshold in microvolts<br />
eegNoiseThresh: eeg noise rejection threshold in microvolts (see pop_artmwppth in ERPLAB)<br />

eegResampleRate: optional sampling rate to resample EEG at<br />
eegResample: set to true to resample EEG<br />

rejFlatline: remove trials with flatline data <br />
