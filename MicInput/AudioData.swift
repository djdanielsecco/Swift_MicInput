//
//  AudioData.swift
//  MicInput
//
//  Created by 湯川 修平 on 2/21/16.
//  Copyright © 2016 湯川 修平. All rights reserved.
//

import Foundation
import CoreAudio
import AudioUnit

class AudioData
{
    // Mic用AudioUnit
    var inputUnit = AudioUnit()
    
    // 取得したAudioData
    var audioDataArray: UnsafeBufferPointer<Int16>? = nil
    
    class var sharedInstance: AudioData
    {
        struct Static
        {
            static let instance : AudioData = AudioData()
        }
        return Static.instance
    }
}
