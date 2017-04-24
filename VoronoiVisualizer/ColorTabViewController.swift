//
//  ColorTabViewController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

protocol ColoringSchemeViewController: class {
    
    var dismissHandler:((VoronoiViewColoringScheme) -> Void)? { set get }
    
}

class ColorTabViewController: NSTabViewController {
    
    weak var colorViewController:ColorChooserController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabView.delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let index = self.selectedTabViewItemIndex
        self.colorViewController?.colorChooserDelegate = self.tabViewItems[index].viewController as? ColorChooserDelegate
    }
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        self.colorViewController?.colorChooserDelegate = tabViewItem?.viewController as? ColorChooserDelegate
    }
    
}
