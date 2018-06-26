//
//  ActivityIndicatorVC.swift
//  De Brand
//
//  Created by Anshul on 07/06/18.
//  Copyright © 2018 ANSHUL. All rights reserved.
//

import UIKit

class ActivityIndicatorVC: NSObject {
 
    var activityView: UIActivityIndicatorView?
    var view: UIView?
    
    static let sharedInstance:ActivityIndicatorVC = {
        let instance = ActivityIndicatorVC ()
        return instance
    } ()
    
    // MARK: Init
    override init() {
        print("")
        // initialized with variable or property
    }
    
    func startIndicator() {
        makeVisible()
        activityView?.startAnimating()

    }
    
    func stopIndicator() {
        view?.removeFromSuperview()
        activityView?.stopAnimating()
    }
    
    func makeVisible() {
        let appDelegate: AppDelegate? = (UIApplication.shared.delegate as? AppDelegate)
        view = UIView(frame: UIScreen.main.bounds)
        activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityView?.center = (view?.center)!
        view?.addSubview(activityView!)
        view?.backgroundColor = UIColor.black
        view?.alpha = 0.7
        appDelegate?.window?.addSubview(view!)
    }
    
}
