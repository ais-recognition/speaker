//
//  MessageInputAccessoryView.swift
//  SpeakerClient
//
//  Created by to0 on 3/13/15.
//  Copyright (c) 2015 to0. All rights reserved.
//

import UIKit

protocol MessageInputAccessoryViewDelegate {
    func didEndInput(inputView: MessageInputAccessoryView, message: String)
    
}

class MessageInputAccessoryView: UIToolbar, UITextViewDelegate {
    let textView = UITextView(frame: CGRectZero)
    let sendButton = UIButton.buttonWithType(.System) as! UIButton
    var messageDelegate: MessageInputAccessoryViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.backgroundColor = UIColor(white: <#CGFloat#>, alpha: <#CGFloat#>)
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
        sendButton.setTitle("Send", forState: .Normal)
        sendButton.setTitleColor(UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1), forState: .Disabled)
        sendButton.setTitleColor(UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1), forState: .Normal)
        sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        sendButton.addTarget(self, action: "didTapSendButton", forControlEvents: UIControlEvents.TouchUpInside)
        self.addSubview(sendButton)
        
        // Auto Layout allows `sendButton` to change width, e.g., for localization.
        textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: 8))
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 7.5))
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Right, relatedBy: .Equal, toItem: sendButton, attribute: .Left, multiplier: 1, constant: -2))
        self.addConstraint(NSLayoutConstraint(item: textView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -8))
        self.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -4.5))

    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func textViewDidChange(textView: UITextView) {
//        updateTextViewHeight()
        sendButton.enabled = textView.hasText()
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
