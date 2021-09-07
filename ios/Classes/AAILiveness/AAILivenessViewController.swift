//
//  AAILivenessViewController.swift
//  guardian_liveness
//

import Foundation
import AVFoundation
import AAILivenessSDK

class AAILivenessViewController : UIViewController, AAILivenessWrapDelegate {
    
    private var backBtn: UIButton?
    private var stateLabel: UILabel!
    private var stateImgView: UIImageView!
    // Voice
    private var voiceBtn: UIButton!
    //Time label
    private var timeLabel: UILabel!
    private var roundViewFrame: CGRect?
    
    private var preResult: AAIDetectionResult = AAIDetectionResultUnknown
    private var isReady: Bool = false
    private var _isRequestingAuth: Bool = false
    private var _requestAuthSucceed: Bool = false
    
    private var wrapView: AAILivenessWrapView!
    private var requestAuthComplete: Bool = false
    private var requestAuthCached: Bool = false
    private var hasPortraitDirection: Bool = false
    private var util: AAILivenessUtil!
    
    var result: FlutterResult?
    
    var isRequestingAuth: Bool {
        get {
            _isRequestingAuth
        }
        set {
            _isRequestingAuth = newValue
        }
    }
    
    var requestAuthSucceed: Bool {
        get {
            _requestAuthSucceed
        }
        set {
            _requestAuthSucceed = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        util = AAILivenessUtil()
        
        let sv: UIView = self.view
        let wrapView: AAILivenessWrapView = AAILivenessWrapView()
        sv.addSubview(wrapView)
        /*
        //Custom UI
        wrapView.backgroundColor = [UIColor grayColor];
        wrapView.roundBorderView.layer.borderColor = [UIColor redColor].CGColor;
        wrapView.roundBorderView.layer.borderWidth = 2;
         */
        /*
        //You can custom detectionActions
        wrapView.detectionActions = @[@(AAIDetectionTypeMouth), @(AAIDetectionTypePosYaw), @(AAIDetectionTypeBlink)];
         */
        wrapView.wrapDelegate = self
        self.wrapView = wrapView
        
        // Back Button
        if navigationController?.isNavigationBarHidden == true || navigationController == nil {
            let backBtn: UIButton = UIButton(type: .custom)
            backBtn.setImage(AAILivenessUtil.imgWithName("arrow_back"), for: .normal)
            sv.addSubview(backBtn)
            backBtn.addTarget(self, action: #selector(tapBackBtnAction), for: .touchUpInside)
            self.backBtn = backBtn
        }
        
        // Detect state label
        let stateLabel: UILabel = UILabel()
        stateLabel.font = UIFont.systemFont(ofSize: 16)
        stateLabel.textColor = UIColor.black
        stateLabel.numberOfLines = 0
        stateLabel.textAlignment = .center
        sv.addSubview(stateLabel)
        self.stateLabel = stateLabel
        
        // Action status imageView
        let stateImgView: UIImageView = UIImageView()
        stateImgView.contentMode = .scaleAspectFit
        sv.addSubview(stateImgView)
        self.stateImgView = stateImgView
        
        // Voice switch button
        let voiceBtn: UIButton = UIButton()
        voiceBtn.setImage(AAILivenessUtil.imgWithName("liveness_open_voice@2x.png"), for: .normal)
        voiceBtn.setImage(AAILivenessUtil.imgWithName("liveness_close_voice@2x.png"), for: .selected)
        sv.addSubview(voiceBtn)
        voiceBtn.addTarget(self, action: #selector(tapVoiceBtnAction), for: .touchUpInside)
        
        if AAILivenessUtil.isSilent() {
            voiceBtn.isSelected = true
        }
        
        self.voiceBtn = voiceBtn
        
        // Timeout interval label
        timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor(red: 0x36/255, green: 0x36/255, blue: 0x36/255, alpha: 1)
        timeLabel.text = String(format: "%d S", aai_timeout_interval)
        timeLabel.textAlignment = .center
        sv.addSubview(timeLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(restartDetection), name: Notification.Name(rawValue: "kAAIRestart"), object: nil)
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: .new, context: nil)
        
        util.saveCurrBrightness()
        
        timeLabel.isHidden = true
        self.voiceBtn.isHidden = true
        
        startCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Do not modify begin
        let rect: CGRect = self.view.frame
        wrapView.frame = rect
        wrapView.setNeedsLayout()
        wrapView.layoutIfNeeded()
        
        let size: CGSize = rect.size
        let tmpFrame: CGRect = wrapView.roundBorderView.frame
        roundViewFrame = wrapView.roundBorderView.convert(tmpFrame, to: self.view)
        // Do not modify end
        
        // top
        var top: CGFloat = 0
        let marginLeft: CGFloat = 20, marginTop: CGFloat = 20
        if #available(iOS 11, *) {
            top = self.view.safeAreaInsets.top
        } else {
            if let navigationController = self.navigationController {
                if navigationController.isNavigationBarHidden {
                    top = UIApplication.shared.statusBarFrame.size.height
                } else {
                    top = navigationController.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height
                }
            }
        }
        
        // Back button
        backBtn?.frame = CGRect(x: marginLeft, y: top + marginTop, width: 40, height: 40)
        
        // State image
        let stateImgViewWidth: CGFloat = 120
        stateImgView.frame = CGRect(x: (size.width - stateImgViewWidth) / 2, y: roundViewFrame?.maxY ?? 0, width: stateImgViewWidth, height: stateImgViewWidth)
        
        // Time label
        var timeLabelCenterY: CGFloat = 0
        let timeLabelSize: CGSize = CGSize(width: 40, height: 24)
        if let backBtn = backBtn {
            timeLabelCenterY = backBtn.center.y
        } else {
            timeLabelCenterY = top + marginTop + timeLabelSize.height / 2
        }
        timeLabel.bounds = CGRect(x: 0, y: 0, width: timeLabelSize.width, height: timeLabelSize.height)
        timeLabel.center = CGPoint(x: size.width - marginLeft - 20, y: timeLabelCenterY)
        timeLabel.layer.cornerRadius = 12
        timeLabel.layer.borderWidth = 1
        timeLabel.layer.borderColor = timeLabel.textColor.cgColor
        
        voiceBtn.bounds = CGRect(x: 0, y: 0, width: 32, height: 32)
        voiceBtn.center = CGPoint(x: timeLabel.center.x, y: timeLabel.frame.maxY + 20)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        util.graduallyResumeBrightness()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        util.graduallyResumeBrightness()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetViewState()
        wrapView.roundBorderView.backgroundColor = UIColor.white
    }
    
    private func updateStateLabel(_ state: String?) {
        if let frame = roundViewFrame {
            let w: CGFloat = frame.size.width
            let marginTop: CGFloat = 40
            if let state = state, let stateLabel = stateLabel {
                stateLabel.text = state
                let size: CGSize = stateLabel.sizeThatFits( CGSize(width: w, height: 1000))
                stateLabel.frame = CGRect(x: frame.origin.x, y: frame.origin.y + w + marginTop, width: w, height: size.height)
            } else {
                stateLabel.text = nil
                stateLabel.frame = CGRect(x: frame.origin.x, y: frame.origin.y + w + marginTop, width: frame.size.width, height: 30)
            }
        }
    }
    
    private func showImgWithType(_ detectionType: AAIDetectionType) {
        switch (detectionType) {
            case AAIDetectionTypeBlink, AAIDetectionTypeMouth, AAIDetectionTypePosYaw:
                stateImgView.stopAnimating()
                if let array = AAILivenessUtil.stateImgWithType(detectionType) {
                    stateImgView.animationImages = array
                    stateImgView.animationDuration = TimeInterval(exactly: array.count * 1 / 5)!
                    stateImgView.startAnimating()
                }
                break
            default:
                break
        }
    }
    
    // MARK: UserAction
    private func startCamera() {
        weak var weakSelf: AAILivenessViewController? = self
        wrapView.checkCameraPermission(completionBlk: { (authed) in
            guard let weakSelf = weakSelf else { return }
            
            // Alert no permission
            AAIHUD.showMsg(AAILivenessUtil.localStrForKey("no_camera_permission") ?? "", onView: weakSelf.view, duration: 1.5)
        })
    }
    
    private func requestAuth() {
        isRequestingAuth = true
        isReady = false
        timeLabel.isHidden = true
        
        weak var weakSelf: AAILivenessViewController? = self
        AAIHUD.showWaitWithMsg(AAILivenessUtil.localStrForKey("auth_check") ?? "", onView: self.view)
        wrapView.startAuth(completionBlk: { (error) in
            if let strongSelf = weakSelf {
                strongSelf.isRequestingAuth = false
                strongSelf.requestAuthComplete = true
                
                if error != nil {
                    strongSelf.requestAuthSucceed = false
                    
                    AAIHUD.dismissHUDOnView(strongSelf.view, afterDelay: 0)
                    
                    self.popError(code: "AUTH_REQUEST_FAILED", message: error.localizedDescription, details: nil)
//                     let resultVC: AAILivenessResultViewController = AAILivenessResultViewController(false, resultState: error.localizedDescription)
//                     weakSelf?.navigationController?.pushViewController(resultVC, animated: true)
                } else {
                    strongSelf.requestAuthCached = true
                    strongSelf.requestAuthSucceed = true
                    AAIHUD.dismissHUDOnView(strongSelf.view, afterDelay: 0)
                }
            }
        })
    }
    
    @objc private func tapVoiceBtnAction(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        if btn.isSelected {
            // Close
            util.configVolume(0)
        } else {
            // Open
            util.configVolume(0.5)
        }
    }
    
    private func popResult(detectionResult: Any?) {
        if let navc: UINavigationController = self.navigationController {
            if navc.viewControllers.contains(self) {
                navc.popViewController(animated: true)
                result?(detectionResult)
            } else {
                navc.presentingViewController?.dismiss(animated: true, completion: {
                    self.result?(detectionResult)
                })
            }
        } else {
            dismiss(animated: true) {
                self.result?(detectionResult)
            }
        }
    }
    
    private func popError(code: String, message: String?, details: Any?) {
        if let navc: UINavigationController = self.navigationController {
            if navc.viewControllers.contains(self) {
                navc.popViewController(animated: true)
                result?(
                    FlutterError(code: code, message: message, details: details)
                )
            } else {
                navc.presentingViewController?.dismiss(animated: true, completion: {
                    self.result?(
                        FlutterError(code: code, message: message, details: details)
                    )
                })
            }
        }
    }
    
    @objc private func tapBackBtnAction() {
        if let navc: UINavigationController = self.navigationController {
            if navc.viewControllers.contains(self) {
                navc.popViewController(animated: true)
                self.result?(
                    FlutterError(code: "USER_GIVE_UP", message: "Detection Failed", details: nil)
                )
            } else {
                navc.presentingViewController?.dismiss(animated: true, completion: {
                    self.result?(
                        FlutterError(code: "USER_GIVE_UP", message: "Detection Failed", details: nil)
                    )
                })
            }
        } else {
            dismiss(animated: true) {
                self.result?(
                    FlutterError(code: "USER_GIVE_UP", message: "Detection Failed", details: nil)
                )
            }
        }
    }
    
    private func resetViewState() {
        stateLabel.text = nil
        
        stateImgView.animationImages = nil
        isReady = false
        timeLabel.isHidden = true
        voiceBtn.isHidden = true
    }
    
    @objc private func restartDetection() {
        resetViewState()
        wrapView.roundBorderView.backgroundColor = UIColor.white
        hasPortraitDirection = false
        requestAuthComplete = false
        
        startCamera()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.wrapView.roundBorderView.backgroundColor = UIColor.clear
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume" {
            if let volume = change?[NSKeyValueChangeKey.newKey] as? Float {
                util.configPlayerVolume(volume)
                if volume == 0 {
                    if voiceBtn.isSelected == false {
                        voiceBtn.isSelected = true
                    }
                } else {
                    if voiceBtn.isSelected == true {
                        voiceBtn.isSelected = false
                    }
                }
            }
        }
    }
    
    // MARK: WrapViewDelegate
    func onDetectionReady(_ detectionType: AAIDetectionType) {
        isReady = true
        timeLabel.isHidden = false
        
        var key: String?
        switch (detectionType) {
            case AAIDetectionTypeBlink:
                key = "pls_blink"
                util.playAudio("action_blink.mp3")
                break
            case AAIDetectionTypeMouth:
                key = "pls_open_mouth"
                util.playAudio("action_open_mouth.mp3")
                break
            case AAIDetectionTypePosYaw:
                key = "pls_turn_head"
                util.playAudio("action_turn_head.mp3")
                break
            default: break
        }
        if let key = key {
            stateLabel.text = AAILivenessUtil.localStrForKey(key)
            showImgWithType(detectionType)
        }
    }
    
    func onDetectionFailed(_ detectionResult: AAIDetectionResult, for detectionType: AAIDetectionType) {
        util.playAudio("detection_failed.mp3")
        AAILocalizationUtil.stopMonitor()
        
        // Reset
        preResult = AAIDetectionResultUnknown
        
        var key: String?
        var errorCode: String = "UNDEFINED"
        switch (detectionResult) {
            case AAIDetectionResultTimeout:
                key = "fail_reason_timeout"
                errorCode = "ACTION_TIMEOUT"
                break
            case AAIDetectionResultErrorMutipleFaces:
                key = "fail_reason_multi_face"
                errorCode = "MULTIPLE_FACE"
                break
            case AAIDetectionResultErrorFaceMissing:
                errorCode = "FACE_MISSING"
                switch (detectionType) {
                    case AAIDetectionTypeBlink, AAIDetectionTypeMouth:
                        key = "fail_reason_facemiss_blink_mouth"
                        break
                    case AAIDetectionTypePosYaw:
                        key = "fail_reason_facemiss_pos_yaw"
                        break
                    default:
                        break
                }
                break
            case AAIDetectionResultErrorMuchMotion:
                key = "fail_reason_much_motion"
                errorCode = "MUCH_MOTION"
                break
            default:
                break
        }
        
        // Show result page
        if let key = key {
            
            let state = AAILivenessUtil.localStrForKey(key)
            updateStateLabel(state)

            stateImgView.stopAnimating()
            
            popError(code: errorCode, message: "Detection Failed", details: nil)
//
//             let resultVC: AAILivenessResultViewController = AAILivenessResultViewController(false, resultState: key)
//             navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    func shouldDetect() -> Bool {
        if !hasPortraitDirection {
            hasPortraitDirection = AAILocalizationUtil.isPortraitDirection()
            if hasPortraitDirection {
                if !requestAuthCached && !isRequestingAuth && !requestAuthComplete {
                    DispatchQueue.main.async {
                        self.requestAuth()
                    }
                }
                return requestAuthCached
            } else {
                DispatchQueue.main.async {
                    if !self.isReady {
                        self.timeLabel.isHidden = true
                        self.voiceBtn.isHidden = true
                        self.stateImgView.animationImages = nil
                    }
                    
                    let state = AAILivenessUtil.localStrForKey("pls_hold_phone_v")
                    self.updateStateLabel(state)
                }
            }
            
            return false
        } else {
            if !requestAuthCached && !isRequestingAuth && !requestAuthComplete {
                DispatchQueue.main.async {
                    self.updateStateLabel(nil)
                    self.requestAuth()
                }
            }
            return requestAuthCached
        }
    }
    
    func onFrameDetected(_ result: AAIDetectionResult, status: AAIActionStatus, for detectionType: AAIDetectionType) {
        var key: String?
        if !isReady && !AAILocalizationUtil.isPortraitDirection() {
            key = "pls_hold_phone_v"
        } else {
            if preResult == result {
                return
            }
            
            switch result {
                case AAIDetectionResultFaceMissing:
                    key = "no_face"
                    break
                case AAIDetectionResultFaceLarge:
                    key = "move_further"
                    break
                case AAIDetectionResultFaceSmall:
                    key = "move_closer"
                    break
                case AAIDetectionResultFaceNotCenter:
                    key = "move_center"
                    break
                case AAIDetectionResultFaceNotFrontal:
                    key = "frontal"
                    break
                case AAIDetectionResultFaceNotStill:
                    key = "stay_still"
                    break
                case AAIDetectionResultFaceInAction:
                    switch detectionType {
                        case AAIDetectionTypeBlink:
                            key = "pls_blink"
                            break
                        case AAIDetectionTypePosYaw:
                            key = "pls_turn_head"
                            break
                        case AAIDetectionTypeMouth:
                            key = "pls_open_mouth"
                            break
                        default:
                            break
                    }
                    break
                default:
                    break
            }
        }
        
        if let key = key {
            let state = AAILivenessUtil.localStrForKey(key)
            updateStateLabel(state)
        }
    }
    
    func onDetectionTypeChanged(_ toDetectionType: AAIDetectionType) {
        var key: String?
        switch toDetectionType {
            case AAIDetectionTypeBlink:
                key = "pls_blink"
                util.playAudio("action_blink.mp3")
                break
            case AAIDetectionTypeMouth:
                key = "pls_open_mouth"
                util.playAudio("action_open_mouth.mp3")
                break
            case AAIDetectionTypePosYaw:
                key = "pls_turn_head"
                util.playAudio("action_turn_head.mp3")
                break
            default:
                break
        }
        
        if let key = key {
            let state = AAILivenessUtil.localStrForKey(key)
            updateStateLabel(state)
            showImgWithType(toDetectionType)
        }
    }
    
    func onDetectionComplete(_ resultInfo: [AnyHashable : Any]) {
//        util.playAudio("detection_success.mp3")
        AAILocalizationUtil.stopMonitor()
        let state = AAILivenessUtil.localStrForKey("detection_success")
        updateStateLabel(state)
        stateImgView.stopAnimating()
        preResult = AAIDetectionResultUnknown
        
        /*
         {
            "img":xxx,
         }
         
         //Get bestImg
         UIImage *bestImg = resultInfo[@"img"];
         
         //Request anti-spoofing api
         NSData *imgData = UIImageJPEGRepresentation(bestImg, 1);
         AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
         [manager POST:@"https://example.com/anti-spoofing" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
             [formData appendPartWithFileData:imgData name:@"file" fileName:@"bestImage.jpg" mimeType:@"image/jpeg"];
         } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
             NSLog(@"%@",responseObject);
         } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {

         }];
         */
        
        if let bestImg = resultInfo["img"] as? UIImage, let imgData = bestImg.jpegData(compressionQuality: 1) {
            NSLog("%d", imgData.count)
            
            if let imgData = bestImg.pngData() {
                let detectionResult: [String: Any?] = [
                    "base64Str": imgData.base64EncodedString(options: .lineLength64Characters),
                    "bitmap": FlutterStandardTypedData(bytes: imgData)
                ]
                popResult(detectionResult: detectionResult)
            } else {
                popError(code: "CODEC_FAILURE", message: "Detection succeeded but converting to PNG failed", details: nil)
            }
            // Show result page
//             let resultVC: AAILivenessResultViewController = AAILivenessResultViewController(resultInfo)
//             navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    func onDetectionRemainingTime(_ remainingTime: TimeInterval, for detectionType: AAIDetectionType) {
        if isReady {
            timeLabel.isHidden = false
            voiceBtn.isHidden = false
            timeLabel.text = String(format: "%.f S", remainingTime)
        }
    }
    
    func livenessViewBeginRequest(_ param: AAILivenessWrapView) {
        AAIHUD.showWaitWithMsg(AAILivenessUtil.localStrForKey("auth_check") ?? "", onView: self.view)
        
        updateStateLabel(nil)
        stateImgView.stopAnimating()
    }
    
    func livenessView(_ param: AAILivenessWrapView, endRequest error: Error?) {
        AAIHUD.dismissHUDOnView(self.view, afterDelay: 0)
        
        if let error = error {
            
            popError(code: "LIVENESS_VIEW_ERROR", message: error.localizedDescription, details: nil)
//             let resultVC: AAILivenessResultViewController = AAILivenessResultViewController(false, resultState: error.localizedDescription)
//             navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    deinit {
        // If `viewDidLoad` method not called, we do nothing.
        if util != nil {
            AAILocalizationUtil.stopMonitor()
            util.removeVolumeView()
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "kAAIRestart"), object: nil)
            AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        }
    }
}
