//
//  ColorSplitViewController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa

class ColorSplitViewController: NSSplitViewController {

    weak var colorViewController:NSViewController? = nil
    weak var gradientViewController:BilinearGradientController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let colorTab = self.childViewControllers.find({ $0 is ColorTabViewController }) as? ColorTabViewController {
            colorTab.colorViewController = self.childViewControllers.find({ $0 is ColorChooserController }) as? ColorChooserController
        }
    }
    
}
