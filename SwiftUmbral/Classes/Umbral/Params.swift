//
//  params.swift
//  ReEncryptHealth
//
//  Created by Anton Grigorev on 05.10.2018.
//  Copyright © 2018 Anton Grigorev. All rights reserved.
//

import Foundation
import BigInt
import EllipticSwift
import CryptoSwift

//TODO: - Curve?
public class UmbralParameters<T> where T: PrimeFieldProtocol {
    public typealias RawType = T.UnderlyingRawType
    public typealias AffinePointType = EllipticSwift.WeierstrassCurve<T>.AffineType
    public typealias CurveOrderField = NaivePrimeField<RawType>
    
    public typealias HashFunction = (Data) -> Data
    
    public enum Error: Swift.Error {
        case invalidGenerator
        case fieldSizeMismatch
        case pointSerializationError
        case digestLengthMismatch
    }
    
    public var curveKeySizeBytes: Int
    public var curveFieldSizeBytes: Int
    public var curve: EllipticSwift.WeierstrassCurve<T>
    public var G: EllipticSwift.WeierstrassCurve<T>.AffineType
    public var U: EllipticSwift.WeierstrassCurve<T>.AffineType
    
    var curveOrderField: CurveOrderField
    
    public var hashFunction: HashFunction
    public var KDF: HashFunction
    
    public init(curve: EllipticSwift.WeierstrassCurve<T>, generator: (X: BigUInt, Y: BigUInt), hashFunction: @escaping HashFunction, kdf: @escaping HashFunction) throws {
        self.curve = curve
        self.curveKeySizeBytes = Int((self.curve.order.bitWidth + 7) / 8)
        self.curveFieldSizeBytes = Int(T.UnderlyingRawType.zero.fullBitWidth)
        self.curveOrderField = NaivePrimeField.init(self.curve.order)
        
        guard let G = self.curve.toPoint(generator.X, generator.Y) else {
            throw Error.invalidGenerator
        }
        self.G = G
        
//        guard let gBytes = serializePoint(self.G) else {
//            throw Error.fieldSizeMismatch
//        }
        
        let parametersSeed = "matterinc/UmbralParameters/".data(using: .utf8)!.sha3(.keccak256)
        self.U = self.curve.hashInto(parametersSeed)
        
        self.hashFunction = hashFunction
        self.KDF = kdf
    }
    
    // does not compress
    public func serializePoint(_ p: EllipticSwift.WeierstrassCurve<T>.AffineType) -> Data? {
        let coordinates = self.G.coordinates
        guard let dataX = padToBytes(coordinates.X.serialize(), length: self.curveFieldSizeBytes) else { return nil }
        guard let dataY = padToBytes(coordinates.Y.serialize(), length: self.curveFieldSizeBytes) else { return nil }
        return dataX + dataY
    }
    
    func padToBytes(_ data: Data, length: Int) -> Data? {
        if data.count > length {
            return nil
        }
        let padding = Data.init(repeating: 0, count: length - data.count)
        return padding + data
    }
    
    func H2(_ parameters: (AffinePointType, AffinePointType)) throws -> RawType {
        guard let p0 = serializePoint(parameters.0) else {
            throw Error.pointSerializationError
        }
        guard let p1 = serializePoint(parameters.1) else {
            throw Error.pointSerializationError
        }
        let data = p0 + p1
        let hash = self.hashFunction(data)
        guard let raw = RawType.init(hash) else {
            throw Error.digestLengthMismatch
        }
        return raw.mod(self.curve.order)
    }
    
    func H3(_ parameters: (AffinePointType, AffinePointType, AffinePointType)) throws -> RawType {
        guard let p0 = serializePoint(parameters.0) else {
            throw Error.pointSerializationError
        }
        guard let p1 = serializePoint(parameters.1) else {
            throw Error.pointSerializationError
        }
        guard let p2 = serializePoint(parameters.2) else {
            throw Error.pointSerializationError
        }
        let data = p0 + p1 + p2
        let hash = self.hashFunction(data)
        guard let raw = RawType.init(hash) else {
            throw Error.digestLengthMismatch
        }
        return raw.mod(self.curve.order)
    }
    
    func H4(_ parameters: (AffinePointType, AffinePointType, AffinePointType, RawType)) throws -> RawType {
        guard let p0 = serializePoint(parameters.0) else {
            throw Error.pointSerializationError
        }
        guard let p1 = serializePoint(parameters.1) else {
            throw Error.pointSerializationError
        }
        guard let p2 = serializePoint(parameters.2) else {
            throw Error.pointSerializationError
        }
        let data = p0 + p1 + p2 + parameters.3.bytes
        let hash = self.hashFunction(data)
        guard let raw = RawType.init(hash) else {
            throw Error.digestLengthMismatch
        }
        return raw.mod(self.curve.order)
    }
    
}

