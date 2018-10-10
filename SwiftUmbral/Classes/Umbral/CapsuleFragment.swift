//
//  CapsuleFragment.swift
//  SwiftUmbral
//
//  Created by Alex Vlasov on 10/10/2018.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import EllipticSwift
import BigInt

public struct CapsuleFragment<T, U> where T: UmbralParameters<U>, U: PrimeFieldProtocol {
    public var id: T.RawType?
    public var Xa: T.AffinePointType?
    public var E1: T.AffinePointType?
    public var V1: T.AffinePointType?
    
    public init(params: T) {
        
    }
}
