//
//  ViewController.swift
//  SwiftHooks
//
//  Created by stephenwzl on 11/17/2023.
//  Copyright (c) 2023 stephenwzl. All rights reserved.
//

import UIKit
import SwiftHooks

class ViewController: UIViewController, Fiber {
    
    lazy var count = useState(1)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

