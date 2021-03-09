import pyaudio
import wave
import os
import subprocess
import sys

from subprocess import Popen, PIPE
from sys import byteorder
from array import array
from struct import pack

shoutThresh = 1000          # Decibel level needed to be reached for shouting
talkThresh = 50             # Decibel level needed to be reached for talking
CHUNK_SIZE = 700            # Size of data chunks
FORMAT = pyaudio.paInt16    
device = 2                  # Where microphone is attached 
myChannel = 1               # input channels (only 1)
RATE = 44100                # Rate of recording


# Location of directory which containes files to be uploaded
homeDirectory= os.getcwd()
# Path to the Dropbox-uploaded shell script
uploadPath = homeDirectory + "/Dropbox-Uploader/dropbox_uploader.sh"


restart = 1

# Format for information from uploader to be output
def dropboxUploadOutput(msg, level):
    print((" " * level * 2) + msg)

# What is Silent
def is_silent (currentData):
    #Returns 'True' if below the 'silent' talkThresh
    return max(currentData) < talkThresh

# What is Shouting
def is_shout (currentData):
    #Returns 'True' if above shoutThresh
    return max(currentData) > shoutThresh

# What is Talking
def is_talk (currentData):
    #Return 'True if between 'talkThresh' and 'shoutThresh
    return talkThresh < max(currentData) < shoutThresh

# Bring recording into an average volume so it is at an acceptable level throughout
def averageVolume(currentData):    
    MAX = 15000
    # Find aveage
    times = float(MAX)/max(abs(i) for i in currentData)
    r = array('h')
    # Apply average to all data
    for i in currentData:
        r.append(int(i*times))
    return r

# Remove blank data at the start and end of the recording
def concentrateData(currentData):
    def _concentrateData(currentData):
        dataSending = False
        r = array('h')
        #Find all data that is silent before the activation point
        for i in currentData:
            if not dataSending and abs(i)>talkThresh:
                dataSending = True
                r.append(i)             
                    

            elif dataSending:
                r.append(i)
                
        return r    

    # Remove all appropriate data at start of recording
    currentData = _concentrateData(currentData)
    

    # Remove all appropriate data at end of recording by;
    # flipping all data, apply removal, flip back 
    currentData.reverse()
    currentData = _concentrateData(currentData)
    currentData.reverse()
    return currentData

# After removing the potentially lengthy silences, add a short amount of silence 
# to both sides of recording so that the file feels more professional
def addSilence(currentData, seconds):
    r = array('h', [0 for i in range(int(seconds*RATE))])
    r.extend(currentData)
    r.extend([0 for i in range(int(seconds*RATE))])
    return r

# Retrieves files in Dropbox directory in child program and returns them as a list to main program
def listDropboxFiles(path):
    # Open child program
    p = Popen([uploadPath, "list", path], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    # Format output
    output = p.communicate()[0].decode("utf-8")

    outputList = list()
    lines = output.splitlines()

    # Neaten output data into separate lines
    for line in lines:
        if line.startswith(" [F]"):
            line = line[5:]
            line = line[line.index(' ')+1:]
            outputList.append(line)
                   
    return outputList

# This class gets the files from the local drive, compares to dropbox space, 
# plus uploads new file if no match
def uploadToDropbox(path, level):
    homePath = os.path.join(homeDirectory,path)
    dropboxUploadOutput("Syncing " + homePath,level)

    if not os.path.exists(homePath):
        dropboxUploadOutput("No path at: " + path, level)
    else:
        # List files and directories in local space
        localSpace = os.listdir(homePath)

        # Group      
        files = list()
        directories = list()

        # For everything in the local space, add to either 'files' or 'directories'
        for file in localSpace:
            fileAddress = os.path.join(homePath,file)
            if os.path.isfile(fileAddress):
                files.append(file)       
            if os.path.isdir(fileAddress):
                directories.append(file)

        # Let user know how many directories and files found
        dropboxUploadOutput(str(len(directories)) + " Directories, " + str(len(files)) + " Files ",level)

        # Get list of files in dropbox
        if len(files) > 0:
            dropboxFiles = listDropboxFiles(path)

        # For each file, check if the file can be uploaded properly
        for f in files:                                 
            dropboxUploadOutput("Found: " + f,level)   
            if not f in dropboxFiles:
                fullAddress = os.path.join(homePath,f)
                relativeAddress = os.path.join(path,f)  
                dropboxUploadOutput("Uploading: " + f,level+1)   
                if fileUpload(fullAddress, relativeAddress) == 1:
                    dropboxUploadOutput("Upload Complete for: " + f,level + 1)                                            
                else:
                    dropboxUploadOutput("Error With File: " + f,level + 1)
                    
        # Loop through directories within local space       
        for d in directories:
            dropboxUploadOutput("Directory: " + d + "found", level)
            directoryPath = os.path.join(path,d)
            uploadToDropbox(directoryPath, level + 1)

# Process of uploading a single file 
def fileUpload(localPath, remotePath):
    p = Popen([uploadPath, "upload", localPath, remotePath], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output = p.communicate()[0].decode("utf-8").strip()
    # If the output starts and finishes with these two messages then the file will have been uploaded
    # successfully through 'Dropbox_Uploader' program
    if output.startswith("> Uploading") and output.endswith("DONE"):
        print ("got here")
        return 1
    else:
        return 0

# Class that handles the setting up of audio stream, activating system on decibel level reached, 
# appropriate collection of data surrounding anchor point, restarts system if no shouting detected 
# and applies processing
def record():       
    shoutingLoop = 1
    # While the system hasn't heard shouting
    while shoutingLoop == 1 :
        # Open stream
        p = pyaudio.PyAudio()
        stream = p.open(format=FORMAT, channels=myChannel, rate=RATE, input_device_index = device,
            input = True, output = True,
            frames_per_buffer=CHUNK_SIZE)

        # Counters
        num_silent = 0
        talkTime = 0
    
        dataSending = False
        shoutingNotDetected = True
        talkDetected = False
        recordingLoop = 1    

        r = array('h')

        # While neither counter has reached its capacity and system needs to listen for new data
        while recordingLoop < 2 :
            # Associate new data chunks with current data object
            currentData = array('h', stream.read(CHUNK_SIZE))

            if byteorder == 'big':
                currentData.byteswap()
            r.extend(currentData)

            silent = is_silent(currentData)
            talk = is_talk (currentData)
            shout = is_shout(currentData)               
        
            # While shoutingNotDetected:
            # If talking heard set to true            
            if talk:
                talkDetected = True

            # If time since talking is below 5 seconds, keep sending data
            if talkTime < 500:
                dataSending = True

            # If time since talking initially heard exceeds 5 seconds, reset timer and tell user no shouting heard
            if talkTime >= 500:
                print ("No shouting heard in last 5 seconds, reset memory")                
                talkTime = 0                         
                print ("Not sending data")
                # Break recording loop, so that a new stream can be opened, deleting old data (with no shouting)
                recordingLoop = 3 #BREAK

            if talkDetected == True:                
                talkTime += 1
                #print (talkTime)
             
            # When shouting is detected, set boolean to true & reset talking timer
            if shout:
                print ("Shouting Detected")
                shoutingNotDetected = False
                #dataSending = True            
                talkTime = 0

            #Increase silence time if send has started and nothing is heard
            if silent and dataSending == True:
                num_silent += 1

            # If there is silence and shouting has been detected, the talking timer will be set to 0
            # (so talk time doesn't reach maximum and stop recording)
            if silent and not shoutingNotDetected:
                print ("Waiting ...")
                talkTime = 0
                #print (num_silent)   

            #Reset silence timer if any audio is heard as to extend the recording
            if not silent and dataSending == True:
                print ("Reset Timer, More Heard") 
                num_silent = 0

            # If sending has started, shouting is hear and the number of silence is greater than 5 seconds
            if dataSending == True and not shoutingNotDetected and num_silent > 500:
                # Break the recording loop
                recordingLoop == 4 #BREAK
                break    
        
        # Get size of file in chunks + stop and close audio stream
        sample_width = p.get_sample_size(FORMAT)
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        # Check if shouting has been heard before applying the processing and saving of file
        if not shoutingNotDetected:
            shoutingLoop = 2 #BREAK

    # Process data according to classes
    r = averageVolume(r)
    r = concentrateData(r)    
    r = addSilence(r, 0.5)
    return sample_width, r

# Records data from the microphone selected and saves it to the local disk 
# with same properties as data from record class above 
def convertToFile(path):
    sample_width, data = record()
    data = pack('<' + ('h'*len(data)), *data)

    wf = wave.open(path, 'wb')
    wf.setnchannels(1)
    wf.setsampwidth(sample_width)
    wf.setframerate(RATE)
    wf.writeframes(data)
    wf.close()

# Path the program will take on start up
if __name__ == '__main__':   
    # Infinite loop so system will always records if active 
    while restart == 1:
        print("please speak into the microphone")

        # First file to be named 'demo.wav' as this should be a test of the system 
        # Rest of files to be named with date and time
        if os.path.exists('demo.wav'):
            import time
            timestr = time.strftime("%Y%m%d-%H%M%S")
            convertToFile('demo_{}.wav'.format(timestr))
            print("Done - result saved 1")
        else:
            convertToFile('demo.wav')
            print("Done - result saved 2")

        # After saving file locally, upload to dropbox
        uploadToDropbox("",1)

        print("Complete")

        # Restart
        restart = 1
    