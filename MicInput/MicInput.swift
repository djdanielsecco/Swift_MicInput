//
//  MicInput.swift
//  MicInput
//
//  Created by 湯川 修平 on 1/11/16.
//  Copyright © 2016 湯川 修平. All rights reserved.
//

import Foundation
import CoreAudio
import AudioUnit

class MicInput
{
    let inputProc : AURenderCallback = { (
        inRefCon: UnsafeMutablePointer<Void>,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBufNumber: UInt32,
        inNumberFrames: UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus in
        
        var err :OSStatus? = nil
        
        let buffer = MicInput.allocateAudioBuffer(2 ,size: inNumberFrames)
        var bufferList = AudioBufferList.init(mNumberBuffers: 1, mBuffers: buffer)
        
        // AudioDataを引っ張る
        err = AudioUnitRender(AudioData.sharedInstance.inputUnit, ioActionFlags, inTimeStamp, inBufNumber, inNumberFrames, &bufferList)
        
        if err == noErr
        {
            // AudioDataの追加
            FFT.addAudioData(bufferList)
        }
        return err!
    }
    
    class func allocateAudioBuffer(let numChannel: UInt32, let size: UInt32) -> AudioBuffer
    {
        let dataSize = UInt32(numChannel * UInt32(sizeof(Float64)) * size)
        let data = malloc(Int(dataSize))
        let buffer = AudioBuffer.init(mNumberChannels: numChannel, mDataByteSize: dataSize, mData: data)
        data.dealloc(Int(dataSize))
        
        return buffer
    }
    
    private func setUpAudioHAL() -> OSStatus
    {
        // AudioUnitを作成する
        var desc = AudioComponentDescription()
        var comp:AudioComponent?
        
        desc.componentType = kAudioUnitType_Output
        desc.componentSubType = kAudioUnitSubType_HALOutput
        
        desc.componentManufacturer = kAudioUnitManufacturer_Apple
        desc.componentFlags = 0
        desc.componentFlagsMask = 0
        
        comp = AudioComponentFindNext(nil, &desc)
        if comp == nil
        {
            return -1
        }
        
        let err = AudioComponentInstanceNew(comp!, &AudioData.sharedInstance.inputUnit)
        return err
    }
    
    private func setUpEnableIO() -> OSStatus
    {
        // AudioUnitの入力を有効化、出力を無効化する。
        // デフォルトは出力有効設定
        var enableIO: UInt32 = 1
        var disableIO: UInt32 = 0
        var err: OSStatus?
        
        err = AudioUnitSetProperty(AudioData.sharedInstance.inputUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableIO, UInt32(sizeof(UInt32)))
        
        if err == noErr
        {
            err = AudioUnitSetProperty(AudioData.sharedInstance.inputUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &disableIO, UInt32(sizeof(UInt32)))
        }
        
        return err!
    }
    
    private func setUpMicInput() -> OSStatus
    {
        // 入力デバイスを設定
        
        var inputDeviceId = AudioDeviceID()
        var address =  AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var size = UInt32(sizeof(AudioDeviceID))
        
        var err = AudioObjectGetPropertyData(UInt32(kAudioObjectSystemObject), &address, 0, nil, &size, &inputDeviceId)
        // デフォルトの入力デバイスを取得
        
        if err == noErr
        {
            err = AudioUnitSetProperty(AudioData.sharedInstance.inputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &inputDeviceId, size)
            // AudioUnitにデバイスを設定
        }
        
        // 確認用
        print("DeviceName:",self.deviceName(inputDeviceId))
        print("BufferSize:",self.bufferSize(inputDeviceId))
        
        return err
    }
    
    private func deviceName(let devID: AudioDeviceID) -> String
    {
        // 名前確認
        var address =  AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var name: CFStringRef?
        var stringsize = UInt32(sizeof(CFStringRef))
        
        AudioObjectGetPropertyData(devID, &address, 0, nil, &stringsize, &name)
        
        let string = String(name)
        return string
        
    }
    
    private func bufferSize(let devID: AudioDeviceID) -> UInt32
    {
        // バッファサイズ確認
        var address =  AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyBufferFrameSize, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var buf: UInt32 = 0
        var bufSize = UInt32(sizeof(UInt32))
        
        AudioObjectGetPropertyData(devID, &address, 0, nil, &bufSize, &buf)
        
        return buf
    }
    
    private func setUpInputFormat() -> OSStatus
    {
        // サンプリングレートやデータビット数、データフォーマットなどを設定
        var audioFormat = AudioStreamBasicDescription()
        audioFormat.mBitsPerChannel = 16
        audioFormat.mBytesPerFrame = 4
        audioFormat.mBytesPerPacket = 4
        audioFormat.mChannelsPerFrame = 2
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
        audioFormat.mFormatID = kAudioFormatLinearPCM
        audioFormat.mFramesPerPacket = 1
        audioFormat.mSampleRate = 44100.00
        
        let size = UInt32(sizeof(AudioStreamBasicDescription))
        let err = AudioUnitSetProperty(AudioData.sharedInstance.inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &audioFormat, size)
        
        return err
    }
    
    private func setUpCallback() -> OSStatus
    {
        // サンプリング用コールバックを設定
        var input = AURenderCallbackStruct(inputProc: self.inputProc, inputProcRefCon: nil)
        
        let size = UInt32(sizeof(AURenderCallbackStruct))
        let err = AudioUnitSetProperty(AudioData.sharedInstance.inputUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0, &input, size)
        
        return err
    }
    
    func setUpAudioDevice()
    {
        if self.setUpAudioHAL() != noErr
        {
            print("Error: setUpAudioHAL");
            exit(-1)
        }
        
        if self.setUpEnableIO() != noErr
        {
            print("Error: setUpEnable");
            exit(-1)
        }
        
        if self.setUpMicInput() != noErr
        {
            print("Error: setUpMicInput");
            exit(-1)
        }
        
        if self.setUpInputFormat() != noErr
        {
            print("Error: setUpInputFormat");
            exit(-1)
        }
        
        if self.setUpCallback() != noErr
        {
            print("Error: setUpCallback");
            exit(-1)
        }
        
        if AudioUnitInitialize(AudioData.sharedInstance.inputUnit) != noErr
        {
            print("Error: AudioUnitInitialize");
            exit(-1)
        }
    }
    
    func startAudio()
    {
        if AudioOutputUnitStart(AudioData.sharedInstance.inputUnit) != noErr
        {
            print("Error: AudioOutputUnitStart");
            exit(-1)
        }
    }
    
    func stopAudio()
    {
        if AudioOutputUnitStop(AudioData.sharedInstance.inputUnit) != noErr
        {
            print("Error: AudioOutputUnitStop");
            exit(-1)
        }
    }
}