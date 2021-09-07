//
//  AAIHUD.swift
//  guardian_liveness
//

import Foundation
import UIKit

class AAIHUDHandlerItem {
    var btnTitle: String?
    var handler: (() -> Void)?
}

class AAIHUD: UIView {
    
    private var indicatorView: UIActivityIndicatorView!
    private var msgLabel: UILabel!
    private var handlerItem: AAIHUDHandlerItem?
    private var handlerButton: UIButton?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let sv: UIView = self
        let indicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        sv.addSubview(indicatorView)
        self.indicatorView = indicatorView
        
        let label: UILabel = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.textAlignment = NSTextAlignment.center
        sv.addSubview(label)
        msgLabel = label
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.sizeThatFits(UIScreen.main.bounds.size)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let imgWidth: CGFloat = 37, marginLeft: CGFloat = 14, marginTop: CGFloat = 18, padding: CGFloat = 8, minWidth: CGFloat = 120
        msgLabel.preferredMaxLayoutWidth = size.width - 2 * marginLeft - padding
        let labelSize: CGSize = msgLabel.sizeThatFits(CGSize(width: msgLabel.preferredMaxLayoutWidth, height: size.height))
        
        var width: CGFloat = labelSize.width + 2 * marginLeft
        if width < msgLabel.preferredMaxLayoutWidth {
            if (width < (imgWidth + 2 * marginLeft)) {
                width = imgWidth + 2 * marginLeft
            }
        }
        if (width < minWidth) {
            width = minWidth
        }
        
        var height: CGFloat = marginTop
        var top: CGFloat = 0
        if !indicatorView.isHidden {
            indicatorView.frame = CGRect(x: (width - imgWidth) / 2, y: marginTop, width: imgWidth, height: imgWidth)
            height += imgWidth
            if (!msgLabel.isHidden) {
                height += padding
            }
            top = indicatorView.frame.maxY
        } else {
            top = marginTop
        }
        
        if !msgLabel.isHidden {
            if (!indicatorView.isHidden) {
                top += padding
            }
            msgLabel.frame = CGRect(x: (width - labelSize.width) / 2, y: labelSize.width, width: labelSize.width, height: labelSize.height)
        }
        
        if handlerItem != nil {
            if let handlerButton = handlerButton {
                if handlerButton.superview == nil {
                    self.addSubview(handlerButton)
                }
                
                handlerButton.titleLabel?.sizeToFit()
                var btnSize: CGSize? = handlerButton.titleLabel?.bounds.size
                btnSize?.width += 20
                btnSize?.height += 20
                
                if let btnSize = btnSize {
                    if width <= btnSize.width {
                        width = btnSize.width + 2 * marginLeft
                        var originCenter: CGPoint = msgLabel.center
                        originCenter.x = width / 2
                        msgLabel.center = originCenter
                        handlerButton.frame = CGRect(x: marginLeft, y: height + padding, width: width - 2 * marginLeft, height: btnSize.height)
                    } else {
                        handlerButton.frame = CGRect(x: marginLeft, y: height + padding, width: width - 2 * marginLeft, height: btnSize.height)
                    }
                    height += (padding + btnSize.height)
                }
            }
        }
        
        height += marginTop
        if height > size.height {
            height = size.height
        }
        
        return CGSize(width: width, height: height)
    }
    
    static func showWaitWithMsg(_ msg: String, onView sv: UIView) {
        dismissHUDOnView(sv)
        
        let hud: AAIHUD = createHUDIfNeeded(sv)
        hud.handlerItem = nil
        if let handlerButton = hud.handlerButton {
            handlerButton.isHidden = true
        }
        
        hud.indicatorView.isHidden = false
        hud.indicatorView.startAnimating()
        hud.msgLabel.text = msg
        
        let screenSize: CGSize = UIScreen.main.bounds.size
        let size: CGSize = hud.sizeThatFits(screenSize)
        hud.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        hud.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        
        hud.alpha = 0
        UIView.animate(withDuration: 0.3) {
            hud.alpha = 1
        }
    }
    
    static func showAlertWithMsg(_ msg: String, onView sv: UIView, handlerItem: AAIHUDHandlerItem) {
        dismissHUDOnView(sv)
        
        let hud: AAIHUD = createHUDIfNeeded(sv)
        hud.msgLabel.text = msg
        hud.indicatorView.isHidden = true
        hud.handlerItem = handlerItem
        let btn: UIButton = UIButton(type: .custom)
        btn.setTitle(handlerItem.btnTitle, for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.backgroundColor = UIColor.gray
        btn.layer.cornerRadius = 4
        btn.addTarget(hud, action: #selector(tapBtnAction), for: .touchUpInside)
        hud.handlerButton = btn
        
        let screenSize: CGSize = UIScreen.main.bounds.size
        let size: CGSize = hud.sizeThatFits(screenSize)
        hud.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        hud.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        
        hud.alpha = 0
        UIView.animate(withDuration: 0.3) {
            hud.alpha = 1
        }
    }
    
    @objc private func tapBtnAction() {
        if let handler = handlerItem?.handler {
            handler()
            if let superview = self.superview {
                AAIHUD.dismissHUDOnView(superview, afterDelay: 0)
            }
        }
    }
    
    private static func hudForView(_ sv: UIView) -> AAIHUD? {
        let subviewsEnum: [UIView] = sv.subviews.reversed()
        for subview: UIView in subviewsEnum {
            if subview is AAIHUD {
                let hud = subview as! AAIHUD
                return hud
            }
        }
        return nil
    }
    
    private static func createHUDIfNeeded(_ sv: UIView) -> AAIHUD {
        let hud: AAIHUD? = AAIHUD.hudForView(sv)
        if let hud = hud {
            hud.layer.cornerRadius = 4
            return hud
        } else {
            let hud = AAIHUD(frame: CGRect.zero)
            hud.backgroundColor = UIColor(red: 0x20/255.0, green: 0x20/255, blue: 0x20/255, alpha: 0.86)
            sv.addSubview(hud)
            hud.layer.cornerRadius = 4
            return hud
        }
    }
    
    static func showMsg(_ msg: String, onView sv: UIView) {
        dismissHUDOnView(sv)
        
        let hud = createHUDIfNeeded(sv)
        hud.msgLabel.text = msg
        hud.indicatorView.isHidden = true
        hud.handlerButton = nil
        if let handlerButton = hud.handlerButton {
            handlerButton.isHidden = true
        }
        
        let screenSize: CGSize = UIScreen.main.bounds.size
        let size: CGSize = hud.sizeThatFits(screenSize)
        hud.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        hud.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        
        hud.alpha = 0
        UIView.animate(withDuration: 0.3) {
            hud.alpha = 1
        }
    }
    
    static func showMsg(_ msg: String, onView sv: UIView, duration interval : TimeInterval) {
        showMsg(msg, onView: sv)
        dismissHUDOnView(sv, afterDelay: interval)
    }
    
    private static func dismissHUDOnView(_ sv: UIView) {
        if let hud = hudForView(sv) {
            hud.removeFromSuperview()
        }
    }
    
    static func dismissHUDOnView(_ sv: UIView, afterDelay interval: TimeInterval) {
        guard let hud = hudForView(sv) else { return }
        
        UIView.animate(withDuration: 0.3, delay: interval, options: .curveEaseInOut, animations: {
            hud.alpha = 0
        }) { (finished) in
            hud.removeFromSuperview()
        }
    }
}
