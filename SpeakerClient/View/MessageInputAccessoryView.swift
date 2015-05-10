//
//  MessageInputAccessoryView.swift
//  SpeakerClient
//
//  Created by to0 on 3/13/15.
//  Copyright (c) 2015 to0. All rights reserved.
//

import UIKit
import AVFoundation

protocol MessageInputAccessoryViewDelegate {
    func didEndInput(inputView: MessageInputAccessoryView, message: String)
    func didEndRecording(voiceData: NSData)
}

class MessageInputAccessoryView: UIToolbar, UITextViewDelegate, AVAudioRecorderDelegate {
    let BUTTON_NORMAL_COLOR = UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1)
    let BUTTON_DISABLE_COLOR = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
    let textView = UITextView(frame: CGRectZero)
    let sendButton = UIButton.buttonWithType(.System) as! UIButton
    let voiceButton = UIButton.buttonWithType(.System) as! UIButton
    var messageDelegate: MessageInputAccessoryViewDelegate?
    var audioRecorder: AVAudioRecorder?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let fileManager = NSFileManager()
        
        let documentsFolderUrl = fileManager.URLForDirectory(.DocumentDirectory,
            inDomain: .UserDomainMask,
            appropriateForURL: nil,
            create: false,
            error: nil)
        
        let voiceUrl = documentsFolderUrl!.URLByAppendingPathComponent("Recording.m4a")
        let voiceSetting = [AVFormatIDKey: kAudioFormatMPEG4AAC as NSNumber,
            AVSampleRateKey: 8000.0 as NSNumber,
            AVNumberOfChannelsKey : 1 as NSNumber,
            AVEncoderAudioQualityKey : AVAudioQuality.Low.rawValue as NSNumber]
        
        audioRecorder = AVAudioRecorder(URL: voiceUrl, settings: voiceSetting, error: nil)
        audioRecorder!.delegate = self
        audioRecorder!.prepareToRecord()
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DuckOthers, error: nil)
        
        textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
        textView.delegate = self
        textView.font = UIFont.systemFontOfSize(messageFontSize)
        textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
        textView.layer.borderWidth = 0.5
        textView.layer.cornerRadius = 5
        textView.scrollsToTop = false
        textView.textContainerInset = UIEdgeInsetsMake(4, 3, 3, 3)
        self.addSubview(textView)
        
        sendButton.enabled = false
        sendButton.titleLabel?.font = UIFont.boldSystemFontOfSize(17)
        sendButton.setTitle("Set Name", forState: .Normal)
        sendButton.setTitleColor(BUTTON_DISABLE_COLOR, forState: .Disabled)
        sendButton.setTitleColor(BUTTON_NORMAL_COLOR, forState: .Normal)
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        sendButton.addTarget(self, action: "didTapSendButton", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(sendButton)
        
        voiceButton.setTitle("Voice", forState: .Normal)
        voiceButton.titleLabel?.font = UIFont.boldSystemFontOfSize(17)
        voiceButton.setTitleColor(BUTTON_NORMAL_COLOR, forState: .Normal)
        voiceButton.setTitleColor(BUTTON_DISABLE_COLOR, forState: .Disabled)
        voiceButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 20, bottom: 6, right: 20)
        voiceButton.addTarget(self, action: "didTouchVoiceButton", forControlEvents: UIControlEvents.TouchDown)
        self.addSubview(voiceButton)
        voiceButton.addTarget(self, action: "didReleaseVoiceButton", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Auto Layout allows `sendButton` to change width, e.g., for localization.
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        voiceButton.setTranslatesAutoresizingMaskIntoConstraints(false)// why?
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Left, relatedBy: .Equal, toItem: voiceButton, attribute: .Right, multiplier: 1, constant: -2))
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 7.5))
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Right, relatedBy: .Equal, toItem: sendButton, attribute: .Left, multiplier: 1, constant: -2))
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -8))
        self.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -4.5))
        self.addConstraint(NSLayoutConstraint(item: voiceButton, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: voiceButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -4.5))

    }
    
    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")

    }
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        println(flag)
        var error: NSError?
        let player = AVAudioPlayer(contentsOfURL: recorder.url, error: &error)
        println(error)
        player.play()
        let data = NSData(contentsOfURL: audioRecorder!.url)
        println(data)
        messageDelegate?.didEndRecording(data!)
    }
    
    func textViewDidChange(textView: UITextView) {
//        updateTextViewHeight()
        sendButton.enabled = textView.hasText()
    }
    
    func didTouchVoiceButton() {
        // start recording
        let session = AVAudioSession.sharedInstance()
        session.setActive(true, error: nil)
        audioRecorder?.record()
    }
    
    func didReleaseVoiceButton() {
        // end recording
        audioRecorder?.stop()
        AVAudioSession.sharedInstance().setActive(false, error: nil)
    }
    
    func didTapSendButton() {
        // Autocomplete text before sending #hack
//        textView.resignFirstResponder()
//        textView.becomeFirstResponder()
        let message = textView.text
        textView.text = nil
//        updateTextViewHeight()
        sendButton.enabled = false
        messageDelegate?.didEndInput(self, message: message)
    }
    //    func updateTextViewHeight() {
    //        let oldHeight = toolBar.textView.frame.height
    //        let maxHeight = UIInterfaceOrientationIsPortrait(interfaceOrientation) ? textViewMaxHeight.portrait : textViewMaxHeight.landscape
    //        var newHeight = min(toolBar.textView.sizeThatFits(CGSize(width: toolBar.textView.frame.width, height: CGFloat.max)).height, maxHeight)
    //        #if arch(x86_64) || arch(arm64)
    //            newHeight = ceil(newHeight)
    //        #else
    //            newHeight = CGFloat(ceilf(newHeight.native))
    //        #endif
    //        if newHeight != oldHeight {
    //            toolBar.frame.size.height = newHeight+8*2-0.5
    //        }
    //    }
}
