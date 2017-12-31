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
    static let ImageNotification = "com.coopercorona.VoronoiVisualizer.ImageNotification"
    static let MaskNotification = "com.coopercorona.VoronoiVisualizer.MaskNotification"
    static let NoImageNotification = "com.coopercorona.VoronoiVisualizer.NoImageNotification"
    
    @IBAction func exportMenuItemClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.ExportImageNotification), object: self)
    }

    @IBAction func imageMenuItemClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.ImageNotification), object: self)
    }
    
    @IBAction func maskMenuItemClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.MaskNotification), object: self)
    }
    
    @IBAction func noImageMenuItemClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.NoImageNotification), object: self)
    }
    
}

