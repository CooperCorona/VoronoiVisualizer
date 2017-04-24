//
//  ColorSplitViewController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa

class ColorSplitViewController: NSSplitViewController {

    weak var colorViewController:ColorSliderController? = nil
    weak var gradientViewController:BilinearGradientController? = nil
    var coloringScheme:VoronoiViewColoringScheme? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let colorTab = self.childViewControllers.find({ $0 is ColorTabViewController }) as? ColorTabViewController {
            colorTab.colorViewController = self.childViewControllers.find({ $0 is ColorChooserController }) as? ColorChooserController
            self.colorViewController = colorTab.childViewControllers.find({ $0 is ColorSliderController }) as? ColorSliderController
            self.gradientViewController = colorTab.childViewControllers.find({ $0 is BilinearGradientController }) as? BilinearGradientController
            self.colorViewController?.colorChooserController = colorTab.colorViewController
            self.gradientViewController?.colorChooserController = colorTab.colorViewController
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let scheme = self.coloringScheme {
            self.set(scheme: scheme)
        }
    }
    
    func set(scheme:VoronoiViewColoringScheme) {
        if let gradient = scheme as? LightSourceGradientColoringScheme {
            self.gradientViewController?.set(gradient: gradient.gradient)
        } else if let discrete = scheme as? DiscreteColoringScheme {
            self.colorViewController?.set(colors: discrete.colors)
        }
    }
    
}
