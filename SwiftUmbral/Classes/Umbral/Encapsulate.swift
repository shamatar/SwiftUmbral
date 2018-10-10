//  Created by Alex Vlasov on 09/10/2018.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import CryptoSwift
import EllipticSwift
import BigInt

public final class Encapsulator {
    enum Error: Swift.Error {
        case noEntropy
        case invalidCapsule
        case invalidDelegatorKey
    }
    
    public static func encapsulate<T, U>(parameters: T, delegatorKey: UmbralKey<T, U>) throws -> (symmeticKey: Data, capsule: Capsule<T, U>) where T: UmbralParameters<U>, U: PrimeFieldProtocol {
        
        let keyLength = parameters.curveKeySizeBytes
        let field = parameters.curveOrderField
        
        guard let randomUbytes = getRandomBytes(length: keyLength) else {
            throw Error.noEntropy
        }
        let u = PrimeFieldElement.fromBytes(randomUbytes, field: field)
        precondition(u.nativeValue < parameters.curve.order)
        let V = (u.nativeValue * parameters.G).toAffine()
        
        guard let randomRbytes = getRandomBytes(length: keyLength) else {
            throw Error.noEntropy
        }
        if randomRbytes == randomUbytes {
            throw Error.noEntropy
        }
        let r = PrimeFieldElement.fromBytes(randomRbytes, field: field)
        precondition(r.nativeValue < parameters.curve.order)
        let E = (r.nativeValue * parameters.G).toAffine()
        
        let hNative = try parameters.H2((E, V))
        let h = PrimeFieldElement.fromValue(hNative, field: field)
        let s = u + h*r
        let scalar = (r + u).nativeValue
        let point = (scalar * delegatorKey.pubkey).toAffine()
        let pointSerialization = parameters.serializePoint(point)!
        let K = parameters.KDF(pointSerialization)
        var capsule = Capsule(params: parameters)
        capsule.E = E
        capsule.V = V
        capsule.s = s.nativeValue
        return (K, capsule)
    }
    
    public static func checkCapsule<T, U>(capsule: Capsule<T, U>, parameters: T) throws -> Bool where T: UmbralParameters<U>, U: PrimeFieldProtocol {
        if capsule.E == nil || capsule.V == nil || capsule.s == nil {
            return false
        }
        let hNative = try parameters.H2((capsule.E!, capsule.V!))
        let lhs = (capsule.s! * parameters.G).toAffine()
        let rhs = ((hNative * capsule.E!).toAffine() + capsule.V!).toAffine()
        return lhs == rhs

    }
    
    public static func decapsulate<T, U>(capsule: Capsule<T, U>, parameters: T, delegatorKey: UmbralKey<T, U>) throws -> Data where T: UmbralParameters<U>, U: PrimeFieldProtocol {
        let valid = try checkCapsule(capsule: capsule, parameters: parameters)
        if !valid {
            throw Error.invalidCapsule
        }
        guard let pk = delegatorKey.bnKey else {
            throw Error.invalidDelegatorKey
        }
        guard let nativeA = T.RawType(pk.serialize()) else {
            throw Error.invalidDelegatorKey
        }
        let base = (capsule.E! + capsule.V!).toAffine()
        let point = (nativeA * base).toAffine()
        let pointSerialization = parameters.serializePoint(point)!
        let K = parameters.KDF(pointSerialization)
        return K
    }
}
