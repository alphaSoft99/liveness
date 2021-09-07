//
//  AAILivenessUtil.swift
//  guardian_liveness
//

import Foundation
import AVFoundation
import MediaPlayer
import AAILivenessSDK

class AAILivenessUtil {
    
    private var volume: Float = 0.5
    private var audioPlayer: AVAudioPlayer?
    private var brightnessQueue: OperationQueue = OperationQueue()
    private var currBrightness: CGFloat?
    private var volumeView: MPVolumeView?
 
    init() {
        brightnessQueue.maxConcurrentOperationCount = 1
    }
    
    static func isSilent() -> Bool {
        return AVAudioSession.sharedInstance().outputVolume == 0
    }
    
    private func createVolumeView() -> MPVolumeView {
        if let volumeView = volumeView {
            return volumeView
        } else {
            let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 5, height: 5))
            UIApplication.shared.delegate?.window??.addSubview(volumeView)
            self.volumeView = volumeView
            return volumeView
        }
    }

    private func volumeSlider() -> UISlider? {
        var slider: UISlider?
        let volumeView = createVolumeView()
        volumeView.showsVolumeSlider = true
        for view: UIView in volumeView.subviews {
            if String(describing: type(of: view)) == "MPVolumeSlider" {
                slider = view as? UISlider
                break
            }
        }
        return slider
    }

    private func configSystemVolume(_ volume: Float) {
        if let slider = volumeSlider() {
            slider.setValue(volume, animated: false)
            slider.sendActions(for: .touchUpInside)
            volumeView?.sizeToFit()
        }
    }

    func configPlayerVolume(_ volume: Float) {
        self.volume = volume
        audioPlayer?.volume = volume
    }

    func configVolume(_ volume: Float) {
        self.volume = volume
        configSystemVolume(volume)
    }

    func removeVolumeView() {
        volumeView?.removeFromSuperview()
        volumeView = nil
    }

    func setVolume(_ volume: Float) {
        self.volume = volume
        audioPlayer?.volume = volume
    }

    static private func currLanguageKey() -> String {
        let array: [String] = NSLocale.preferredLanguages
        if array.count >= 1 {
            var lanKey: String = array[0]
            let components: [String] = lanKey.components(separatedBy: "-")
            if components.count == 2 {
                lanKey = components[0]
            } else if components.count == 3 {
                if lanKey.hasPrefix("zh-Hans") == true {
                    lanKey = "zh-Hans"
                }
            }

            return lanKey
        }

        return "en"
    }

    static private func currLanForBundle(_ bundle: Bundle) -> String {
        let availableLprojItems = "en id vi zh-Hans"
        let currLproj = currLanguageKey()
        if availableLprojItems.contains(currLproj) {
            return currLproj
        } else {
            return "en"
        }
    }

    func playAudio(_ audioName: NSString?) {
        guard let audioName = audioName else { return }

        let bundle: Bundle = Bundle(for: type(of: self))
        let lan = AAILivenessUtil.currLanForBundle(bundle)

//        let pathComponent: String = String(format: "/AAIAudio.bundle/%@.lproj/%@", lan, audioName)
        let pathComponent: String = String(format: "/%@.lproj/%@", lan, audioName)
        let path: String = (bundle.bundlePath as NSString).appendingPathComponent(pathComponent)
        let url: URL? = URL(string: path)

        audioPlayer?.stop()

        if let url = url {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = volume
                audioPlayer?.play()
            } catch {
                print(error)
            }
        }
    }
    
    static func localStrForKey(_ key: String) -> String? {
        let bundle: Bundle = Bundle(for: Self.self)
        let lan = currLanForBundle(bundle)
//        let pathComponent: String = String(format: "/AAILanguageString.bundle/%@.lproj", lan)
        let pathComponent: String = String(format: "/%@.lproj", lan)
        let lprojPath = (bundle.bundlePath as NSString).appendingPathComponent(pathComponent)
        let str = Bundle(path: lprojPath)?.localizedString(forKey: key, value: nil, table: nil)
        return str
    }

    static func imgWithName(_ imgName: String) -> UIImage? {
        let bundle: Bundle = Bundle(for: Self.self)
//        let imgPath: String = bundle.bundlePath.appendingFormat("/AAIImgs.bundle/%@", imgName)
        let imgPath: String = bundle.bundlePath.appendingFormat("/%@", imgName)
        let img: UIImage? = UIImage(contentsOfFile: imgPath)
        return img
    }

    static func stateImgWithType(_ detectionType: AAIDetectionType) -> [UIImage]? {
        let bundle: Bundle = Bundle(for: Self.self)
        let bundlePath: String = bundle.bundlePath
        
        switch (detectionType) {
            case AAIDetectionTypeBlink:
                var array: [UIImage] = []
                for i in 1...4 {
                    let imgPath: String = bundlePath.appendingFormat("AAIImgs.bundle/blink_%d@2x.jpg", i)
                    if let img = UIImage(contentsOfFile: imgPath) {
                        array.append(img)
                    }
                }
                return array
            case AAIDetectionTypeMouth:
                var array: [UIImage] = []
                for i in 1...4 {
                    let imgPath: String = bundlePath.appendingFormat("AAIImgs.bundle/open_mouth_%d@2x.jpg", i)
                    if let img = UIImage(contentsOfFile: imgPath) {
                        array.append(img)
                    }
                }
                return array
            case AAIDetectionTypePosYaw:
                var array: [UIImage] = []
                for i in 1...4 {
                    let imgPath: String = bundlePath.appendingFormat("AAIImgs.bundle/turn_head_%d@2x.jpg", i)
                    if let img = UIImage(contentsOfFile: imgPath) {
                        array.append(img)
                    }
                }
                return array
            default:
                return nil
        }
    }
    
    // MARK: - brightless

    func saveCurrBrightness() {
        currBrightness = UIScreen.main.brightness
    }

    func graduallySetBrightness(_ value: CGFloat) {
        brightnessQueue.cancelAllOperations()
        
        let ratio: CGFloat = 0.01
        let brightness: CGFloat = UIScreen.main.brightness
        let step: CGFloat = ratio * ((value > brightness) ? 1 : -1)
        let times: Int = Int(abs((value - brightness) / ratio))
        
        if times < 1 { return }
        for i in 1..<times {
            brightnessQueue.addOperation {
                Thread.sleep(forTimeInterval: 1 / 180)
                DispatchQueue.main.async {
                    UIScreen.main.brightness = brightness + CGFloat(integerLiteral: i) * step
                }
            }
        }
    }

    func graduallyResumeBrightness() {
        if let currBrightness = currBrightness{
            graduallySetBrightness(currBrightness)
        }
    }

    func fastResumeBrightness() {
        brightnessQueue.cancelAllOperations()
        weak var weakSelf: AAILivenessUtil? = self
        brightnessQueue.addOperation {
            if let weakSelf = weakSelf, let currBrightness = weakSelf.currBrightness {
                UIScreen.main.brightness = currBrightness
            }
        }
    }
}
