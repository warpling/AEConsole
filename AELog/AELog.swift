//
//  AELog.swift
//  AELog
//
//  Created by Marko Tadic on 3/16/16.
//  Copyright © 2016 AE. All rights reserved.
//

import Foundation
import UIKit

public func aelog(message: String = "", filePath: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
    AELog.sharedInstance.log(message, filePath: filePath, line: line, function: function)
}

public class AELog {
    
    private struct Key {
        static let ClassName = NSStringFromClass(AELog).componentsSeparatedByString(".").last!
        static let Enabled = "Enabled"
    }
    
    // MARK: - Singleton
    
    public static let sharedInstance = AELog()
    
    public class func launchWithDelegate(delegate: AELogDelegate, settingsPath: String? = nil) {
        AELog.sharedInstance.delegate = delegate
        AELog.sharedInstance.settingsPath = settingsPath
    }
    
    // MARK: - Properties
    
    public weak var delegate: AELogDelegate? {
        didSet {
            guard let
                app = delegate as? AppDelegate,
                window = app.window
            else { return }

            textView.frame = window.bounds
            window.addSubview(textView)
        }
    }
    
    public var settingsPath: String?
    
    private var text = "" {
        didSet {
            textView.text = text
        }
    }
    
    // MARK: - Helpers
    
    private var infoPlist: NSDictionary? {
        guard let
            path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist"),
            info = NSDictionary(contentsOfFile: path)
        else { return nil }
        return info
    }
    
    private var logSettings: [String : AnyObject]? {
        if let path = settingsPath {
            return settingsForPath(path)
        } else if let path = NSBundle.mainBundle().pathForResource(Key.ClassName, ofType: "plist") {
            return settingsForPath(path)
        } else {
            guard let
                info = infoPlist,
                settings = info[Key.ClassName] as? [String : AnyObject]
            else { return nil }
            return settings
        }
    }
    
    private func settingsForPath(path: String?) -> [String : AnyObject]? {
        guard let
            path = path,
            settings = NSDictionary(contentsOfFile: path) as? [String : AnyObject]
        else { return nil }
        return settings
    }
    
    private var logEnabled: Bool {
        guard let
            settings = logSettings,
            enabled = settings[Key.Enabled] as? Bool
        else { return false }
        return enabled
    }
    
    // MARK: - UI
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        textView.userInteractionEnabled = false
        textView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        textView.textColor = UIColor.whiteColor()
        return textView
    }()
    
    // MARK: - Actions
    
    private func log(message: String = "", filePath: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
        if logEnabled {
            var threadName = ""
            threadName = NSThread.currentThread().isMainThread ? "MAIN THREAD" : (NSThread.currentThread().name ?? "UNKNOWN THREAD")
            threadName = "[" + threadName + "] "
            
            let fileName = NSURL(fileURLWithPath: filePath).URLByDeletingPathExtension?.lastPathComponent ?? "???"
            
            var msg = ""
            if message != "" {
                msg = " - \(message)"
            }
            
            NSLog("-- " + threadName + fileName + "(\(line))" + " -> " + function + msg)
            
            delegate?.didLog(message)
        }
    }
    
}

public protocol AELogDelegate: class {
    func didLog(message: String)
}

extension AELogDelegate where Self: AppDelegate {
    
    func didLog(message: String) {
        guard let window = self.window else { return }
        let textView = AELog.sharedInstance.textView
        window.bringSubviewToFront(textView)
        AELog.sharedInstance.text += "\n\(message)"
    }
    
}






