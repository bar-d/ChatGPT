//
//  ChatGPTAPI.swift
//  ChatGPTBot
//
//  Created by bard on 2023/02/24.
//

import Foundation

final class ChatGPTAPI {
    
    // MARK: Properties
    
    private let apiKey: String
    private let urlSession = URLSession.shared
    private var urlRequest: URLRequest {
        guard let url = URL(string: "https://api.openai.com/v1/completions") else {
            fatalError("invalid URL")
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }
        return urlRequest
    }
    
    private let jsonDecoder = JSONDecoder()
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter
    }()
    private var headers: [String: String] {
        [
            "Content-Type" : "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    
    private var historyList: [String] = []
    
    private var historyListText: String {
        historyList.joined()
    }
    
    private var basePrompt: String {
        "You are ChatGPT, a large language model trained by OpenAI. Respond conversationally. Do not answer as the user. Current date: \(dateFormatter.string(from: Date()))"
        + "\n\n"
        + "User: Hello\n"
        + "ChatGPT: Hello! How can I help you today? <|im_end|>\n\n\n"
    }
    
    // MARK: - Initializers
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Methods
    
    func sendMessageStream(text: String) async throws -> AsyncThrowingStream<String, Error> {
        var urlRequest = urlRequest
        urlRequest.httpBody = try jsonBody(text: text)
        
        let (result, response) = try await urlSession.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.badResponse(responseCode: httpResponse.statusCode)
        }
        
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    var streamText = ""
                    for try await line in result.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let response = try? jsonDecoder.decode(CompletionResponse.self, from: data),
                           let text = response.choices.first?.text {
                            streamText += text
                            continuation.yield(text)
                        }
                    }
                    historyList.append(streamText)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func sendMessage(_ text: String) async throws -> String {
        var urlRequest = urlRequest
        urlRequest.httpBody = try jsonBody(text: text, stream: false)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.badResponse(responseCode: httpResponse.statusCode)
        }
        
        do {
            let completionResponse = try jsonDecoder.decode(CompletionResponse.self, from: data)
            let responseText = completionResponse.choices.first?.text ?? ""
            historyList.append(responseText)
            return responseText
        } catch {
            throw APIError.unknown(error: error)
        }
    }
    
    private func generateChatGPTPrompt(from text: String) -> String {
        var prompt = basePrompt + historyListText + "User: \(text)\nChatGPT:"
        if prompt.count > (4000 * 4) {
            _ = historyList.dropFirst()
            prompt = generateChatGPTPrompt(from: text)
        }
        
        return prompt
    }
    
    private func jsonBody(text: String, stream: Bool = true) throws -> Data {
        let jsonBody: [String: Any] = [
            "model": "text-davinci-003",
            "temperature": 0.5,
            "max_tokens": 1024,
            "prompt": generateChatGPTPrompt(from: text),
            "stop": [
                "\n\n\n",
                "<|im_end|>"
            ],
            "stream": stream
        ]
        
        return try JSONSerialization.data(withJSONObject: jsonBody)
    }
}

enum APIError: Error {
    case invalidResponse
    case badResponse(responseCode: Int)
    case unknown(error: Error)

    var description: String {
        switch self {
        case .invalidResponse:
            return "Invalid Response"
        case .badResponse(let responseCode):
            return "Bad Response: \(responseCode)"
        case .unknown(error: let error):
            return "error: \(error)"
        }
    }
}
