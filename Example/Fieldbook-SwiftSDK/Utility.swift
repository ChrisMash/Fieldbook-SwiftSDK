//
//  Utility.swift
//  Fieldbook-SwiftSDK
//
//  Created by Chris Mash on 22/02/2016.
//  Copyright © 2016 Chris Mash. All rights reserved.
//

import UIKit

class Utility
{
    static func displayAlert( title: String, message: String, viewController: UIViewController )
    {
        let alert = UIAlertController( title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert )
        alert.addAction( UIAlertAction( title: "OK", style: UIAlertActionStyle.Default, handler: nil ) )
        viewController.presentViewController( alert, animated: true, completion: nil )
    }
    
}
