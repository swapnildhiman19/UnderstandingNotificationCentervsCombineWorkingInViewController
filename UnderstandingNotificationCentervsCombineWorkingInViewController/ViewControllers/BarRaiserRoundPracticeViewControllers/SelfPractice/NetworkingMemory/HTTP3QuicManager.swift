//
//  HTTP3QuicManager.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by EasyAiWithSwapnil on 27/12/25.
//

import Foundation
import UIKit

final class HTTP3NetworkManager {
    
    static let shared = HTTP3NetworkManager()
    
    private let session : URLSession
    
    private init(){
        let configuration = URLSessionConfiguration()
        
        configuration.httpMaximumConnectionsPerHost = 10
        /*
        if #available(iOS 15.0, *) {
            configuration.assumesHTTP3Capable = true
        }
        */
        //iOS 15+ URLSession automatically supports HTTP/3 when server supports it ( via Alt-Svc header )
        /*
         let url = URL(string: "https://yourserver.com")!
         let (data, response) = try await URLSession.shared.data(from: url)

         if let httpResponse = response as? HTTPURLResponse {
             // Access the Alt-Svc header specifically
             if let altSvc = httpResponse.value(forHTTPHeaderField: "Alt-Svc") {
                 print("Server Alt-Svc header: \(altSvc)")
             }
         }
         */
        
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        configuration.urlCache = URLCache(memoryCapacity: 50*1024*1024, diskCapacity: 100*1024*1024, diskPath: "http3_cache")
        
        self.session = URLSession(configuration: configuration)
    }
    
    func fetchData(url : URL, completion : @escaping (Result<(Data,HTTPProtocolInfo),Error>) -> Void) {
        var request = URLRequest(url: url)
        request.assumesHTTP3Capable = true
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            let protocolInfo = self.extractProtocolInfo(from: httpResponse)
            
            completion(.success((data,protocolInfo)))
        }.resume()
    }
    
    func fetchMultiple(
        urls:[URL],
        completion: @escaping ([URL:Result<Data,Error>]) -> Void
    ) {
        var results = [URL:Result<Data,Error>]()
        let group = DispatchGroup()
        let lock = NSLock()
        
        for url in urls {
            group.enter()
            
            fetchData(url: url) { result in
                lock.lock()
                switch result {
                case .success(let (data, _)):
                    results[url] = .success(data)
                case .failure(let error):
                    results[url] = .failure(error)
                }
                lock.unlock()
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    private func extractProtocolInfo(from response: HTTPURLResponse) -> HTTPProtocolInfo {
        let altSvc = response.allHeaderFields["Alt-Svc"] as? String
        
        var protocolVersion = "HTTP/1.1"
        
        if let altSvc = altSvc, altSvc.contains("h3") {
            protocolVersion = "HTTP/3"
        } else if let altSvc = altSvc, altSvc.contains("h2"){
            protocolVersion = "HTTP/2"
        }
        
        return HTTPProtocolInfo(
            version: protocolVersion,
            statusCode: response.statusCode,
            headers: response.allHeaderFields as? [String:String] ?? [:]
        )
    }
}

struct HTTPProtocolInfo {
    let version : String
    let statusCode : Int
    let headers: [String: String]
}

enum NetworkError : Error {
    case invalidResponse
    case invalidURL
    case noData
}

final class HTTP3ImageLoader {
    static let shared = HTTP3ImageLoader()
    
    private let networkManager = HTTP3NetworkManager.shared
    private let cache = NSCache<NSURL, NSData>()
    
    private init(){
        cache.countLimit  = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func loadImages(
        urls: [URL],
        progress: ((Int,Int) -> Void)? = nil,
        completion: @escaping ([URL:Data]) -> Void
    ) {
        var loadedContent = 0
        var totalCount = urls.count
        var results = [URL:Data]()
        let lock = NSLock()
        let group = DispatchGroup()
        
        for url in urls {
            //check the cached data first
            if let cachedData = cache.object(forKey: url as NSURL) {
                //load it directly
                lock.lock()
                results[url] = cachedData as Data
                loadedContent += 1
                progress?(loadedContent, totalCount)
                lock.unlock()
                continue
            }
            
            group.enter()
            
            networkManager.fetchData(url: url) { [weak self] result in
                defer { group.leave() }
                lock.lock()
                defer { lock.unlock() }
                
                switch result {
                case .success(let (data,protocolInfo)):
                    results[url] = data
                    self?.cache.setObject(data as NSData, forKey: url as NSURL)
                    print("Swapnil Loaded \(url.lastPathComponent) via \(protocolInfo.version)")
                case .failure(let error):
                    print("Swapnil Failed loading image url \(url.absoluteString)")
                }
                
                loadedContent += 1
                progress?(loadedContent,totalCount)
            }
            
            group.notify(queue: .main) {
                completion(results)
            }
        }
    }
}
