//
//  ViewModel.swift
//  ChatGPTBot
//
//  Created by bard on 2023/02/24.
//

import Foundation

final class ViewModel: ObservableObject {
    
    // MARK: Properties
    
    @Published var isInteractingWithChatGPT = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    
    private let api: ChatGPTAPI
    
    
    // MARK: - Initializers
    
    init(api: ChatGPTAPI) {
        self.api = api
    }
    
    // MARK: - Methods
    
    @MainActor
    func sendTapped() async {
        let text = inputMessage
        inputMessage = ""
        await send(text: text)
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        messages.remove(at: index)
        await send(text: message.sendText)
    }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithChatGPT = false
        
        var streamText = ""
        var messageRow = MessageRow(
            isInteractingWithChatGPT: true,
            sendImage: "person.circle.fill",
            sendText: text,
            responseImage: "openai",
            responseText: streamText,
            responseError: nil
        )
        
        messages.append(messageRow)
        
        do {
            let stream = try await api.sendMessageStream(text: text)
            for try await text in stream {
                streamText += text
                messageRow.responseText = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
                messages[messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        messageRow.isInteractingWithChatGPT = false
        messages[messages.count - 1] = messageRow
        isInteractingWithChatGPT = false
    }
}
