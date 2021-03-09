from sys import byteorder
from array import array
from struct import pack

import pyaudio
import wave
import os

shoutThresh = 10000
talkThresh = 500
CHUNK_SIZE = 1024
FORMAT = pyaudio.paInt16
RATE = 44100


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

def record():

    "Recording Voice"
    
    it = 1
    while it == 1 :
        p = pyaudio.PyAudio()
        stream = p.open(format=FORMAT, channels=1, rate=RATE,
            input=True, output=True,
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
            if talkTime < 50:
                snd_started = True
            if talkTime >= 500:
                print ("No shouting heard in last 5 seconds, reset memory")                
                talkTime = 0                         
                print ("Not sending data")
                itera = 3
            if talkDetected == True:
                talkTime += 1
                print ("Talk:")
                
        
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
                print (num_silent)   
        
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
    print("please speak into the microphone")
    #record_to_file('demo.wav')    
    if os.path.exists('demo.wav'):
        import time
        timestr = time.strftime("%Y%m%d-%H%M%S")
        record_to_file('demo_{}.wav'.format(timestr))
        print("Done - result saved")
    else:
        record_to_file('demo.wav')
        print("Done - result saved")
        
    