// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import AlphaWalletOpenSea
import BigInt
import RealmSwift
import Combine

enum DataStoreError: Error {
    case objectTypeMismatch
    case objectNotFound
    case objectDeleted
    case general(error: Error)
}

/// Multiple-chains tokens data store
protocol TokensDataStore: NSObjectProtocol {
    func enabledTokensChangeset(for servers: [RPCServer]) -> AnyPublisher<ChangeSet<[Token]>, Never>
    func enabledTokens(for servers: [RPCServer]) -> [Token]
    func tokenPublisher(for contract: AlphaWallet.Address, server: RPCServer) -> AnyPublisher<Token?, DataStoreError>
    func deletedContracts(forServer server: RPCServer) -> [AddressAndRPCServer]
    func delegateContracts(forServer server: RPCServer) -> [AddressAndRPCServer]
    func hiddenContracts(forServer server: RPCServer) -> [AddressAndRPCServer]
    func addEthToken(forServer server: RPCServer)
    func token(forContract contract: AlphaWallet.Address) -> Token?
    func tokenObject(forContract contract: AlphaWallet.Address, server: RPCServer) -> TokenObject?
    func token(forContract contract: AlphaWallet.Address, server: RPCServer) -> Token?
    @discardableResult func addCustom(tokens: [ERCToken], shouldUpdateBalance: Bool) -> [Token]
    func add(hiddenContracts: [HiddenContract])
    func deleteTestsOnly(tokens: [Token])
    func updateOrderedTokens(with orderedTokens: [Token])
    func add(tokenUpdates updates: [TokenUpdate])
    @discardableResult func updateToken(primaryKey: String, action: TokenUpdateAction) -> Bool?
    @discardableResult func addTokenObjects(values: [SingleChainTokensAutodetector.AddTokenObjectOperation]) -> [Token]
    @discardableResult func batchUpdateToken(_ actions: [PrivateBalanceFetcher.TokenBatchOperation]) -> Bool?
}

enum TokenUpdateAction {
    case value(BigInt)
    case isDisabled(Bool)
    case nonFungibleBalance([String])
    case name(String)
    case type(TokenType)
    case isHidden(Bool)
}

/// Should be `final`, but removed for test purposes
/*final*/ class MultipleChainsTokensDataStore: NSObject, TokensDataStore {
    //NOTE: adds synchronized access to realm, to make requests from different threads. Replace other calls
    private let store: RealmStore

    init(store: RealmStore, servers: [RPCServer]) {
        self.store = store
        super.init()

        for each in servers {
            addEthToken(forServer: each)
        }
    }

    func enabledTokensChangeset(for servers: [RPCServer]) -> AnyPublisher<ChangeSet<[Token]>, Never> {
        var publisher: AnyPublisher<ChangeSet<[Token]>, Never>!
        store.performSync { realm in
            publisher = self.enabledTokenObjectResults(forServers: servers, realm: realm)
                .changesetPublisher
                .map { change in
                    switch change {
                    case .initial(let tokenObjects):
                        let tokens = Array(tokenObjects).map { Token(tokenObject: $0) }
                        return .initial(tokens)
                    case .update(let tokenObjects, let deletions, let insertions, let modifications):
                        let tokens = Array(tokenObjects).map { Token(tokenObject: $0) }
                        return .update(tokens, deletions: deletions, insertions: insertions, modifications: modifications)
                    case .error(let error):
                        return .error(error)
                    }
                }
                .eraseToAnyPublisher()
        }

        return publisher
    }

    func tokenPublisher(for contract: AlphaWallet.Address, server: RPCServer) -> AnyPublisher<Token?, DataStoreError> {
        let predicate = MultipleChainsTokensDataStore
            .functional
            .tokenPredicate(server: server, contract: contract)

        let publisher: CurrentValueSubject<Token?, DataStoreError> = .init(nil)
        var notificationToken: NotificationToken?

        store.performSync { realm in
            guard let token = realm.objects(TokenObject.self).filter(predicate).first else {
                publisher.send(completion: .failure(DataStoreError.objectNotFound))
                return
            }

            publisher.send(Token(tokenObject: token))

            notificationToken = token.observe { change in
                switch change {
                case .change(let object, _):
                    guard let token = object as? TokenObject else { return }
                    publisher.send(Token(tokenObject: token))
                case .deleted:
                    publisher.send(completion: .failure(.objectDeleted))
                case .error(let e):
                    publisher.send(completion: .failure(.general(error: e)))
                }
            }
        }

        return publisher
            .handleEvents(receiveCancel: {
                notificationToken?.invalidate()
            }).eraseToAnyPublisher()
    }

    func enabledTokens(for servers: [RPCServer]) -> [Token] {
        var tokensToReturn: [Token] = []
        store.performSync { realm in
            let tokens = Array(self.enabledTokenObjectResults(forServers: servers, realm: realm).map { Token(tokenObject: $0) })
            tokensToReturn = MultipleChainsTokensDataStore.functional.erc20AddressForNativeTokenFilter(servers: servers, tokenObjects: tokens)
        }

        return tokensToReturn
    }

    func deletedContracts(forServer server: RPCServer) -> [AddressAndRPCServer] {
        var deletedContracts: [AddressAndRPCServer] = []
        store.performSync { realm in
            deletedContracts = Array(realm.objects(DeletedContract.self).filter("chainId = \(server.chainID)"))
                .map { .init(address: $0.contractAddress, server: $0.server) }
        }

        return deletedContracts
    }

    func delegateContracts(forServer server: RPCServer) -> [AddressAndRPCServer] {
        var delegateContracts: [AddressAndRPCServer] = []
        store.performSync { realm in
            delegateContracts = Array(realm.objects(DelegateContract.self).filter("chainId = \(server.chainID)"))
                .map { .init(address: $0.contractAddress, server: $0.server) }
        }
        return delegateContracts
    }

    func hiddenContracts(forServer server: RPCServer) -> [AddressAndRPCServer] {
        var hiddenContracts: [AddressAndRPCServer] = []
        store.performSync { realm in
            hiddenContracts = Array(realm.objects(HiddenContract.self).filter("chainId = \(server.chainID)"))
                .map { .init(address: $0.contractAddress, server: $0.server) }
        }
        return hiddenContracts
    }

    func add(tokenUpdates updates: [TokenUpdate]) {
        store.performSync { realm in
            try? realm.safeWrite {
                for token in updates {
                    //Even though primaryKey is provided, it is important to specific contract because this might be creating a new TokenObject instance from transactions
                    let update: [String: Any] = [
                        "primaryKey": token.primaryKey,
                        "contract": token.address.eip55String,
                        "chainId": token.server.chainID,
                        "name": token.name,
                        "symbol": token.symbol,
                        "decimals": token.decimals,
                        "rawType": token.tokenType.rawValue,
                    ]
                    realm.create(TokenObject.self, value: update, update: .all)
                }
            }
        }
    }

    func addEthToken(forServer server: RPCServer) {
        store.performSync { realm in
            let tokenObjects = realm.objects(TokenObject.self)
                .filter(MultipleChainsTokensDataStore.functional.nonEmptyContractTokenPredicate(server: server))
            let etherToken = MultipleChainsTokensDataStore.functional.etherTokenObject(forServer: server)

            if !tokenObjects.contains(where: { $0 == etherToken }) {
                try? realm.safeWrite {
                    self.addTokenWithoutCommitWrite(tokenObject: etherToken, realm: realm)
                }
            }
        }
    }

    func token(forContract contract: AlphaWallet.Address) -> Token? {
        let predicate = MultipleChainsTokensDataStore
            .functional
            .tokenPredicate(contract: contract)

        var token: Token?
        store.performSync { realm in
            token = realm.objects(TokenObject.self)
                .filter(predicate)
                .first
                .map { Token(tokenObject: $0) }
        }

        return token
    }

    func token(forContract contract: AlphaWallet.Address, server: RPCServer) -> Token? {
        let predicate = MultipleChainsTokensDataStore
            .functional
            .tokenPredicate(server: server, contract: contract)

        var token: Token?

        store.performSync { realm in
            token = realm.objects(TokenObject.self)
                .filter(predicate)
                .first
                .map { Token(tokenObject: $0) }
        }

        return token
    }

    func tokenObject(forContract contract: AlphaWallet.Address, server: RPCServer) -> TokenObject? {
        var token: TokenObject?
        store.performSync { realm in
            token = self.tokenObject(forContract: contract, server: server, realm: realm)
        }

        return token
    }

    private func tokenObject(forContract contract: AlphaWallet.Address, server: RPCServer, realm: Realm) -> TokenObject? {
        let predicate = MultipleChainsTokensDataStore
            .functional
            .tokenPredicate(server: server, contract: contract)

        return realm.objects(TokenObject.self)
            .filter(predicate)
            .first
    }

    @discardableResult func addCustom(tokens: [ERCToken], shouldUpdateBalance: Bool) -> [Token] {
        guard !tokens.isEmpty else { return [] }
        var tokensToReturn: [Token] = []
        store.performSync { realm in
            let newTokens = tokens.compactMap { MultipleChainsTokensDataStore.functional.createTokenObject(ercToken: $0, shouldUpdateBalance: shouldUpdateBalance) }
            try? realm.safeWrite {
                //TODO: save existed sort index and displaying state
                for token in newTokens {
                    self.addTokenWithoutCommitWrite(tokenObject: token, realm: realm)
                }
            }

            tokensToReturn = newTokens.map { Token(tokenObject: $0) }
        }

        return tokensToReturn
    }

    @discardableResult func addTokenObjects(values: [SingleChainTokensAutodetector.AddTokenObjectOperation]) -> [Token] {
        guard !values.isEmpty else { return [] }

        store.performSync { realm in
            try? realm.safeWrite {
                for each in values {
                    switch each {
                    case .delegateContracts(let delegateContract):
                        realm.add(delegateContract, update: .all)
                    case .ercToken(let token):
                        let newTokenObject = MultipleChainsTokensDataStore.functional.createTokenObject(ercToken: token, shouldUpdateBalance: token.type.shouldUpdateBalanceWhenDetected)
                        self.addTokenWithoutCommitWrite(tokenObject: newTokenObject, realm: realm)
                    case .tokenObject(let token):
                        let tokenObject = TokenObject(token: token)
                        self.addTokenWithoutCommitWrite(tokenObject: tokenObject, realm: realm)
                    case .deletedContracts(let deadContracts):
                        realm.add(deadContracts, update: .all)
                    case .fungibleTokenComplete(let name, let symbol, let decimals, let contract, let server, let onlyIfThereIsABalance):
                        let existedTokenObject = self.tokenObject(forContract: contract, server: server, realm: realm)

                        let value = existedTokenObject?.value ?? "0"
                        guard !onlyIfThereIsABalance || (onlyIfThereIsABalance && !(value != "0")) else {
                            continue
                        }
                        let tokenObject = TokenObject(
                                contract: contract,
                                server: server,
                                name: name,
                                symbol: symbol,
                                decimals: Int(decimals),
                                value: value,
                                type: .erc20
                        )
                        self.addTokenWithoutCommitWrite(tokenObject: tokenObject, realm: realm)
                    case .none:
                        break
                    }
                }
            }
        }

        let tokenObjects = values
            .compactMap { $0.addressAndRPCServer }
            .compactMap { token(forContract: $0.address, server: $0.server) }

        return tokenObjects
    }

    func add(hiddenContracts: [HiddenContract]) {
        store.performSync { realm in
            try? realm.safeWrite {
                realm.add(hiddenContracts, update: .all)
            }
        }
    }

    func deleteTestsOnly(tokens: [Token]) {
        guard !tokens.isEmpty else { return }

        store.performSync { realm in
            try? realm.safeWrite {
                let tokendToDelete = tokens.compactMap { realm.object(ofType: TokenObject.self, forPrimaryKey: $0.primaryKey) }
                realm.delete(tokendToDelete)
            }
        }
    }

    func updateOrderedTokens(with orderedTokens: [Token]) {
        guard !orderedTokens.isEmpty else { return }
        store.performSync { realm in
            let orderedTokensIds = orderedTokens.map { $0.primaryKey }

            let storedTokens = Array(realm.objects(TokenObject.self))
            guard !storedTokens.isEmpty else { return }

            try? realm.safeWrite {
                for token in storedTokens {
                    token.sortIndex.value = orderedTokensIds.firstIndex(where: { $0 == token.primaryKey })
                }
            }
        }
    }

    @discardableResult func batchUpdateToken(_ actions: [PrivateBalanceFetcher.TokenBatchOperation]) -> Bool? {
        guard !actions.isEmpty else { return nil }

        var result: Bool?
        store.performSync { realm in
            try? realm.safeWrite {
                for each in actions {
                    var value: Bool?
                    switch each {
                    case .add(let token, let shouldUpdateBalance):
                        let newToken = MultipleChainsTokensDataStore.functional.createTokenObject(ercToken: token, shouldUpdateBalance: shouldUpdateBalance)
                        self.addTokenWithoutCommitWrite(tokenObject: newToken, realm: realm)
                        value = true
                    case .update(let tokenObject, let action):
                        value = self.updateTokenWithoutCommitWrite(primaryKey: tokenObject.primaryKey, action: action, realm: realm)
                    }

                    if result == nil {
                        result = value
                    }
                }
            }
        }
        return result
    }

    @discardableResult func updateToken(primaryKey: String, action: TokenUpdateAction) -> Bool? {
        var result: Bool?
        store.performSync { realm in
            try? realm.safeWrite {
                result = self.updateTokenWithoutCommitWrite(primaryKey: primaryKey, action: action, realm: realm)
            }
        }

        return result
    }

    private func addTokenWithoutCommitWrite(tokenObject: TokenObject, realm: Realm) {
        //TODO: save existed sort index and displaying state
        if let object = realm.object(ofType: TokenObject.self, forPrimaryKey: tokenObject.primaryKey) {
            tokenObject.sortIndex = object.sortIndex
            tokenObject.shouldDisplay = object.shouldDisplay
        }

        realm.add(tokenObject, update: .all)
    }

    @discardableResult private func updateTokenWithoutCommitWrite(primaryKey: String, action: TokenUpdateAction, realm: Realm) -> Bool? {
        guard let tokenObject = realm.object(ofType: TokenObject.self, forPrimaryKey: primaryKey) else { return nil }

        var result: Bool = false

        switch action {
        case .value(let value):
            return updateFungibleBalance(balance: value, token: tokenObject)
        case .nonFungibleBalance(let balances):
            return updateNonFungibleBalance(balances: balances, token: tokenObject)
        case .name(let name):
            if tokenObject.name != name {
                tokenObject.name = name
                result = true
            }
        case .type(let type):
            if tokenObject.rawType != type.rawValue {
                tokenObject.rawType = type.rawValue
                result = true
            }
        case .isDisabled(let value):
            result = true

            tokenObject.isDisabled = value
        case .isHidden(let value):
            result = true

            tokenObject.shouldDisplay = !value
            if !value {
                tokenObject.sortIndex.value = nil
            }
        }

        return result
    }

    private func updateFungibleBalance(balance value: BigInt, token: TokenObject) -> Bool {
        if token.value != value.description {
            token.value = value.description
            return true
        }

        return false
    }

    private func updateNonFungibleBalance(balances: [String], token: TokenObject) -> Bool {
        //NOTE: add new balances
        let balancesToAdd = balances
            .filter { b in !token.balance.contains(where: { v in v.balance == b }) }
            .map { TokenBalance(balance: $0) }

        //NOTE: remove old balances if something has changed
        let balancesToDelete = token.balance
            .filter { !balances.contains($0.balance) }
            .compactMap { token.balance.index(of: $0) }

        if !balancesToAdd.isEmpty || !balancesToDelete.isEmpty {
            for index in balancesToDelete {
                token.balance.remove(at: index)
            }

            token.balance.append(objectsIn: balancesToAdd)

            return true
        }

        return false
    }

    private func enabledTokenObjectResults(forServers servers: [RPCServer], realm: Realm) -> Results<TokenObject> {
        let predicate = MultipleChainsTokensDataStore
            .functional
            .nonEmptyContractTokenPredicateWithErc20AddressForNativeTokenFilter(servers: servers, isDisabled: false)

        return realm
            .objects(TokenObject.self)
            .filter(predicate)
    }
}

extension TokenObject {
    var addressAndRPCServer: AddressAndRPCServer {
        return .init(address: contractAddress, server: server)
    }
}

extension MultipleChainsTokensDataStore {
    class functional {}
}

extension MultipleChainsTokensDataStore.functional {
    static func nonFungibleTokenType(fromTokenType tokenType: TokenType) -> NonFungibleFromJsonTokenType {
        switch tokenType {
        case .erc721, .erc721ForTickets:
            return NonFungibleFromJsonTokenType.erc721
        case .erc1155:
            return NonFungibleFromJsonTokenType.erc1155
        case .nativeCryptocurrency, .erc20, .erc875:
            return NonFungibleFromJsonTokenType.erc721
        }
    }

    static func chainIdPredicate(servers: [RPCServer]) -> NSPredicate {
        return NSPredicate(format: "chainId IN %@", servers.map { $0.chainID })
    }

    static func isDisabledPredicate(isDisabled: Bool) -> NSPredicate {
        return NSPredicate(format: "isDisabled = \(isDisabled ? "true" : "false")")
    }

    static func nonEmptyContractPredicate() -> NSPredicate {
        return NSPredicate(format: "contract != ''")
    }

    static func contractPredicate(contract: AlphaWallet.Address) -> NSPredicate {
        return NSPredicate(format: "contract = '\(contract.eip55String)'")
    }

    static func tokenPredicate(server: RPCServer, isDisabled: Bool, contract: AlphaWallet.Address) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            contractPredicate(contract: contract),
            isDisabledPredicate(isDisabled: isDisabled),
            chainIdPredicate(servers: [server])
        ])
    }

    static func tokenPredicate(server: RPCServer, contract: AlphaWallet.Address) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            contractPredicate(contract: contract),
            chainIdPredicate(servers: [server])
        ])
    }

    static func tokenPredicate(contract: AlphaWallet.Address) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            contractPredicate(contract: contract)
        ])
    }

    static func nonEmptyContractTokenPredicate(servers: [RPCServer], isDisabled: Bool) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            isDisabledPredicate(isDisabled: isDisabled),
            chainIdPredicate(servers: servers),
            nonEmptyContractPredicate()
        ])
    }

    static func nonEmptyContractTokenPredicateWithErc20AddressForNativeTokenFilter(servers: [RPCServer], isDisabled: Bool) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            isDisabledPredicate(isDisabled: isDisabled),
            chainIdPredicate(servers: servers),
            nonEmptyContractPredicate()
        ])
    }

    static func nonEmptyContractTokenPredicate(server: RPCServer) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            chainIdPredicate(servers: [server]),
            nonEmptyContractPredicate()
        ])
    }

    static func etherTokenObject(forServer server: RPCServer) -> TokenObject {
        return TokenObject(
                contract: Constants.nativeCryptoAddressInDatabase,
                server: server,
                name: server.name,
                symbol: server.symbol,
                decimals: server.decimals,
                value: "0",
                isCustom: false,
                type: .nativeCryptocurrency
        )
    }

    static func etherToken(forServer server: RPCServer) -> Token {
        return Token(
                contract: Constants.nativeCryptoAddressInDatabase,
                server: server,
                name: server.name,
                symbol: server.symbol,
                decimals: server.decimals,
                value: .zero,
                type: .nativeCryptocurrency
        )
    }

    //TODO might be best to remove ethToken(for:) and just use token(for:) if possible, but careful with the contract value returned for .ether
    static func token(forServer server: RPCServer) -> TokenObject {
        return TokenObject(
                contract: server.priceID,
                server: server,
                name: server.name,
                symbol: server.symbol,
                decimals: server.decimals,
                value: "0",
                isCustom: false,
                type: .nativeCryptocurrency
        )
    }

    //TODO: Rename tokenObject(ercToken with createTokenObject(ercToken, more clear name
    static func createTokenObject(ercToken token: ERCToken, shouldUpdateBalance: Bool) -> TokenObject {
        let newToken = TokenObject(
                contract: token.contract,
                server: token.server,
                name: token.name,
                symbol: token.symbol,
                decimals: token.decimals,
                value: "0",
                isCustom: true,
                type: token.type
        )
        if shouldUpdateBalance {
            token.balance.forEach { balance in
                newToken.balance.append(TokenBalance(balance: balance))
            }
        }

        return newToken
    }

    static func erc20AddressForNativeTokenFilter(servers: [RPCServer], tokenObjects: [Token]) -> [Token] {
        var result = tokenObjects
        for server in servers {
            if let address = server.erc20AddressForNativeToken, result.contains(where: { $0.contractAddress.sameContract(as: address) }) {
                result = result.filter { !$0.contractAddress.sameContract(as: Constants.nativeCryptoAddressInDatabase) && $0.server == server }
            } else {
                continue
            }
        }

        return result
    }
}
