//
//  AAILivenessResultViewController.swift
//  guardian_liveness
//

import Foundation

class AAILivenessResultViewController: UIViewController {
    
    private var succeed: Bool!
    private var stateKey: String?
    
    private var stateImgView: UIImageView!
    private var resultLabel: UILabel!
    private var stateLabel: UILabel?
    
    private var scoreLabel: UILabel?
    private var score: CGFloat = -1
    
    private var tryAgainBtn: UIButton?
    private var backBtn: UIButton?
    
    convenience init(_ resultInfo: [AnyHashable : Any]) {
        self.init()
        if let error = resultInfo["error"] as? NSError {
            succeed = false
            stateKey = error.localizedDescription
        } else {
            succeed = true
            if let score = resultInfo["score"] as? CGFloat {
                self.score = score
            }
        }
    }
    
    convenience init(_ succeed: Bool, resultState stateKey: String?) {
        self.init()
        self.succeed = succeed
        self.stateKey = stateKey
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sv: UIView = self.view
        sv.backgroundColor = UIColor.white
        
        // Back button
        let navc: UINavigationController? = self.navigationController
        if navc == nil || (navc != nil && navc?.isNavigationBarHidden == true) {
            let backBtn: UIButton = UIButton(type: .custom)
            backBtn.setImage(AAILivenessUtil.imgWithName("arrow_back"), for: .normal)
            sv.addSubview(backBtn)
            backBtn.addTarget(self, action: #selector(tapBackBtnAction), for: .touchUpInside)
            self.backBtn = backBtn
        }
        
        var imgName: String!
        var stateStr: String!
        if succeed {
            imgName = "icon_liveness_success@2x.jpg"
            stateStr = "detection_success"
        } else {
            imgName = "icon_liveness_fail@2x.jpg"
            stateStr = stateKey != nil ? stateKey : "detection_fail"
        }
        
        stateImgView = UIImageView(image: AAILivenessUtil.imgWithName(imgName))
        sv.addSubview(stateImgView)
        
        //
        resultLabel = UILabel()
        resultLabel.font = pingfangFontWithSize(18)
        resultLabel.textAlignment = .center
        let resultStrKey = succeed ? "detection_success" : "detection_fail"
        resultLabel.text = AAILivenessUtil.localStrForKey(resultStrKey)
        resultLabel.numberOfLines = 0
        sv.addSubview(resultLabel)
        
        //
        
        if !succeed {
            stateLabel = UILabel()
            stateLabel?.font = pingfangFontWithSize(15)
            stateLabel?.textAlignment = .center
            stateLabel?.numberOfLines = 0
            let localeStr: String? = AAILivenessUtil.localStrForKey(stateStr)
            stateLabel?.text = localeStr != nil ? localeStr : stateStr
            stateLabel?.textColor = UIColor(red: 0x55/255, green: 0x55/255, blue: 0x55/255, alpha: 1)
            sv.addSubview(stateLabel!)
        }
        
        if score >= 0 {
            scoreLabel = UILabel()
            scoreLabel?.font = pingfangFontWithSize(16)
            scoreLabel?.textAlignment = .center
            scoreLabel?.textColor = UIColor(red: 0x55/255, green: 0x55/255, blue: 0x55/255, alpha: 1)
            scoreLabel?.text = String(format: "Liveness score: %.f", score)
            sv.addSubview(scoreLabel!)
        }
        
        if !succeed {
            tryAgainBtn = UIButton(type: .custom)
            tryAgainBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            tryAgainBtn?.setTitleColor(UIColor.white, for: .normal)
            tryAgainBtn?.setTitle(AAILivenessUtil.localStrForKey("try_again"), for: .normal)
            let bcgColor: UIColor = UIColor(red: 0x14/255, green: 0x14/255, blue: 0x14/255, alpha: 1)
            var bcgImg: UIImage? = imageWithColor(bcgColor, CGSize(width: 80, height: 44))
            bcgImg = bcgImg?.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
            tryAgainBtn?.setBackgroundImage(bcgImg, for: .normal)
            tryAgainBtn?.addTarget(self, action: #selector(tapTryBtnAction), for: .touchUpInside)
            sv.addSubview(tryAgainBtn!)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Config back button frame
        var top: CGFloat = 0
        let marginLeft: CGFloat = 20, marginTop: CGFloat = 20
        if #available(iOS 11, *) {
            top = self.view.safeAreaInsets.top
        } else {
            if let navc = navigationController {
                if navc.isNavigationBarHidden {
                    top = UIApplication.shared.statusBarFrame.size.height
                } else {
                    navc.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height
                }
            }
        }
        
        backBtn?.frame = CGRect(x: 20, y: top + marginTop, width: 40, height: 40)
        
        let size: CGSize = self.view.frame.size
        let imgSize: CGSize = stateImgView.bounds.size
        stateImgView.center = CGPoint(x: (size.width) / 2, y: (size.height - imgSize.height) / 2 - 40)
        
        let preferMaxSize: CGSize = CGSize(width: size.width - 2 * marginLeft, height: size.height)
        var labelSize: CGSize = resultLabel.sizeThatFits(preferMaxSize)
        resultLabel.bounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
        resultLabel.center = CGPoint(x: stateImgView.center.x, y: stateImgView.frame.maxY + 30)
        
        if let stateLabel = stateLabel {
            labelSize = stateLabel.sizeThatFits(preferMaxSize)
            stateLabel.bounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
            stateLabel.center = CGPoint(x: stateImgView.center.x, y: resultLabel.frame.maxY + 45)
        }
        
        var preViewFrame: CGRect? = stateLabel?.frame
        if let scoreLabel = scoreLabel {
            scoreLabel.sizeToFit()
            scoreLabel.center = CGPoint(x: resultLabel.center.x, y: resultLabel.center.y + 40)
            preViewFrame = scoreLabel.frame
        }
        
        if let tryAgainBtn = tryAgainBtn {
            let marginLeft: CGFloat = 40
            if let previewFrame = preViewFrame {
                tryAgainBtn.frame = CGRect(x: marginLeft, y: previewFrame.maxY + 40, width: size.width - 2 * marginLeft, height: 44)
            }
        }
    }
    
    private func pingfangFontWithSize(_ fontSize: CGFloat) -> UIFont {
        let font: UIFont = UIFont(name: "PingFangSC-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        return font
    }
    
    private func imageWithColor(_ color: UIColor, _ size: CGSize) -> UIImage? {
        let rect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @objc private func tapBackBtnAction() {
        // You can customize the back logic.
        if let navc = navigationController, navc.viewControllers.contains(self) {
            let count: Int = navc.viewControllers.count
            if count >= 3 {
                // Skip the `AAILivenessViewController` page.
                navc.popToViewController(navc.viewControllers[count - 3], animated: true)
            } else {
                navc.popToRootViewController(animated: true)
            }
        } else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func tapTryBtnAction() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: Notification.Name("kAAIRestart"), object: nil)
        }
        navigationController?.popViewController(animated: true)
    }
}
