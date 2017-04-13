//
//  main.swift
//  MicInput
//
//  Created by 湯川 修平 on 1/11/16.
//  Copyright © 2016 湯川 修平. All rights reserved.
//

import Foundation

let micInput = MicInput()

micInput.setUpAudioDevice()

micInput.startAudio()

// Enterで終了
getchar()

micInput.stopAudio()
