//
//  TokenListModel.swift
//  AlphaWallet
//
//  Created by Rajan Maharjan on 26/01/2024.
//

import Foundation


// MARK: - TokenListModel
struct TokenListModel: Codable {
    let connections: [Connection]
}

// MARK: - Connection
struct Connection: Codable {
    let fromChainID, toChainID: Int
    let fromTokens, toTokens: [TokenData]

    enum CodingKeys: String, CodingKey {
        case fromChainID = "fromChainId"
        case toChainID = "toChainId"
        case fromTokens, toTokens
    }
}

// MARK: - Token
struct TokenData: Codable {
    let address: String
    let chainID: Int
    let symbol: String
    let decimals: Int
    let name: String
    let coinKey: String
    let logoURI: String?
    let priceUSD: String

    enum CodingKeys: String, CodingKey {
        case address
        case chainID = "chainId"
        case symbol, decimals, name, coinKey, logoURI, priceUSD
    }
}
