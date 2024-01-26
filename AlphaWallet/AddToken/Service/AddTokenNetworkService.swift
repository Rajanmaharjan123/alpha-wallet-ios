//
//  AddTokenNetworkService.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 26/01/2024.
//

import Foundation

class AddTokenNetworkService {
    func makePostAPICall(fromChain: String, toChain: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "https://li.quest/v1/connections?fromChain=1&toChain=1"
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                completion(.failure(error))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Response: \(responseString ?? "")")
                    completion(.success(responseString ?? ""))
                }
            }
        }
        
        task.resume()
    }
}
