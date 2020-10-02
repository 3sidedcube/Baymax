//
//  StormImageLiteral.swift
//  ThunderCloud
//
//  Created by Simon Mitchell on 15/08/2019.
//  Copyright © 2019 threesidedcube. All rights reserved.
//

import UIKit

/// A wrapper for Image Literals which allow them being pulled from Baymax's `Assets.xcassets`
struct BaymaxImageLiteral: _ExpressibleByImageLiteral {
    
    /// The final image which was found in the storm assets
    let image: UIImage?
    
    init(imageLiteralResourceName name: String) {
        image = UIImage(named: name, in: .current, compatibleWith: nil)
    }
}
