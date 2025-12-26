//
//  OOMKit.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by EasyAiWithSwapnil on 25/12/25.
//

import Foundation
import UIKit

//OOM : Out of Memory -> iOS kills the app due to excessive memory usage
//MetricKit doesn't report that OOM has happened, OS silently kills the app, we have to infer it our own

/*
 App Termination Good Reasons:
 1. User force quit
 2. System upgrade
 3. App update
 4. Normal app termination
 5. Crash (use MXDiagnosticPayload)
 6. Way too long in the background : WatchDog Kill
 */

//High memory + no clean exit + no update + foreground : Likely OOM

final class OOMDetector {
    
    static let shared = OOMDetector()
    
    private enum Keys {
        static let didTerminateCleanly = "oom_detector_did_terminate_cleanly"
        static let lastKnownMemoryMB = "oom_detector_last_memory_mb"
        static let lastAppVersion = "oom_detector_last_app_version"
        static let wasInBackground = "oom_detector_was_in_background"
        static let lastSessionStartTime = "oom_detector_session_start"
    }
    
    //Memory Crash above which we detect OOM
    private let highMemoryThresholdMB : Double = 500
    
    //How often we need to do memory sampling rate(seconds)
    private let memorySamplingInterval : TimeInterval = 30
    
    private let defaults: UserDefaults
    private let analyticsService: AnalyticsServiceProtocol
    
    private var memorySamplingTimer : Timer?
    private var currentSessionStartTime: Date?
    
    private init(){
        self.defaults = UserDefaults.standard
        self.analyticsService = AnalyticsService.shared
    }
    
    init(defaults: UserDefaults, analyticsService: AnalyticsServiceProtocol) {
        self.defaults = defaults
        self.analyticsService = analyticsService
    }
    
    //Public API
    //AppDelegate: applicationDidFinishLaunchingWithOptions
    func applicationDidLaunch(){
        //1.checking previous session
        checkForPreviousOOM()
        
        //2.Starting monitoring
        markSessionStarted()
        
        //3. Start memory sampling
        startMemorySampling()
    }
    
    //AppDelegate: app enters background
    func applicationDidEnterBackground(){
        defaults.set(true, forKey: Keys.wasInBackground)
        //Taking final memory reading
        recordCurrentMemory()
    }
    
    //AppDelegate : app enters foreground
    func applicationDidEnterForeground() {
        defaults.set(false, forKey: Keys.wasInBackground)
    }
    
    func applicationWillTerminate() {
        markClearTermination()
    }
    
    //MARK: Detection Logic
    private func checkForPreviousOOM(){
        let didTerminateCleanly = defaults.bool(forKey: Keys.didTerminateCleanly)
        
        if didTerminateCleanly {
            print("Swapnil previous session ended cleanly")
            return
        }
        
        print("Swapnil session did not ended cleanly - investigating")
        
        let evidence = gatherOOMEvidence()
        
        if evidence.isLikelyOOM {
            reportPotentialOOM(evidence: evidence)
        } else {
            reportUnclearTermination(evidence: evidence)
        }
    }
    
    private func markSessionStarted(){
        defaults.set(false, forKey: Keys.didTerminateCleanly)
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        defaults.set(currentVersion,forKey: Keys.lastAppVersion)
        
        currentSessionStartTime = Date()
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastSessionStartTime)
        
        defaults.set(false, forKey: Keys.wasInBackground)
    }
    
    private func markClearTermination(){
        defaults.set(true, forKey: Keys.didTerminateCleanly)
        stopMemorySampling()
    }
    
    private func startMemorySampling(){
        recordCurrentMemory()
        
        memorySamplingTimer = Timer.scheduledTimer(
            withTimeInterval: memorySamplingInterval,
            repeats: true, block: { [weak self] _ in
            self?.recordCurrentMemory()
        })
    }
    
    private func stopMemorySampling() {
        memorySamplingTimer?.invalidate()
        memorySamplingTimer = nil
    }
    
    private func recordCurrentMemory(){
        let memoryMB = getCurrentMemoryUsage()
        defaults.set(memoryMB, forKey: Keys.lastKnownMemoryMB)
        
        if memoryMB > highMemoryThresholdMB {
            print("Swapnil High memory usage detected: \(memoryMB)MB")
            analyticsService.log(event: "high_memory_warning", params: [
                "memory_mb": memoryMB
            ])
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size
        )
        
        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    intPtr,
                    &count
                )
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        // Convert bytes to megabytes
        return Double(info.resident_size) / 1024.0 / 1024.0
    }
    
    private func gatherOOMEvidence() -> OOMEvidence {
        let lastMemoryMB = defaults.double(forKey: Keys.lastKnownMemoryMB)
        let lastAppVersion = defaults.string(forKey: Keys.lastAppVersion)
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let wasInBackGround = defaults.bool(forKey: Keys.wasInBackground)
        let sessionStartTime = defaults.double(forKey: Keys.lastSessionStartTime)
        
        return OOMEvidence(lastMemoryDB: lastMemoryMB, wasMemoryHigh: lastMemoryMB > highMemoryThresholdMB, wasAppUpdated: lastAppVersion != currentAppVersion, wasInBackground: wasInBackGround, sessionDurationSeconds: sessionStartTime > 0 ? Date().timeIntervalSince1970 - sessionStartTime : 0)
    }
    
    private func reportPotentialOOM(evidence: OOMEvidence){
        print("Swapnil Potential OOM Detected")
        print("Swapnil last memory : \(evidence.lastMemoryDB)MB")
        print("Swapnil was in background: \(evidence.wasInBackground)")
        
        analyticsService.log(event: "potential_oom", params: [
            "last_memory_db": evidence.lastMemoryDB,
            "was_in_background":evidence.wasInBackground,
            "session_duration_in_seconds": evidence.sessionDurationSeconds
        ])
        
        //Also sending this to crash reporting service
        CrashReporter.shared.report(
            .oom,
            info: [
                "last_memory_db": evidence.lastMemoryDB,
                "was_in_background":evidence.wasInBackground
            ],
            callStack: nil
        ) //OOM doesn't have call stack
        
    }
    
    private func reportUnclearTermination(evidence: OOMEvidence){
        analyticsService.log(event: "unclear_termination", params: [
            "last_memory_db": evidence.lastMemoryDB,
            "was_in_background":evidence.wasInBackground,
            "was_app_updated":evidence.wasAppUpdated
        ])
    }
}

//MARK: Strcut OOM Evidence
struct OOMEvidence {
    let lastMemoryDB: Double
    let wasMemoryHigh: Bool
    let wasAppUpdated: Bool
    let wasInBackground: Bool
    let sessionDurationSeconds: TimeInterval
    
    var isLikelyOOM: Bool {
        if wasMemoryHigh && !wasInBackground {
            return true
        }
        
        if wasMemoryHigh && !wasAppUpdated {
            return true
        }
        
        if sessionDurationSeconds < 5 {
            return false
        }
        
        return wasMemoryHigh
    }
}

extension OOMDetector {
    var currentMemoryMB: Double {
        self.getCurrentMemoryUsagePublic()
    }
    
    private func getCurrentMemoryUsagePublic() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size
        )
        
        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1024.0 / 1024.0
    }
}

final class OOMPreventionManager {
    
    static let shared = OOMPreventionManager()
    
    private let warningThreshold : Double = 400
    private let criticalThreshold: Double = 600
    private let emergencyThreshold: Double = 800
    
    func evaluateMemoryPressure(){
        let currentMemory = OOMDetector.shared.currentMemoryMB
        
        switch currentMemory {
        case ..<warningThreshold :
            break
        case warningThreshold..<criticalThreshold:
            handleWarningLevel()
        case criticalThreshold..<emergencyThreshold:
            handleCriticalLevel()
        default:
            handleEmergencyLevel()
        }
    }
    
    private func handleWarningLevel() {
        print("Swapnil Memory Warning Level - Clearing the optional caches")
        
        URLCache.shared.removeAllCachedResponses()
        
        NotificationCenter.default.post(name: .memoryWarningLevel, object: nil)
    }
    private func handleCriticalLevel() {
        print("Swapnil Memory Critical Level - Clearing the image caches, preload cachces - Agressive Cleanup")
        
        //ImageCache.removeAll()
        //PreloadManager.shared.releaseAll()
        
        NotificationCenter.default.post(
            name: .memoryCriticalLevel,
            object: nil
        )
    }
    
    private func handleEmergencyLevel() {
        print("Swapnil Memory Emergency Level reached - Survival mode")
        handleCriticalLevel()
        //Disable Feature flag, show user the message warning
        showWarningToUser()
        NotificationCenter.default.post(
            name: .memoryEmergencyLevel,
            object: nil
        )
    }
    
    private func showWarningToUser() {
        print("Swapnil Hey User Memory Full App could get close any moment")
    }
}

extension Notification.Name {
    static let memoryWarningLevel = Notification.Name("OOM_MemoryWarningLevel")
    static let memoryCriticalLevel = Notification.Name("OOM_MemoryCriticalLevel")
    static let memoryEmergencyLevel = Notification.Name("OOM_MemoryEmergencyLevel")
}
