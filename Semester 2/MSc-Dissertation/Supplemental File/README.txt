This folder contains the source code for a decibel monitor that will start recording conversations from the attatched microphone if a certain decibel level is reached. It does this in order to capture conflicts that may be occuring in the home that can have an affect on a childs mental health. This folder also contains the source code for the attached report that was created with LaTeX formatting in TexWorks.

Requirements:
- Raspberry Pi 3 B+
- Power cable for Raspberry Pi
- USB microphone
(If running from command line you will need the following also)
- USB keyboard
- USB mouse
- Monitor
- HDMI cable

To activate the system simply plug the Raspberrry Pi device into a power point and click the button on the wire to turn it on. From here the system will be active and listening out for conversations.

If activation levels are too high/low these can be adjusted by changing 'shoutThresh' and 'talkThresh'.

THIS PROJECT WILL NOT RUN ON DESKTOP DUE TO CHANNEL NUMBER AND DEVICE INDEX BENIG SET TO RASPBERRY PI SETTINGS

To run the project from the command line:
- Navigate to folder containing 'Decibel Monitor Application'
- Type 'python Decibel Monitor Application' to start the application

To make the software run on a new system via the command line pyaudio must be downloaded. Instructions for downloading this can be found here: https://people.csail.mit.edu/hubert/pyaudio/

ANY WORK IN THE 'DROPBOX-UPLOADER-MASTER' IS NOT MINE


