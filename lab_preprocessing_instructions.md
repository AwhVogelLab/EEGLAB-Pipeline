## Preprocessing How-To

1. Copy data into subject folder
2. Convert .edf to .asc using EDF Converter
3. Open eegreject.m in MATLAB
4. Change subjectDirectories to match subjects you want to preprocess and run script.
5. Open unchecked .set files using EEGLAB.
6. Use `EEG = align_channels(EEG,true)` to align EEG channels.
    a. NOTE: You have to flag a trial first to see flagged channels (EEGLAB bug)
7. Use `pop_eegplot(EEG, 1, 1, 1)` to view data.
8. "Stack" data and set scaling to 30.
9. Visually inspect data, flagging and unflagging trials.
10. Press the "Reject" button. Press okay to pop_newset window.
11. Use `EEG = align_channels(EEG,false)` to realign EEG channels.
12. Save new dataset with File > Save Current Dataset as. Save as "checked".