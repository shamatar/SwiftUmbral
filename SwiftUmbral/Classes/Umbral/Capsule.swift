//
//  Created by Alex Vlasov on 09/10/2018.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import EllipticSwift
import BigInt

public struct Capsule<T, U> where T: UmbralParameters<U>, U: PrimeFieldProtocol {
    public var s: T.RawType?
    public var E: T.AffinePointType?
    public var V: T.AffinePointType?
    
    public init(params: T) {
        
    }
}
