//
//  SwiftUmbralTests.swift
//  SwiftUmbralTests
//
//  Created by Alex Vlasov on 09/10/2018.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import XCTest
import EllipticSwift
import BigInt
import CryptoSwift

@testable import SwiftUmbral

class SwiftUmbralTests: XCTestCase {

    func hashFunc(_ data: Data) -> Data {
        return data.sha3(.keccak256)
    }
    
    func kdf(_ data: Data) -> Data {
        return data.sha3(.keccak512)
    }
    
    func testPointMul() {
        let curve = EllipticSwift.bn256Curve
        for _ in 0 ..< 100 {
            let bn256PrimeBUI = BigUInt("21888242871839275222246405745257275088696311157297823662689037894645226208583", radix: 10)!
            let randomBytes = BigUInt.randomInteger(lessThan: bn256PrimeBUI).serialize()
            let point = curve.hashInto(randomBytes)
    //        let generatorX = BigUInt("1", radix: 10)!
    //        let generatorY = BigUInt("2", radix: 10)!
    //        let point = curve.toPoint(generatorX, generatorY)!
            let TWO = PrimeFieldElement.fromValue(UInt64(2), field: curve.field)
            var double = (TWO.nativeValue * point).toAffine()
            var added = (point + point).toAffine()
            XCTAssert(added == double)
            for _ in 0 ..< 250 {
                double = (TWO.nativeValue * double).toAffine()
                added = (added + added).toAffine()
                XCTAssert(double == added)
            }
        }
    }
    
    func testEncapsulation() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        for _ in 0 ..< 100 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                let delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let key = try Encapsulator.decapsulate(capsule: capsule, parameters: params, delegatorKey: delegatorKey)
                XCTAssertEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
    func testEncapsulationForKeyMismatch() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        for _ in 0 ..< 100 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                let delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let key = try Encapsulator.decapsulate(capsule: capsule, parameters: params, delegatorKey: delegateeKey)
                XCTAssert(key != symKey)
            } catch {
                print(error)
            }
        }
    }
    
    func testReencapsulation() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        for _ in 0 ..< 100 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                let delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let fragments = try RekeyGenerator.generateRekeyFragments(parameters: params, delegatorKey: delegatorKey, delegateeKey: delegateeKey, numFragments: 1, threshold: 1)
                let fragment = fragments![0]
                let capsuleFragment = try Reencapsulator.reencapsulate(parameters: params, capsule: capsule, fragment: fragment)
                delegatorKey.bnKey = nil
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: [capsuleFragment], delegatorKey: delegatorKey, delegateeKey: delegateeKey, treshold: 1)
                XCTAssertEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
    func testReencapsulationWithMismatch() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        for _ in 0 ..< 100 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                var delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let fragments = try RekeyGenerator.generateRekeyFragments(parameters: params, delegatorKey: delegatorKey, delegateeKey: delegateeKey, numFragments: 1, threshold: 1)
                let fragment = fragments![0]
                let capsuleFragment = try Reencapsulator.reencapsulate(parameters: params, capsule: capsule, fragment: fragment)
                delegatorKey.bnKey = nil
                delegateeKey = try UmbralKey(params: params)
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: [capsuleFragment], delegatorKey: delegatorKey, delegateeKey: delegateeKey, treshold: 1)
                XCTAssertNotEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
    
}
