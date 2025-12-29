//
//  WidgetFramework.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by EasyAiWithSwapnil on 29/12/25.
//

import WidgetKit
import Foundation
import UIKit
import Combine

final class WidgetDataStore {
    
    static let shared = WidgetDataStore()
    
    private let appGroupID = "group.com.meesho.shared"
    
    private lazy var sharedDefaults : UserDefaults? = {
       return UserDefaults(suiteName: appGroupID)
    }()
    
    private lazy var sharedContainerURL : URL? = {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }()
    
    private enum Keys {
        static let cartCount = "widget_cart_count"
        static let activeOrders = "widget_active_orders"
        static let flashDeals = "widget_flash_deals"
        static let lastUpdate = "widget_last_update"
    }
    
    //MARK: Widget Cart Count
    
    var cartCount : Int {
        get { sharedDefaults?.integer(forKey: Keys.cartCount) ?? 0 }
        set {
            sharedDefaults?.set(newValue, forKey: Keys.cartCount)
            notifyWidgetToRefresh()
        }
    }
    
    //MARK: Widget Order Data
    func saveActiveOrders(_ orders: [WidgetOrder]){
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(orders) {
            sharedDefaults?.set(data, forKey: Keys.activeOrders)
            notifyWidgetToRefresh()
        }
    }
    
    func getActiveOrders() -> [WidgetOrder] {
        guard let data = sharedDefaults?.data(forKey: Keys.activeOrders),
              let orders = try? JSONDecoder().decode([WidgetOrder].self, from: data) else {
            return []
        }
        return orders
    }
    
    //MARK: Widget Flash Deals Data
    
    func saveFlashDeals(_ deals : [WidgetDeal]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(deals) {
            sharedDefaults?.set(data, forKey: Keys.flashDeals)
            notifyWidgetToRefresh()
        }
    }
    
    func getFlashDeals() -> [WidgetDeal] {
        guard let data = sharedDefaults?.data(forKey: Keys.flashDeals),
              let deals = try? JSONDecoder().decode([WidgetDeal].self, from: data) else {
            return []
        }
        return deals
    }
    
    private func notifyWidgetToRefresh(){
        
    }
    
    func syncFromMainApp(){
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdate)
    }
}

struct WidgetOrder: Codable {
    let orderId: String
    let productName : String
    let status : String
    let imageUrl : String
    let estimatedDelivery: Date?
}

struct WidgetDeal : Codable {
    let dealId: String
    let title : String
    let discount: Int
    let imageUrl : String
    let expiresAt: Date
}

//MARK: Widget TimeLine
protocol WidgetDataProvider {
    associatedtype EntryType : TimelineEntry
    
    //Function to fetch current data for widget
    func fetchCurrentEntry() async -> EntryType
    
    //Calculate next refresh time
    func nextRefreshDate() -> Date
}


