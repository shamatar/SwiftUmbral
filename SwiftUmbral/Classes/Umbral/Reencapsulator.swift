//
//  Reencapsulator.swift
//  SwiftUmbral
//
//  Created by Alex Vlasov on 10/10/2018.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import CryptoSwift
import EllipticSwift
import BigInt

public final class Reencapsulator {
    enum Error: Swift.Error {
        case noEntropy
        case invalidCapsule
        case invalidCapsuleFragment
        case notEnoughFragments
        case invalidDelegateeKey
    }
    
    public static func reencapsulate<T, U>(parameters: T, capsule: Capsule<T, U>, fragment: KeyFragment<T, U>) throws -> CapsuleFragment<T, U> where T: UmbralParameters<U>, U: PrimeFieldProtocol {
        
        let valid = try Encapsulator.checkCapsule(capsule: capsule, parameters: parameters)
        if !valid {
            throw Error.invalidCapsule
        }
        
        let E = capsule.E!
        let V = capsule.V!
        
        guard let rk = fragment.rk else {
            throw Error.invalidCapsuleFragment
        }
        
        let V1 = (rk * V).toAffine()
        let E1 = (rk * E).toAffine()
  
        var capsuleFragment = CapsuleFragment(params: parameters)
        capsuleFragment.E1 = E1
        capsuleFragment.V1 = V1
        capsuleFragment.id = fragment.id
        capsuleFragment.Xa = fragment.Xa
        return capsuleFragment
    }
    
    
    public static func decapsulateFragments<T, U>(parameters: T, capsuleFragments: [CapsuleFragment<T, U>], delegatorKey: UmbralKey<T, U>,  delegateeKey: UmbralKey<T, U>) throws -> Data where T: UmbralParameters<U>, U: PrimeFieldProtocol {
        
        guard let privateKey = delegateeKey.bnKey else {
            throw Error.invalidDelegateeKey
        }
        
        let field = parameters.curveOrderField
        let b = PrimeFieldElement.fromValue(privateKey, field: field)
        
        let DHPoint = b.nativeValue * delegatorKey.pubkey
        let D = try parameters.H3((delegatorKey.pubkey,
                                   delegateeKey.pubkey, DHPoint.toAffine()))
        
        if capsuleFragments.count == 1 {
            let frag = capsuleFragments[0]
            if frag.E1 == nil || frag.V1 == nil || frag.id == nil || frag.Xa == nil {
                throw Error.invalidCapsuleFragment
            }
//            let skBytes = parameters.hashFunction(parameters.serializeZq(frag.id!)! + parameters.serializeZq(D)!)
//            let sk = PrimeFieldElement.fromBytes(skBytes, field: field)
            let Eprime = frag.E1!
            let Vprime = frag.V1!
            let Xa = frag.Xa!
            let ephDHPoint = b.nativeValue * Xa
            let d = try parameters.H3((Xa, delegateeKey.pubkey, ephDHPoint.toAffine()))
            let base = Eprime + Vprime
            let point = (d * base).toAffine()
            let pointSerialization = parameters.serializePoint(point)!
            let K = parameters.KDF(pointSerialization)
            return K
        } else {
            var lagrangeCoeffs = [PrimeFieldElement<T.CurveOrderField>]()
            lagrangeCoeffs.reserveCapacity(capsuleFragments.count)
            for i in 0 ..< capsuleFragments.count {
                let frag = capsuleFragments[i]
                if frag.E1 == nil || frag.V1 == nil || frag.id == nil || frag.Xa == nil {
                    throw Error.invalidCapsuleFragment
                }
                let skBytes_i = parameters.hashFunction(parameters.serializeZq(frag.id!)! + parameters.serializeZq(D)!)
                let sk_i = PrimeFieldElement.fromBytes(skBytes_i, field: field)
                var elems = [PrimeFieldElement<T.CurveOrderField>]()
                elems.reserveCapacity(capsuleFragments.count - 1)
                for j in 0 ..< capsuleFragments.count {
                    if i == j {
                        continue
                    }
                    let otherFrag = capsuleFragments[j]
                    if otherFrag.E1 == nil || otherFrag.V1 == nil || otherFrag.id == nil || otherFrag.Xa == nil {
                        throw Error.invalidCapsuleFragment
                    }
                    let skBytes_j = parameters.hashFunction(parameters.serializeZq(otherFrag.id!)! + parameters.serializeZq(D)!)
                    let sk_j = PrimeFieldElement.fromBytes(skBytes_j, field: field)
                    let elem = sk_j * (sk_j - sk_i).inv()
                    elems.append(elem)
                }
                var lambda = elems[0]
                for k in 1 ..< elems.count {
                    lambda = lambda * elems[k]
                }
                lagrangeCoeffs.append(lambda)
            }
            var Eprime = lagrangeCoeffs[0].nativeValue * capsuleFragments[0].E1!
            var Vprime = lagrangeCoeffs[0].nativeValue * capsuleFragments[0].V1!
            for k in 1 ..< lagrangeCoeffs.count {
                Eprime = Eprime + (lagrangeCoeffs[k].nativeValue * capsuleFragments[k].E1!)
                Vprime = Vprime + (lagrangeCoeffs[k].nativeValue * capsuleFragments[k].V1!)
            }
            let Xa = capsuleFragments[0].Xa!
            let ephDHPoint = b.nativeValue * Xa
            let d = try parameters.H3((Xa, delegateeKey.pubkey, ephDHPoint.toAffine()))
            let base = Eprime + Vprime
            let point = (d * base).toAffine()
            let pointSerialization = parameters.serializePoint(point)!
            let K = parameters.KDF(pointSerialization)
            return K
        }
    }
}

