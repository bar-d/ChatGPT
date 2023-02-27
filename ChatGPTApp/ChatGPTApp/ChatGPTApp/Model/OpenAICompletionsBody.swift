//
//  OpenAICompletionsBody.swift
//  ChatGPTApp
//
//  Created by bard on 2023/02/27.
//

struct OpenAICompletionsBody: Encodable {
    let model: String
    let prompt: String
    let temperature: Float?
    let max_tokens: Int?
}
