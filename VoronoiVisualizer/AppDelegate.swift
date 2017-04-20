//
//  AppDelegate.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 9/16/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    static let ExportImageNotification = "com.coopercorona.VoronoiVisualizer.ExportImageNotification"
    static let GradientItemClickedNotification = "com.coopercorona.VoronoiVisualizer.GradientItemClickedNotification"
    
    @IBAction func exportMenuItemClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.ExportImageNotification), object: self)
    }
    @IBAction func gradientItemClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.GradientItemClickedNotification), object: self)
    }

}

