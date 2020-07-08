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
**lowboundFilterHz** (float): lower range for bandpass filtering of EEG<br />
**highboundFilterHz** (float): upper range for bandpass filtering of EEG<br />

**rerefType** (str): what type of referencing to do on EEG<br />
**rerefExcludeChans** (cell array of str): which, if any, channels to exclude from rereferencing (e.g. you shouldn't rereference EOG channels)<br />

**EYEEEGKeyword** (str): keyword sent with eyetracking messages to sync events to portcodes<br />
**startEvent** (int): portcode to signal beginning of session (can be the first instance of many)<br />
**endEvent** (int): portcode to signal end of session (can be the last instance of many)<br />
**eyeRecorded** (str): which eyes were tracked<br />

**binlistFile** (str):<br />
**timelockCodes** (vector of int): portcodes to timelock to (will become time 0 in epoch)<br />
**trialStart** (float): how many milliseconds to grab before timelocked event <br />
**trialEnd** (float): how many milliseconds to grab after timelocked event<br />
**baselineStart** (float): beginning of baseline period of epoch<br />
**baselineEnd** (float): ending of baseline period of epoch<br />
**rejectionStart** (float): beginning of artifact rejection period of epoch (useful if you only want to reject based on a portion of epoch)<br />
**rejectionEnd** (float): ending of artifact rejection period of epoch<br />

**eyeMoveThresh** (float): eye movement rejection threshold in degrees <br />
**distFromScreen** (float): how many millimeters from screen subject sits<br />
**monitorWidth** (float): monitor width in mm<br />
**monitorHeight** (float): monitor height in mm<br />
**screenResX** (float): monitor resolution width in pixels<br />
**screenResY** (float): monitor resolution height in pixels<br />
(the previous 5 parameters are necessary for calculating degrees of eye movement)<br />

**eogThresh** (float): eog rejection threshold in microvolts<br />

**eegThresh** (float): eeg rejection threshold in microvolts<br />
**eegNoiseThresh** (float): eeg noise rejection threshold in microvolts (see pop_artmwppth in ERPLAB)<br />

**eegResampleRate** (float): optional sampling rate to resample EEG at<br />
**eegResample** (bool): set to true to resample EEG<br />

**rejFlatline** (bool): remove trials with flatline data <br />
