//
//  ColorTabViewController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa

class ColorTabViewController: NSTabViewController {
    
    weak var colorViewController:ColorChooserController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.colorViewController?.colorChooserDelegate = self.tabViewItems[self.selectedTabViewItemIndex].viewController as? ColorChooserDelegate
        if let gradientController = self.childViewControllers.find({ $0 is BilinearGradientController }) as? BilinearGradientController {
            gradientController.colorChooserController = self.colorViewController
        }
    }
 
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        self.colorViewController?.colorChooserDelegate = tabViewItem?.viewController as? ColorChooserDelegate
    }
    
}
