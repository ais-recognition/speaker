//
//  Message.swift
//  speaker
//
//  Created by to0 on 2/26/15.
//  Copyright (c) 2015 to0. All rights reserved.
//
import Foundation

class Message {
    let incoming: Bool
    let text: String
    let sentDate: NSDate

    init(incoming: Bool, text: String, sentDate: NSDate) {
        self.incoming = incoming
        self.text = text
        self.sentDate = sentDate
    }
}
