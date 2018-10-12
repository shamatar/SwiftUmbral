//
//  SwiftUmbral_iOSTests.swift
//  SwiftUmbral_iOSTests
//
//  Created by Alex Vlasov on 11/10/2018.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import XCTest
import EllipticSwift
import BigInt
import CryptoSwift

//import SwiftUmbral_iOS

@testable import SwiftUmbral_iOS

class SwiftUmbralTests: XCTestCase {
    
    func hashFunc(_ data: Data) -> Data {
        return data.sha3(.keccak256)
    }
    
    func kdf(_ data: Data) -> Data {
        return data.sha3(.keccak512)
    }
    
    func testPointMul() {
        let curve = EllipticSwift.bn256Curve
        for _ in 0 ..< 1 {
            let bn256PrimeBUI = BigUInt("21888242871839275222246405745257275088696311157297823662689037894645226208583", radix: 10)!
            let randomBytes = BigUInt.randomInteger(lessThan: bn256PrimeBUI).serialize()
            let point = curve.hashInto(randomBytes)
            let TWO = PrimeFieldElement.fromValue(UInt64(2), field: curve.field)
            var double = (TWO.nativeValue * point).toAffine()
            var added = (point + point).toAffine()
            XCTAssert(!added.isInfinity)
            XCTAssert(!double.isInfinity)
            XCTAssert(added == double)
            for _ in 0 ..< 250 {
                double = (TWO.nativeValue * double).toAffine()
                added = (added + added).toAffine()
                XCTAssert(!added.isInfinity)
                XCTAssert(!double.isInfinity)
                XCTAssert(double == added)
            }
        }
    }
    
    func testPointMulFromVector() {
        let secp256k1PrimeBUI = BigUInt("fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f", radix: 16)!
        //        let secp256k1PrimeField = MontPrimeField<U256>.init(secp256k1PrimeBUI)
        let secp256k1PrimeField = NaivePrimeField<NativeU256>.init(secp256k1PrimeBUI)
        let secp256k1CurveOrderBUI = BigUInt("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141", radix: 16)!
        let secp256k1CurveOrder = NativeU256(secp256k1CurveOrderBUI.serialize())!
        let secp256k1WeierstrassCurve = WeierstrassCurve(field: secp256k1PrimeField, order: secp256k1CurveOrder, A: NativeU256(UInt64(0)), B: NativeU256(UInt64(7)))
        let generatorX = BigUInt("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", radix: 16)!
        let generatorY = BigUInt("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", radix: 16)!
        let success = secp256k1WeierstrassCurve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init secp256k1 curve!")
        
        let scalar = BigUInt("e853ff4cc88e32bc6c2b74ffaca14a7e4b118686e77eefb086cb0ae298811127", radix: 16)!
        let c = secp256k1WeierstrassCurve
        let p = c.toPoint(BigUInt("5cfdf0eaa22d4d954067ab6f348e400f97357e2703821195131bfe78f7c92b38", radix: 16)!, BigUInt("584171d79868d22fae4442faede6d2c4972a35d1699453254d1b0df029225032", radix: 16)!)
        XCTAssert(p != nil)
        let ss = NativeU256(scalar.serialize())!
        let res = c.mul(ss, p!)
        let resAff = res.toAffine().coordinates
        XCTAssert(!resAff.isInfinity)
        XCTAssert(resAff.X == BigUInt("e2b1976566023f61f70893549a497dbf68f14e6cb44ba1b3bbe8c438a172a7b0", radix: 16)!)
        XCTAssert(resAff.Y == BigUInt("d088864d26ac7c96690ebc652b2906e8f2b85bccfb27b181d587899ccab4b442", radix: 16)!)
    }
    
    func testPointAddition() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let bn256PrimeBUI = BigUInt("21888242871839275222246405745257275088696311157297823662689037894645226208583", radix: 10)!
//        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
//        XCTAssert(success, "Failed to init bn256 curve!")
        let p = curve.toPoint(generatorX, generatorY)!
        let p2 = curve.toPoint(generatorX, bn256PrimeBUI - generatorY)!
        let sum = p + p2
        XCTAssert(sum.isInfinity)
        XCTAssert(sum.toAffine().isInfinity)
    }
    
    func testPointMul2() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        //        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        //        XCTAssert(success, "Failed to init bn256 curve!")
        let a = NativeU256(UInt64(32498273234))
        let bn256CurveOrderBUI = BigUInt("21888242871839275222246405745257275088548364400416034343698204186575808495617", radix: 10)!
        print("BN256 order is " + String(bn256CurveOrderBUI, radix: 16))
        let b = curve.order - a
        print("A")
        print(String(BigUInt(a.bytes), radix: 16))
        print("B")
        print(String(BigUInt(b.bytes), radix: 16))
        
        let p = curve.toPoint(generatorX, generatorY)!
        let s1 = (b * p).toAffine()
        let s2 = (a * p).toAffine()
        XCTAssert(s1.rawX.value == s2.rawX.value)
        XCTAssert(s1.rawY.negate().value == s2.rawY.value)
        let sum = b * p + a * p
        XCTAssert(sum.isInfinity)
        XCTAssert(sum.toAffine().isInfinity)
    }
    
    func testPointMul3() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        //        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        //        XCTAssert(success, "Failed to init bn256 curve!")
        var a = NativeU256(UInt64(1))
        for _ in 0 ..< 10 {
            let b = curve.order - a
            let p = curve.toPoint(generatorX, generatorY)!
            let s1 = (b * p).toAffine()
            let s2 = (a * p).toAffine()
            XCTAssert(s1.rawX.value == s2.rawX.value)
            XCTAssert(s1.rawY.negate().value == s2.rawY.value)
            let sum = b * p + a * p
            XCTAssert(sum.isInfinity)
            XCTAssert(sum.toAffine().isInfinity)
            a = a.modMultiply(a, curve.order)
        }
    }
    
    func testPointMul4() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let p = curve.toPoint(generatorX, generatorY)!
//        let bn256PrimeBUI = BigUInt("21888242871839275222246405745257275088696311157297823662689037894645226208583", radix: 10)!
//        let p = curve.toPoint(generatorX, bn256PrimeBUI - generatorY)!
        var i = UInt64(2)
        let px = NativeU256(p.rawX.nativeValue)
        let py = NativeU256(p.rawY.nativeValue)
//        var y = ProjectivePoint<WeierstrassCurve<NaivePrimeField<U256>>>.infinityPoint(curve)
        var x = p.toProjective()
        x = x + x
        for _ in 0 ..< 20 {
            let a = NativeU256(i)
            let s = (a * p).toAffine()

            if s.coordinates.X != x.toAffine().coordinates.X ||
                s.coordinates.Y != x.toAffine().coordinates.Y {
                print(i)
                XCTFail()
//                fatalError()
            }
            x = x + p.toProjective()
            let t = s + p
            if t.toAffine().coordinates.X != x.toAffine().coordinates.X ||
                t.toAffine().coordinates.Y != x.toAffine().coordinates.Y {
                print(i)
                XCTFail()
//                fatalError()
            }
            i = i + 1
            let pxprime = NativeU256(p.rawX.nativeValue)
            let pyprime = NativeU256(p.rawY.nativeValue)
            XCTAssert(px == pxprime)
            XCTAssert(py == pyprime)
        }
    }
    
    func testPointMul5() {
        let curve = EllipticSwift.secp256k1Curve
        let generatorX = BigUInt("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", radix: 16)!
        let generatorY = BigUInt("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", radix: 16)!
        let p = curve.toPoint(generatorX, generatorY)!
        //        let bn256PrimeBUI = BigUInt("21888242871839275222246405745257275088696311157297823662689037894645226208583", radix: 10)!
        //        let p = curve.toPoint(generatorX, bn256PrimeBUI - generatorY)!
        var i = UInt64(2)
        let px = NativeU256(p.rawX.nativeValue)
        let py = NativeU256(p.rawY.nativeValue)
        //        var y = ProjectivePoint<WeierstrassCurve<NaivePrimeField<U256>>>.infinityPoint(curve)
        var x = p.toProjective()
        x = x + x
        for _ in 0 ..< 20 {
            let a = NativeU256(i)
            let s = (a * p).toAffine()
            
            if s.coordinates.X != x.toAffine().coordinates.X ||
                s.coordinates.Y != x.toAffine().coordinates.Y {
                print(i)
                XCTFail()
                //                fatalError()
            }
            x = x + p.toProjective()
            let t = s + p
            if t.toAffine().coordinates.X != x.toAffine().coordinates.X ||
                t.toAffine().coordinates.Y != x.toAffine().coordinates.Y {
                print(i)
                XCTFail()
                //                fatalError()
            }
            i = i + 1
            let pxprime = NativeU256(p.rawX.nativeValue)
            let pyprime = NativeU256(p.rawY.nativeValue)
            XCTAssert(px == pxprime)
            XCTAssert(py == pyprime)
        }
    }
    
    
    
    func testQuasiDH() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let p = curve.toPoint(generatorX, generatorY)!
//        let p2 = curve.toPoint(generatorX, bn256PrimeBUI - generatorY)!
        let a = NativeU256(UInt64(32498273234))
        let b = NativeU256(UInt64(98732423523))
        let p1 = a * (b * p)
        let p2 = b * (a * p)
        XCTAssert(!p1.isInfinity)
        XCTAssert(!p2.isInfinity)
        XCTAssert(p1 == p2)
    }
    
    func testQuasiDH2() {
        let curve = EllipticSwift.secp256k1Curve
        let generatorX = BigUInt("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", radix: 16)!
        let generatorY = BigUInt("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", radix: 16)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let p = curve.toPoint(generatorX, generatorY)!
        //        let p2 = curve.toPoint(generatorX, bn256PrimeBUI - generatorY)!
        let a = NativeU256(UInt64(32498273234))
        let b = NativeU256(UInt64(98732423523))
        let p1 = a * (b * p)
        let p2 = b * (a * p)
        XCTAssert(!p1.isInfinity)
        XCTAssert(!p2.isInfinity)
        XCTAssert(p1 == p2)
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
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: [capsuleFragment], delegatorKey: delegatorKey, delegateeKey: delegateeKey)
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
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: [capsuleFragment], delegatorKey: delegatorKey, delegateeKey: delegateeKey)
                XCTAssertNotEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
    func testReencapsulationForManyFragments() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        let threshold = 5
        for _ in 0 ..< 10 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                let delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let fragments = try RekeyGenerator.generateRekeyFragments(parameters: params, delegatorKey: delegatorKey, delegateeKey: delegateeKey, numFragments: 20, threshold: threshold)
                let capsuleFragments = try fragments!.map { (fragment) throws -> CapsuleFragment<UmbralParameters<NaivePrimeField<U256>>, NaivePrimeField<U256>> in
                    return try Reencapsulator.reencapsulate(parameters: params, capsule: capsule, fragment: fragment)
                }
                let fragmentsSlice = Array(capsuleFragments[0 ..< threshold])
                delegatorKey.bnKey = nil
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: fragmentsSlice, delegatorKey: delegatorKey, delegateeKey: delegateeKey)
                XCTAssertEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
    func testReencapsulationForNotEnoughFragments() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        let threshold = 5
        for _ in 0 ..< 10 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                let delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let fragments = try RekeyGenerator.generateRekeyFragments(parameters: params, delegatorKey: delegatorKey, delegateeKey: delegateeKey, numFragments: 20, threshold: threshold)
                let capsuleFragments = try fragments!.map { (fragment) throws -> CapsuleFragment<UmbralParameters<NaivePrimeField<U256>>, NaivePrimeField<U256>> in
                    return try Reencapsulator.reencapsulate(parameters: params, capsule: capsule, fragment: fragment)
                }
                let fragmentsSlice = Array(capsuleFragments[0 ..< threshold-1])
                delegatorKey.bnKey = nil
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: fragmentsSlice, delegatorKey: delegatorKey, delegateeKey: delegateeKey)
                XCTAssertNotEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
    func testReencapsulationForNotEnoughFragmentsSecp256k1() {
        let curve = EllipticSwift.secp256k1Curve
        let generatorX = BigUInt("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", radix: 16)!
        let generatorY = BigUInt("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", radix: 16)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        let threshold = 5
        for _ in 0 ..< 1 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                let delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let fragments = try RekeyGenerator.generateRekeyFragments(parameters: params, delegatorKey: delegatorKey, delegateeKey: delegateeKey, numFragments: 20, threshold: threshold)
                let capsuleFragments = try fragments!.map { (fragment) throws -> CapsuleFragment<UmbralParameters<NaivePrimeField<U256>>, NaivePrimeField<U256>> in
                    return try Reencapsulator.reencapsulate(parameters: params, capsule: capsule, fragment: fragment)
                }
                let fragmentsSlice = Array(capsuleFragments[0 ..< threshold-1])
                delegatorKey.bnKey = nil
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: fragmentsSlice, delegatorKey: delegatorKey, delegateeKey: delegateeKey)
                XCTAssertNotEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
    func testReencapsulationForManyFragmentsOnNativeType() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        let threshold = 5
        for _ in 0 ..< 10 {
            do {
                let delegatorKey = try UmbralKey(params: params)
                let delegateeKey = try UmbralKey(params: params)
                XCTAssert(delegatorKey.bnKey! != delegateeKey.bnKey!)
                let res = try Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
                let capsule = res.capsule
                let symKey = res.symmeticKey
                let fragments = try RekeyGenerator.generateRekeyFragments(parameters: params, delegatorKey: delegatorKey, delegateeKey: delegateeKey, numFragments: 20, threshold: threshold)
                let capsuleFragments = try fragments!.map { (fragment) throws -> CapsuleFragment<UmbralParameters<NaivePrimeField<U256>>, NaivePrimeField<U256>> in
                    return try Reencapsulator.reencapsulate(parameters: params, capsule: capsule, fragment: fragment)
                }
                let fragmentsSlice = Array(capsuleFragments[0 ..< threshold])
                delegatorKey.bnKey = nil
                let key = try Reencapsulator.decapsulateFragments(parameters: params, capsuleFragments: fragmentsSlice, delegatorKey: delegatorKey, delegateeKey: delegateeKey)
                XCTAssertEqual(key.toHexString(), symKey.toHexString())
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
}
