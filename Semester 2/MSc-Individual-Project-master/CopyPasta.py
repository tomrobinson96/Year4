import pyaudio
import wave
import os
import subprocess
import sys

from subprocess import Popen, PIPE
from sys import byteorder
from array import array
from struct import pack

shoutThresh = 1000
talkThresh = 50
CHUNK_SIZE = 700
FORMAT = pyaudio.paInt16
dev_index = 2 # device index found by p.get_device_info_by_index(ii)
chans = 1 # 1 channel
RATE = 44100

#The directory to sync
syncdir="/home/pi/Audio Files/"
#Path to the Dropbox-uploaded shell script
uploader = "/home/pi/Dropbox-Uploader/dropbox_uploader.sh"

recursive = 1
restart = 1

#Prints indented output
def print_output(msg, level):
    print((" " * level * 2) + msg)

def is_silent (snd_data):
    "Returns 'True' if below the 'silent' talkThresh"
    return max(snd_data) < talkThresh

def is_shout (snd_data):
    "Returns 'True' if above shoutThresh"
    return max(snd_data) > shoutThresh

def is_talk (snd_data):
    "Return 'True if between 'talkThresh' and 'shoutThresh"
    return talkThresh < max(snd_data) < shoutThresh

def normalize(snd_data):
    "Average the volume out"
    MAXIMUM = 16384
    times = float(MAXIMUM)/max(abs(i) for i in snd_data)

    r = array('h')
    for i in snd_data:
        r.append(int(i*times))
    return r

def trim(snd_data):
    "Trim the blank spots at the start and end"
    def _trim(snd_data):
        snd_started = False
        r = array('h')

        for i in snd_data:
            if not snd_started and abs(i)>talkThresh:
                snd_started = True
                r.append(i)
                
                    

            elif snd_started:
                r.append(i)
                
        return r    

    # Trim to the left
    snd_data = _trim(snd_data)
    

    # Trim to the right
    snd_data.reverse()
    snd_data = _trim(snd_data)
    snd_data.reverse()
    return snd_data

def add_silence(snd_data, seconds):
    "Add silence to the start and end of 'snd_data' of length 'seconds' (float)"
    r = array('h', [0 for i in range(int(seconds*RATE))])
    r.extend(snd_data)
    r.extend([0 for i in range(int(seconds*RATE))])
    return r

#Gets a list of files in a dropbox directory
def list_files(path):
    p = Popen([uploader, "list", path], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output = p.communicate()[0].decode("utf-8")

    fileList = list()
    lines = output.splitlines()

    for line in lines:
        if line.startswith(" [F]"):
            line = line[5:]
            line = line[line.index(' ')+1:]
            fileList.append(line)
                   
    return fileList

def upload_files(path, level):
    fullpath = os.path.join(syncdir,path)
    print_output("Syncing " + fullpath,level)
    if not os.path.exists(fullpath):
        print_output("Path not found: " + path, level)
    else:

        #Get a list of file/dir in the path
        filesAndDirs = os.listdir(fullpath)

        #Group files and directories
        
        files = list()
        dirs = list()

        for file in filesAndDirs:
            filepath = os.path.join(fullpath,file)
            if os.path.isfile(filepath):
                files.append(file)       
            if os.path.isdir(filepath):
                dirs.append(file)

        print_output(str(len(files)) + " Files, " + str(len(dirs)) + " Directories",level)

        #If the path contains files and we don't want to override get a list of files in dropbox
        if len(files) > 0:
            dfiles = list_files(path)

        #Loop through the files to check to upload
        for f in files:                                 
            print_output("Found File: " + f,level)   
            if not f in dfiles:
                fullFilePath = os.path.join(fullpath,f)
                relativeFilePath = os.path.join(path,f)  
                print_output("Uploading File: " + f,level+1)   
                if upload_file(fullFilePath, relativeFilePath) == 1:
                    print_output("Uploaded File: " + f,level + 1)                                            
                else:
                    print_output("Error Uploading File: " + f,level + 1)
                    
        #If recursive loop through the directories   
        if recursive == 1:
            for d in dirs:
                print_output("Found Directory: " + d, level)
                relativePath = os.path.join(path,d)
                upload_files(relativePath, level + 1)

#Uploads a single file
def upload_file(localPath, remotePath):
    p = Popen([uploader, "upload", localPath, remotePath], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output = p.communicate()[0].decode("utf-8").strip()
    if output.startswith("> Uploading") and output.endswith("DONE"):
        print ("got here")
        return 1
    else:
        return 0

def record():

    "Recording Voice"
    
    it = 1
    while it == 1 :
        p = pyaudio.PyAudio()
        stream = p.open(format=FORMAT, channels=chans, rate=RATE, input_device_index = dev_index,
            input = True, output = True,
            frames_per_buffer=CHUNK_SIZE)

        num_silent = 0
        talkTime = 0
    
        snd_started = False
        shoutHasNotBeenDetected = True
        talkDetected = False
        itera = 1
    

        r = array('h')

        while itera < 2 :
            # little endian, signed short
            snd_data = array('h', stream.read(CHUNK_SIZE))
            if byteorder == 'big':
                snd_data.byteswap()
            r.extend(snd_data)

            silent = is_silent(snd_data)
            talk = is_talk (snd_data)
            shout = is_shout(snd_data)               
        
            #while shoutHasNotBeenDetected is True:            
            if talk:
                talkDetected = True       
            if talkTime < 500:
                snd_started = True
            if talkTime >= 500:
                print ("No shouting heard in last 5 seconds, reset memory")                
                talkTime = 0                         
                print ("Not sending data")
                itera = 3
            if talkDetected == True:                
                talkTime += 1
                #print (talkTime) 
        
            if shout:
                print ("Shouting Detected")
                shoutHasNotBeenDetected = False
                #snd_started = True            
                talkTime = 0

            #Increase silence time if send has started and nothing is heard
            if silent and snd_started == True:
                num_silent += 1
        
            #if silent and shoutHasNotBeenDetected:
            #    snd_started = False
                #print ("Silence and no shout")
        
            if silent and not shoutHasNotBeenDetected:
                print ("Waiting for more audio..")
                talkTime = 0
                #print (num_silent)   
        
            if not silent and snd_started == True:
                print ("More Voices heard") 
                num_silent = 0
                #snd_started = False 

            if snd_started == True and not shoutHasNotBeenDetected and num_silent > 500:
                itera == 4
                break    
        
        sample_width = p.get_sample_size(FORMAT)
        stream.stop_stream()
        stream.close()
        p.terminate()

        if not shoutHasNotBeenDetected:
            it = 2

    r = normalize(r)
    r = trim(r)    
    r = add_silence(r, 0.5)
    return sample_width, r

def record_to_file(path):
    "Records from the microphone and outputs the resulting data to 'path'"
    sample_width, data = record()
    data = pack('<' + ('h'*len(data)), *data)

    wf = wave.open(path, 'wb')
    wf.setnchannels(1)
    wf.setsampwidth(sample_width)
    wf.setframerate(RATE)
    wf.writeframes(data)
    wf.close()

if __name__ == '__main__':
    
    while restart == 1:
        print("please speak into the microphone")
        #record_to_file('demo.wav')    
        if os.path.exists('demo.wav'):
            import time
            timestr = time.strftime("%Y%m%d-%H%M%S")
            record_to_file('demo_{}.wav'.format(timestr))
            print("Done - result saved 1")
        else:
            record_to_file('demo.wav')
            print("Done - result saved 2")
        upload_files("",1)
        print("Complete")
        restart = 1
    