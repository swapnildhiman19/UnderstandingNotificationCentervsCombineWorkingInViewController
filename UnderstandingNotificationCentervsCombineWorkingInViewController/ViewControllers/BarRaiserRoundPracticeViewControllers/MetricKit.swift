//
//  MetricKit.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 24/12/25.
//

import Foundation
import MetricKit
import UIKit

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
            print("Metric Kit already monitoring")
            return
        }
        isMonitoring = true
        MXMetricManager.shared.add(self)

        print("MetricKit monitoring started")
    }

    //applicationWillResignActive: About active to inactive (user gets the phone call) ,
    //applicationDidEnterBackground : App fully into the background,
    // applicationWillTerminate : Run only if user kills the app, but not by the iOS will get called
    func stopMonitoring() {
        MXMetricManager.shared.remove(self)
        isMonitoring = false
        print("MetricKit monitoring stopped")
    }
}

//MARK: MXMetricManagerSubscriber implementation
extension MetricKitManager : MXMetricManagerSubscriber {

}

protocol AnalyticsServiceProtocol {}
protocol CrashReporterProtocol {}

class AnalyticsService : AnalyticsServiceProtocol {
    static let shared = AnalyticsService()
}

class CrashReporter: CrashReporterProtocol {
    static let shared = CrashReporter()
}
