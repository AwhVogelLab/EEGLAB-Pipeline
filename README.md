# EEGLAB-Pipeline
A standardized pipeline for EEG preprocessing and artifact rejection using EEGLAB

## Installation

1. Install EEGLAB using the instructions [here](https://sccn.ucsd.edu/eeglab/downloadtoolbox.php/download.php).
3. Add the eeglab directory to your path using "Set Path > Add Folder..." (you do not need to add with subfolders).
4. Install ERPLAB with the EEGLAB plugin manager using the instructions [here](https://github.com/lucklab/erplab/wiki/Installation).
5. Install EYE-EEG with the EEGLAB plugin manager.<br />
   a. Instructions for using EYE-EEG are [here](https://www.eyetracking-eeg.org/tutorial.html).<br />
   b. Importantly, eyetracking messages that synchronize with the EEG parallel portcodes **must** have a synchronize keyword before the digits. See more details about [Method 2: Messages+triggers](https://www.eyetracking-eeg.org/tutorial.html#tutorial1).<br />
5. Install bva-io with the EEGLAB plugin manager.
6. Install the [EEGLAB Signal Processing Toolbox](https://www.mathworks.com/products/signal.html).   
   NOTE: It may be possible to avoid using this expensive plugin. I believe the only function that requires it is `pop_resample` which changes the sampling rate of your eyetracking/EEG.
8. `git clone` this repo (or download as a zip) into your desired folder.
9. Optionally, download the test_data with `source get_test_data.sh`
10. You also need a way to convert EDF eyetracking files to ASC files that are viewable in MATLAB. Learn more [here](https://download.sr-support.com/dispdoc/page25.html).  

## Usage
This script is essentially a template which you can copy and edit per project. After running this script, you will have saved "unchecked" .set files which can then be opened in EEGLAB. The trials that have been flagged for rejection are not yet removed. The rejection flags are stored in EEG.reject. You can visually inspect the rejections using this command: <br />
    *pop_eegplot( EEG, 1, 1, 1);*<br />
This allows you to scroll through the EEG data. You have the option to manually add or remove rejections by clicking the trials of interest. Once you are done, you can press the "Reject" button and it will remove all trials flagged for rejection.<br />

To simply apply the pipeline's rejections automatically, you can use the command:<br />
    *EEG = pop_rejepoch(EEG,EEG.reject.rejmanual,0);*

Optionally, you can align the channels and stack them during visual inspection. To do this, use the align_channels function before visual inspection with this command:<br />
*EEG = align_channels(EEG,true)*<br />
After plotting the EEG, press the "Stack" button and all EEG channels will be aligned in the middle. EOG and Stimtrak will be above. Eyetracking will be below. Then you can reject as usual. It is recommended that you undo the alignment before saving your data. Do this with the same function:<br />
*EEG = align_channels(EEG,false)*<br />

## Options

**subjectParentDir** (str): folder that contains subjects' data folders<br />
**subjectDirectories** (cell array of str): which subject folders to include in analysis<br />
**noEyetracking** (cell array of str): which subjects to **not** do eyetracking rejection on <br />
**doEogRejection** (cell array of str): which subject to do EOG rejection on<br />

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

**eegResampleRate** (float): optional sampling rate to resample EEG at<br />
**eegResample** (bool): set to true to resample EEG<br />

**eogThresh** (float): eog rejection threshold in microvolts<br />

**eegThresh** (float): eeg rejection threshold in microvolts<br />
**eegNoiseThresh** (float): eeg noise rejection threshold in microvolts (see pop_artmwppth in ERPLAB)<br />
**eegMinSlop** (flot): %minimal absolute slope of the linear trend of the activity for rejection<br />
**eegResample** (bool): %minimal R^2 for rejection<br />

**rejFlatline** (bool): remove trials with flatline data <br />
