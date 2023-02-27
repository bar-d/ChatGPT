//
//  CompletionResponse.swift
//  ChatGPTBot
//
//  Created by bard on 2023/02/25.
//

struct CompletionResponse: Decodable {
    let choices: [Choice]
}
