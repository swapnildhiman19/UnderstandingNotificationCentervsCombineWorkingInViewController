// ============================================================================
// MEESHO BAR RAISER INTERVIEW - QUICK REFERENCE CHEATSHEET
// ============================================================================
// Print this or keep open during your final review before the interview!
// ============================================================================

import Foundation

// ============================================================================
// THE INTERVIEWER'S KEY ACHIEVEMENTS (What they might ask about)
// ============================================================================
/*
 1. ✅ MetricKit Integration      → Day 1-2 files
 2. ✅ OOM Detection              → Day 1-2 files
 3. ✅ Page Load Tracking         → Day 1-2 files
 4. ✅ HTTP/3 (QUIC) - 40% faster → Day 3-4 files
 5. ✅ Memory Optimization - 50%  → Day 3-4 files
 6. ✅ Image Caching System       → Day 3-4 files
 7. ✅ Safe Mode (Crash Recovery) → Day 5 files
 8. ✅ Server-Driven UI           → Day 6 files
 9. ✅ Widget Framework           → Day 6 files
 10. ✅ Auto-Login via Keychain   → Day 7 files
 11. ✅ Build Time Optimization   → Day 3-4 (mentioned in HTTP/3)
*/

// ============================================================================
// TOP 10 CONCEPTS TO MEMORIZE
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 1. IMAGE DOWNSAMPLING (100x memory reduction)                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 let options = [
     kCGImageSourceCreateThumbnailFromImageAlways: true,
     kCGImageSourceThumbnailMaxPixelSize: targetSize,
     kCGImageSourceShouldCacheImmediately: true
 ] as CFDictionary
 
 let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options)
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 2. OOM DETECTION (Flag-based)                                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Launch: Set flag "sessionStarted = true"
 Clean exit: Set flag "sessionStarted = false"
 Next launch: If flag is still true → Previous session crashed
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 3. CRASH LOOP DETECTION                                                     │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 - Track crash timestamps in array
 - If >= 3 crashes in 5 minutes → Safe Mode
 - Safe Mode: Clear caches, disable risky features
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 4. HTTP/3 BENEFITS                                                          │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 - No head-of-line blocking (streams independent)
 - 0-RTT connection resumption (instant for returning users)
 - Connection migration (WiFi → Cellular seamlessly)
 - iOS 15+: URLSession uses it automatically if server supports
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 5. TWO-TIER IMAGE CACHE                                                     │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Memory Cache (NSCache):
 - 50 MB limit
 - Auto-evicts on memory warning
 - Stores decoded UIImage
 
 Disk Cache (FileManager):
 - 200 MB limit
 - Persists across launches
 - Stores original data
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 6. METRICKIT                                                                │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 MXMetricPayload: Aggregated metrics (24h) - launch time, memory, battery
 MXDiagnosticPayload: Incident reports - crashes, hangs, CPU exceptions
 
 Key: MXMetricManager.shared.add(self) in AppDelegate
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 7. WEAK VS UNOWNED                                                          │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 [weak self]: Becomes nil, safe, use in closures
 [unowned self]: Crashes if nil, use when 100% sure about lifetime
 
 Default to [weak self] in interview answers!
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 8. KEYCHAIN FOR AUTO-LOGIN                                                  │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Only storage that survives app uninstall!
 Use: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 9. SDUI ARCHITECTURE                                                        │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Server → JSON (type + data) → ComponentRegistry → UIView
 
 Benefits: No app release for UI changes, A/B testing, personalization
 
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ 10. REPOSITORY PATTERN                                                      │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Protocol: Defines data operations
 Impl: Uses Network + Cache
 Mock: Returns fake data for tests
 
 ViewModel → Repository (Protocol) → Network/Cache
*/

// ============================================================================
// COMMON INTERVIEW QUESTIONS - QUICK ANSWERS
// ============================================================================

/*
 Q: "How would you detect OOMs?"
 A: Flag-based detection. Set flag on launch, clear on clean exit.
    If flag is set on next launch + memory was high → likely OOM.
 
 Q: "How would you reduce memory 50%?"
 A: Image downsampling (biggest), NSCache limits, fix retain cycles,
    clear caches on memory warning, prepareForReuse in cells.
 
 Q: "What is HTTP/3?"
 A: HTTP over QUIC (UDP-based). No head-of-line blocking,
    0-RTT resumption, connection migration. 40% faster for Meesho.
 
 Q: "Design an image caching system"
 A: Two-tier (Memory + Disk), downsampling, prefetching,
    cancel on scroll past, NSCache for auto-eviction.
 
 Q: "What is SDUI?"
 A: Server sends UI structure as JSON. App renders dynamically.
    Benefits: No app release for UI changes, A/B testing.
 
 Q: "How does Safe Mode work?"
 A: Detect crash loop (3 crashes in 5 min), clear caches,
    disable risky features, show minimal stable UI.
 
 Q: "How does auto-login survive reinstall?"
 A: Keychain persists after uninstall. Store token in Keychain,
    check on launch, validate with server.
 
 Q: "Weak vs Unowned?"
 A: Weak = optional, becomes nil safely.
    Unowned = not optional, crashes if accessed after dealloc.
    Default to weak in closures.
*/

// ============================================================================
// WHITEBOARD STRUCTURE TEMPLATE
// ============================================================================

/*
 1. CLARIFY (2-3 min)
    "Before I design, let me clarify..."
    - Scale? Users? Products?
    - Offline required?
    - Performance targets?
 
 2. HIGH-LEVEL (5 min)
    Draw: ViewController → ViewModel → Repository → Network/Cache
    
 3. DEEP DIVE (10 min)
    Pick 2-3 components, show detail
    
 4. API DESIGN (5 min)
    GET /products?cursor=xxx&limit=20
    Response: { products: [...], nextCursor: "..." }
    
 5. OPTIMIZATIONS (5 min)
    - Downsampling
    - Prefetching
    - Caching strategy
    
 6. TRADE-OFFS (3 min)
    "With more time, I'd add..."
*/

// ============================================================================
// NUMBERS TO REMEMBER
// ============================================================================

/*
 Image Memory:
 - 4000x3000 image = 48 MB in memory (full resolution)
 - 400x300 = 480 KB in memory (downsampled)
 - Reduction: 100x
 
 Device Memory Limits:
 - iPhone 15 Pro: ~1.5 GB safe
 - iPhone 12: ~1 GB safe
 - iPhone SE: ~600 MB safe
 
 Launch Time:
 - Good: < 400ms cold start
 - Acceptable: 400-1000ms
 - Bad: > 1000ms
 
 HTTP/3 Impact:
 - ~40% faster page loads (Meesho's result)
 - Best gains on poor networks
 
 Safe Mode:
 - Trigger: 3 crashes in 5 minutes
 - Duration: Stay in safe mode for 1 hour
*/

// ============================================================================
// FINAL CHECKLIST BEFORE INTERVIEW
// ============================================================================

/*
 [ ] Review all Day 1-7 files one more time
 [ ] Practice drawing system diagrams on paper
 [ ] Prepare 2-3 questions for the interviewer:
     - "How does Meesho handle backward compatibility in SDUI?"
     - "What was the biggest challenge in HTTP/3 adoption?"
     - "How do you measure Safe Mode success rate?"
 
 [ ] Get good sleep the night before
 [ ] Arrive 10 minutes early
 [ ] Bring: Pen for notes, water
 
 GOOD LUCK! 🚀
 You've got this!
*/

