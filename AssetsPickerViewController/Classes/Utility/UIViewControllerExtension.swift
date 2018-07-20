//
//  UIViewControllerExtension.swift
//  AssetsPickerViewController
//
//  Created by Pablo Paciello on 7/20/18.
//

import UIKit
import AVFoundation

extension UIViewController {
    
    func hapticFeedback() {
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}
