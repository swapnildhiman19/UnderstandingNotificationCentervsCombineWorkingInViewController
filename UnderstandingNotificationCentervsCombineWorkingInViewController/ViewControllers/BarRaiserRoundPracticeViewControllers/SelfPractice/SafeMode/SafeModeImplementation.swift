//
//  SafeModeImplementation.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by EasyAiWithSwapnil on 28/12/25.
//

import Foundation
import UIKit

final class CrashLoopDetector {
    
    //MARK: CONFIGURATION
    struct Configuration {
        let crashThreshold : Int
        let timeWindowSeconds: TimeInterval
        let safeModeDurationSeconds: TimeInterval
        
        static let `default` = Configuration (
            crashThreshold: 3,
            timeWindowSeconds: 300, //5 mins
            safeModeDurationSeconds: 3600 //1 hour
        )
    }
    
    static let shared = CrashLoopDetector()
    
    private enum Keys {
        static let crashTimestamps = "crash_loop_timestamps"
        static let safeModeActivatedAt = "safe_mode_activated_at"
        static let sessionStarted = "session_started_flag"
        static let lastSuccessfullLaunch = "last_successfull_launch"
    }
    
    private let defaults : UserDefaults
    private let config : Configuration
    private(set) var isInSafeMode: Bool = false
    
    private init(
        defaults : UserDefaults = .standard,
        config: Configuration = .default
    ) {
        self.defaults = defaults
        self.config = config
    }
    
    //MARK: PUBLIC API
    //call at start of app launch
    func checkOnLaunch() -> Bool {
        if !defaults.bool(forKey: Keys.sessionStarted) {
            //First launch or it was a clean exit
        } else {
            //Previous session crash happened
            recordCrash()
        }
        
        isInSafeMode = shouldActivateSafeMode()
        
        if isInSafeMode {
            print("Swapnil SAFE MODE ACTIVATED -\(getCrashCount()) crashes")
        }
        
        return isInSafeMode
    }
    
    func markCleanShutDown() {
        defaults.set(false, forKey: Keys.sessionStarted)
    }
    
    func markBecomingActive(){
        defaults.set(true, forKey: Keys.sessionStarted)
    }
    
    private func recordCrash() {
        var timestamps = getCrashTimeStamps()
        timestamps.append(Date().timeIntervalSince1970)
        
        let cutOff = Date().timeIntervalSince1970 - config.timeWindowSeconds
        timestamps = timestamps.filter { $0 > cutOff }
        
        defaults.set(timestamps, forKey: Keys.crashTimestamps)
        print("Swapnil Crash Recorded. Total recent crashes \(timestamps.count)")
    }
    
    private func getCrashTimeStamps() -> [TimeInterval] {
        return defaults.object(forKey: Keys.crashTimestamps) as? [TimeInterval] ?? []
    }
    
    private func shouldActivateSafeMode() -> Bool {
        if let activatedAt = defaults.object(forKey: Keys.safeModeActivatedAt) as? TimeInterval {
            let elapsed = Date().timeIntervalSince1970 - activatedAt
            if elapsed < config.safeModeDurationSeconds {
                return true
            } else {
                //Safe mode expired, try normal mode
                defaults.removeObject(forKey: Keys.safeModeActivatedAt)
                clearCrashHistory()
                return false
            }
        }
        
        if getCrashCount() >= config.crashThreshold {
            defaults.set(Date().timeIntervalSince1970, forKey: Keys.safeModeActivatedAt)
            return true
        }
        
        return false
    }
    
    private func clearCrashHistory() {
        defaults.removeObject(forKey: Keys.crashTimestamps)
    }

    private func getCrashCount() -> Int {
        let cutOff = Date().timeIntervalSince1970 - config.timeWindowSeconds
        return getCrashTimeStamps().filter { $0 < cutOff }.count
    }
}

//MARK: Manages what to disable
final class SafeModeManager {
    static let shared = SafeModeManager()
    
    var isInSafeMode: Bool {
        return CrashLoopDetector.shared.isInSafeMode
    }
    
    private var disabledFeatures : Set<SafeModeFeature> = []
    
    enum SafeModeFeature: String,CaseIterable {
        case experimentalUI
        case thirdPartyAnalytics
        case serverDrivenUI
        case videoPlayback
        case animatedBanners
        case webViews
        case pushNotifications
        case backgroundSync
    }
    
    private init() {}
    
    func activateSafeMode() {
        print("Swapnil Activating Safe mode")
        
        clearCaches()
        
        disableRiskyFeatures()
        
        logSafeModeActivated()
        
        NotificationCenter.default.post(name: .safeModeActivated, object: nil)
    }
    
    func isFeatureEnabled(_ feature: SafeModeFeature) -> Bool {
        if isInSafeMode {
            return !disabledFeatures.contains(feature)
        }
        return true
    }
    
    func exitSafeMode(){
        disabledFeatures.removeAll()
        NotificationCenter.default.post(name: .safeModeDeActivated, object: nil)
    }
    
    private func clearCaches(){
        URLCache.shared.removeAllCachedResponses()
        ImageCacheManager.shared.clearAll()
        clearCorruptedData()
        print("Swapnil Clear Caches")
    }
    
    private func clearCorruptedData(){
        //Clearing API Cached Data
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let apiCacheDir = cacheDir.appendingPathComponent("APICache")
        try? FileManager.default.removeItem(at: apiCacheDir)
        
        //Do not clear Auth Token: User would log out otherwise
        UserDefaults.standard.removeObject(forKey: "cached_home_feed")
        UserDefaults.standard.removeObject(forKey: "cached_banner")
    }
    
    private func disableRiskyFeatures(){
        disabledFeatures = [
            .experimentalUI,
            .thirdPartyAnalytics,
            .videoPlayback,
            .animatedBanners,
            .serverDrivenUI //SDUI might have bad config
        ]
        
        print("Swapnil Disabled features : \(disabledFeatures.map {$0.rawValue})")
    }
    
    private func logSafeModeActivated(){
        print("Swapnil Logging safe mode activation")
        AnalyticsService.shared.log(event: "log_safe_mode_activation", params: ["activated_at": Date().timeIntervalSince1970])
    }
}

extension Notification.Name {
    static let safeModeActivated = Notification.Name("safeModeActivated")
    static let safeModeDeActivated = Notification.Name("safeModeDeActivated")
}
