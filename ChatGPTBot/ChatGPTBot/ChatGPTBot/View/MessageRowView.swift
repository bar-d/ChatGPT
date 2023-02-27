//
//  MessageRowView.swift
//  ChatGPTBot
//
//  Created by bard on 2023/02/24.
//

import SwiftUI

struct MessageRowView: View {
    
    // MARK: Properties
    
    @Environment(\.colorScheme) private var colorScheme
    let message: MessageRow
    let retryCallback: (MessageRow) -> Void
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 0) {
            messageRow(
                text: message.sendText,
                image: message.sendImage,
                bgColor: colorScheme == .light ? .white
                : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5)
            )
            
            if let text = message.responseText {
                Divider()
                messageRow(
                    text: text,
                    image: message.responseImage,
                    bgColor: colorScheme == .light ? .gray.opacity(0.1)
                    : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 1),
                    responseError: message.responseError,
                    showDotLoading: message.isInteractingWithChatGPT
                )
                Divider()
            }
        }
    }
    
    // MARK: - Methods
    
    private func messageRow(
        text: String,
        image: String,
        bgColor: Color,
        responseError: String? = nil,
        showDotLoading: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 24) {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 25, height: 25)
                } placeholder: {
                    ProgressView()
                }
            } else {
                if image == message.sendImage {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                } else {
                    Image(image)
                        .resizable()
                        .frame(width: 25, height: 25)
                }
            }
            
            VStack(alignment: .leading) {
                if !text.isEmpty {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
                
                if let error = responseError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Button("Regenerate Response") {
                        retryCallback(message)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.top)
                }
                
                if showDotLoading {
                    DotLoadingView()
                        .frame(width: 60, height: 30)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
    }
}

struct MessageRowView_Previews: PreviewProvider {
    static let message = MessageRow(
        isInteractingWithChatGPT: false,
        sendImage: "person.circle.fill",
        sendText: "What is SwiftUI?",
        responseImage: "openai",
        responseText: "SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc."
    )
    
    static let message2 = MessageRow(
        isInteractingWithChatGPT: true,
        sendImage: "person.circle.fill",
        sendText: "What is SwiftUI?",
        responseImage: "openai",
        responseText: ""
        ,responseError: "ChatGPT is Currently not available"
    )
    
    static var previews: some View {
        NavigationStack {
            ScrollView {
                MessageRowView(message: message) { messageRow in
                    
                }
                
                MessageRowView(message: message2) { messageRow in
                    
                }
            }
        }
    }
}
