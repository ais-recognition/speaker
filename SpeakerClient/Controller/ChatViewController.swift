//
//  ChatViewController.swift
//  speaker
//
//  Created by to0 on 2/26/15.
//  Copyright (c) 2015 to0. All rights reserved.
//

import AudioToolbox
import UIKit

let messageFontSize: CGFloat = 17
let toolBarMinHeight: CGFloat = 44
let textViewMaxHeight: (portrait: CGFloat, landscape: CGFloat) = (portrait: 272, landscape: 90)
let messageSoundOutgoing: SystemSoundID = createMessageSoundOutgoing()

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    let chat: Chat
    var tableView: UITableView!
    var toolBar: MessageInputAccessoryView!
    var textView: UITextView!
    var sendButton: UIButton!
    var rotating = false
    let mqtt = MQTTClient(clientId: "ios")

    override var inputAccessoryView: UIView! {
        if toolBar == nil {
            toolBar = MessageInputAccessoryView(frame: CGRectMake(0, 0, 0, toolBarMinHeight-0.5))
        }
        return toolBar
//    get {
//        if toolBar == nil {
//            toolBar = UIToolbar(frame: CGRectMake(0, 0, 0, toolBarMinHeight-0.5))
//
//            textView = UITextView(frame: CGRectZero)
//            textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
//            textView.delegate = self
//            textView.font = UIFont.systemFontOfSize(messageFontSize)
//            textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
//            textView.layer.borderWidth = 0.5
//            textView.layer.cornerRadius = 5
////        textView.placeholder = "Message"
//            textView.scrollsToTop = false
//            textView.textContainerInset = UIEdgeInsetsMake(4, 3, 3, 3)
//            toolBar.addSubview(textView)
//
//            sendButton = UIButton.buttonWithType(.System) as! UIButton
//            sendButton.enabled = false
//            sendButton.titleLabel?.font = UIFont.boldSystemFontOfSize(17)
//            sendButton.setTitle("Send", forState: .Normal)
//            sendButton.setTitleColor(UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1), forState: .Disabled)
//            sendButton.setTitleColor(UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1), forState: .Normal)
//            sendButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
//            sendButton.addTarget(self, action: "sendAction", forControlEvents: UIControlEvents.TouchUpInside)
//            toolBar.addSubview(sendButton)
//
//            // Auto Layout allows `sendButton` to change width, e.g., for localization.
//            textView.setTranslatesAutoresizingMaskIntoConstraints(false)
//            sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)
//            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Left, relatedBy: .Equal, toItem: toolBar, attribute: .Left, multiplier: 1, constant: 8))
//            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .Equal, toItem: toolBar, attribute: .Top, multiplier: 1, constant: 7.5))
//            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Right, relatedBy: .Equal, toItem: sendButton, attribute: .Left, multiplier: 1, constant: -2))
//            toolBar.addConstraint(NSLayoutConstraint(item: textView, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Bottom, multiplier: 1, constant: -8))
//            toolBar.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Right, relatedBy: .Equal, toItem: toolBar, attribute: .Right, multiplier: 1, constant: 0))
//            toolBar.addConstraint(NSLayoutConstraint(item: sendButton, attribute: .Bottom, relatedBy: .Equal, toItem: toolBar, attribute: .Bottom, multiplier: 1, constant: -4.5))
//        }
//        return toolBar
//    }
    }

    init(chat: Chat) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
        title = chat.user.name
    }

    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
        self.chat =  Chat(user: User(ID: 2, username: "samihah", firstName: "Angel", lastName: "Rao"), lastMessageText: "6 sounds good :-)", lastMessageSentDate: NSDate())
        super.init(nibName: nil, bundle: nil)
        title = chat.user.name

    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mqtt.messageHandler = {(message: MQTTMessage!) -> Void in
            println(message.payloadString())
        }
        
        mqtt.connectToHost("127.0.0.1", completionHandler: {(code: MQTTConnectionReturnCode) -> Void in
            println(code)
            if code.value  == 0 {
                self.mqtt.subscribe("aaaa", withCompletionHandler: nil)
            }
        })

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
        chat.draft = toolBar.textView.text
//        chat.draft = textView.text
    }

    // This gets called a lot. Perhaps there's a better way to know when `view.window` has been set?
    override func viewDidLayoutSubviews()  {
        super.viewDidLayoutSubviews()
//        toolBar.textView.becomeFirstResponder()

        if !chat.draft.isEmpty {
            toolBar.textView.text = chat.draft
//            textView.text = chat.draft
            chat.draft = ""
            textViewDidChange(toolBar.textView)
            toolBar.textView.becomeFirstResponder()
        }
    }

//    // #iOS7.1
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)

        if UIInterfaceOrientationIsLandscape(toInterfaceOrientation) {
            if toolBar.frame.height > textViewMaxHeight.landscape {
                toolBar.frame.size.height = textViewMaxHeight.landscape+8*2-0.5
            }
        } else { // portrait
            updateTextViewHeight()
        }
    }
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
    func tableView(tableView: UITableView!, willSelectRowAtIndexPath indexPath: NSIndexPath!)-> NSIndexPath!?{
        return nil
    }

    func textViewDidChange(textView: UITextView) {
        updateTextViewHeight()
        toolBar.sendButton.enabled = toolBar.textView.hasText()
    }

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

    func updateTextViewHeight() {
        let oldHeight = toolBar.textView.frame.height
        let maxHeight = UIInterfaceOrientationIsPortrait(interfaceOrientation) ? textViewMaxHeight.portrait : textViewMaxHeight.landscape
        var newHeight = min(toolBar.textView.sizeThatFits(CGSize(width: toolBar.textView.frame.width, height: CGFloat.max)).height, maxHeight)
        #if arch(x86_64) || arch(arm64)
            newHeight = ceil(newHeight)
        #else
            newHeight = CGFloat(ceilf(newHeight.native))
        #endif
        if newHeight != oldHeight {
            toolBar.frame.size.height = newHeight+8*2-0.5
        }
    }

    func sendAction() {
        // Autocomplete text before sending #hack
        toolBar.textView.resignFirstResponder()
        toolBar.textView.becomeFirstResponder()

        chat.loadedMessages.append([Message(incoming: false, text: toolBar.textView.text, sentDate: NSDate())])
        toolBar.textView.text = nil
        updateTextViewHeight()
        toolBar.sendButton.enabled = false

        let lastSection = tableView.numberOfSections()
        tableView.beginUpdates()
        tableView.insertSections(NSIndexSet(index: lastSection), withRowAnimation: .Automatic)
        tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow: 0, inSection: lastSection),
            NSIndexPath(forRow: 1, inSection: lastSection)
            ], withRowAnimation: .Automatic)
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

