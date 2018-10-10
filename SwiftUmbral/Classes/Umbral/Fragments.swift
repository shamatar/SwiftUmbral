//  Created by Alex Vlasov on 09/10/2018.
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
import EllipticSwift
import BigInt

public struct KeyFragment<T, U> where T: UmbralParameters<U>, U: PrimeFieldProtocol {
    public var id: T.RawType?
    public var rk: T.RawType?
    public var Xa: T.AffinePointType?
    public var U1: T.AffinePointType?
    public var z1: T.RawType?
    public var z2: T.RawType?
    
    public init(params: T) {
        
    }
}
