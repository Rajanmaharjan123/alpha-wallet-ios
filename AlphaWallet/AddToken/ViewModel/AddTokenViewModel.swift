//
//  AddTokenViewModel.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 25/01/2024.
//

import Foundation

class AddTokenViewModel: NSObject {
    
    let networkService = AddTokenNetworkService()
    let title = "Tokens"
    
    var addTokenGot: (([TokenData]) -> Void)?
    
    override init() {
        super.init()
    }
    
    func fetchTokenList() {
        networkService.makePostAPICall(fromChain: "1", toChain: "1") { result in
            switch result {
            case .success(let response):
                if let jsonData = response.data(using: .utf8) {
                    do {
                        let tokenListModel = try JSONDecoder().decode(TokenListModel.self, from: jsonData)
                        print(tokenListModel.connections)
                        for connection in tokenListModel.connections {
                            self.addTokenGot?(connection.fromTokens)
                        }
                    } catch {
                        print("Error Occured")
                    }
                } else {
                    print("Error Occured")
                }
            case .failure(let error):
                print("API Call Failure: \(error.localizedDescription)")
            }
        }
    }
    
}

