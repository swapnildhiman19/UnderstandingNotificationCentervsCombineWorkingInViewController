//
//  MetricKit.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 24/12/25.
//

import Foundation
import MetricKit
import UIKit

//NSObject allows Swift class to interact smoothly with Objective-C frameworks
final class MetricKitManager : NSObject {
    static let shared = MetricKitManager()

    private let analyticsService: AnalyticsServiceProtocol
    private let crashReporter: CrashReporterProtocol

    private(set) var isMonitoring = false

    private override init() {
        self.analyticsService = AnalyticsService.shared
        self.crashReporter = CrashReporter.shared
        super.init()
    }

    //Need to call this early in app development cycle: didFinishLaunchingWithOption in AppDelegate
    func startMonitoring() {
        guard !isMonitoring else {
            print("Swapnil Metric Kit already monitoring")
            return
        }
        isMonitoring = true
        MXMetricManager.shared.add(self)
        print("Swapnil MetricKit monitoring started")
    }

    //applicationWillResignActive: About active to inactive (user gets the phone call) ,
    //applicationDidEnterBackground : App fully into the background,
    // applicationWillTerminate : Run only if user kills the app, but not by the iOS will get called
    func stopMonitoring() {
        MXMetricManager.shared.remove(self)
        isMonitoring = false
        print("Swapnil MetricKit monitoring stopped")
    }
}

//MARK: MXMetricManagerSubscriber implementation
extension MetricKitManager : MXMetricManagerSubscriber {
    //Performance Metrics (Called 24 hrs)
    //Called by iOS when aggregated performance metrics are available, these are histograms and not single data
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            processMetricPayload(payload)
        }
    }
    
    //Called when crash or hang diagnostics are available
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            processDiagnosticPayload(payload)
        }
    }
    
    private func processMetricPayload(_ payload: MXMetricPayload) {
        
        // cold start P50, P95 percentiles
        if let launchMetrics = payload.applicationLaunchMetrics {
            processLaunchMetrics(launchMetrics)
        }
        
        // peak memory usage
        if let memoryMetrics = payload.memoryMetrics {
            processMemoryMetrics(memoryMetrics)
        }
        
        //scroll jank
        if let responsivenessMetrics = payload.applicationResponsivenessMetrics {
            processResponsivenessMetrics(responsivenessMetrics)
        }
        
        sendFullPayloadToBackend(payload)
    }
    
    /// Process app launch metrics - INTERVIEW FOCUS AREA
    private func processLaunchMetrics(_ metrics: MXAppLaunchMetric) {

        // histogrammedTimeToFirstDraw: Time from launch to first frame rendered
        let coldLaunchHistogram = metrics.histogrammedTimeToFirstDraw
        
        // Extract percentiles for cold launch
        // P50 = median (50% of launches faster than this)
        // P95 = 95th percentile (only 5% of launches slower)
        // P99 = 99th percentile (worst case performance)
        
        let coldLaunchP50 = coldLaunchHistogram.bucketEnumerator
            // Note: In real code, you'd calculate percentiles from buckets
        
        // Log the average (simple approach)
        let averageColdLaunch = coldLaunchHistogram.averageMeasurement
        let coldLaunchMs = averageColdLaunch.converted(to: .milliseconds).value
        
        analyticsService.log(
            event: "metric_cold_launch",
            params: [
                "average_ms": coldLaunchMs,
                "sample_count": coldLaunchHistogram.totalBucketCount
            ]
        )
        
        print("Swapnil 🚀 Cold Launch Average: \(coldLaunchMs)ms")
        
        // - Good: < 400ms
        // - Acceptable: 400-1000ms
        // - Bad: > 1000ms
        if coldLaunchMs > 1000 {
            analyticsService.log(event: "cold_launch_slow", params: ["ms": coldLaunchMs])
        }
    }
    
    private func processMemoryMetrics(_ metrics: MXMemoryMetric) {
        //peak memory usage : The highest memory our app used during the reporting period
        //Average Suspended Memory : Keep it as low as possible, so that app doesn't get killed by OS
        let peakMemory = metrics.peakMemoryUsage
        let peakMemoryMB = peakMemory.converted(to: .megabytes).value
        analyticsService.log(event: "metric_peak_memory", params: ["mb": peakMemoryMB])
        
        print("Swapnil Peak Memory: \(peakMemoryMB)MB")
        
        if peakMemoryMB > 1000 {
            analyticsService.log(event: "high_memory_usage", params: ["mb":peakMemoryMB])
        }
    }
    
    private func processResponsivenessMetrics(_ metrics : MXAppResponsivenessMetric) {
        /*
         1 second = 1000 milliseconds (ms).
         Formula: \(1000\text{\ ms}/\text{FPS}=\text{ms\ per\ frame}\).
         For 60 FPS: \(1000\text{\ ms}/60=16.666...\text{\ ms}\) (which rounds to 16.67ms).
         */
        let hitchTimeRatio = metrics.histogrammedApplicationHangTime.averageMeasurement.converted(to: .milliseconds)
        let averageHitchMs = hitchTimeRatio.value
        analyticsService.log(
            event: "metric_hitch_ratio",
            params: ["average_ms": averageHitchMs]
        )
    }
    
    private func processDiagnosticPayload(_ payload: MXDiagnosticPayload) {
        if let crashes = payload.crashDiagnostics {
            for crash in crashes {
                processCrashDiagnostic(crash)
            }
        }
        
        if let hangs = payload.hangDiagnostics {
            for hang in hangs {
                processHangDiagnostic(hang)
            }
        }
        
        if let cpuExceptions = payload.cpuExceptionDiagnostics {
            for exception in cpuExceptions {
                processCPUException(exception)
            }
        }
    }
    
    private func processCrashDiagnostic(_ crash: MXCrashDiagnostic) {
        let crashInfo : [String:Any] = [
            "exception_type" : crash.exceptionType?.intValue ?? -1,
            "signal": crash.signal?.intValue ?? -1,
            "exception_code": crash.exceptionCode?.intValue ?? -1,
            "termination_code": crash.terminationReason ?? "unknow"
        ]
        
        let callStack = crash.callStackTree.jsonRepresentation()
        
        crashReporter.report(
            .crash,
            info: crashInfo,
            callStack: callStack
        )
        
        print("Swapnil Crash Detected: \(crashInfo)")
    }
    
    private func processHangDiagnostic(_ hang: MXHangDiagnostic) {
        //main thread being heavy
        let hangDuration = hang.hangDuration.converted(to: .seconds).value
        
        crashReporter.report(
            .hang,
            info: ["duration_seconds": hang],
            callStack: hang.callStackTree.jsonRepresentation()
        )
        
        print("Swapnil Hang Detected: \(hangDuration)")
    }
    
    private func processCPUException(_ exception: MXCPUExceptionDiagnostic) {
        let cpuTime = exception.totalCPUTime.converted(to: .seconds).value
        let sampledTime = exception.totalSampledTime.converted(to: .seconds).value //periodic snapshot of CPU time being used when the app was active
        crashReporter.report(
            .cpuException,
            info: [
                "cpu_time_seconds": cpuTime,
                "sampled_time_seconds": sampledTime
            ],
            callStack: exception.callStackTree.jsonRepresentation()
        )
        
        print("Swapnil CPU Exception detected : \(cpuTime) cpuTime seconds, \(sampledTime) sampled time seconds")
    }
    
    private func sendFullPayloadToBackend(_ payload: MXMetricPayload) {
        let jsonData = payload.jsonRepresentation()
        analyticsService.sendRawMetrics(jsonData)
    }
}

//MARK: Protocols
protocol AnalyticsServiceProtocol {
    func log(event: String, params:[String:Any])
    func sendRawMetrics(_ data: Data)
}

protocol CrashReporterProtocol {
    func report(_ type : CrashType, info: [String:Any], callStack: Data?)
    //callStack : List of the function calls that lead upto the crash
}

enum CrashType {
    case hang
    case crash
    case cpuException
    case oom
}

//MARK: Helper Analytics and CrashReported class
class AnalyticsService : AnalyticsServiceProtocol {
    
    func sendRawMetrics(_ data: Data) {
        // POST to your metrics backend
        print("Swapnil sending complete \(data.count) byets of metrics to backend")
    }
    
    func log(event: String, params: [String : Any]) {
        // In production: Send to Firebase
        print("Swapnil Analytics: \(event) - \(params)")
    }
    
    static let shared = AnalyticsService()
}

class CrashReporter: CrashReporterProtocol {
    func report(_ type: CrashType, info: [String : Any], callStack: Data?) {
        print("Swapnil Crash Report [\(type)] : \(info)")
        print("Swapnil callStack data for Crash : \(String(describing: callStack?.debugDescription))")
    }
    
    static let shared = CrashReporter()
}


//MARK: Extension for finding Average for cold launch, not a good paramter
extension MXHistogram where UnitType == UnitDuration {
    var averageMeasurement: Measurement<UnitDuration> {
        var totalDuration = 0.0
        var totalCount = 0
        
        // Iterate through all buckets in the histogram
        for bucket in self.bucketEnumerator {
            if let bucket = bucket as? MXHistogramBucket<UnitDuration> {
                let count = Double(bucket.bucketCount)
                
                // Calculate the midpoint of the bucket (Start + End) / 2
                let start = bucket.bucketStart.converted(to: .milliseconds).value
                let end = bucket.bucketEnd.converted(to: .milliseconds).value
                let midPoint = (start + end) / 2.0
                
                // Add weighted duration to total
                totalDuration += midPoint * count
                totalCount += bucket.bucketCount
            }
        }
        
        // Avoid division by zero
        let average = totalCount > 0 ? totalDuration / Double(totalCount) : 0.0
        
        return Measurement(value: average, unit: .milliseconds)
    }
}
