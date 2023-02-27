//
//  MessageRow.swift
//  ChatGPTBot
//
//  Created by bard on 2023/02/24.
//

import SwiftUI

struct MessageRow: Identifiable {
    let id = UUID()
    
    var isInteractingWithChatGPT: Bool
    
    let sendImage: String
    let sendText: String
    let responseImage: String
    var responseText: String
    var responseError: String?
}
