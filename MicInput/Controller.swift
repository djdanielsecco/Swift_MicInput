//
//  Controller.swift
//  MicInput
//
//  Created by 湯川 修平 on 2/21/16.
//  Copyright © 2016 湯川 修平. All rights reserved.
//

import Cocoa

class Controller: NSViewController {

    @IBOutlet var levelView: NSView?
    @IBOutlet var fftView: NSView?
    @IBOutlet var audioStartButton: NSButton?
    @IBAction func buttonTapped(sender: AnyObject)
    {
        self.isCaptureAudio = !self.isCaptureAudio
        if self.isCaptureAudio
        {
            micInput.startAudio()
            self.audioStartButton!.title = "Start"
        }
        else
        {
            micInput.stopAudio()
            self.audioStartButton!.title = "Stop"
        }
    }
    
    var isCaptureAudio = false
    let micInput = MicInput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // AudioUnitのセットアップ
        self.micInput.setUpAudioDevice()
    }
    
    func updateLevelView()
    {
        
    }
    
    func updateFFTView()
    {
        
    }
}
