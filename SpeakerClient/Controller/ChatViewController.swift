//
//  ChatViewController.swift
//  speaker
//
//  Created by to0 on 2/26/15.
//  Copyright (c) 2015 to0. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

let messageFontSize: CGFloat = 17
let toolBarMinHeight: CGFloat = 44
let textViewMaxHeight: (portrait: CGFloat, landscape: CGFloat) = (portrait: 272, landscape: 90)
let messageSoundOutgoing: SystemSoundID = createMessageSoundOutgoing()

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioRecorderDelegate, MessageInputAccessoryViewDelegate {
    let chat: Chat = Chat(user: User(ID: 2, username: "samihah", firstName: "Angel", lastName: "Rao"), lastMessageText: "6 sounds good :-)", lastMessageSentDate: NSDate())
//    var audioRecorder: AVAudioRecorder
    var tableView: UITableView!
    var inputAccessory: MessageInputAccessoryView!
    var rotating = false
    let mqtt = MQTTClient(clientId: "ios")
    var remoteAudioPath: String?

    override var inputAccessoryView: UIView! {
        if inputAccessory == nil {
            inputAccessory = MessageInputAccessoryView(frame: CGRectMake(0, 0, 0, toolBarMinHeight-0.5))
            inputAccessory.messageDelegate = self
        }
        return inputAccessory
    }

//    init(chat: Chat) {
//        self.chat = chat
//        super.init(nibName: nil, bundle: nil)
//        title = chat.user.name
//    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = chat.user.name
        mqtt.messageHandler = {[weak self] (message: MQTTMessage!) -> Void in
            
            let topic = message.topic
            let type = topic.componentsSeparatedByString("/")[2]
            var speaker: String
            if type == "result" {
                speaker = "\(message.payloadString()) is speaking"
            }
            else if type == "unknown" {
                speaker = "We don't have your voice record?"
                self?.remoteAudioPath = message.payloadString()
            }
            else {
                return
            }
            println(speaker)
            
            dispatch_async(dispatch_get_main_queue(), {
                self?.chat.loadedMessages.append([Message(incoming: true, text: speaker, sentDate: NSDate())])
                self?.inputAccessory.textView.text = nil
                //        updateTextViewHeight()
                
                let lastSection = tableView.numberOfSections()
                self?.tableView.beginUpdates()
                self?.tableView.insertSections(NSIndexSet(index: lastSection), withRowAnimation: UITableViewRowAnimation.Right)
                self?.tableView.insertRowsAtIndexPaths([
                    NSIndexPath(forRow: 0, inSection: lastSection),
                    NSIndexPath(forRow: 1, inSection: lastSection)
                    ], withRowAnimation: UITableViewRowAnimation.Right)
                self?.tableView.endUpdates()
                self?.tableViewScrollToBottomAnimated(true)
                AudioServicesPlaySystemSound(messageSoundOutgoing)
            })
        }
        
        mqtt.connectToHost("iot.eclipse.org", completionHandler: {[weak self](code: MQTTConnectionReturnCode) -> Void in
            println(code)
            if code.value  == 0 {
                self?.mqtt.subscribe("ais/recognize/result/+", withCompletionHandler: nil)
                self?.mqtt.subscribe("ais/recognize/unknown/+", withCompletionHandler: nil)
            }
        })
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        chat.loadedMessages = []

        let whiteColor = UIColor.whiteColor()
        view.backgroundColor = whiteColor // smooths push animation

        tableView = UITableView(frame: view.bounds, style: .Plain)
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        tableView.backgroundColor = whiteColor
        let edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: toolBarMinHeight, right: 0)
        tableView.contentInset = edgeInsets
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .Interactive
        tableView.estimatedRowHeight = 44
        tableView.separatorStyle = .None
        tableView.registerClass(MessageSentDateCell.self, forCellReuseIdentifier: NSStringFromClass(MessageSentDateCell))
        view.addSubview(tableView)

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        // tableViewScrollToBottomAnimated(false) // doesn't work
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidAppear(animated: Bool)  {
        super.viewDidAppear(animated)
        tableView.flashScrollIndicators()
    }

    override func viewWillDisappear(animated: Bool)  {
        super.viewWillDisappear(animated)
        chat.draft = inputAccessory.textView.text
//        chat.draft = textView.text
    }

//     This gets called a lot. Perhaps there's a better way to know when `view.window` has been set?
//    override func viewDidLayoutSubviews()  {
//        super.viewDidLayoutSubviews()
//        toolBar.textView.becomeFirstResponder()

//        if !chat.draft.isEmpty {
//            toolBar.textView.text = chat.draft
////            textView.text = chat.draft
//            chat.draft = ""
////            textViewDidChange(toolBar.textView)
//            toolBar.textView.becomeFirstResponder()
//        }
//    }

//    // #iOS7.1
//    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
//        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)
//
//        if UIInterfaceOrientationIsLandscape(toInterfaceOrientation) {
//            if toolBar.frame.height > textViewMaxHeight.landscape {
//                toolBar.frame.size.height = textViewMaxHeight.landscape+8*2-0.5
//            }
//        } else { // portrait
////            updateTextViewHeight()
//        }
//    }
//    // #iOS8
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator!) {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return chat.loadedMessages.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chat.loadedMessages[section].count + 1 // for sent-date cell
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(MessageSentDateCell), forIndexPath: indexPath)as! MessageSentDateCell
            let message = chat.loadedMessages[indexPath.section][0]
            dateFormatter.dateStyle = .ShortStyle
            dateFormatter.timeStyle = .ShortStyle
            cell.sentDateLabel.text = dateFormatter.stringFromDate(message.sentDate)
            return cell
        } else {
            let cellIdentifier = NSStringFromClass(MessageBubbleCell)
            var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as!MessageBubbleCell!
            if cell == nil {
                cell = MessageBubbleCell(style: .Default, reuseIdentifier: cellIdentifier)
            }
            let message = chat.loadedMessages[indexPath.section][indexPath.row-1]
            cell.configureWithMessage(message)
            return cell
        }
    }

    // Reserve row selection #CopyMessage
//    func tableView(tableView: UITableView!, willSelectRowAtIndexPath indexPath: NSIndexPath!)-> NSIndexPath!?{
//        return nil
//    }

//    func textViewDidChange(textView: UITextView) {
//        updateTextViewHeight()
//        toolBar.sendButton.enabled = toolBar.textView.hasText()
//    }

    func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        let insetOld = tableView.contentInset
        let insetChange = insetNewBottom - insetOld.bottom
        let overflow = tableView.contentSize.height - (tableView.frame.height-insetOld.top-insetOld.bottom)

        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animations: (() -> Void) = {
            if !(self.tableView.tracking || self.tableView.decelerating) {
                // Move content with keyboard
                if overflow > 0 {                   // scrollable before
                    self.tableView.contentOffset.y += insetChange
                    if self.tableView.contentOffset.y < -insetOld.top {
                        self.tableView.contentOffset.y = -insetOld.top
                    }
                } else if insetChange > -overflow { // scrollable after
                    self.tableView.contentOffset.y += insetChange + overflow
                }
            }
        }
        if duration > 0 {
            let options = UIViewAnimationOptions(UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16)) // http://stackoverflow.com/a/18873820/242933
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }

    func keyboardDidShow(notification: NSNotification) {
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height

        // Inset `tableView` with keyboard
        let contentOffsetY = tableView.contentOffset.y
        tableView.contentInset.bottom = insetNewBottom
        tableView.scrollIndicatorInsets.bottom = insetNewBottom
        // Prevents jump after keyboard dismissal
        if self.tableView.tracking || self.tableView.decelerating {
            tableView.contentOffset.y = contentOffsetY
        }
    }
    func didEndRecording(voiceData: NSData) {
        mqtt.publishData(voiceData, toTopic: "ais/recognize/voice/test_id", withQos: MQTTQualityOfService(0), retain: true, completionHandler: nil)
        chat.loadedMessages.append([Message(incoming: false, text: "Voice sent", sentDate: NSDate())])
        inputAccessory.textView.text = nil
        //        updateTextViewHeight()
        
        let lastSection = tableView.numberOfSections()
        tableView.beginUpdates()
        tableView.insertSections(NSIndexSet(index: lastSection), withRowAnimation: UITableViewRowAnimation.Right)
        tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow: 0, inSection: lastSection),
            NSIndexPath(forRow: 1, inSection: lastSection)
            ], withRowAnimation: UITableViewRowAnimation.Right)
        tableView.endUpdates()
        tableViewScrollToBottomAnimated(true)
        AudioServicesPlaySystemSound(messageSoundOutgoing)
    }
    
    func didEndInput(inputView: MessageInputAccessoryView, message: String) {
        if remoteAudioPath == nil {
            return
        }
        mqtt.publishString("\(remoteAudioPath!)=\(message)", toTopic: "ais/recognize/setname/test_id", withQos: MQTTQualityOfService(0), retain: true, completionHandler: nil)
        chat.loadedMessages.append([Message(incoming: false, text: message, sentDate: NSDate())])
        inputAccessory.textView.text = nil
//        updateTextViewHeight()

        let lastSection = tableView.numberOfSections()
        tableView.beginUpdates()
        tableView.insertSections(NSIndexSet(index: lastSection), withRowAnimation: UITableViewRowAnimation.Right)
        tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow: 0, inSection: lastSection),
            NSIndexPath(forRow: 1, inSection: lastSection)
            ], withRowAnimation: UITableViewRowAnimation.Right)
        tableView.endUpdates()
        tableViewScrollToBottomAnimated(true)
        AudioServicesPlaySystemSound(messageSoundOutgoing)
    }

    func tableViewScrollToBottomAnimated(animated: Bool) {
        let numberOfSections = tableView.numberOfSections()
        let numberOfRows = tableView.numberOfRowsInSection(numberOfSections - 1)
        
        if numberOfRows > 0 {
            let indexPath = NSIndexPath(forRow: numberOfRows - 1, inSection: numberOfSections - 1)
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: animated)
        }
    }
}

func createMessageSoundOutgoing() -> SystemSoundID {
    var soundID: SystemSoundID = 0
    let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "MessageOutgoing", "aiff", nil)
    AudioServicesCreateSystemSoundID(soundURL, &soundID)
    return soundID
}

