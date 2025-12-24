/*
// ============================================================================
// MEESHO INTERVIEW PREP: HTTP/3 and QUIC Complete Guide
// ============================================================================
// Day 3-4: Networking and Memory Optimization
//
// The interviewer achieved ~40% faster page & image load times by adopting
// HTTP/3 (QUIC). This is a crucial topic for understanding network optimization.
// ============================================================================

import Foundation

// ============================================================================
// SECTION 1: WHAT IS HTTP/3 AND QUIC? (Layman's Explanation)
// ============================================================================
/*
 🎯 SIMPLE ANALOGY:
 
 Think of loading a webpage like ordering multiple items at a restaurant:
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                           HTTP/1.1 (Old Restaurant)                         │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │                                                                             │
 │  You: "I'd like a burger"                                                   │
 │  Waiter: "Let me get that" → Goes to kitchen → Returns with burger          │
 │  You: "Now I'd like fries"                                                  │
 │  Waiter: "Let me get that" → Goes to kitchen → Returns with fries           │
 │  You: "Now I'd like a drink"                                                │
 │  Waiter: "Let me get that" → Goes to kitchen → Returns with drink           │
 │                                                                             │
 │  PROBLEM: One item at a time! Very slow with many items.                    │
 │  This is "Head-of-Line Blocking"                                            │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                        HTTP/2 (Better Restaurant)                           │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │                                                                             │
 │  You: "I'd like a burger, fries, and a drink"                               │
 │  Waiter: "Got it!" → Goes to kitchen                                        │
 │                                                                             │
 │  Kitchen prepares all three in parallel, but...                             │
 │                                                                             │
 │  Waiter carries everything on ONE TRAY (TCP)                                │
 │  If the burger falls on the way back...                                     │
 │  Waiter STOPS, goes back, gets burger, and starts over                      │
 │                                                                             │
 │  PROBLEM: All items delayed because of one problem!                         │
 │  (TCP Head-of-Line Blocking at transport layer)                             │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                       HTTP/3 + QUIC (Smart Restaurant)                      │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │                                                                             │
 │  You: "I'd like a burger, fries, and a drink"                               │
 │  THREE different waiters go to kitchen simultaneously!                      │
 │                                                                             │
 │  Waiter 1: Brings burger ✓                                                  │
 │  Waiter 2: Drops fries, goes back to get more (doesn't affect others)       │
 │  Waiter 3: Brings drink ✓                                                   │
 │  Waiter 2: Finally brings fries ✓                                           │
 │                                                                             │
 │  BENEFIT: Each item independent! One failure doesn't block others.          │
 │  (QUIC uses independent streams over UDP)                                   │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 
 WHY 40% FASTER FOR MEESHO?
 
 E-commerce pages have LOTS of resources:
 - 20+ product images
 - CSS/JS files
 - API calls for data
 - Analytics beacons
 
 With HTTP/3:
 - All resources load in parallel TRULY independently
 - One slow/dropped image doesn't block others
 - Connection setup is faster (0-RTT)
 - Works better on poor mobile networks
*/

// ============================================================================
// SECTION 2: TECHNICAL DEEP DIVE - QUIC vs TCP
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         Protocol Stack Comparison                           │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │                                                                             │
 │  HTTP/2 Stack:                    HTTP/3 Stack:                             │
 │                                                                             │
 │  ┌─────────────┐                  ┌─────────────┐                           │
 │  │   HTTP/2    │                  │   HTTP/3    │                           │
 │  ├─────────────┤                  ├─────────────┤                           │
 │  │    TLS      │                  │    QUIC     │ ← Combines TLS + Transport│
 │  ├─────────────┤                  ├─────────────┤                           │
 │  │    TCP      │                  │    UDP      │                           │
 │  ├─────────────┤                  ├─────────────┤                           │
 │  │    IP       │                  │    IP       │                           │
 │  └─────────────┘                  └─────────────┘                           │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 KEY QUIC ADVANTAGES:
 
 1. 0-RTT CONNECTION RESUMPTION:
    ┌────────────────────────────────────────────────────────────────────────┐
    │                                                                        │
    │  TCP + TLS (New Connection):         QUIC (Resumed Connection):        │
    │                                                                        │
    │  Client         Server               Client         Server             │
    │    │               │                   │               │               │
    │    │───SYN────────▶│                   │───Data + Auth─▶│  0-RTT!     │
    │    │◀──SYN+ACK─────│                   │◀──Response─────│              │
    │    │───ACK────────▶│                   │               │               │
    │    │               │                   │               │               │
    │    │───TLS Hello──▶│                   No extra round trips!           │
    │    │◀──TLS Hello───│                                                   │
    │    │───TLS Finish─▶│                                                   │
    │    │◀──TLS Finish──│                                                   │
    │    │               │                                                   │
    │    │───HTTP Req───▶│   Finally!                                        │
    │    │               │                                                   │
    │    3 round trips!                                                      │
    │                                                                        │
    └────────────────────────────────────────────────────────────────────────┘
 
 2. NO HEAD-OF-LINE BLOCKING:
    ┌────────────────────────────────────────────────────────────────────────┐
    │                                                                        │
    │  TCP (HTTP/2):                       QUIC (HTTP/3):                    │
    │                                                                        │
    │  Stream 1: ████░░░░ (waiting)        Stream 1: ████████ ✓             │
    │  Stream 2: ████░░░░ (waiting)        Stream 2: ████░░░░ (retransmit)   │
    │  Stream 3: ████░░░░ (waiting)        Stream 3: ████████ ✓             │
    │            ↑                                                           │
    │         Packet lost on Stream 2                                        │
    │         blocks ALL streams!          Only Stream 2 waits!              │
    │                                                                        │
    └────────────────────────────────────────────────────────────────────────┘
 
 3. CONNECTION MIGRATION:
    ┌────────────────────────────────────────────────────────────────────────┐
    │                                                                        │
    │  Scenario: User walks from WiFi to Cellular                            │
    │                                                                        │
    │  TCP: Connection breaks! Must reconnect + re-authenticate              │
    │       All in-flight requests lost                                      │
    │                                                                        │
    │  QUIC: Connection ID stays same!                                       │
    │        Seamlessly continues on new network                             │
    │        No data loss, no reconnection                                   │
    │                                                                        │
    │  This is HUGE for mobile e-commerce (users on the go)                  │
    │                                                                        │
    └────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 3: ENABLING HTTP/3 IN iOS
// ============================================================================

/// Network manager optimized for HTTP/3.
/// iOS 15+ automatically negotiates HTTP/3 when server supports it.
final class HTTP3NetworkManager {
    
    // MARK: - Singleton
    static let shared = HTTP3NetworkManager()
    
    // MARK: - Properties
    private let session: URLSession
    
    // MARK: - Initialization
    
    private init() {
        let configuration = URLSessionConfiguration.default
        
        // iOS 15+: URLSession automatically uses HTTP/3 if available
        // No special configuration needed!
        
        // However, we can optimize for HTTP/3:
        
        // 1. Allow more connections per host (HTTP/3 is efficient)
        configuration.httpMaximumConnectionsPerHost = 10
        
        // 2. Enable HTTP/3 hint (iOS 15+)
        if #available(iOS 15.0, *) {
            configuration.assumesHTTP3Capable = true
        }
        
        // 3. Timeout settings
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        // 4. Caching for subsequent requests
        configuration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB memory
            diskCapacity: 100 * 1024 * 1024,   // 100 MB disk
            diskPath: "http3_cache"
        )
        
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Public API
    
    /// Fetch data from URL with HTTP/3 support
    func fetchData(
        from url: URL,
        completion: @escaping (Result<(Data, HTTPProtocolInfo), Error>) -> Void
    ) {
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // Extract protocol information for analytics
            let protocolInfo = self.extractProtocolInfo(from: httpResponse)
            
            completion(.success((data, protocolInfo)))
        }
        
        task.resume()
    }
    
    /// Fetch multiple resources in parallel (benefits from HTTP/3 streams)
    func fetchMultiple(
        urls: [URL],
        completion: @escaping ([URL: Result<Data, Error>]) -> Void
    ) {
        let group = DispatchGroup()
        var results: [URL: Result<Data, Error>] = [:]
        let lock = NSLock()
        
        for url in urls {
            group.enter()
            
            fetchData(from: url) { result in
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
    
    // MARK: - Protocol Detection
    
    private func extractProtocolInfo(from response: HTTPURLResponse) -> HTTPProtocolInfo {
        // Check for Alt-Svc header (indicates HTTP/3 availability)
        let altSvc = response.allHeaderFields["Alt-Svc"] as? String
        
        // In iOS 15+, we can check the negotiated protocol
        var protocolVersion = "HTTP/1.1" // Default assumption
        
        if let altSvc = altSvc, altSvc.contains("h3") {
            protocolVersion = "HTTP/3"
        } else if let altSvc = altSvc, altSvc.contains("h2") {
            protocolVersion = "HTTP/2"
        }
        
        return HTTPProtocolInfo(
            version: protocolVersion,
            statusCode: response.statusCode,
            headers: response.allHeaderFields as? [String: String] ?? [:]
        )
    }
}

// MARK: - Supporting Types

struct HTTPProtocolInfo {
    let version: String
    let statusCode: Int
    let headers: [String: String]
}

enum NetworkError: Error {
    case invalidResponse
    case noData
    case serverError(Int)
}

// ============================================================================
// SECTION 4: MEASURING HTTP/3 IMPACT
// ============================================================================

/// Tracks and compares performance of HTTP/2 vs HTTP/3
final class HTTP3PerformanceTracker {
    
    static let shared = HTTP3PerformanceTracker()
    
    // MARK: - Metrics Storage
    
    private var http2Latencies: [TimeInterval] = []
    private var http3Latencies: [TimeInterval] = []
    private let queue = DispatchQueue(label: "com.meesho.http3tracker")
    
    // MARK: - Recording
    
    func recordRequest(protocol: String, latency: TimeInterval) {
        queue.async {
            if `protocol`.contains("3") || `protocol`.contains("QUIC") {
                self.http3Latencies.append(latency)
            } else {
                self.http2Latencies.append(latency)
            }
        }
    }
    
    // MARK: - Analysis
    
    func getComparison() -> ProtocolComparison {
        return queue.sync {
            let http2Avg = http2Latencies.isEmpty ? 0 :
                http2Latencies.reduce(0, +) / Double(http2Latencies.count)
            let http3Avg = http3Latencies.isEmpty ? 0 :
                http3Latencies.reduce(0, +) / Double(http3Latencies.count)
            
            let improvement = http2Avg > 0 ?
                ((http2Avg - http3Avg) / http2Avg) * 100 : 0
            
            return ProtocolComparison(
                http2AverageMs: http2Avg * 1000,
                http3AverageMs: http3Avg * 1000,
                improvementPercent: improvement,
                http2SampleCount: http2Latencies.count,
                http3SampleCount: http3Latencies.count
            )
        }
    }
}

struct ProtocolComparison {
    let http2AverageMs: Double
    let http3AverageMs: Double
    let improvementPercent: Double
    let http2SampleCount: Int
    let http3SampleCount: Int
    
    var summary: String {
        """
        HTTP/2: \(String(format: "%.1f", http2AverageMs))ms avg (\(http2SampleCount) samples)
        HTTP/3: \(String(format: "%.1f", http3AverageMs))ms avg (\(http3SampleCount) samples)
        Improvement: \(String(format: "%.1f", improvementPercent))%
        """
    }
}

// ============================================================================
// SECTION 5: OPTIMIZED IMAGE LOADING WITH HTTP/3
// ============================================================================

/// Image loader optimized for HTTP/3's parallel streams
final class HTTP3ImageLoader {
    
    static let shared = HTTP3ImageLoader()
    
    private let networkManager = HTTP3NetworkManager.shared
    private let cache = NSCache<NSURL, NSData>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    /// Load multiple images in parallel - leverages HTTP/3's independent streams
    func loadImages(
        urls: [URL],
        progress: ((Int, Int) -> Void)? = nil,
        completion: @escaping ([URL: Data]) -> Void
    ) {
        var loadedCount = 0
        let totalCount = urls.count
        var results: [URL: Data] = [:]
        let lock = NSLock()
        let group = DispatchGroup()
        
        for url in urls {
            // Check cache first
            if let cachedData = cache.object(forKey: url as NSURL) {
                lock.lock()
                results[url] = cachedData as Data
                loadedCount += 1
                progress?(loadedCount, totalCount)
                lock.unlock()
                continue
            }
            
            group.enter()
            
            networkManager.fetchData(from: url) { [weak self] result in
                defer { group.leave() }
                
                lock.lock()
                defer { lock.unlock() }
                
                switch result {
                case .success(let (data, protocolInfo)):
                    results[url] = data
                    self?.cache.setObject(data as NSData, forKey: url as NSURL)
                    
                    // Track which protocol was used
                    print("📷 Loaded \(url.lastPathComponent) via \(protocolInfo.version)")
                    
                case .failure(let error):
                    print("❌ Failed to load \(url): \(error)")
                }
                
                loadedCount += 1
                progress?(loadedCount, totalCount)
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
}

// ============================================================================
// SECTION 6: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "What is HTTP/3 and how is it different from HTTP/2?"                  │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  HTTP/3 is the latest version of HTTP, built on QUIC instead of TCP.       │
 │                                                                             │
 │  KEY DIFFERENCES:                                                           │
 │                                                                             │
 │  1. TRANSPORT LAYER:                                                        │
 │     - HTTP/2: Built on TCP (reliable, ordered delivery)                     │
 │     - HTTP/3: Built on QUIC (UDP-based, handles reliability itself)         │
 │                                                                             │
 │  2. HEAD-OF-LINE BLOCKING:                                                  │
 │     - HTTP/2: One lost packet blocks ALL streams (TCP limitation)           │
 │     - HTTP/3: Streams are independent, one loss affects only that stream    │
 │                                                                             │
 │  3. CONNECTION SETUP:                                                       │
 │     - HTTP/2: 2-3 round trips (TCP + TLS handshakes)                        │
 │     - HTTP/3: 0-1 round trips (0-RTT resumption)                            │
 │                                                                             │
 │  4. CONNECTION MIGRATION:                                                   │
 │     - HTTP/2: Connection breaks when IP changes (WiFi → Cellular)           │
 │     - HTTP/3: Seamlessly continues (uses Connection ID)                     │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "How did HTTP/3 help Meesho achieve 40% faster loads?"                 │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  E-commerce apps like Meesho load MANY resources per page:                  │
 │  - 20-50 product images                                                     │
 │  - API responses                                                            │
 │  - CSS/JS bundles                                                           │
 │                                                                             │
 │  With HTTP/2 on TCP:                                                        │
 │  - A single dropped packet blocks ALL images                                │
 │  - On mobile networks (high packet loss), this is common                    │
 │  - Users see spinning wheels while waiting                                  │
 │                                                                             │
 │  With HTTP/3 on QUIC:                                                       │
 │  - Each image loads on independent stream                                   │
 │  - Dropped packet only affects that ONE image                               │
 │  - Other images continue loading                                            │
 │  - 0-RTT means returning users connect instantly                            │
 │                                                                             │
 │  Result: Especially on poor networks (rural India), HTTP/3 provides         │
 │  significant improvement because those networks have higher packet loss.    │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q3: "How would you measure HTTP/3 impact in production?"                   │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  A/B TESTING APPROACH:                                                      │
 │                                                                             │
 │  1. Server-Side: Enable HTTP/3 on CDN for 50% of users                      │
 │                                                                             │
 │  2. Client-Side Metrics:                                                    │
 │     - Page load time (PLT)                                                  │
 │     - Time to First Byte (TTFB)                                             │
 │     - Image load time                                                       │
 │     - Connection setup time                                                 │
 │                                                                             │
 │  3. Track which protocol was used:                                          │
 │     - Check Alt-Svc header                                                  │
 │     - Log with analytics events                                             │
 │                                                                             │
 │  4. Segment by network type:                                                │
 │     - WiFi vs Cellular                                                      │
 │     - 4G vs 3G                                                              │
 │     - Urban vs Rural                                                        │
 │                                                                             │
 │  5. Compare:                                                                │
 │     - HTTP/2 cohort vs HTTP/3 cohort                                        │
 │     - Same device types, same regions                                       │
 │                                                                             │
 │  EXPECTED FINDINGS:                                                         │
 │  - Biggest gains on poor networks (high packet loss)                        │
 │  - Modest gains on WiFi (already low latency)                               │
 │  - Large gains for returning users (0-RTT)                                  │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q4: "Do you need to change iOS code to use HTTP/3?"                        │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  Mostly NO! iOS 15+ URLSession automatically uses HTTP/3 when:              │
 │  1. Server supports it (advertises via Alt-Svc header)                      │
 │  2. Network path supports UDP                                               │
 │                                                                             │
 │  OPTIONAL OPTIMIZATIONS:                                                    │
 │  - Set assumesHTTP3Capable = true (hint to try HTTP/3 first)                │
 │  - Increase httpMaximumConnectionsPerHost (HTTP/3 is efficient)             │
 │                                                                             │
 │  MAIN WORK IS SERVER-SIDE:                                                  │
 │  - CDN must support HTTP/3 (Cloudflare, Fastly, AWS CloudFront)             │
 │  - Backend servers need QUIC support                                        │
 │  - Firewall must allow UDP on port 443                                      │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 7: WHITEBOARD DIAGRAM
// ============================================================================

/*
 HTTP/3 vs HTTP/2 COMPARISON (Draw this):
 
 ┌───────────────────────────────────────────────────────────────────────────┐
 │                         PAGE LOAD COMPARISON                              │
 └───────────────────────────────────────────────────────────────────────────┘
 
 HTTP/2 over TCP:
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                                                                         │
 │  Time →                                                                 │
 │  0ms      100ms     200ms     300ms     400ms     500ms     600ms      │
 │  │         │         │         │         │         │         │         │
 │  ├─────────┤ TCP Handshake                                             │
 │  │         ├─────────┤ TLS Handshake                                   │
 │  │         │         ├─────────────────────────────────────────────────│
 │  │         │         │                                                 │
 │  │         │         │ Image 1 ████████████████████                   │
 │  │         │         │ Image 2 ████░░░░░░░░░░░░░░░░ (blocked!)        │
 │  │         │         │ Image 3 ████░░░░░░░░░░░░░░░░ (blocked!)        │
 │  │         │         │ Image 4 ████░░░░░░░░░░░░░░░░ (blocked!)        │
 │  │         │         │            ↑                                    │
 │  │         │         │      Packet lost                                │
 │  │         │         │      ALL streams wait!                          │
 │                                                                         │
 │  Total: ~600ms                                                          │
 │                                                                         │
 └─────────────────────────────────────────────────────────────────────────┘
 
 HTTP/3 over QUIC:
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                                                                         │
 │  Time →                                                                 │
 │  0ms      100ms     200ms     300ms     400ms                          │
 │  │         │         │         │         │                              │
 │  ├─────────┤ QUIC (0-RTT for returning users!)                         │
 │  │         │                                                            │
 │  │         │ Image 1 ████████████████ ✓                                │
 │  │         │ Image 2 ████░░░░████████ (retransmit only this stream)    │
 │  │         │ Image 3 ████████████████ ✓                                │
 │  │         │ Image 4 ████████████████ ✓                                │
 │  │         │            ↑                                               │
 │  │         │      Packet lost                                           │
 │  │         │      ONLY Image 2 waits!                                   │
 │                                                                         │
 │  Total: ~350ms (40% faster!)                                            │
 │                                                                         │
 └─────────────────────────────────────────────────────────────────────────┘
 
 
 CONNECTION MIGRATION (Draw this for mobile context):
 
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                                                                         │
 │  User walks: Home (WiFi) ───────────▶ Outside (Cellular)                │
 │                                                                         │
 │  TCP/HTTP/2:                                                            │
 │  ┌─────────┐         ┌─────────┐         ┌─────────┐                   │
 │  │  WiFi   │ ──X──── │   GAP   │ ─────── │Cellular │                   │
 │  │Connected│ Broken! │Reconnect│  New    │Connected│                   │
 │  └─────────┘         └─────────┘  Conn   └─────────┘                   │
 │       │                  │                    │                         │
 │    Loading            Timeout             Restart                       │
 │    product            2-3sec              download                      │
 │                                                                         │
 │  QUIC/HTTP/3:                                                           │
 │  ┌─────────┐                              ┌─────────┐                   │
 │  │  WiFi   │ ─────────────────────────── │Cellular │                   │
 │  │Connected│      Same Connection!       │Connected│                   │
 │  └─────────┘      (Connection ID)        └─────────┘                   │
 │       │                                       │                         │
 │    Loading ────────────────────────────▶ Completes                     │
 │    product         Seamless!             on cellular                    │
 │                                                                         │
 └─────────────────────────────────────────────────────────────────────────┘
*/
*/
