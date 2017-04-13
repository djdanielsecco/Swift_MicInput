//
//  FFT.swift
//  MicInput
//
//  Created by 湯川 修平 on 2/21/16.
//  Copyright © 2016 湯川 修平. All rights reserved.
//

import Foundation
import CoreAudio
import AudioUnit
import Accelerate

struct Sampling
{
    let samplingFrequency = 1024
    let samplingRate = 44100
    let FFTLength = 1024
}

class FFT
{
    private class func audioDataForDSP() -> UnsafePointer<Float>
    {
        let positive: Float = 32767.0
        let negative: Float = 32768.0
        
        let samplingFrequency = Sampling().samplingFrequency
        
        let dataForDSP = AudioData.sharedInstance.audioDataArray?.baseAddress
        let output = UnsafeMutablePointer<Float>.alloc(samplingFrequency)
        
        vDSP_vflt16(dataForDSP!, 1, output, 1, UInt(samplingFrequency))

        for var i = 0 ;i < samplingFrequency; i++
        {
            if dataForDSP![i] >= 0
            {
                output[i] = output[i] / positive
            }
            else
            {
                output[i] = output[i] / negative
            }
        }
        
        // output解放
        let returnData = UnsafePointer<Float>(output)
        output.dealloc(samplingFrequency)

        return returnData
    }
    
    private class func fft(buffer :UnsafePointer<Float>, splitComplex: UnsafeMutablePointer<DSPSplitComplex>)
    {
        let fftLength = Sampling().FFTLength
        
        let setup = vDSP_create_fftsetup(vDSP_Length(log2(CDouble(fftLength))), FFTRadix(kFFTRadix2))

        let xAsComplex = UnsafePointer<DSPComplex>(buffer)
        vDSP_ctoz(xAsComplex, 2, splitComplex, 1, vDSP_Length(fftLength/2))
        vDSP_fft_zrip(setup, splitComplex, 1, vDSP_Length(log2(CDouble(fftLength))), FFTDirection(kFFTDirection_Forward))
        vDSP_destroy_fftsetup(setup)
    }
    
    class func addAudioData(bufferList: AudioBufferList)
    {
        let audioData = UnsafePointer<Int16>(bufferList.mBuffers.mData)
        AudioData.sharedInstance.audioDataArray = UnsafeBufferPointer<Int16>(start:audioData, count: Int(bufferList.mBuffers.mDataByteSize)/sizeof(Int16))
        
         FFTData()
    }
    
    class func FFTData() -> UnsafePointer<Float>
    {
        let fftLength = Sampling().FFTLength
        let fftData = UnsafeMutablePointer<Float>.alloc(fftLength)
        let audioData = self.audioDataForDSP()
        
        let complexImage = UnsafeMutablePointer<Float>.alloc(fftLength)
        let complexReal = UnsafeMutablePointer<Float>.alloc(fftLength)
        var complex = DSPSplitComplex.init(realp: complexReal, imagp: complexImage)
        
        
        //make window (fft size)
        let window = UnsafeMutablePointer<Float>.alloc(fftLength)
        //hanning window
        vDSP_hann_window(window, UInt(fftLength), 0);
        //windowing
        vDSP_vmul(audioData, 1, window, 1, fftData, 1, UInt(fftLength))
        
        self.fft(fftData, splitComplex: &complex)
        
        
        // to check
        let magnitude = UnsafeMutablePointer<Float>.alloc(fftLength)
        vDSP_zvabs(&complex, 1, magnitude, 1, UInt(fftLength))
        
        let freq_bins = Float(44100.0 / 512.0)
        
        for i in 0  ..< fftLength/2
        {
            if Float(i) * freq_bins > 0 && Float(i) * freq_bins < 1000
            {
                print(Float(i) * freq_bins , ": magnitude = " , magnitude[i])
            }
        }
        
        let returnData = UnsafePointer<Float>(fftData)
        
        fftData.dealloc(fftLength)
        complexImage.dealloc(fftLength)
        complexReal.dealloc(fftLength)
        window.dealloc(fftLength)
        
        return returnData
    }
    
    /*
    class func signalData() -> UnsafePointer<Float>
    {
        
    }
    */
}
