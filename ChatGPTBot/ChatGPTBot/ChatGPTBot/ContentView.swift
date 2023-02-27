//
//  ContentView.swift
//  ChatGPTBot
//
//  Created by bard on 2023/02/24.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel = ViewModel(api: ChatGPTAPI(apiKey: "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"))
    @FocusState var isTextFieldFocused
    
    var body: some View {
        chatListView
            .navigationTitle("ChatGPT")
    }
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages) { message in
                            MessageRowView(message: message) { message in
                                Task { @MainActor in
                                    await viewModel.retry(message: message)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                Divider()
                bottomView(image: "person.circle.fill", proxy: proxy)
                Spacer()
            }
            .onChange(of: viewModel.messages.last?.responseText) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
        .background(
            colorScheme == . light ? .white
            : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5)
        )
    }
    
    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if image.hasPrefix("http"), let url = URL(string: image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .frame(width: 30, height: 30)
                } placeholder: {
                    ProgressView()
                }
            } else {
                if image == "person.circle.fill" {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                } else {
                    Image(image)
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            }
            
            TextField(
                "Send Message",
                text: $viewModel.inputMessage,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .focused($isTextFieldFocused)
            .disabled(viewModel.isInteractingWithChatGPT)
            
            if viewModel.isInteractingWithChatGPT {
                DotLoadingView()
                    .frame(width: 60, height: 30)
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await viewModel.sendTapped()
                    }
                } label: { 
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 30))
                }
                .disabled(
                    viewModel.inputMessage
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                )

            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = viewModel.messages.last?.id else {
            return
        }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContentView()
        }
    }
}
