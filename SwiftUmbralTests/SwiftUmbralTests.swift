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
    
    func testEncapsulation() {
        let curve = EllipticSwift.bn256Curve
        let generatorX = BigUInt("1", radix: 10)!
        let generatorY = BigUInt("2", radix: 10)!
        let success = curve.testGenerator(AffineCoordinates(generatorX, generatorY))
        XCTAssert(success, "Failed to init bn256 curve!")
        let params = try! UmbralParameters(curve: curve, generator: (generatorX, generatorY), hashFunction: hashFunc, kdf: kdf)
        let delegatorKey = try! UmbralKey(params: params)
        let delegateeKey = try! UmbralKey(params: params)
        let res = try! Encapsulator.encapsulate(parameters: params, delegatorKey: delegatorKey)
        let capsule = res.capsule
        let symKey = res.symmeticKey
        let key = try! Encapsulator.decapsulate(capsule: capsule, parameters: params, delegatorKey: delegatorKey)
        XCTAssert(key == symKey)
    }
    
    
}
