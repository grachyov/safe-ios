//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import EthereumDomainModel
import EthereumApplication
import EthereumKit
import Common
import CryptoSwift
import BigInt

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
public enum EIP155ChainId: Int {
    case mainnet = 1
    case morden = 2
    case ropsten = 3
    case rinkeby = 4
    case rootstockMainnet = 30
    case rootstockTestnet = 31
    case kovan = 42
    case ethereumClassicMainnet = 61
    case ethereumClassicTestnet = 62
    case gethPrivateChains = 1_337
    case any = 0
}

struct ExtensionCode {

    let expirationDate: String
    let v: BInt
    let r: BInt
    let s: BInt

    init?(json: Any) {
        guard let json = json as? [String: Any],
            let expirationDate = json["expirationDate"] as? String,
            let signature = json["signature"] as? [String: Any],
            let vInt = signature["v"] as? Int,
            let rStr = signature["r"] as? String,
            let r = BInt(rStr, radix: 10), // FIXME: crashes on iOS 10.0
            let sStr = signature["s"] as? String,
            let s = BInt(sStr, radix: 10)
            else { return nil }
        self.expirationDate = expirationDate
        self.v = BInt(vInt)
        self.r = r
        self.s = s
    }

}

public protocol EthereumService: Assertable {

    func createMnemonic() -> [String]
    func createSeed(mnemonic: [String]) -> Data
    func createPrivateKey(seed: Data, network: EIP155ChainId) -> Data
    func createPublicKey(privateKey: Data) -> Data
    func createAddress(publicKey: Data) -> String

}

public enum EthereumServiceError: String, LocalizedError, Hashable {
    case invalidMnemonicWordsCount
}

public extension EthereumService {

    func createExternallyOwnedAccount(chainId: EIP155ChainId) throws ->
        (mnemonic: [String], privateKey: Data, publicKey: Data, address: String) {
        let words = createMnemonic()
        try assertEqual(words.count, 12, EthereumServiceError.invalidMnemonicWordsCount)
        let seed = createSeed(mnemonic: words)
        let privateKey = createPrivateKey(seed: seed, network: chainId)
        let publicKey = createPublicKey(privateKey: privateKey)
        let address = createAddress(publicKey: publicKey)
        return (words, privateKey, publicKey, address)
    }
}

public class EncryptionService: EncryptionDomainService {

    public enum Error: String, LocalizedError, Hashable {
        case failedToGenerateAccount
        case invalidTransactionData
        case invalidSignature
    }

    let chainId: EIP155ChainId
    let ethereumService: EthereumService

    public init(chainId: EIP155ChainId = .mainnet, ethereumService: EthereumService = EthereumKitEthereumService()) {
        self.chainId = chainId
        self.ethereumService = ethereumService
    }

    public func address(browserExtensionCode: String) -> String? {
        guard let code = extensionCode(from: browserExtensionCode) else {
            ApplicationServiceRegistry.logger.error("Failed to convert extension code (\(browserExtensionCode))")
            return nil
        }
        let signer = EIP155Signer(chainID: chainId.rawValue)
        let signature = signer.calculateSignature(r: code.r, s: code.s, v: code.v)
        let message = "GNO" + code.expirationDate
        let signedData = Crypto.hashSHA3_256(message.data(using: .utf8)!)
        guard let pubKey = Crypto.publicKey(signature: signature, of: signedData, compressed: false) else {
            ApplicationServiceRegistry.logger.error(
                "Failed to extract public key from extension code (\(browserExtensionCode))")
            return nil
        }
        return PublicKey(raw: Data(hex: "0x") + pubKey).generateAddress()
    }

    public func contractAddress(from signature: RSVSignature, for transaction: EthTransaction) throws -> String? {
        guard let gasPrice = Int(transaction.gasPrice),
            let gasLimit = Int(transaction.gas) else {
            throw Error.invalidTransactionData
        }
        let txData = try RLP.encode([
            transaction.nonce,
            gasPrice,
            gasLimit,
            0, // to
            transaction.value,
            Data(hex: transaction.data)])
        let txHash = Crypto.hashSHA3_256(txData)
        guard let r = BInt.init(signature.r, radix: 10), let s = BInt.init(signature.s, radix: 10) else {
            throw Error.invalidSignature
        }
        let v = BInt.init(signature.v)
        let signature = EIP155Signer(chainID: chainId.rawValue).calculateSignature(r: r, s: s, v: v)
        guard let key = Crypto.publicKey(signature: signature, of: txHash, compressed: false) else {
            throw Error.invalidSignature
        }
        let senderAddress = ethereumService.createAddress(publicKey: key)
        guard senderAddress == transaction.from else {
            throw Error.invalidSignature
        }
        let rlpAddress = try RLP.encode([
            Data(hex: senderAddress),
            0]) // nonce
        let addressData = Crypto.hashSHA3_256(rlpAddress).suffix(from: 12)
        let contractAddress = EthereumKit.Address(data: addressData).string
        return contractAddress
    }

    private func extensionCode(from code: String) -> ExtensionCode? {
        guard let data = code.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let extensionCode = ExtensionCode(json: json) else {
                return nil
        }
        return extensionCode
    }

    public func generateExternallyOwnedAccount() throws -> ExternallyOwnedAccount {
        let (mnemonicWords, privateKeyData, publicKeyData, address) =
            try ethereumService.createExternallyOwnedAccount(chainId: chainId)
        let account = ExternallyOwnedAccount(address: Address(value: address),
                                             mnemonic: Mnemonic(words: mnemonicWords),
                                             privateKey: PrivateKey(data: privateKeyData),
                                             publicKey: PublicKey(data: publicKeyData))
        return account
    }

    public func randomUInt256() -> String {
        return String(BigUInt.randomInteger(withExactWidth: 256))
    }

    public func sign(message: String, privateKey: EthereumDomainModel.PrivateKey) throws -> RSVSignature {
        let hash = Crypto.hashSHA3_256(message.data(using: .utf8)!)
        let rawSignature = try Crypto.sign(hash, privateKey: privateKey.data)
        let signer = EIP155Signer(chainID: chainId.rawValue)
        let (r, s, v) = signer.calculateRSV(signiture: rawSignature)
        return (r.asString(withBase: 10), s.asString(withBase: 10), Int(v.asString(withBase: 10))!)
    }

}
