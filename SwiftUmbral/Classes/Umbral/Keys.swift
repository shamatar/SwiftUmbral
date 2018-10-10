//
//  keys.swift
//  ReEncryptHealth
//
//  Created by Anton Grigorev on 05.10.2018.
//  Copyright © 2018 Anton Grigorev. All rights reserved.
//

import Foundation
import BigInt
import EllipticSwift
import CryptoSwift

public final class UmbralKey<P, U> where P: UmbralParameters<U>, U: PrimeFieldProtocol {

    enum Error: Swift.Error {
        case invalidKeyLength
        case publicKeyIsInfinity
        case publicKeyIsNotOnCurve
        case noEntropy
    }
    
    public var bnKey: BigUInt?
    public var pubkey: P.AffinePointType
    
    public init(bnKey: BigUInt, params: P) throws {
        self.bnKey = bnKey
        guard let rawKey = P.RawType(bnKey.serialize()) else {
            throw Error.invalidKeyLength
        }
        self.pubkey = params.curve.mul(rawKey, params.G).toAffine()
        guard !pubkey.isInfinity else {
            throw Error.publicKeyIsInfinity
        }
    }
    
    public init(params: P) throws {
        guard let randomBytes = getRandomBytes(length: params.curveKeySizeBytes) else {
            throw Error.noEntropy
        }
        self.bnKey = BigUInt(randomBytes)
        guard let rawKey = P.RawType(self.bnKey!.serialize()) else {
            throw Error.invalidKeyLength
        }
        self.pubkey = params.curve.mul(rawKey, params.G).toAffine()
        guard !pubkey.isInfinity else {
            throw Error.publicKeyIsInfinity
        }
    }
    
    public init(pubkey: P.AffinePointType, params: P) throws {
        guard params.curve.checkOnCurve(pubkey) else {
            throw Error.publicKeyIsNotOnCurve
        }
        guard !pubkey.isInfinity else {
            throw Error.publicKeyIsInfinity
        }
        self.pubkey = pubkey
    }
}

func getRandomBytes(length: Int) -> Data? {
    for _ in 0...1024 {
        var data = Data(repeating: 0, count: length)
        let result = data.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
        }
        if result == errSecSuccess {
            return data
        }
    }
    return nil
}
