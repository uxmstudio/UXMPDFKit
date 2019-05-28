//
//  AppDelegate.swift
//  UXMPDFKit
//
//  Created by Chris Anderson on 03/05/2016.
//  Copyright (c) 2016 Chris Anderson. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

    let dirPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    print("App Path: \(dirPaths)")

    return true
  }

  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    if let rootViewController = self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController) {
      if (rootViewController.responds(to: Selector("canRotate"))) {
        // Unlock landscape view orientations for this view controller
        return .landscapeLeft
      }
    }

    // Only allow portrait (standard behaviour)
    return .portrait
  }

  private func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController? {
    if (rootViewController == nil) { return nil }
    if (rootViewController.isKind(of: UITabBarController.self)) {
      return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UITabBarController).selectedViewController)
    } else if (rootViewController.isKind(of: UINavigationController.self)) {
      return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UINavigationController).visibleViewController)
    } else if (rootViewController.presentedViewController != nil) {
      return topViewControllerWithRootViewController(rootViewController: rootViewController.presentedViewController)
    }
    return rootViewController
  }
}

