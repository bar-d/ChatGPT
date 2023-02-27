//
//  OpenAICompletionsResponse.swift
//  ChatGPTApp
//
//  Created by bard on 2023/02/27.
//

struct OpenAICompletionsResponse: Decodable {
    let id: String
    let choices: [OpenAICompletionsChoices]
}
