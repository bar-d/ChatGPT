//
//  OpenAIService.swift
//  ChatGPTApp
//
//  Created by bard on 2023/02/27.
//

import Alamofire
import Combine
import Foundation

final class OpenAIService {
    let baseURL = "https://api.openai.com/v1/"
    
    func sendMessage(message: String) -> AnyPublisher<OpenAICompletionsResponse, Error> {
        let body = OpenAICompletionsBody(
            model: "text-davinci-003",
            prompt: message,
            temperature: 0.7,
            max_tokens: 256
        )
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)"
        ]
        
        return Future { [weak self] promise in
            guard let self = self else {return }
            
            AF.request(
                self.baseURL + "completions",
                method: .post,
                parameters: body,
                encoder: .json,
                headers: headers
            ).responseDecodable(of: OpenAICompletionsResponse.self) { response in
                switch response.result {
                case .success(let result):
                    promise(.success(result))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
