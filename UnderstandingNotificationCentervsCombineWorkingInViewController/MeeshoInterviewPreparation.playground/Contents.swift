////////class Bird {
////////    var nest : Nest?
////////    deinit {
////////        print("Bird is being deinitialized")
////////    }
////////}
////////
////////class Nest {
////////    unowned var bird : Bird
////////    init(bird: Bird) {
////////        self.bird = bird
////////    }
////////    deinit {
////////        print("Nest is being deinitialized")
////////    }
////////}
////////
////////var bird: Bird? = Bird()
////////var nest: Nest? = Nest(bird: bird!)
////////
//////////nest?.bird = bird
//////////bird?.nest = nest
//////////
//////////bird = nil
//////////nest = nil
////////
////////// nest?.bird.nest // bad memory access if using unowned parent should outlive the child
////////
////////class NetworkManager {
////////    var data : String = ""
////////    func fetchData() {
////////        //        MockAPIService.fetch { [weak self] responseData in
////////        //            guard let self = self else { return }
////////        //            self.data = responseData
////////        //        }
////////    }
////////}
////////
////////import Foundation
////////import UIKit
////////import Combine
////////
////////class ViewController : UIViewController
////////{
////////    var task = Set<AnyCancellable>()
////////    var publisher = PassthroughSubject<String, Never>().eraseToAnyPublisher()
////////    var dataString: String = ""
////////
////////    func setupSubscriber()
////////    {
////////        //        NotificationCenter.default.addObserver(forName: .pushNotificationReceived, object: nil, queue: .main) {[weak self] notification in
////////        //            guard let self = self else { return }
////////        //            // Handle notification
////////        //            self.handleNotificationUIUpdate()
////////        //        }
////////
////////        //        publisher.sink { [weak self] str in
////////        //            self?.dataString = str
////////        //        }
////////
////////    }
////////    func handleNotificationUIUpdate(){
////////        print("UI has been updated after receiving notification")
////////    }
////////}
////////
////////protocol Identifiable {
////////    var id : String { get set }
////////    func displayID()
////////    associatedtype IDType
////////}
////////
////////extension Identifiable {
////////    func displayID() {
////////        print("ID is \(id)")
////////    }
////////}
////////
////////struct User: Identifiable {
////////    typealias IDType = Int
////////
////////    var id: String
////////    var name: String
////////    mutating func changeId(to newId: String) {
////////        id = newId
////////    }
////////}
////////
//////////var user = User(id: "12345")
//////////user.displayID()
//////////user.id = "67890"
//////////user.displayID()
////////
////////
////////struct Stack<Element> {
////////    var items: [Element] = []
////////
////////    mutating func push(_ item: Element) {
////////        items.append(item)
////////    }
////////
////////    mutating func pop() -> Element? {
////////        return items.popLast()
////////    }
////////
////////    func peek() -> Element? {
////////        return items.last
////////    }
////////
////////    var isEmpty: Bool {
////////        return items.isEmpty
////////    }
////////}
////////
////////var integerStack : Stack<Int> = Stack<Int>()
////////integerStack.push(10)
////////
////////func genericComparison<T : Comparable> (a: T, b: T) -> Bool {
////////    return a < b
////////}
////////
//////////print(genericComparison(a: "z", b: "a"))
////////protocol Container {
////////    associatedtype ItemType
////////    var items : [ItemType] { get set }
////////    mutating func addItem(_ item: ItemType)
////////}
////////
////////struct Item: Container {
////////    typealias ItemType = Int
////////    var items : [Int] = []
////////    mutating func addItem(_ item: Int) {
////////        items.append(item)
////////    }
////////}
////////
////////class StepsCounter {
////////    var steps: Int = 0 {
////////        willSet(newSteps) {
////////            print("About to set steps to \(newSteps)")
////////        }
////////        didSet(oldValue) {
////////            if steps > oldValue {
////////                print("Added \(steps - oldValue) steps")
////////            }
////////            else {
////////                print("Removed \(oldValue - steps) steps")
////////            }
////////        }
////////    }
////////}
////////
//////////let counter = StepsCounter()
//////////counter.steps = 1000
//////////counter.steps = 1500
////////
////////class UserProfileView : UIView {
////////    struct Model {
////////        let id : Int
////////        let name: String
////////    }
////////
////////    var model : Model? {
////////        willSet(newValue) {
////////            print("User profile is about to be updated")
////////        }
////////        didSet {
////////            applyModel()
////////        }
////////    }
////////
////////    private func applyModel() {
////////        print("User profile is getting updated")
////////    }
////////}
////////
////////class ViewControllerForClosure {
////////    var completionHandler : (()->Void)?
////////
////////    func processData(completion: ()->Void) {
////////        print("processing")
////////        completion()
////////    }
////////
////////    func fetchAsyncData(completion: @escaping (String)->Void) {
////////        DispatchQueue.global().asyncAfter(deadline: .now()+2){
////////            completion("Data has been received")
////////        }
////////    }
////////
////////    func storingClosure(closure :@escaping ()->Void) {
////////        self.completionHandler = closure
////////    }
////////}
////////
////////
////////class MyClass {
////////    var name = "MyClass"
////////
////////    func nonEscaping(closure: () -> Void) {
////////        closure()  // No need for self, compiler knows it's safe
////////    }
////////
////////    func escaping(closure: @escaping () -> Void) {
////////        DispatchQueue.global().asyncAfter(deadline:.now()+2) { [weak self] in
////////            closure()  // Must explicitly capture self
////////        }
////////    }
////////
////////    func demo() {
////////        escaping {
////////            print("this is escaping \(self.name)")
////////        }
////////
////////        nonEscaping {
////////            print("this is non escaping \(name)")
////////        }
////////    }
////////}
////////
//////////let myClass = MyClass()
//////////myClass.demo()
////////
////////
////////enum NetworkError: Error {
////////    case invalidUrl
////////    case noData
////////    case decodingFailed
////////}
////////
//////////func fetchUser(id: Int) throws -> User {
//////////    guard id > 0 else {
//////////        throw NetworkError.invalidUrl
//////////    }
//////////
//////////    guard let data = loadData() else {
//////////        throw NetworkError.noData
//////////    }
//////////
//////////    return try JSONDecoder().decode(User.self, from: data)
//////////}
////////
////////extension User: Decodable {}
////////
////////func loadData() -> Data? {
////////    return Data()
////////}
////////
////////// Using it
//////////do {
//////////    let user = try fetchUser(id: 123)
//////////    print(user.name)
//////////} catch NetworkError.invalidUrl {
//////////    print("Invalid URL")
//////////} catch NetworkError.noData {
//////////    print("No data received")
//////////} catch {
//////////    print("Other error: \(error)")
//////////}
////////
////////// try? - Converts to optional (nil on error)
//////////let user = try? fetchUser(id: 123)  // User?
////////
////////func fetchUser(id: Int) -> Result<User, NetworkError> {
////////    guard id > 0 else {
////////        return .failure(.invalidUrl)
////////    }
////////
////////    guard let data = loadData() else {
////////        return .failure(.noData)
////////    }
////////
////////    do {
////////        let user = try JSONDecoder().decode(User.self, from: data)
////////        return .success(user)
////////    }
////////    catch {
////////        return .failure(.decodingFailed)
////////    }
////////}
////////
//////////let result = fetchUser(id: 10)
//////////switch result {
//////////    case .success(let user) :
//////////        print("User name is \(user.name)")
//////////    case .failure(let error) :
//////////        print("Error occurred: \(error)")
//////////}
////////
////////struct StructUnderstandingComparable: Comparable {
////////    static func < (lhs: StructUnderstandingComparable, rhs: StructUnderstandingComparable) -> Bool {
////////        return lhs.grade < rhs.grade
////////    }
////////
////////    let id : Int
////////    let name: String
////////    let grade: Double
////////}
////////
////////extension StructUnderstandingComparable : Hashable {
////////    func hash(into hasher: inout Hasher) {
////////        hasher.combine(id)
////////        hasher.combine(name)
////////        hasher.combine(grade)
////////    }
////////
////////    static func == (lhs: StructUnderstandingComparable, rhs: StructUnderstandingComparable) -> Bool {
////////        return lhs.id == rhs.id && lhs.grade == rhs.grade && lhs.name == rhs.name
////////    }
////////}
////////
////////var dictionary : [StructUnderstandingComparable: Int] = [:]
////////let s1 = StructUnderstandingComparable(id: 1, name: "Swapnil Dhiman", grade: 100)
////////let s2 = StructUnderstandingComparable(id: 2, name: "XYZ", grade: 20)
////////dictionary[s1] = 95
////////dictionary[s2] = 85
////////
////////
////////let jsonString = """
////////{
////////"full_name": "Swapnil Dhiman from JSON",
////////"id" : 1,
////////"grade": 100.0
////////}
////////"""
////////
//////////extension StructUnderstandingComparable : Decodable {
//////////    enum CodingKeys : String,CodingKey {
//////////        case name = "full_name"
//////////        case id
//////////        case grade
//////////    }
//////////}
////////
////////let jsonData = jsonString.data(using: .utf8)
////////let decoder = JSONDecoder()
////////if let jsonData = jsonData {
////////    do {
////////        let decodedStructFromJSON = try decoder.decode(StructUnderstandingComparable.self, from: jsonData)
////////        print(decodedStructFromJSON.name)
////////    } catch {
////////        print("Decoding failed: \(error)")
////////    }
////////}
////////
//////////extension StructUnderstandingComparable: Encodable {
//////////
//////////}
////////
////////let structUnderstandingComparable = StructUnderstandingComparable(id: 3, name: "Encode Test", grade: 88.5)
////////let encoder = JSONEncoder()
////////encoder.outputFormatting = .prettyPrinted
////////
////////do {
////////    let encodedData = try encoder.encode(structUnderstandingComparable)
////////    if let jsonString = String(data: encodedData, encoding: .utf8) {
////////        print(jsonString)
////////    }
////////}
////////catch {
////////    print("Encoding failed: \(error)")
////////}
////////
////////extension StructUnderstandingComparable: Codable {
////////    enum CodingKeys : String,CodingKey {
////////        case name = "full_name"
////////        case id
////////        case grade
////////    }
////////}
//////
//////import Combine
//////
//////// ❌ PassthroughSubject - No initial value
//////let passthrough = PassthroughSubject<String, Never>()
//////var cancellables = Set<AnyCancellable>()
//////
//////// First subscriber
//////passthrough.sink { value in
//////    print("Sub 1: \(value)")
//////}.store(in: &cancellables)
//////
//////passthrough.send("Hello")  // Sub 1: Hello
//////passthrough.send("World")  // Sub 1: World
//////
//////// ⚠️ Second subscriber (late arrival)
//////passthrough.sink { value in
//////    print("Sub 2: \(value)")
//////}.store(in: &cancellables)
//////// Sub 2 receives NOTHING from before!
//////
//////passthrough.send("!")      // Sub 1: !
//////                           // Sub 2: !
//////
//////let currentSubject = CurrentValueSubject<String,Never>("Initial")
//////
//////currentSubject.sink { value in
//////    print("Curr Sub 1: \(value)")
//////}
//////
//////currentSubject.send("Hello")
//////currentSubject.send("World")
//////
//////currentSubject.sink { value in
//////    print("Curr Sub 2: \(value)")
//////}
//////
//////currentSubject.send("!")
//////print(currentSubject.value)
////
////import Foundation
////
////func demonstrateThreads(){
////    print("Main Thread: \(Thread.current)")
////    print("Is Main Thread? : \(Thread.isMainThread)")
////    DispatchQueue.global().async {
////        print("Background Thread: \(Thread.current)")
////        print("Is Main Thread? : \(Thread.isMainThread)")
////    }
////}
////
////demonstrateThreads()
////
////DispatchQueue.global().async {
////    print("Task 1: \(Thread.current)")
////}
////
////
////DispatchQueue.global().async {
////    print("Task 2: \(Thread.current)")
////}
////
////DispatchQueue.global().async {
////    print("Task 3: \(Thread.current)")
////}
////
////
////// ✅ Background thread - for heavy work
////// System creates and manages these automatically
////
////DispatchQueue.global(qos: .background).async {
////    // This runs on a BACKGROUND thread
////    print("Is this main thread? \(Thread.isMainThread)")  // false
////    print("\(Thread.current)")
////
////    // Do heavy work here:
////    // - Network requests
////    // - Image processing
////    // - File operations
////    // - Complex calculations
////
////    let result = performHeavyCalculation()
////
////    // ✅ When done, update UI on MAIN thread
////    DispatchQueue.main.async {
////        // self.label.text = result
////        print("Back on main thread: \(Thread.isMainThread)")  // true
////    }
////}
////
////func performHeavyCalculation() -> String {
////    print("Is this thread a main thread : \(Thread.isMainThread)")
////    print("\(Thread.current)")
////    Thread.sleep(forTimeInterval: 2)  // Simulate heavy work
////    return "Done!"
////}
//
////import Foundation
////
////DispatchQueue.global(qos: .userInitiated).async {
////    print("Outer Most : \(Thread.current)")
////
////    //DispatchQueue.global(qos:) -> Background queue, can still access main thread. Sync Will use the thread which is previously being used outside of this
////    DispatchQueue.global(qos: .userInitiated).sync {
////        print("Outer Thread: \(Thread.current)")
////        DispatchQueue.global(qos: .userInitiated).sync {
////            print("Inner Thread: \(Thread.current)")
////        }
////    }
////}
//
//import Foundation
//
////print("Is this main thread, \(Thread.isMainThread) ?")
////DispatchQueue.main.sync {
//// Here I am saying to the main queue to stop whatever you are doing and block yourself till you complete this task, but now the issue is main queue can't start this work as it working already and now it will wait for itself indefinitely.
////    print("App is getting crashed ?")
////}
////print("I am here outside this block ?")
//
//// prints: Is this main thread, true ?
//
//func asyncAsyncOnMain() {
//    print("Start on main : \(Thread.isMainThread)")
//    DispatchQueue.main.async {
//        // Here I am saying to the main queue that whenever you get the time execute this block of code later, no need to block yourself for me.
//        print("Outer async on main : \(Thread.isMainThread)")
//
//        DispatchQueue.main.async {
//            print("Inner async on main : \(Thread.isMainThread)")
//        }
//
//        print("After inner main async")
//    }
//    print("After outer main async")
//}
//
////asyncAsyncOnMain()
//
//func asyncAsyncOnGlobal() {
//    DispatchQueue.global().async {
//        print("Outer async on global: \(Thread.current)")
//
//        DispatchQueue.global().async {
//            print("Inner async on global: \(Thread.current)")
//        }
//
//        print("Inner async on global complete")
//    }
//    print("Outer async on global complete")
//}
//
////asyncAsyncOnGlobal()
//
//func asyncSyncOnMain_FromMain(){
//    print("Start on main : \(Thread.isMainThread)")
//
//    DispatchQueue.main.async {
//        print("Outer async on main : \(Thread.isMainThread), \(Thread.current)")
//
//        DispatchQueue.main.sync {
//            print("This will not print: DEADLOCK")
//        }
//
//        print("Inner sync on main work done, this will also not be printed")
//    }
//
//    print("After outer async")
//}
//
////asyncSyncOnMain_FromMain()
//
//func asyncSyncOnMain_FromBackground() {
//    DispatchQueue.global().async {
//        print("Background thread: \(Thread.current)")
//
//        DispatchQueue.main.async {
//            print("Switching to main thread: Outer async on main")
//            print("\(Thread.current)")
//
//            DispatchQueue.main.sync {
//                print("\(Thread.current)")
//                print("This will not print: DEADLOCK")
//            }
//
//            print("Inner sync on main work done, this will not be printed")
//        }
//
//        print("After outer async")
//    }
//}
//
////asyncSyncOnMain_FromBackground()
//
//func asyncSyncOnGlobal() {
//    // Global Queue is a concurrent queue we have multiple background thread
//    DispatchQueue.global().async {
//        print("Outer - thread : \(Thread.current)")
//        DispatchQueue.global().sync {
//            print("Inner - thread: \(Thread.current)")
//        }
//        print("Inner global sync completed")
//    }
//    print("Outer global async")
//}
//
//// asyncSyncOnGlobal()
//
//
////let serialQueue = DispatchQueue(label: "com.example.serial", attributes: [])
////
////serialQueue.async{
////    print("Task1 started")
////    Thread.sleep(forTimeInterval: 1)
////    print("Task1 completed")
////}
////
////serialQueue.async {
////    print("Task2 started")
////    Thread.sleep(forTimeInterval: 1)
////    print("Task2 completed")
////}
////
////serialQueue.async {
////    print("Task3 started")
////    Thread.sleep(forTimeInterval: 1)
////    print("Task3 completed")
////}
//
////let customConcurrentQueue = DispatchQueue(
////    label: "com.example.concurrent",
////    attributes: .concurrent
////)
////
////customConcurrentQueue.async {
////    print("Task1 concurrent queue started")
////    Thread.sleep(forTimeInterval: 1)
////    print("\(Thread.current)")
////    print("Task1 concrurrent queue completed")
////}
////
////customConcurrentQueue.async {
////    print("Task2 concurrent queue started")
////    Thread.sleep(forTimeInterval: 1)
////    print("\(Thread.current)")
////    print("Task2 concurrent queue completed")
////}
//
////let group = DispatchGroup()
////
////group.enter()
////DispatchQueue.global().async {
////    print("Task1 starting...")
////    Thread.sleep(forTimeInterval: 2)
////    print("Task1 ended")
////    group.leave()
////}
////
////group.enter()
////DispatchQueue.global().async {
////    print("Task2 starting...")
////    Thread.sleep(forTimeInterval: 1)
////    print("Task2 ended")
////    group.leave()
////}
////
////group.enter()
////DispatchQueue.global().async {
////    print("Task3 starting...")
////    Thread.sleep(forTimeInterval: 3)
////    print("Task3 ended")
////    group.leave()
////}
////
////group.notify(queue: .main) {
////    print("Task1, Task2, Task3 has been completed")
////}
//
///*
// Task1 starting...
// Task2 starting...
// Task3 starting...
// Task2 ended
// Task1 ended
// Task3 ended
// Task1, Task2, Task3 has been completed
// */
//
//
////let group = DispatchGroup()
////
////group.notify(queue: .main) {
////    print("Task1, Task2, Task3 has been completed")
////}
////
////
////group.enter()
////DispatchQueue.global().async {
////    print("Task1 starting...")
////    Thread.sleep(forTimeInterval: 2)
////    print("Task1 ended")
////    group.leave()
////}
////
////group.enter()
////DispatchQueue.global().async {
////    print("Task2 starting...")
////    Thread.sleep(forTimeInterval: 1)
////    print("Task2 ended")
////    group.leave()
////}
////
////group.enter()
////DispatchQueue.global().async {
////    print("Task3 starting...")
////    Thread.sleep(forTimeInterval: 3)
////    print("Task3 ended")
////    group.leave()
////}
//
///*
// Task1 starting...
// Task3 starting...
// Task2 starting...
// Task1, Task2, Task3 has been completed
// Task2 ended
// Task1 ended
// Task3 ended
// */
//
///*
//let group = DispatchGroup()
//
//group.enter()
//DispatchQueue.global().async {
//    print("Task1 starting...")
//    Thread.sleep(forTimeInterval: 2)
//    print("Task1 ended")
//    group.leave()
//}
//
//group.enter()
//DispatchQueue.global().async {
//    print("Task2 starting...")
//    Thread.sleep(forTimeInterval: 1)
//    print("Task2 ended")
//    group.leave()
//}
//
//group.enter()
//DispatchQueue.global().async {
//    print("Task3 starting...")
//    Thread.sleep(forTimeInterval: 3)
//    print("Task3 ended")
//    group.leave()
//}
//
//group.notify(queue: .global()) {
//    print("Task1, Task2, Task3 has been completed")
//}
// */
//
///*
// Task1 starting...
// Task3 starting...
// Task2 starting...
// Task2 ended
// Task1 ended
// Task3 ended
//
// Notify has not been printed
// */
//
//// let semaphore = DispatchSemaphore(value: 2)
//
////for i in 0...5 {
////    DispatchQueue.global().async {
////        semaphore.wait()
////        print("Task\(i) started on \(Thread.current) started at : \(Date.now)")
////        Thread.sleep(forTimeInterval: 2)
////        print("Task\(i) completed on \(Thread.current) ended at : \(Date.now)")
////        semaphore.signal()
////        /*
////         Task0 started on <NSThread: 0x60000171c180>{number = 8, name = (null)} started at : 2025-12-09 09:14:51 +0000
////         Task1 started on <NSThread: 0x600001709200>{number = 5, name = (null)} started at : 2025-12-09 09:14:51 +0000
////         Task0 completed on <NSThread: 0x60000171c180>{number = 8, name = (null)} ended at : 2025-12-09 09:14:53 +0000
////         Task1 completed on <NSThread: 0x600001709200>{number = 5, name = (null)} ended at : 2025-12-09 09:14:53 +0000
////         Task2 started on <NSThread: 0x600001708500>{number = 12, name = (null)} started at : 2025-12-09 09:14:53 +0000
////         Task3 started on <NSThread: 0x600001707380>{number = 3, name = (null)} started at : 2025-12-09 09:14:53 +0000
////         Task2 completed on <NSThread: 0x600001708500>{number = 12, name = (null)} ended at : 2025-12-09 09:14:55 +0000
////         Task3 completed on <NSThread: 0x600001707380>{number = 3, name = (null)} ended at : 2025-12-09 09:14:55 +0000
////         Task4 started on <NSThread: 0x600001709040>{number = 13, name = (null)} started at : 2025-12-09 09:14:55 +0000
////         Task5 started on <NSThread: 0x600001700e00>{number = 4, name = (null)} started at : 2025-12-09 09:14:55 +0000
////         Task5 completed on <NSThread: 0x600001700e00>{number = 4, name = (null)} ended at : 2025-12-09 09:14:57 +0000
////         Task4 completed on <NSThread: 0x600001709040>{number = 13, name = (null)} ended at : 2025-12-09 09:14:57 +0000
////         */
////    }
////}
//
//import UIKit
//
////class RateLimitDownloader {
////    private let semaphore = DispatchSemaphore(value: 3)
////
////    func downloadImages(_ urls: [URL], completion: @escaping ([UIImage]) -> Void){
////        let dispatchGroup = DispatchGroup()
////        let lock = NSLock()
////        var images : [UIImage] = []
////
////        for url in urls {
////            dispatchGroup.enter()
////            DispatchQueue.global(qos: .userInitiated).async {
////                self.semaphore.wait()
////
////                if let data = try? Data(NSData(contentsOf: url)),
////                   let image = UIImage(data: data)
////                {
////                    lock.lock()
////                    images.append(image)
////                    lock.unlock()
////                }
////
////                self.semaphore.signal()
////                dispatchGroup.leave()
////            }
////        }
////
////        dispatchGroup.notify(queue: .main) {
////            completion(images)
////        }
////    }
////}
//
////var counter = 0
////let lock = NSLock()
////let semaphore = DispatchSemaphore(value: 1)
////
////DispatchQueue.global().async {
////    for _ in 0..<1000 {
////        counter += 1
////    }
////    print(counter)
////}
////
////
////DispatchQueue.global().async {
////    for _ in 0..<1000 {
////        counter += 1
////    }
////    print(counter)
////}
////
////print(counter)
//
//class ThreadSafeCounter1 {
//    private var _count = 0
//
//    let serialQueue = DispatchQueue(label:"com.threadSafety")
//
//    var count : Int {
//        serialQueue.sync {
//            _count
//        }
//    }
//
//    func increment () {
//        serialQueue.sync { _count += 1 }
//    }
//}
//
////let threadSafeCounter1 = ThreadSafeCounter1()
////DispatchQueue.global().async {
////    for _ in 0..<1000 {
////        threadSafeCounter1.increment()
////    }
////    print(threadSafeCounter1.count)
////}
////
////DispatchQueue.global().async {
////    for _ in 0..<1000 {
////        threadSafeCounter1.increment()
////    }
////    print(threadSafeCounter1.count)
////}
//
//class ThreadSafeCounter2 {
//    private var _count = 0
//    private let lock = NSLock()
//
//    var count : Int {
//        lock.lock()
//        defer {lock.unlock()}
//        return _count
//    }
//
//    func increment(){
//        lock.lock()
//        _count += 1
//        lock.unlock()
//    }
//}
//
//class ThreadSafeCounter3 {
//    private var _count = 0
//    private let concurrentQueue = DispatchQueue(
//        label: "com.concurrentQueue",
//        attributes: .concurrent
//    )
//
//    var count : Int {
//        concurrentQueue.sync {
//            _count
//        }
//    }
//
//    func increment(){
//        concurrentQueue.async(flags: .barrier) {
//            self._count += 1
//        }
//    }
//}
//
////let threadSafeCounter = ThreadSafeCounter3()
////DispatchQueue.global().async {
////    for _ in 0..<1000 {
////        threadSafeCounter.increment()
////    }
////    print(threadSafeCounter.count)
////}
////
////DispatchQueue.global().async {
////    for _ in 0..<1000 {
////        threadSafeCounter.increment()
////    }
////    print(threadSafeCounter.count)
////}
///*
//actor ThreadSafeCounter4 {
//    private var _count = 0
//
//    var count: Int {
//        _count
//    }
//
//    func increment() {
//        _count += 1
//    }
//
//    func getValue() -> Int {
//        return _count
//    }
//}
//
//
//
//let threadCounter = ThreadSafeCounter4()
//
//Task {
//    for _ in 0..<1000 {
//        await threadCounter.increment()
//    }
//    print("Task A done: \(await threadCounter.count)")
//}
//
//Task {
//    for _ in 0..<1000 {
//        await threadCounter.increment()
//    }
//    print("Task B done: \(await threadCounter.count)")
//}
//*/
//
////how networking handles threading
//
////if let url = URL(string: "https:typecode.com") {
////    URLSession.shared.dataTask(with: url){ data, response, error in
////
////        if let data = data {
////            let result = JSONDecoder().decode(data)
////            DispatchQueue.main.async {
////                //Update the UI element
////            }
////        }
////    }.resume()
////}
///*
//
//let url = URL(string:"https:typecode.com")
//Task {
//    do {
//        let (data,response) = try await URLSession.shared.data(from: url!)
//    } catch {
//        print(error)
//    }
//    await MainActor.run {
//        //update the UI if you want
//    }
//}
//
//import Combine
//
//var task = Set<AnyCancellable>()
//URLSession.shared.dataTaskPublisher(for: url!)
//    .subscribe(on: DispatchQueue.global())
//    .receive(on: DispatchQueue.main)
//    .sink (receiveCompletion: {_ in}) { data, response in
//        //main Thread
//
//    }.store(in: &task)
//
//*/

// Singleton Pattern - Configuration manager, analytics manager -> the one which don't need different configuration
struct User : Codable, Identifiable, Equatable {
    let id : Int
    let name : String
    let email : String
    let phone : String?

    var initials : String {
        let parts =  name.split(separator: " ")
        let firstInitial = parts.first?.prefix(1) ?? ""
        let lastInitial = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
}

final class UserSession {
    @MainActor static let shared = UserSession()

    private init() {}

    private(set) var currentUser: User?
    private(set) var authToken: String?

    var isLoggedIn: Bool {
        currentUser != nil && authToken != nil
    }

    func login(user: User, token : String) {
        currentUser = user
        authToken = token
    }

    func logout(){
        currentUser = nil
        authToken = nil
    }
}

let user = User(id: 1, name: "Swapnil Dhiman", email: "swapnil.dhiman@walmart.com", phone: "123123123")
UserSession.shared.login(user: user, token: "123123")
if UserSession.shared.isLoggedIn {
    print("\(user.name) has been logged in")
}

@MainActor
class ProfileViewModel {
    private let userSession: UserSession

    init(userSession: UserSession = .shared) {
        self.userSession = userSession
    }
}

import UIKit

//building a complex object step by step
//class AlertBuilder {
//    private var title : String = ""
//    private var message : String = ""
//    private var style : UIAlertController.Style = .alert
//    private var actions : [UIAlertAction] = []
//
//    func setTitle(_ title: String) -> AlertBuilder {
//        self.title = title
//        return self
//    }
//
//    func setMessage(_ message: String) -> AlertBuilder {
//        self.message = message
//        return self
//    }
//
//    func setStyle(_ style: UIAlertController.Style) -> AlertBuilder {
//        self.style = style
//        return self
//    }
//
//    func build() -> UIAlertController {
//        let alert = UIAlertController()
//        return alert
//    }
//}
//
//let alert = AlertBuilder()
//    .setTitle("Swapnil is comimg")
//    .setMessage("Let's fuckinnnggggg goooooooo")
//    .build()

protocol UserServiceProtocol {
    func fetchUser(id: Int) async throws -> User
    func saveUser(_ user: User) async throws
}

protocol AnalyticsProtocol {
    func track(event: String, properties: [String: Any])
}

class UserService : UserServiceProtocol {
    func fetchUser(id: Int) async throws -> User {
        print("🌐 UserService: Fetching user from API...")
        // Real API call would go here
        return User(
            id: id,
            name: "John Doe",
            email: "john@example.com",
            phone: nil
        )
    }

    func saveUser(_ user: User) async throws {
        print("🌐 UserService: Saving user to API...")
    }
}

class AnlayticsService: AnalyticsProtocol {
    func track(event: String, properties: [String: Any] = [:]) {
        print("📊 Analytics: Tracked '\(event)' with \(properties)")
        // Real analytics (Firebase, Mixpanel, etc.)
    }
}

class MockUserService: UserServiceProtocol {

    var userToReturn : User?
    var shouldThrowError = false
    var fetchCallCount = 0

    func fetchUser(id: Int) async throws -> User {
        fetchCallCount += 1
        print("MockUserService: returning fake user")
        if shouldThrowError {
            throw NSError(domain: "Test", code: 1)
        }
        return userToReturn ?? User(id: id, name: "Swapnil Dhiman", email: "asd", phone: nil)
    }

    func saveUser(_ user: User) async throws {
        print("MockUserService pretending to save")
    }
}

class MockAnalyticsService : AnalyticsProtocol {
    var trackedEvents : [(event: String, properties: [String:Any])] = []
    func track(event: String, properties: [String : Any]) {
        trackedEvents.append((event, properties))
        print("Mock Analytics: \(event)")
    }
}

protocol DependencyContainerProtocol {
    var userService: UserServiceProtocol {get}
    var analyticsService: AnalyticsProtocol {get}
}

class AppDependencyContainer : DependencyContainerProtocol {
    lazy var userService: UserServiceProtocol = UserService()
    lazy var analyticsService: AnalyticsProtocol = AnlayticsService()
}

class TestDependencyContainer: DependencyContainerProtocol {
    let mockUserService = MockUserService()
    let mockAnalytics = MockAnalyticsService()

    var userService: UserServiceProtocol { mockUserService }
    var analyticsService: AnalyticsProtocol { mockAnalytics }
}

class UserViewModel {
    private let userService : UserServiceProtocol
    private let analytics : AnalyticsProtocol

    var user : User?
    var errorMessage : String?

    init(userService: UserServiceProtocol, analytics: AnalyticsProtocol) {
        self.userService = userService
        self.analytics = analytics
    }

    init(container: DependencyContainerProtocol) {
        self.userService = container.userService
        self.analytics = container.analyticsService
    }

    func loadUser(id: Int) async {
        analytics.track(event: "user_load_started", properties: ["user_id": id])

        do {
            user = try await userService.fetchUser(id: id)
            analytics.track(event: "user_load_success", properties: ["user_id": id])
        } catch {
            errorMessage = error.localizedDescription
            analytics.track(event: "user_load_failed", properties: ["error": error.localizedDescription])
        }
    }
}

//func productionExample(){
//    let container = AppDependencyContainer()
//    let viewModel = UserViewModel(container: container)
//
//    Task {
//        await viewModel.loadUser(id: 12)
//    }
//}

//SOLID
//S: Single Class Responsibility
class BadUserManager {
    func fetchUser(id: Int) async throws -> User {
        //Network layer call
        return User(
            id: 1,
            name: "Swapnil Dhiman",
            email: "swapnil.dhiman@walmart.com",
            phone: nil
        )
    }
    func saveUser(_ user: User) async throws {
        //Database layer call
    }
    func validateEmail(_ user: User) -> Bool {
        //Validation Logic
        return false
    }
}

enum UserError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(error: Error)
    case encodingError(error: Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .noData:
            return "No data received from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode JSON: \(error.localizedDescription)"
        }
    }
}

//Single responsibility
class UserNetworkService {
    let baseURL = "https://jsonplaceholder.typicode.com"
    func fetchUser(_ id: Int) async throws -> User {
        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
            throw UserError.invalidURL
        }
        let (data,response) = try await URLSession.shared.data(from: url)
        guard let httpsResposne = response as? HTTPURLResponse,
              (200...299).contains(httpsResposne.statusCode) else {
            throw UserError.invalidResponse
        }
        return try JSONDecoder().decode(User.self, from: data)
    }
}

class UserRepository {
    func save(_ user: User){
        UserDefaults.standard.set(user.id, forKey: "lastuserId")
    }
}

class UserFormatter {
    func displayInitials(for user: User) -> String {
        let name = user.name
        let parts = name.split(separator: " ")
        let firstInitial = parts.first?.prefix(1) ?? ""
        let lastInitial = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
}

// Validation only
class EmailValidator {
    func isValid(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

// 2. Open Close Principle : Open for extend/close for change
class BadPaymentProcessor {
    func processPayment(type: String, amount: Double) -> Bool {
        if type == "Credit Card" {
            return true
        } else if type == "Apple Pay"{
            return true
        } else if type == "Google Pay" {
            //Bad thing need to edit an existing function here
            return true
        }
        return false
    }
}

//Correct way of implementation
protocol PaymentProcess {
    var name : String { get }
    func processPayment(amount:Double) -> Bool
}

class CreditCardProcessor : PaymentProcess {
    var name: String = "Credit Card"
    func processPayment(amount: Double) -> Bool {
        if amount > 0 {
            print("Credit Card has processed the payment")
            return true
        }
        print("Payment declined")
        return false
    }
}


// ✅ Add NEW payment without changing existing code!
class CryptoPayment: PaymentProcess {
    var name = "Crypto"
    func processPayment(amount: Double) -> Bool {
        print("₿ Processing $\(amount) via Crypto")
        return true
    }
}

class PaymentProcessor {
    func processPayment(type: PaymentProcess, amount: Double) -> Bool {
        return type.processPayment(amount: amount)
    }
}

let processor = PaymentProcessor()
processor.processPayment(type: CreditCardProcessor(), amount: 200)

//LSP: Lischov Substituion Principle : child can replace parent
class BadBird {
    func fly(){
        print("assuming all bird can fly")
    }
}

class BadPenguin : BadBird {
    override func fly(){
        fatalError("Hey wait Penguins can't flyyyyy") //App getting crashed here
    }
}

func makeBadMove(bird: BadBird) {
    bird.fly() //BadPenguin will crash the app
}

protocol Bird {
    var name: String { get }
    func move()
}

protocol FlyingBird: Bird {
    func fly()
}

protocol SwimmingBird: Bird {
    func swim()
}

class Sparrow : FlyingBird {
    func fly() {
        print("Sparrow is flying")
    }

    var name: String  = "Sparrow"

    func move() {
        fly()
    }
}

class Penguin: SwimmingBird {
    func swim() {
        print("Penguin is swimming")
    }

    var name: String = "Penguin"

    func move() {
        swim()
    }
}

func makeMove(bird: Bird) {
    bird.move()
}

let sparrow = Sparrow()
let penguin = Penguin()

makeMove(bird: sparrow)
makeMove(bird: penguin)

// I : Interface Segregation
protocol BadWorker {
    func work()
    func sleep()
    func eat()
    func attendMeeting()
}

class Robot : BadWorker {
    func work() {
        print("Chitti is working")
    }

    func sleep() {
        // Chitti doesn't sleep
    }

    func eat() {
        // Chitti doesn't eat
    }

    func attendMeeting() {
        print("Chitti attends meetings")
    }
}

protocol Workable {
    func work()
}

protocol Eatable {
    func eat()
}

class SmartRobot: Workable {
    func work(){ print("Smart chitti is working") }
}

// Dependency Inversion
class BadUserViewModel {
    /*
     var service = UserService()
     var analytics = FirebaseAnalytics() -> Tight Coupling
     */
    func loadUsers() async {

    }
}

/* Correct way of using
 protocol UserServiceProtocol {
 func fetchUser(_ id : Int) async throws -> User
 }
 protocol AnlayticsProtocol {
 func track(event: String)
 }

 class UserService: UserServiceProtocol {
 func fetchUser(_ id : Int) async throws -> User {
 //real API call
 }
 }

 class MockUserService : UserServiceProtocol {
 var userToReturn = User(id:1, name: "Swapnil Dhiman", email:"")
 func fetchUser(_ id :Int) async throws -> User {
 return userToReturn
 }
 }

 class GoodUserViewModel {
 let userService : UserServiceProtocol
 let analyticsService : AnalyticsServiceProtocol
 init(service: UserServiceProtocol , analyticsService : AnalyticsServiceProtocol) {}
 func loadUser(id: Int) async {
 do {
 let user = try await userService.fetchUser(id:id)
 } catch {
 analyticsService.trackEvent("event failed")
 }
 }
 }

 let prodViewModel = GoodUserViewModel(service = UserService(), analytics: FirebaseAnalytics())
 */

//Type of initializers
// Designated init
class Parent {
    let parentVal : Int
    init(parentVal: Int) {
        self.parentVal = parentVal
    }
}

class Child: Parent {
    let childVal : Int
    init(childVal: Int, parentVal:Int) {
        self.childVal = childVal
        super.init(parentVal: parentVal)
    }
}

//Convenience init
class Pizza {
    var crust: String
    var size: String
    var toppings: [String]

    //Designated initializer
    init(crust: String, size: String, toppings: [String]) {
        self.crust = crust
        self.size = size
        self.toppings = toppings
    }

    //convenience init to make my work simpler by initializing few things by itself
    convenience init(size: String) {
        //Assuming rest it wants Margrehita
        self.init(crust: "Maida", size: size, toppings: ["Jalepeno","Olives"])
    }
}

//Required Init
// 👤 BASE CLASS - Defines the required initializer
class Person {
    var name: String
    var age: Int

    // ✅ REQUIRED - Every Person subclass MUST have this init
    required init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

// 👨‍🎓 SUBCLASS 1 - Must implement required init
class Student: Person {
    var studentID: String

    // ✅ REQUIRED - Must use "required", not "override"
    required init(name: String, age: Int) {
        self.studentID = "Unknown"  // Default value
        super.init(name: name, age: age)
    }

    // ✅ Can also have its own designated init
    init(name: String, age: Int, studentID: String) {
        self.studentID = studentID
        super.init(name: name, age: age)
    }
}

// 👨‍🏫 SUBCLASS 2 - Must also implement required init
class Teacher: Person {
    var subject: String

    // ✅ REQUIRED - Compiler forces us to implement this
    required init(name: String, age: Int) {
        self.subject = "General"  // Default value
        super.init(name: name, age: age)
    }
}

// Usage - Both can be created with the same init signature:
let student = Student(name: "John", age: 20)
let teacher = Teacher(name: "Prof. Smith", age: 45)

// This is useful for factory patterns:
func createPerson(type: Person.Type, name: String, age: Int) -> Person {
    return type.init(name: name, age: age)  // Works because of required!
}

let person1 = createPerson(type: Student.self, name: "Alice", age: 22)
let person2 = createPerson(type: Teacher.self, name: "Bob", age: 50)

print(person1)
print(person2)

//Failable init
struct Product {
    let id : String
    let price : Double

    init?(id: String, price: Double) {
        guard !id.isEmpty && price > 0 else {
            return nil
        }
        self.id = id
        self.price = price
    }
}

let invalidProduct = Product(id: "12", price: -123.23)
print(invalidProduct) //This is nil

// ✅ @autoclosure: Automatically wraps expression in closure

func log(_ message: ()->String) {
    print(message())
}
log {
    "Swapnil Dhiman"
}

func log(_ message: @autoclosure () -> String) {
    print(message())
}

log("Swapnil Dhiman testing autoclosure")

func expensiveComputation() -> String {
    print("Computing...")
    return "Result"
}

// Only evaluates if condition is true
func assert(_ condition: Bool, _ message: @autoclosure () -> String) {
    if !condition {
        print("Assertion failed: \(message())")  // Only called if false
    }
}

assert(true, expensiveComputation())   // "Computing..." NOT printed!
assert(false, expensiveComputation())  // "Computing..." printed

import Combine

let baseURL = "https://jsonplaceholder.typicode.com"

func fetchUsers() -> AnyPublisher<[User],Error> {
    guard let url = URL(string: "\(baseURL)/users") else {
        return Fail(error: UserError.invalidURL).eraseToAnyPublisher()
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST/PUT/GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    //    request.httpBody = try JSONEncoder().encode(Data())

    return URLSession.shared.dataTaskPublisher(for: url)
        .subscribe(on: DispatchQueue.global(qos: .userInitiated))
        .tryMap { data, response in
            guard let httpsResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpsResponse.statusCode) else {
                throw UserError.invalidResponse
            }
            return data
        }
        .decode(type: [User].self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}

// ----------------------------------------------------------
//MARK: Meesho Round 1 Interview Question
/*
 Data : json
 Question, Answer, Options, Priority
 Start With Priority X -> If answered incorrectly goes back to the priority which hasn't been answered previously and question in that priority should not be repeated unless and until all the questions of that priority has been shown once to the user
 If answered correctly -> Do this same thing but increase the priority by 1 in that case
 If X > 10 : Stop the Quiz
 */

//MARK: Meesho Round 2 Interview
/*
 Question 1:
 protocol SomeProtocol {
 }
 class SomeClass {
 weak var pr : SomeProtocol?
 }

 # 🎯 Excellent Interview Question: `weak` and Protocol Constraints

 This is a **fantastic** question because it tests deep understanding of Swift's type system, value types vs reference types, and memory management. Let me explain completely!

 ---

 ## 📝 Simple Explanation First

 **The Problem:**
 - `weak` can only be used with **class types** (reference types)
 - A protocol by default can be adopted by **both classes AND structs**
 - Structs are **value types** - they're copied, not referenced
 - You can't have a "weak reference" to something that's copied - it makes no sense!

 ```
 ┌─────────────────────────────────────────────────────────────┐
 │                    Why This Matters                         │
 ├─────────────────────────────────────────────────────────────┤
 │                                                             │
 │  Reference Type (Class):                                    │
 │  ┌─────────┐    ┌─────────┐                                │
 │  │Variable1│───▶│ Object  │◀───│Variable2│                 │
 │  └─────────┘    └─────────┘    └─────────┘                 │
 │       ↑                             ↑                       │
 │   Both point to SAME object in memory                       │
 │   weak makes sense - object can be deallocated              │
 │                                                             │
 │  Value Type (Struct):                                       │
 │  ┌─────────┐    ┌─────────┐                                │
 │  │Variable1│───▶│  Copy1  │                                │
 │  └─────────┘    └─────────┘                                │
 │  ┌─────────┐    ┌─────────┐                                │
 │  │Variable2│───▶│  Copy2  │  (Different copy!)             │
 │  └─────────┘    └─────────┘                                │
 │       ↑                                                     │
 │   Each variable has its OWN copy                            │
 │   weak makes NO sense - nothing to deallocate separately    │
 │                                                             │
 └─────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🔴 Your First Code - The Error

 ```swift
 protocol SomeProtocol {}

 class SomeClass {
 weak var pr: SomeProtocol?  // ❌ ERROR!
 }
 ```

 **Error:** `'weak' must not be applied to non-class-bound 'any SomeProtocol'`

 **Why?** Because `SomeProtocol` could be adopted by a struct:

 ```swift
 // This struct can conform to SomeProtocol
 struct SomeStruct: SomeProtocol {}

 // If allowed, what would this mean?
 let someClass = SomeClass()
 someClass.pr = SomeStruct()  // ❌ Can't have weak reference to a struct!
 ```

 ---

 ## ✅ The Solution: Constrain Protocol to Classes

 ```swift
 // ✅ Method 1: Use AnyObject constraint (Modern, preferred)
 protocol SomeProtocol: AnyObject {}

 class SomeClass {
 weak var pr: SomeProtocol?  // ✅ Works now!
 }

 // ✅ This works - classes can conform
 class MyClass: SomeProtocol {}

 // ❌ This is now an ERROR - structs cannot conform
 struct MyStruct: SomeProtocol {}  // Error: Non-class type cannot conform
 ```

 ---

 ## 🤔 Your Second Question: Why Do Delegates Usually Work?

 You're right to be confused! Let's look at your delegate example:

 ```swift
 protocol ActionDelegate {
 func didTap()
 }

 class ViewController: UIViewController {
 weak var delegate: ActionDelegate?  // 🤔 Does this work?

 func handleButtonTap() {
 delegate?.didTap()
 }
 }
 ```

 ### The Answer: **It depends on Swift version!**

 #### In Modern Swift (5.4+): This **SHOULD** produce an error!

 ```swift
 protocol ActionDelegate {
 func didTap()
 }

 class ViewController: UIViewController {
 weak var delegate: ActionDelegate?  // ❌ Error in Swift 5.4+
 // 'weak' must not be applied to non-class-bound 'any ActionDelegate'
 }
 ```

 #### Why It Sometimes "Works":

 1. **You're using `: AnyObject` without realizing it:**
 ```swift
 protocol ActionDelegate: AnyObject {  // ✅ Constrained to classes
 func didTap()
 }

 class ViewController: UIViewController {
 weak var delegate: ActionDelegate?  // ✅ Works!
 }
 ```
 ---

 ## 🎯 The Correct Way to Write Delegates

 ```swift
 // ✅ CORRECT: Class-constrained delegate protocol
 protocol ActionDelegate: AnyObject {
 func didTap()
 }

 class ParentViewController: UIViewController, ActionDelegate {
 let childVC = ChildViewController()

 override func viewDidLoad() {
 super.viewDidLoad()
 childVC.delegate = self  // ✅ Safe
 }

 func didTap() {
 print("Button was tapped!")
 }
 }

 class ChildViewController: UIViewController {
 // ✅ weak + AnyObject-constrained protocol = No retain cycle!
 weak var delegate: ActionDelegate?

 func handleButtonTap() {
 delegate?.didTap()
 }
 }
 ```

 ---

 ## 📊 Quick Reference Table

 | Protocol Type | Can Use `weak`? | Who Can Conform? |
 |--------------|-----------------|------------------|
 | `protocol P {}` | ❌ No | Classes + Structs + Enums |
 | `protocol P: AnyObject {}` | ✅ Yes | Classes only |
 | `protocol P: class {}` | ✅ Yes (deprecated) | Classes only |
 | `@objc protocol P {}` | ✅ Yes | Classes only (NSObject subclasses) |

 ---

 ## 💡 Interview Answer Summary

 > **Question:** "What's wrong with `weak var pr: SomeProtocol?`"
 >
 > **Answer:** "The protocol `SomeProtocol` is not constrained to class types. By default, protocols can be adopted by both classes and structs. Since `weak` references only work with reference types (classes), Swift requires the protocol to be marked with `: AnyObject` to guarantee only classes can conform. The fix is to declare `protocol SomeProtocol: AnyObject {}`"

 ---

 ## 🔑 Key Takeaways

 1. **`weak` only works with reference types (classes)**
 2. **Protocols can be adopted by value types (structs) by default**
 3. **Use `: AnyObject` to constrain protocol to classes only**
 4. **Delegate protocols should ALWAYS use `: AnyObject`**
 5. **`@objc` protocols are implicitly class-bound**

 This is a **senior-level question** that tests understanding of Swift's type system, memory management, and protocol semantics. Great question from Meesho! 🎉

 */
/*
 protocol SomeProtocol {}
 class SomeClass {
 var delegate : SomeProtocol?
 }
 struct SomeStruct : SomeProtocol {}
 let classC1 = SomeClass()
 let someStruct = SomeStruct()
 classC1.delegate = someStruct
 This is a NOT a compiler issue as strong can hold Struct
 */

/*
 protocol SomeProtocol {}
 struct SomeStruct : SomeProtocol {}
 var myStruct : SomeStruct? = SomeStruct()
 // This is okay
 */
/*

 If this
 protocol SomeProtocol {
 }
 class SomeClass {
 weak var pr : SomeProtocol?
 }

 Gives compile time error that protocol needs to be restricted to class only if you are using weak reference, then why does

 protocol SomeProtocol {}
 class SomeClass {
 var delegate : SomeProtocol?
 }

 Doesn't give any error, is here some STRONG reference type being happening, can STRONG reference be nullable does it not have any issue here of being SomeProtocol, like will it increase ARC or it doesn't make sense of having ARC of protocol, everything is being getting tangled up and having complete confusion.

 Also when exactly an arc increases does it increase var classC2 = classC1 or does it increase var classC2 : Class ? at that time also

 # 🎯 Great Question! Let's Untangle This Completely

 This is a **deep** question about how Swift handles protocols, memory, and ARC. Let me explain step-by-step with visuals!

 ---

 ## 📝 The Core Confusion

 You're asking: **"If weak reference needs class constraint, why doesn't strong reference need it too?"**

 Let me explain why this makes sense:

 ---

 ## 🔑 Key Insight: Strong References Work Differently!

 ```swift
 protocol SomeProtocol {}

 class SomeClass {
 var delegate: SomeProtocol?  // ✅ This works! No error
 }
 ```

 **Why no error?** Because a **strong reference doesn't care** if it holds a class or a struct!

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │            STRONG vs WEAK - The Fundamental Difference          │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                  │
 │  STRONG REFERENCE (var):                                         │
 │  ┌─────────────────────────────────────────────────────────┐    │
 │  │ "I will HOLD this value and keep it alive"              │    │
 │  │                                                          │    │
 │  │  If it's a CLASS → I increment retain count             │    │
 │  │  If it's a STRUCT → I make a copy (no ARC involved)     │    │
 │  │                                                          │    │
 │  │  ✅ Works with BOTH! No problem!                        │    │
 │  └─────────────────────────────────────────────────────────┘    │
 │                                                                  │
 │  WEAK REFERENCE (weak var):                                      │
 │  ┌─────────────────────────────────────────────────────────┐    │
 │  │ "I will OBSERVE this value but NOT keep it alive"       │    │
 │  │ "When it's deallocated, make me nil"                     │    │
 │  │                                                          │    │
 │  │  If it's a CLASS → I watch for deallocation ✅          │    │
 │  │  If it's a STRUCT → ??? Structs don't deallocate! ❌    │    │
 │  │                                                          │    │
 │  │  ❌ Only works with CLASSES!                             │    │
 │  └─────────────────────────────────────────────────────────┘    │
 │                                                                  │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🧪 Let's Prove This with Code

 ```swift
 protocol SomeProtocol {}

 // A class conforming to protocol
 class MyClass: SomeProtocol {
 deinit { print("MyClass deallocated") }
 }

 // A struct conforming to protocol
 struct MyStruct: SomeProtocol {}

 class Container {
 var delegate: SomeProtocol?  // Strong reference
 }

 // SCENARIO 1: Assign a CLASS
 let container1 = Container()
 container1.delegate = MyClass()
 // ✅ Works! ARC keeps MyClass alive (retain count = 1)

 // SCENARIO 2: Assign a STRUCT
 let container2 = Container()
 container2.delegate = MyStruct()
 // ✅ Works! Struct is COPIED into the variable (no ARC)
 ```

 ### What Happens Internally:

 ```swift
 // When you assign a CLASS to SomeProtocol?
 container1.delegate = MyClass()

 // Internally, Swift wraps it in an "existential container":
 // ┌────────────────────────────────────┐
 // │   Existential Container            │
 // │   ┌──────────────────────────────┐ │
 // │   │ Type: MyClass                │ │
 // │   │ Value: [reference to object] │ │ → ARC count +1
 // │   └──────────────────────────────┘ │
 // └────────────────────────────────────┘

 // When you assign a STRUCT to SomeProtocol?
 container2.delegate = MyStruct()

 // Internally:
 // ┌────────────────────────────────────┐
 // │   Existential Container            │
 // │   ┌──────────────────────────────┐ │
 // │   │ Type: MyStruct               │ │
 // │   │ Value: [copy of struct data] │ │ → NO ARC (it's a copy!)
 // │   └──────────────────────────────┘ │
 // └────────────────────────────────────┘
 ```

 ---

 ## 🔴 Now Why Does `weak` Fail?

 ```swift
 protocol SomeProtocol {}

 class Container {
 weak var delegate: SomeProtocol?  // ❌ Error!
 }
 ```

 **The problem:**

 ```swift
 // If Swift allowed this...
 let container = Container()

 // And you assigned a STRUCT:
 container.delegate = MyStruct()

 // What should happen when "MyStruct" goes out of scope?
 // - Structs don't have lifecycle! They're copied!
 // - There's no "deallocation" to watch for!
 // - "weak" becomes MEANINGLESS!

 // Swift says: "I can't guarantee this protocol is a class,
 //             so I can't let you use 'weak' here!"
 ```

 ---

 ## 📊 ARC: When Does Retain Count Change?

 Now let's answer your second question directly:

 ```swift
 class MyClass {
 var name = "Test"
 deinit { print("Deallocated!") }
 }
 ```

 ### When ARC Count Increases:

 ```swift
 // 1️⃣ DECLARATION - Does NOT increase ARC!
 var classC2: MyClass?
 // ARC count: N/A (nothing assigned yet)

 // 2️⃣ CREATION - Increases ARC to 1
 var classC1 = MyClass()
 // ARC count: 1 (classC1 holds a strong reference)

 // 3️⃣ ASSIGNMENT - Increases ARC!
 classC2 = classC1
 // ARC count: 2 (both classC1 and classC2 point to same object)

 // 4️⃣ ANOTHER ASSIGNMENT - Increases ARC!
 var classC3 = classC1
 // ARC count: 3

 // 5️⃣ Setting to nil - Decreases ARC
 classC1 = nil
 // ARC count: 2 (only classC2 and classC3 now)

 classC2 = nil
 // ARC count: 1 (only classC3 now)

 classC3 = nil
 // ARC count: 0 → "Deallocated!" prints
 ```

 ### Visual Timeline:

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    ARC Count Changes                            │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   var c1: MyClass?              ARC: N/A (just a declaration)  │
 │            ↓                                                    │
 │   c1 = MyClass()               ARC: 1 ← Object created         │
 │            ↓                                                    │
 │   var c2 = c1                  ARC: 2 ← New strong reference   │
 │            ↓                                                    │
 │   var c3 = c1                  ARC: 3 ← Another strong ref     │
 │            ↓                                                    │
 │   c1 = nil                     ARC: 2 ← c1 released            │
 │            ↓                                                    │
 │   c2 = nil                     ARC: 1 ← c2 released            │
 │            ↓                                                    │
 │   c3 = nil                     ARC: 0 ← DEALLOCATED! 💥        │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🧪 Let's Test ARC with Protocol

 ```swift
 protocol SomeProtocol {}

 class MyClass: SomeProtocol {
 deinit { print("MyClass deallocated") }
 }

 struct MyStruct: SomeProtocol {}

 class Container {
 var delegate: SomeProtocol?  // Strong reference
 }

 // EXAMPLE 1: Class through protocol (ARC applies)
 func testClassThroughProtocol() {
 let container = Container()

 var myClass: MyClass? = MyClass()
 print("1. MyClass created")

 container.delegate = myClass  // ARC increases!
 print("2. Assigned to delegate")

 myClass = nil  // ARC decreases, but delegate still holds it!
 print("3. myClass set to nil, but object still alive")

 // Object is still alive because container.delegate holds it!
 print("4. Delegate is nil? \(container.delegate == nil)")  // false
 }

 testClassThroughProtocol()
 // Prints:
 // 1. MyClass created
 // 2. Assigned to delegate
 // 3. myClass set to nil, but object still alive
 // 4. Delegate is nil? false
 // MyClass deallocated (when container goes out of scope)


 // EXAMPLE 2: Struct through protocol (NO ARC)
 func testStructThroughProtocol() {
 let container = Container()

 var myStruct = MyStruct()
 print("1. MyStruct created (stack)")

 container.delegate = myStruct  // COPY made, no ARC!
 print("2. Assigned to delegate (copied)")

 // myStruct and container.delegate are INDEPENDENT copies!
 }

 testStructThroughProtocol()
 // No "deallocated" message - structs don't have deinit!
 ```

 ---

 ## 🎯 The Key Mental Model

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                 Protocol Type Storage                           │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   var delegate: SomeProtocol?                                   │
 │                                                                 │
 │   Swift creates an "Existential Container" that can hold:      │
 │                                                                 │
 │   ┌───────────────────────────────────────┐                    │
 │   │  If CLASS assigned:                   │                    │
 │   │  ┌───────────────────────────────────┐│                    │
 │   │  │ Type Metadata: MyClass            ││                    │
 │   │  │ Value: POINTER to heap object     ││→ ARC managed!     │
 │   │  │ Witness Tables: protocol methods  ││                    │
 │   │  └───────────────────────────────────┘│                    │
 │   └───────────────────────────────────────┘                    │
 │                                                                 │
 │   ┌───────────────────────────────────────┐                    │
 │   │  If STRUCT assigned:                  │                    │
 │   │  ┌───────────────────────────────────┐│                    │
 │   │  │ Type Metadata: MyStruct           ││                    │
 │   │  │ Value: INLINE copy (or heap if big)││→ NO ARC!         │
 │   │  │ Witness Tables: protocol methods  ││                    │
 │   │  └───────────────────────────────────┘│                    │
 │   └───────────────────────────────────────┘                    │
 │                                                                 │
 │   Swift handles both cases transparently!                       │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 📋 Summary Table

 | Code | What Happens | ARC Involved? |
 |------|--------------|---------------|
 | `var c: MyClass?` | Just declaration | ❌ No |
 | `c = MyClass()` | Object created | ✅ Yes (+1) |
 | `c2 = c` | New strong reference | ✅ Yes (+1) |
 | `c = nil` | Reference removed | ✅ Yes (-1) |
 | `var p: SomeProtocol? = MyClass()` | Class in protocol | ✅ Yes (+1) |
 | `var p: SomeProtocol? = MyStruct()` | Struct copied | ❌ No |
 | `weak var p: SomeProtocol?` | Compiler error! | N/A |
 | `weak var p: SomeProtocol?` (with `: AnyObject`) | Works, class only | ✅ Yes (weak ref) |

 ---

 ## 🔑 Key Takeaways
 */

//MARK: Question 2
/*
 Next question that was asked to me was What are the issues you feel could be in this code snippet

 class UserProfile {
 func getUserProfileData(_ completion: (String)-> Void){
 self.getDataFromAPI() { (name: String) in
 completion(name)
 }
 }
 }

 What I was thinking :
 1. getDataFromAPI() would be an async call thus getUserProfileData would become finish it scope before executing this completion() thus it needs to be an escaping closure.
 2. Now I was confused to add [weak self] in closure of getDataFromAPI() because this completion has been passed as an argument, now is this stored by UserProfile or not , should I check here guard let self = self else return {nil} and then completion(name), because am I saying that when getDataFromAPI() has done it's work UserProfile.self has a strong reference to completion(name) and completion(name) has strong reference to Self, which will cause memory leak if self gets out, so let's have it as weak and then check if UserProfile(parent) exists which holds this completionHandler before calling completionHandler() ? Been confused like who has exactly been storing this CompletionHandler() when getUserProfileData has been out of scope and getDataFromAPI() is working to fetch the data ?
 3. Also was thinking could I have stored this completionHandler in global variable of UserProfile would that have been answer or would be totally irrelevant
 4. Ofcourse error handling could be done using Result<String,Error>

 An add on question was asked like how does compiler actually allows that if we wrote just
 func getUserProfileData(_ completion: ((String)->Void)?){
 self.getDataFromAPI(){ (name: String) in completion?(name)
 }

 At this point of time why it is not saying it needs an escaping closure, what would happen here nil being called or how would this act now ?
 */
/*
 //MARK: Answer2
 # 🎯 Excellent Interview Question! Let's Break It Down Completely

 This question tests **deep understanding** of closures, escaping, memory management, and Swift's type system. Let me address each point!

 ---

 ## 📝 The Original Code

 ```swift
 class UserProfile {
 func getUserProfileData(_ completion: (String) -> Void) {
 self.getDataFromAPI { (name: String) in
 completion(name)
 }
 }
 }
 ```

 ---

 ## 🔴 Issue 1: Missing `@escaping`

 **You were correct!** If `getDataFromAPI` is asynchronous, the completion closure will be called AFTER `getUserProfileData` returns. This means the closure "escapes" the function scope.

 ```swift
 // ❌ This won't compile if getDataFromAPI is async
 func getUserProfileData(_ completion: (String) -> Void) {
 self.getDataFromAPI { (name: String) in
 completion(name)  // Called LATER, after function returns
 }
 }

 // ✅ CORRECT: Mark as @escaping
 func getUserProfileData(_ completion: @escaping (String) -> Void) {
 self.getDataFromAPI { (name: String) in
 completion(name)
 }
 }
 ```

 ### What Does @escaping Mean?

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                  @escaping vs Non-Escaping                      │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  NON-ESCAPING (default):                                        │
 │  ┌────────────────────────────────────────┐                    │
 │  │ func doSomething(closure: () -> Void)  │                    │
 │  │   closure()  // Called NOW, during function execution       │
 │  │ } // function returns, closure is gone                      │
 │  └────────────────────────────────────────┘                    │
 │                                                                 │
 │  @ESCAPING:                                                     │
 │  ┌────────────────────────────────────────┐                    │
 │  │ func doSomething(closure: @escaping () -> Void)             │
 │  │   someAsyncWork {                      │                    │
 │  │     closure()  // Called LATER!        │                    │
 │  │   }                                    │                    │
 │  │ } // function returns, but closure still exists somewhere   │
 │  └────────────────────────────────────────┘                    │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🔴 Issue 2: Memory & `[weak self]` - Let's Untangle This!

 This is where you were confused. Let me explain **exactly** who stores what:

 ### The Chain of Ownership

 ```swift
 class UserProfile {
 func getUserProfileData(_ completion: @escaping (String) -> Void) {
 self.getDataFromAPI { (name: String) in  // CLOSURE A
 completion(name)
 }
 }

 func getDataFromAPI(_ callback: @escaping (String) -> Void) {
 // This callback is stored somewhere (URLSession, DispatchQueue, etc.)
 DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
 callback("John")  // Called 2 seconds later
 }
 }
 }
 ```

 ### Who Stores What?

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    CLOSURE STORAGE CHAIN                        │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   Caller                                                        │
 │     │                                                           │
 │     │ calls getUserProfileData(completion)                     │
 │     │                                                           │
 │     ▼                                                           │
 │   getUserProfileData {                                          │
 │     │                                                           │
 │     │ self.getDataFromAPI { name in  ← CLOSURE A               │
 │     │     completion(name)           │                          │
 │     │ }                              │                          │
 │     │                                │                          │
 │     │          CLOSURE A captures:   │                          │
 │     │          - completion (the parameter)                     │
 │     │                                │                          │
 │     │          Does NOT capture self! │                          │
 │     │          (we're not using self in CLOSURE A)              │
 │     │                                │                          │
 │     ▼                                │                          │
 │   getDataFromAPI {                   │                          │
 │     │                                │                          │
 │     │  STORES closure in:            │                          │
 │     │  - DispatchQueue               │                          │
 │     │  - URLSession                  │                          │
 │     │  - some async mechanism        │                          │
 │     │                                │                          │
 │     │  This keeps CLOSURE A alive!   │                          │
 │     │                                                           │
 │     ▼                                                           │
 │   Later... callback is called                                   │
 │     completion("John") executes                                 │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### Do We Need `[weak self]`?

 **In THIS specific code - NO!** Because `self` is not captured!

 ```swift
 class UserProfile {
 func getUserProfileData(_ completion: @escaping (String) -> Void) {
 // ✅ self is NOT captured in this closure
 // The closure only captures 'completion', not 'self'
 self.getDataFromAPI { (name: String) in
 completion(name)  // No 'self' reference here!
 }
 }
 }
 ```

 ### When WOULD We Need `[weak self]`?

 ```swift
 class UserProfile {
 var userName: String = ""

 func getUserProfileData(_ completion: @escaping (String) -> Void) {
 self.getDataFromAPI { (name: String) in
 // ⚠️ NOW we're using self!
 self.userName = name  // Capturing self strongly!
 completion(name)
 }
 }
 }
 ```

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    RETAIN CYCLE SCENARIO                        │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   If we store the completion in UserProfile:                    │
 │                                                                 │
 │   class UserProfile {                                           │
 │       var savedCompletion: ((String) -> Void)?  // ⚠️ Stored!  │
 │                                                                 │
 │       func setup() {                                            │
 │           savedCompletion = { [self] in  // ❌ Strong capture   │
 │               print(self.userName)       // self → closure      │
 │           }                              // closure → self?     │
 │       }                                  // via savedCompletion │
 │   }                                                             │
 │                                                                 │
 │   UserProfile ←───────────────→ Closure                         │
 │       │                            │                            │
 │       │ savedCompletion (strong)   │ captures self (strong)    │
 │       │                            │                            │
 │       └────────── RETAIN CYCLE! ───┘                            │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### The CORRECT Approach for Your Code:

 ```swift
 class UserProfile {
 var userName: String = ""

 func getUserProfileData(_ completion: @escaping (String) -> Void) {
 // ✅ [weak self] because we use self inside
 self.getDataFromAPI { [weak self] (name: String) in
 guard let self = self else {
 return  // UserProfile was deallocated, don't call completion
 }

 self.userName = name  // Safe now
 completion(name)
 }
 }
 }
 ```

 ---

 ## 🔴 Issue 3: Storing Completion in Global Variable

 You asked: "Could I store completion in a global variable of UserProfile?"

 ```swift
 class UserProfile {
 // ⚠️ Storing closure as property
 var pendingCompletion: ((String) -> Void)?

 func getUserProfileData(_ completion: @escaping (String) -> Void) {
 self.pendingCompletion = completion  // Store it

 self.getDataFromAPI { [weak self] (name: String) in
 self?.pendingCompletion?(name)
 self?.pendingCompletion = nil  // Clear after use
 }
 }
 }
 ```

 **This works BUT creates potential retain cycle if completion captures self!**

 ```swift
 // Caller code
 class ViewController: UIViewController {
 let userProfile = UserProfile()

 func loadProfile() {
 userProfile.getUserProfileData { [weak self] name in
 // If we used strong self here and userProfile stores this...
 // We might have issues!
 self?.nameLabel.text = name
 }
 }
 }
 ```

 **Generally, DON'T store completion handlers unless necessary.** Pass them through the chain.

 ---

 ## 🔴 Issue 4: Error Handling with Result

 **Yes, you're correct!** Production code should handle errors:

 ```swift
 class UserProfile {
 func getUserProfileData(_ completion: @escaping (Result<String, Error>) -> Void) {
 self.getDataFromAPI { result in
 completion(result)
 }
 }

 private func getDataFromAPI(_ callback: @escaping (Result<String, Error>) -> Void) {
 URLSession.shared.dataTask(with: url) { data, response, error in
 if let error = error {
 callback(.failure(error))
 return
 }

 guard let data = data,
 let name = String(data: data, encoding: .utf8) else {
 callback(.failure(NetworkError.invalidData))
 return
 }

 callback(.success(name))
 }.resume()
 }
 }
 ```

 ---

 ## 🎯 The Add-On Question: Optional Closures

 **This is a GREAT question!**

 ```swift
 // ❌ This requires @escaping
 func getUserProfileData(_ completion: (String) -> Void) {
 // Error if used in async context
 }

 // ✅ This works WITHOUT @escaping!
 func getUserProfileData(_ completion: ((String) -> Void)?) {
 self.getDataFromAPI { (name: String) in
 completion?(name)  // No @escaping needed!
 }
 }
 ```

 ### Why Does Optional Closure Not Need @escaping?

 **Because Optional is an enum that WRAPS the closure!**

 ```swift
 // What Optional<(String) -> Void> really is:
 enum Optional<Wrapped> {
 case none
 case some(Wrapped)  // ← The closure is stored HERE
 }
 ```

 When you make something Optional, you're **already storing it** in the enum case. This means:

 1. The closure is already being "boxed" in a container
 2. Optionals are **always stored on the heap** (when they contain closures)
 3. This storage implies escaping!

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │            Why Optional Closures Are Implicitly Escaping        │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   NON-OPTIONAL CLOSURE:                                         │
 │   func doWork(closure: () -> Void)                              │
 │                                                                 │
 │   Compiler: "This closure might be used inline only.            │
 │              I'll assume non-escaping for optimization.         │
 │              Tell me explicitly if it escapes!"                 │
 │                                                                 │
 │   ─────────────────────────────────────────────────────────────│
 │                                                                 │
 │   OPTIONAL CLOSURE:                                             │
 │   func doWork(closure: (() -> Void)?)                           │
 │                                                                 │
 │   Compiler: "This is wrapped in Optional.                       │
 │              ┌──────────────────────────────┐                  │
 │              │ Optional<() -> Void>         │                  │
 │              │ ┌──────────────────────────┐ │                  │
 │              │ │ .some(closure)           │ │ ← STORED!       │
 │              │ │ The closure is stored in │ │                  │
 │              │ │ the Optional container   │ │                  │
 │              │ └──────────────────────────┘ │                  │
 │              └──────────────────────────────┘                  │
 │              It's already being stored, so it's escaping!"     │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### Is Optional Closure an Alternative to @escaping?

 **Technically yes, but with trade-offs:**

 ```swift
 // Approach 1: @escaping (Explicit, preferred)
 func method1(_ completion: @escaping (String) -> Void) {
 async {
 completion("done")
 }
 }

 // Approach 2: Optional (Implicit escaping)
 func method2(_ completion: ((String) -> Void)?) {
 async {
 completion?("done")  // Must use optional chaining
 }
 }
 ```

 | Approach | Pros | Cons |
 |----------|------|------|
 | `@escaping` | Explicit intent, clear to readers | Must add keyword |
 | `Optional` | No keyword needed | Hides escaping nature, requires `?` everywhere |

 **Best Practice:** Use `@escaping` for clarity. Use `Optional` only when the closure truly might not be provided.

 ---

 ## ✅ The Complete Corrected Code

 ```swift
 class UserProfile {

 // ✅ Error handling with Result
 // ✅ @escaping for async closure
 func getUserProfileData(_ completion: @escaping (Result<String, Error>) -> Void) {
 // ✅ [weak self] because we might use self inside
 self.getDataFromAPI { [weak self] result in
 guard let self = self else {
 // UserProfile deallocated, still call completion with error
 completion(.failure(UserProfileError.deallocated))
 return
 }

 // Can safely use self here if needed
 completion(result)
 }
 }

 private func getDataFromAPI(_ callback: @escaping (Result<String, Error>) -> Void) {
 DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
 // Simulate API response
 callback(.success("John Doe"))
 }
 }
 }

 enum UserProfileError: Error {
 case deallocated
 case networkError
 }

 // Usage:
 let profile = UserProfile()
 profile.getUserProfileData { result in
 switch result {
 case .success(let name):
 print("Got name: \(name)")
 case .failure(let error):
 print("Error: \(error)")
 }
 }
 ```

 ---

 ## 📋 Summary of All Issues

 | Issue | Problem | Solution |
 |-------|---------|----------|
 | 1. Missing `@escaping` | Closure used after function returns | Add `@escaping` |
 | 2. `[weak self]` | Potential retain cycle if self is used | Add `[weak self]` when capturing self |
 | 3. Stored completion | Could cause retain if caller captures self | Be careful, usually pass-through is better |
 | 4. No error handling | Can't handle failures | Use `Result<Success, Error>` |
 | 5. Optional closure | Works without `@escaping` | Implicit, but hides intent |

 ---

 ## 🔑 Key Takeaways

 1. **`@escaping`** is needed when closure outlives the function call
 2. **`[weak self]`** is needed when `self` is captured AND stored in an escaping closure
 3. **Optional closures are implicitly escaping** because they're wrapped in Optional enum
 4. **The closure is stored by whatever async mechanism runs it** (DispatchQueue, URLSession, etc.)
 5. **Completion handlers should use `Result` type** for proper error handling

 This is an excellent senior-level question that tests deep understanding of Swift's closure semantics! 🎉
 */

//MARK: Question 3
/*
 func doSomething(){
 DispatchQueue.main.async {
 printOnMainQueue()
 }
 }
 func printOnMainQueue() {
 DispatchQueue.main.sync {
 print("Swapnil")
 }
 }
 doSomething()
 //MARK: Answer 3
 //DEADLOCK
 */

/*
 //MARK: Question 4
 func doSomething(){
 DispatchQueue.global().async {
 printOnMainQueue()
 }
 }
 func printOnMainQueue() {
 DispatchQueue.main.sync {
 print("Swapnil")
 }
 }
 doSomething()
 //MARK: Answer 4
 //No Issues
 */

//MARK: Question 5
/*
 class MyClass {}
 let c1 = MyClass()
 let c2 = c1
 let c3 = c2
 weak var c4 = c2
 let c5 = c3
 //Question: Value of Reference Count , Number of objects

 struct MyStruct {}
 let s1 = MyStruct()
 let s2 = s1
 let s3 = s2
 weak var s4 = s2
 let s5 = s4
 //Question: Value of Reference Count, Number of objects (assuming that if weak var s4 = s2 , line isn't there)
 */
//MARK: Answer 5
/*
 # 🎯 Class vs Struct: Reference Count & Objects

 Let me break this down step-by-step with visuals!

 ---

 ## 📦 Part 1: CLASS (Reference Type)

 ```swift
 class MyClass {}
 let c1 = MyClass()
 let c2 = c1
 let c3 = c2
 weak var c4 = c2
 let c5 = c3
 ```

 ### Step-by-Step Analysis:

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │              CLASS - Reference Type Analysis                    │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  let c1 = MyClass()                                            │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    c1 ─────────▶ [ MyClass Object ]  │                       │
 │  │                    (on HEAP)         │                       │
 │  │                                      │                       │
 │  │    Objects: 1                        │                       │
 │  │    Strong References: 1 (c1)         │                       │
 │  │    ARC Count: 1                      │                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 │  let c2 = c1   (COPIES THE REFERENCE, not the object!)         │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    c1 ─────────┐                     │                       │
 │  │                ▼                     │                       │
 │  │            [ MyClass Object ]        │                       │
 │  │                ▲                     │                       │
 │  │    c2 ─────────┘                     │                       │
 │  │                                      │                       │
 │  │    Objects: 1                        │                       │
 │  │    Strong References: 2 (c1, c2)     │                       │
 │  │    ARC Count: 2                      │                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 │  let c3 = c2                                                   │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    c1 ─────────┐                     │                       │
 │  │                │                     │                       │
 │  │    c2 ─────────┼────▶ [ MyClass ]    │                       │
 │  │                │                     │                       │
 │  │    c3 ─────────┘                     │                       │
 │  │                                      │                       │
 │  │    Objects: 1                        │                       │
 │  │    Strong References: 3              │                       │
 │  │    ARC Count: 3                      │                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 │  weak var c4 = c2   (WEAK = doesn't increase count!)           │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    c1 ═════════╗                     │                       │
 │  │                ║                     │                       │
 │  │    c2 ═════════╬════▶ [ MyClass ]    │  ═══ = strong        │
 │  │                ║                     │  ─ ─ = weak          │
 │  │    c3 ═════════╝        ▲            │                       │
 │  │                         │            │                       │
 │  │    c4 ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘            │                       │
 │  │                                      │                       │
 │  │    Objects: 1                        │                       │
 │  │    Strong References: 3 (c1,c2,c3)   │                       │
 │  │    Weak References: 1 (c4)           │                       │
 │  │    ARC Count: 3 (weak doesn't count!)│                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 │  let c5 = c3                                                   │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    c1 ═══╗                           │                       │
 │  │          ║                           │                       │
 │  │    c2 ═══╬═══╗                       │                       │
 │  │          ║   ║                       │                       │
 │  │    c3 ═══╝   ╠════▶ [ MyClass ]      │                       │
 │  │              ║            ▲          │                       │
 │  │    c5 ═══════╝            │          │                       │
 │  │                           │          │                       │
 │  │    c4 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘          │                       │
 │  │                                      │                       │
 │  │    Objects: 1                        │                       │
 │  │    Strong References: 4 (c1,c2,c3,c5)│                       │
 │  │    Weak References: 1 (c4)           │                       │
 │  │    ARC Count: 4                      │                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### ✅ CLASS Final Answer:

 | Question | Answer |
 |----------|--------|
 | **Number of Objects** | **1** (only one object created on heap) |
 | **Strong Reference Count (ARC)** | **4** (c1, c2, c3, c5) |
 | **Weak Reference Count** | **1** (c4) - doesn't increase ARC |
 | **Total Variables** | **5** (c1, c2, c3, c4, c5) |

 ---

 ## 📦 Part 2: STRUCT (Value Type)

 ```swift
 struct MyStruct {}
 let s1 = MyStruct()
 let s2 = s1
 let s3 = s2
 weak var s4 = s2    // ❌ COMPILE ERROR!
 let s5 = s4         // ❌ Won't work
 ```

 ### ⚠️ IMPORTANT: `weak var s4 = s2` is a COMPILE ERROR!

 ```swift
 // This will not compile!
 weak var s4 = s2
 // Error: 'weak' may only be applied to class and class-bound protocol types, not 'MyStruct'
 ```

 **Why?** Because:
 - `weak` only works with **reference types (classes)**
 - Structs are **value types** - they're copied, not referenced
 - You can't have a "weak reference" to something that doesn't have a reference!

 ### Step-by-Step Analysis (without the weak line):

 ```swift
 struct MyStruct {}
 let s1 = MyStruct()
 let s2 = s1
 let s3 = s2
 let s5 = s3   // Assuming s5 = s3 instead
 ```

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │              STRUCT - Value Type Analysis                       │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  let s1 = MyStruct()                                           │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    s1 ─────────▶ [ MyStruct Copy 1 ] │  (on STACK)          │
 │  │                                      │                       │
 │  │    Objects (copies): 1               │                       │
 │  │    ARC Count: N/A (no ARC for structs!)                     │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 │  let s2 = s1   (CREATES A NEW COPY!)                           │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    s1 ─────────▶ [ MyStruct Copy 1 ] │                       │
 │  │                                      │                       │
 │  │    s2 ─────────▶ [ MyStruct Copy 2 ] │  ← NEW copy!         │
 │  │                                      │                       │
 │  │    Objects (copies): 2               │                       │
 │  │    ARC Count: N/A                    │                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 │  let s3 = s2   (CREATES ANOTHER COPY!)                         │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    s1 ─────────▶ [ MyStruct Copy 1 ] │                       │
 │  │                                      │                       │
 │  │    s2 ─────────▶ [ MyStruct Copy 2 ] │                       │
 │  │                                      │                       │
 │  │    s3 ─────────▶ [ MyStruct Copy 3 ] │  ← NEW copy!         │
 │  │                                      │                       │
 │  │    Objects (copies): 3               │                       │
 │  │    ARC Count: N/A                    │                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 │  let s5 = s3   (CREATES ANOTHER COPY!)                         │
 │  ┌─────────────────────────────────────┐                       │
 │  │                                      │                       │
 │  │    s1 ─────────▶ [ MyStruct Copy 1 ] │                       │
 │  │                                      │                       │
 │  │    s2 ─────────▶ [ MyStruct Copy 2 ] │                       │
 │  │                                      │                       │
 │  │    s3 ─────────▶ [ MyStruct Copy 3 ] │                       │
 │  │                                      │                       │
 │  │    s5 ─────────▶ [ MyStruct Copy 4 ] │  ← NEW copy!         │
 │  │                                      │                       │
 │  │    Objects (copies): 4               │                       │
 │  │    ARC Count: N/A (not applicable)   │                       │
 │  │                                      │                       │
 │  └─────────────────────────────────────┘                       │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### ✅ STRUCT Final Answer:

 | Question | Answer |
 |----------|--------|
 | **Number of Objects (copies)** | **4** (s1, s2, s3, s5 - each is a separate copy!) |
 | **Reference Count (ARC)** | **N/A** (ARC doesn't apply to value types) |
 | **Can use `weak`?** | **NO** - compile error! |

 ---

 ## 📊 Complete Comparison

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    CLASS vs STRUCT Summary                      │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │                     CLASS                  STRUCT               │
 │                   ───────                ────────               │
 │                                                                 │
 │  Type:           Reference Type          Value Type            │
 │                                                                 │
 │  Storage:        Heap                    Stack (usually)       │
 │                                                                 │
 │  Assignment:     Copies REFERENCE        Copies VALUE          │
 │                  (same object)           (new copy)            │
 │                                                                 │
 │  After 5 vars:   1 object, 4 refs       4 independent copies   │
 │                                                                 │
 │  ARC applies?    YES                     NO                    │
 │                                                                 │
 │  Can use weak?   YES                     NO (compile error)    │
 │                                                                 │
 │  Memory:         ┌───┐                   ┌───┐ ┌───┐ ┌───┐    │
 │                  │OBJ│ ← all point here  │ 1 │ │ 2 │ │ 3 │    │
 │                  └───┘                   └───┘ └───┘ └───┘    │
 │                                          separate copies       │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🧪 Prove It With Code

 ```swift
 class MyClass {
 let id = UUID()
 deinit { print("MyClass \(id) deallocated") }
 }

 struct MyStruct {
 let id = UUID()
 }

 // CLASS TEST
 print("=== CLASS ===")
 let c1 = MyClass()
 let c2 = c1
 let c3 = c2
 weak var c4 = c2
 let c5 = c3

 print("c1.id: \(c1.id)")
 print("c2.id: \(c2.id)")
 print("c3.id: \(c3.id)")
 print("c4?.id: \(c4?.id)")
 print("c5.id: \(c5.id)")
 print("All same ID? \(c1.id == c2.id && c2.id == c3.id && c3.id == c5.id)")  // true

 // Check if same object using ===
 print("c1 === c2: \(c1 === c2)")  // true
 print("c1 === c5: \(c1 === c5)")  // true

 // STRUCT TEST
 print("\n=== STRUCT ===")
 let s1 = MyStruct()
 let s2 = s1
 let s3 = s2
 // weak var s4 = s2  // ❌ Uncomment to see error!
 let s5 = s3

 print("s1.id: \(s1.id)")
 print("s2.id: \(s2.id)")
 print("s3.id: \(s3.id)")
 print("s5.id: \(s5.id)")
 print("All same ID? \(s1.id == s2.id)")  // false - different copies!

 // Output Example:
 // === CLASS ===
 // c1.id: ABC-123
 // c2.id: ABC-123
 // c3.id: ABC-123
 // c4?.id: ABC-123
 // c5.id: ABC-123
 // All same ID? true
 // c1 === c2: true
 // c1 === c5: true
 //
 // === STRUCT ===
 // s1.id: DEF-456
 // s2.id: GHI-789  ← Different! It's a copy!
 // s3.id: JKL-012  ← Different! Another copy!
 // s5.id: MNO-345  ← Different! Another copy!
 // All same ID? false
 ```

 ---

 ## 🔑 Interview Answer

 > **For CLASS:**
 > - **Objects:** 1 (single object on heap)
 > - **Strong Reference Count:** 4 (c1, c2, c3, c5)
 > - **Weak References:** 1 (c4) - doesn't increase ARC
 >
 > **For STRUCT:**
 > - `weak var s4 = s2` is a **compile error** - can't use weak with value types
 > - **Objects (copies):** 4 (each assignment creates a new copy)
 > - **Reference Count:** N/A - ARC doesn't apply to value types

 This is a fantastic question that tests understanding of Swift's fundamental type system! 🎉
 */

//MARK: Question 6
/*
 Next question was :

 class SomeClass {
 var value : Int = 10
 let anotherClass = AnotherClass()
 }
 class AnotherClass {
 var name: String = "Swapnil"
 }
 var sClass = SomeClass()
 var randomNum: Int = 5
 let closure : () -> Void = { [sClass, randomNum] in
 print(sClass.value)
 print(sClass.anotherClass.name)
 print(randomNum)
 }
 randomNum = 6
 sClass.value = 12
 sClass.anotherClass.name = "Swapnil new"
 closure()

 What will get printed here I thought the answer would be
 12
 Swapnil new
 6

 Because my thinking was that closure captures the reference types and not the value types thus it would have the latest value of this randomNum as well as the class properties but now when I am running it the compiler is printing

 12
 Swapnil new
 5

 This is really confusing for me to understand, also [sClass, randomNum] compiler was showing sClass async, randomNum async, what does that mean.
 */
//MARK: Answer 5
/*
 # 🎯 Excellent Question! Capture Lists Explained In-Depth

 This is one of the **most confusing** aspects of Swift closures. Let me explain exactly what's happening!

 ---

 ## 📝 The Code

 ```swift
 class SomeClass {
 var value: Int = 10
 let anotherClass = AnotherClass()
 }

 class AnotherClass {
 var name: String = "Swapnil"
 }

 var sClass = SomeClass()
 var randomNum: Int = 5

 let closure: () -> Void = { [sClass, randomNum] in
 print(sClass.value)
 print(sClass.anotherClass.name)
 print(randomNum)
 }

 randomNum = 6
 sClass.value = 12
 sClass.anotherClass.name = "Swapnil new"

 closure()
 ```

 **Output:**
 ```
 12
 Swapnil new
 5
 ```

 ---

 ## 🔑 The Key Insight: What Does `[sClass, randomNum]` Do?

 The capture list `[sClass, randomNum]` means:
 > **"At the moment of closure creation, COPY the current values of these variables INTO the closure"**

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │            CAPTURE LIST = SNAPSHOT AT CREATION TIME             │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  BEFORE closure creation:                                       │
 │                                                                 │
 │    sClass ────────────▶ [ SomeClass Object ]                   │
 │                          value: 10                              │
 │                          anotherClass ──▶ [AnotherClass]       │
 │                                            name: "Swapnil"      │
 │                                                                 │
 │    randomNum = 5                                                │
 │                                                                 │
 │  ─────────────────────────────────────────────────────────────  │
 │                                                                 │
 │  AT closure creation [sClass, randomNum]:                       │
 │                                                                 │
 │  ┌─────────────────────────────────────────────────────────┐   │
 │  │              CLOSURE                                     │   │
 │  │  ┌─────────────────────────────────────────────────────┐│   │
 │  │  │ Captured sClass: ──────▶ [ SomeClass Object ]       ││   │
 │  │  │                          (SAME object!)             ││   │
 │  │  │                                                     ││   │
 │  │  │ Captured randomNum: 5    (COPIED value!)            ││   │
 │  │  └─────────────────────────────────────────────────────┘│   │
 │  └─────────────────────────────────────────────────────────┘   │
 │                                                                 │
 │  The REFERENCE is copied, but it points to the SAME object!    │
 │  The INT is copied by VALUE!                                    │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🎯 Step-by-Step Timeline

 ```swift
 // STEP 1: Initial state
 var sClass = SomeClass()
 var randomNum: Int = 5

 // Memory at this point:
 // sClass (reference) ──────▶ [Object on HEAP: value=10, name="Swapnil"]
 // randomNum = 5
 ```

 ```swift
 // STEP 2: Closure is CREATED with capture list [sClass, randomNum]
 let closure: () -> Void = { [sClass, randomNum] in
 print(sClass.value)
 print(sClass.anotherClass.name)
 print(randomNum)
 }

 // Closure now contains:
 // - A COPY of the REFERENCE sClass (still points to same object!)
 // - A COPY of the VALUE randomNum (value: 5)
 ```

 ```swift
 // STEP 3: Modify the original variables
 randomNum = 6  // ← Changes ORIGINAL variable, closure has COPY (5)
 sClass.value = 12  // ← Modifies the OBJECT that closure's reference points to!
 sClass.anotherClass.name = "Swapnil new"  // ← Same object!
 ```

 ```swift
 // STEP 4: Call closure
 closure()

 // Closure uses:
 // - Its captured reference → points to same object → value is now 12 ✓
 // - Its captured reference → same object → name is now "Swapnil new" ✓
 // - Its captured Int value → still 5 ✓
 ```

 ---

 ## 📊 Visual Memory Diagram

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    AFTER ALL MODIFICATIONS                      │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  OUTSIDE CLOSURE:                                               │
 │  ┌─────────────────────────────────────┐                       │
 │  │ sClass ─────────────────────────────┼──┐                    │
 │  │ randomNum = 6                       │  │                    │
 │  └─────────────────────────────────────┘  │                    │
 │                                           │                    │
 │  INSIDE CLOSURE (captured):               │                    │
 │  ┌─────────────────────────────────────┐  │                    │
 │  │ sClass (captured) ──────────────────┼──┤                    │
 │  │ randomNum (captured) = 5            │  │                    │
 │  └─────────────────────────────────────┘  │                    │
 │                                           │                    │
 │                                           ▼                    │
 │  ┌─────────────────────────────────────────────────────────┐   │
 │  │             HEAP - SomeClass Object                      │   │
 │  │  ┌───────────────────────────────────────────────────┐  │   │
 │  │  │  value: 12    (modified!)                         │  │   │
 │  │  │                                                    │  │   │
 │  │  │  anotherClass ───▶ [AnotherClass]                 │  │   │
 │  │  │                     name: "Swapnil new" (modified!)│  │   │
 │  │  └───────────────────────────────────────────────────┘  │   │
 │  └─────────────────────────────────────────────────────────┘   │
 │                                                                 │
 │  BOTH references point to SAME object, so modifications        │
 │  to the object are visible through the captured reference!     │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🔴 Your Confusion Explained

 You thought:
 > "Closure captures reference types, so I'll get latest values"

 **The truth:**
 - Capture list `[sClass]` captures the **reference value** (the pointer)
 - This pointer still points to the **same object** on the heap
 - So modifications to the **object's properties** ARE visible
 - But `randomNum` is **copied by value** (Int is a value type)
 - The original `randomNum = 6` changes the **original variable**, not the captured copy

 ---

 ## 🧪 Let's Prove It - What If We Reassign sClass?

 ```swift
 class SomeClass {
 var value: Int = 10
 }

 var sClass = SomeClass()
 var randomNum: Int = 5

 let closure: () -> Void = { [sClass, randomNum] in
 print(sClass.value)
 print(randomNum)
 }

 // What if we assign a NEW object?
 sClass = SomeClass()  // ← NEW object created!
 sClass.value = 999     // ← Modifying the NEW object

 closure()
 // Prints:
 // 10  ← Captured reference points to ORIGINAL object!
 // 5   ← Captured value
 ```

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │            WHEN sClass IS REASSIGNED TO NEW OBJECT              │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  Before reassignment:                                           │
 │  ┌──────────────────────────────────────────────────┐          │
 │  │ sClass (original) ────────▶ [Object A: value=10] │          │
 │  │ sClass (captured) ────────▶ [Object A: value=10] │          │
 │  └──────────────────────────────────────────────────┘          │
 │                                                                 │
 │  After sClass = SomeClass():                                    │
 │  ┌──────────────────────────────────────────────────┐          │
 │  │ sClass (original) ────────▶ [Object B: value=999]│ NEW!     │
 │  │                                                   │          │
 │  │ sClass (captured) ────────▶ [Object A: value=10] │ STILL A! │
 │  └──────────────────────────────────────────────────┘          │
 │                                                                 │
 │  Closure still has reference to Object A!                       │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 📝 Without Capture List - Different Behavior!

 ```swift
 // WITHOUT capture list:
 let closure: () -> Void = {
 print(sClass.value)
 print(sClass.anotherClass.name)
 print(randomNum)
 }

 randomNum = 6
 sClass.value = 12
 sClass.anotherClass.name = "Swapnil new"

 closure()
 // Prints:
 // 12
 // Swapnil new
 // 6  ← Now shows 6! Because variable is captured by reference!
 ```

 **Without capture list:**
 - Closure captures the **variables themselves** by reference
 - So any change to `randomNum` is reflected

 **With capture list `[randomNum]`:**
 - Closure captures the **current value** of `randomNum`
 - Changes to original don't affect captured copy

 ---

 ## 💡 About "async" Warning

 The compiler shows "async" because:
 1. When you use a capture list like `[sClass, randomNum]`
 2. The compiler is saying these values are captured **asynchronously** (at a specific point in time)
 3. It's a hint that the captured values might be different from current values
 4. In Xcode, it helps you understand the capture semantics

 ---

 ## 📋 Complete Comparison Table

 | Scenario | randomNum | sClass.value | Why |
 |----------|-----------|--------------|-----|
 | `{ [sClass, randomNum] in }` then modify props | 5 | 12 | Int copied by value; reference points to same object |
 | `{ [sClass, randomNum] in }` then reassign sClass | 5 | 10 | Captured reference still points to OLD object |
 | `{ }` (no capture list) then modify | 6 | 12 | Variables captured by reference |
 | `{ [weak sClass] in }` then modify | - | 12 | Weak reference, same object |

 ---

 ## 🔑 Key Takeaways

 1. **Capture List `[x]`** = Copy the VALUE of x at closure creation time
 - For value types (Int): copies the value itself
 - For reference types (class): copies the reference (pointer), not the object

 2. **Modifying object properties** is visible through captured reference (same object on heap)

 3. **Reassigning the variable** after capture doesn't affect captured reference

 4. **Without capture list** = closure captures the variable by reference (sees all changes)

 ```swift
 // RULE OF THUMB:
 // [sClass] captures the REFERENCE (pointer), not the object
 // Changes to object properties → visible ✓
 // Reassigning sClass → NOT visible (still has old reference)

 // [randomNum] captures the VALUE
 // Changes to randomNum → NOT visible
 ```

 This is a **tricky** interview question that tests deep understanding of Swift's value/reference semantics combined with closure captures! 🎉
 */
/*
 class SomeClass {
 var value : Int = 10
 let anotherClass = AnotherClass()
 }
 class AnotherClass {
 var name: String = "Swapnil"
 }
 var sClass = SomeClass()
 var randomNum: Int = 5
 let closure : () -> Void = { [weak sClass, randomNum] in
 print(sClass?.value)
 print(sClass?.anotherClass.name)
 print(randomNum)
 }
 randomNum = 6
 sClass = SomeClass()
 sClass.value = 12
 sClass.anotherClass.name = "Swapnil new"
 closure()

 Prints
 nil
 nil
 5

 # 🎯 Perfect Question! This Shows Exactly How `weak` Works!

 Let me trace through step-by-step to show you **exactly** why you get `nil, nil, 5`!

 ---

 ## 📝 The Code

 ```swift
 class SomeClass {
 var value: Int = 10
 let anotherClass = AnotherClass()
 }

 class AnotherClass {
 var name: String = "Swapnil"
 }

 var sClass = SomeClass()
 var randomNum: Int = 5

 let closure: () -> Void = { [weak sClass, randomNum] in
 print(sClass?.value)
 print(sClass?.anotherClass.name)
 print(randomNum)
 }

 randomNum = 6
 sClass = SomeClass()  // ← THIS IS THE KEY LINE!
 sClass.value = 12
 sClass.anotherClass.name = "Swapnil new"

 closure()
 ```

 ---

 ## 🔑 Step-by-Step Timeline with ARC

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │ STEP 1: var sClass = SomeClass()                               │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   sClass (STRONG) ─────────▶ [ Object A ]                      │
 │                               value: 10                         │
 │                               name: "Swapnil"                   │
 │                                                                 │
 │   ARC Count of Object A: 1                                      │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────┐
 │ STEP 2: Create closure with [weak sClass, randomNum]           │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   sClass (STRONG) ─────────▶ [ Object A ]                      │
 │                               value: 10                         │
 │                      ▲        name: "Swapnil"                   │
 │                      │                                          │
 │   CLOSURE:           │                                          │
 │   ┌──────────────────┼─────────────────────┐                   │
 │   │ weak sClass ─ ─ ─┘  (WEAK reference!)  │                   │
 │   │ randomNum = 5       (copied value)     │                   │
 │   └────────────────────────────────────────┘                   │
 │                                                                 │
 │   ARC Count of Object A: STILL 1 (weak doesn't add!)           │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────┐
 │ STEP 3: sClass = SomeClass()  ← NEW OBJECT CREATED!            │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   BEFORE reassignment:                                          │
 │   sClass (STRONG) ─────────▶ [ Object A ] ← ARC = 1            │
 │                                                                 │
 │   AFTER reassignment:                                           │
 │   sClass (STRONG) ─────────▶ [ Object B ] ← NEW object!        │
 │                               value: 10                         │
 │                               name: "Swapnil"                   │
 │                                                                 │
 │   [ Object A ] ← ARC = 0 ← NO MORE STRONG REFERENCES!          │
 │                                                                 │
 │   🔥 Object A is DEALLOCATED! 🔥                               │
 │                                                                 │
 │   CLOSURE now:                                                  │
 │   ┌────────────────────────────────────────┐                   │
 │   │ weak sClass ─ ─ ─ ▶ nil                │ ← Became nil!     │
 │   │ randomNum = 5                          │                   │
 │   └────────────────────────────────────────┘                   │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────┐
 │ STEP 4: Modify sClass.value, sClass.anotherClass.name          │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   sClass (STRONG) ─────────▶ [ Object B ]                      │
 │                               value: 12       (modified)        │
 │                               name: "Swapnil new" (modified)    │
 │                                                                 │
 │   Object A: 💀 GONE (deallocated)                              │
 │                                                                 │
 │   CLOSURE still has:                                            │
 │   ┌────────────────────────────────────────┐                   │
 │   │ weak sClass ─ ─ ─ ▶ nil                │ ← Still nil!      │
 │   │ randomNum = 5                          │                   │
 │   └────────────────────────────────────────┘                   │
 │                                                                 │
 │   Closure knows NOTHING about Object B!                         │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────┐
 │ STEP 5: closure() is called                                    │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   print(sClass?.value)           → nil (sClass is nil)         │
 │   print(sClass?.anotherClass.name) → nil (sClass is nil)       │
 │   print(randomNum)                → 5 (captured value)          │
 │                                                                 │
 │   OUTPUT:                                                       │
 │   nil                                                           │
 │   nil                                                           │
 │   5                                                             │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🎯 The Key Difference: `weak` vs Strong Capture

 ### With `[weak sClass]`:

 ```swift
 let closure = { [weak sClass] in ... }
 sClass = SomeClass()  // Object A deallocated!
 closure()  // sClass is nil!
 ```

 - Closure has **weak** reference to Object A
 - When `sClass = SomeClass()` creates Object B:
 - `sClass` variable now points to Object B
 - Object A has **no more strong references**
 - Object A is **deallocated**
 - Closure's weak reference becomes **nil**

 ### With `[sClass]` (strong capture):

 ```swift
 let closure = { [sClass] in ... }  // Strong capture!
 sClass = SomeClass()  // Object A still alive!
 closure()  // sClass points to Object A!
 ```

 - Closure has **strong** reference to Object A
 - Even when `sClass = SomeClass()`:
 - Closure still keeps Object A alive
 - Object A has ARC = 1 (from closure)
 - Would print: `10, "Swapnil", 5`

 ---

 ## 📊 Comparison: Same Code With Different Captures

 ```swift
 var sClass = SomeClass()  // Object A
 var randomNum = 5
 ```

 | Capture | After `sClass = SomeClass()` | Output |
 |---------|------------------------------|--------|
 | `[sClass]` (strong) | Object A still alive (ARC=1) | `10, "Swapnil", 5` |
 | `[weak sClass]` | Object A deallocated (ARC=0) | `nil, nil, 5` |
 | No capture list | Uses current `sClass` (Object B) | `12, "Swapnil new", 6` |

 ---

 ## 🧪 Prove It With deinit

 ```swift
 class SomeClass {
 var value: Int = 10
 let anotherClass = AnotherClass()

 deinit {
 print("🔥 SomeClass DEALLOCATED!")
 }
 }

 class AnotherClass {
 var name: String = "Swapnil"
 }

 var sClass = SomeClass()
 var randomNum: Int = 5

 let closure: () -> Void = { [weak sClass, randomNum] in
 print(sClass?.value)
 print(sClass?.anotherClass.name)
 print(randomNum)
 }

 randomNum = 6
 print("About to reassign sClass...")
 sClass = SomeClass()  // ← Object A deallocated HERE!
 print("Reassigned sClass!")
 sClass.value = 12
 sClass.anotherClass.name = "Swapnil new"

 closure()

 // OUTPUT:
 // About to reassign sClass...
 // 🔥 SomeClass DEALLOCATED!     ← Object A is gone!
 // Reassigned sClass!
 // nil
 // nil
 // 5
 ```

 ---

 ## 🔑 Summary

 | Question | Answer |
 |----------|--------|
 | **Why is sClass nil?** | `weak` reference doesn't keep object alive. When you reassigned `sClass = SomeClass()`, the original object lost all strong references and was deallocated. |
 | **Why not 12?** | The closure captured a weak reference to the **original** Object A, not Object B. Object A was deallocated. |
 | **Why 5?** | `randomNum` was captured by value at closure creation time. |

 ```
 Timeline:
 1. Create Object A, sClass → Object A
 2. Closure captures WEAK reference to Object A (ARC still 1)
 3. sClass = SomeClass() creates Object B
 4. Object A loses its only strong reference (sClass)
 5. Object A ARC = 0 → DEALLOCATED
 6. Closure's weak reference becomes nil automatically
 7. closure() prints nil, nil, 5
 ```

 This is **exactly** why `weak` exists - to prevent retain cycles while allowing objects to be deallocated when no longer needed! 🎉
 */

//MARK: Question 6
/*
 Next question that was asked to me in the interview, possible issues in this would be :

 class UserProfile {
 @IBOutlet weak var nameLabel : UILabel!
 var nameLabelAuto: UILabel! = nil
 func getUserProfileData() {
 self.getDataFromAPI() { [weak self] (name: String) in
 self?.nameLabel.text = name
 }
 }
 }

 1. Now I was thinking first of all like this UILabel! we are doing ain't this UserProfile needs to have a init like I am confused usually I saw that compiler automatically says that it needs init but not in this case, we are forcefully unwrapping it meaning it can't be nil or can it be nil, if it can't be nil then it must have some sort of initial data, I am confused what does "!" this operator does and how can it be nil
 2. I suggested we should do this nameLabel change since this is a UI change and this completion handler is working on Background queue we should switch to Main Queue and use DispatchQueue.main.async {}
 3. Another thing I was confused was can nameLabel.text can take an optional value or do we need to give it default value there
 4. Also a bit confused and now my solution that I am trying to run throws ERROR "Sending 'self' risks causing data races", totally confused over this when I am saying
 func getUserProfileData() {
 self.getDataFromAPI() { [weak self] (name: String) in
 DispatchQueue.main.async {
 self?.nameLabel.text = name
 }
 }
 }
 Also this MainActor , non-isolated all this concept feels intimidating to me as I am not able to understand those

 5. Also what's the difference between
 var label: UILabel?
 var label2: UILabel!
 var label3: Optional<UILabel>

 Since optional an enum ?

 Note : I am running this code in Playground
 */
//MARK: Answer 6
/*
 # 🎯 Complete Explanation: Optionals, `!`, MainActor & Concurrency

 These are **excellent** questions that test deep understanding of Swift. Let me explain each one clearly!

 ---

 ## 📝 Question 1: Why No `init` Needed for `UILabel!`?

 ### What is `!` (Implicitly Unwrapped Optional)?

 ```swift
 var nameLabel: UILabel!  // Implicitly Unwrapped Optional (IUO)
 ```

 **Key insight:** `UILabel!` is **still an Optional**! It CAN be nil!

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │              UILabel! = Implicitly Unwrapped Optional           │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   var label: UILabel?   →  Optional<UILabel>                   │
 │   var label: UILabel!   →  ImplicitlyUnwrappedOptional<UILabel>│
 │                                                                 │
 │   BOTH can be nil!                                              │
 │   BOTH are optionals under the hood!                            │
 │                                                                 │
 │   THE DIFFERENCE:                                               │
 │   ┌─────────────────────────────────────────────────────────┐  │
 │   │  UILabel?  →  Must use ? or ! to access                 │  │
 │   │               label?.text = "Hi"                         │  │
 │   │               label!.text = "Hi"                         │  │
 │   │                                                          │  │
 │   │  UILabel!  →  Automatically unwrapped when accessed     │  │
 │   │               label.text = "Hi"  (no ? or ! needed)     │  │
 │   │               ⚠️ CRASHES if nil!                        │  │
 │   └─────────────────────────────────────────────────────────┘  │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### Why No `init` Required?

 **Rule:** Swift requires all stored properties to have values by the end of `init`.

 **Exception:** Optional properties (including `!`) **default to nil**!

 ```swift
 class UserProfile {
 // ✅ No init needed - defaults to nil
 @IBOutlet weak var nameLabel: UILabel!  // Default: nil

 var nameLabelAuto: UILabel! = nil       // Explicit nil (same thing)

 var regularOptional: UILabel?           // Default: nil

 // ❌ THIS would require init:
 // var requiredLabel: UILabel  // Error: has no initializer
 }
 ```

 ### When to Use `!`?

 ```swift
 // ✅ GOOD USE: @IBOutlet
 // Why? Because Interface Builder guarantees it's set before use
 @IBOutlet weak var nameLabel: UILabel!

 // ✅ GOOD USE: Properties set in viewDidLoad before any other access
 var tableView: UITableView!

 // ❌ BAD USE: Properties that might actually be nil at access time
 var userData: User!  // Risky! Could crash if accessed before set
 ```

 ### The Danger:

 ```swift
 var label: UILabel!  // Currently nil

 label.text = "Hello"  // 💥 CRASH! Unwrapping nil!

 // It's like writing:
 label!.text = "Hello"  // Forced unwrap of nil = crash
 ```

 ---

 ## 📝 Question 2: Main Queue for UI Updates

 **You are 100% correct!** UI updates must happen on the main thread.

 ```swift
 func getUserProfileData() {
 self.getDataFromAPI { [weak self] (name: String) in
 // ❌ This might be on background thread!
 self?.nameLabel.text = name

 // ✅ CORRECT: Switch to main thread
 DispatchQueue.main.async {
 self?.nameLabel.text = name
 }
 }
 }
 ```

 ---

 ## 📝 Question 3: Can `nameLabel.text` Accept Optional?

 Yes! `UILabel.text` is already an Optional:

 ```swift
 // UILabel's text property:
 var text: String?  // It's Optional!

 // So this is fine:
 nameLabel.text = nil        // ✅ Valid
 nameLabel.text = "Hello"    // ✅ Valid
 nameLabel.text = someName   // ✅ Valid even if someName is String?
 ```

 ---

 ## 📝 Question 4: "Sending 'self' risks causing data races" Error

 This is **Swift 6's Strict Concurrency** checking! This is the newest and most complex part.

 ### Why This Error Happens

 ```swift
 func getUserProfileData() {
 self.getDataFromAPI { [weak self] (name: String) in
 DispatchQueue.main.async {
 self?.nameLabel.text = name  // ❌ Error in Swift 6!
 }
 }
 }
 ```

 **The Problem:**
 Swift 6 enforces **actor isolation**. `UserProfile` is not on any specific actor, but:
 - The closure might run on a background thread
 - `DispatchQueue.main.async` switches to main thread
 - `self` might be accessed from multiple threads = **data race possible**

 ### Solution 1: Make Class `@MainActor`

 ```swift
 @MainActor  // ← This class runs on main thread
 class UserProfile {
 @IBOutlet weak var nameLabel: UILabel!

 func getUserProfileData() {
 // Now everything is on MainActor, no data race possible
 self.getDataFromAPI { [weak self] (name: String) in
 self?.nameLabel.text = name  // ✅ Already on main actor
 }
 }

 func getDataFromAPI(completion: @escaping (String) -> Void) {
 Task.detached {  // Run on background
 // Simulate network call
 try? await Task.sleep(nanoseconds: 1_000_000_000)
 await MainActor.run {
 completion("John")
 }
 }
 }
 }
 ```

 ### Solution 2: Use `MainActor.run`

 ```swift
 class UserProfile {
 @IBOutlet weak var nameLabel: UILabel!

 func getUserProfileData() {
 self.getDataFromAPI { [weak self] (name: String) in
 Task { @MainActor in
 self?.nameLabel.text = name  // ✅ Explicitly on MainActor
 }
 }
 }
 }
 ```

 ### Solution 3: Use `Task` with `@MainActor`

 ```swift
 class UserProfile {
 @IBOutlet weak var nameLabel: UILabel!

 func getUserProfileData() {
 Task { @MainActor [weak self] in
 let name = await self?.fetchFromAPI()
 self?.nameLabel.text = name
 }
 }

 func fetchFromAPI() async -> String {
 // Async network call
 return "John"
 }
 }
 ```

 ### Understanding @MainActor

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    @MainActor Explained                         │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  WITHOUT @MainActor:                                            │
 │  ┌─────────────────────────────────────────────────────────┐   │
 │  │  class UserProfile {                                     │   │
 │  │      // Can be accessed from ANY thread                  │   │
 │  │      // Swift 6 is worried about data races             │   │
 │  │  }                                                       │   │
 │  └─────────────────────────────────────────────────────────┘   │
 │                                                                 │
 │  WITH @MainActor:                                               │
 │  ┌─────────────────────────────────────────────────────────┐   │
 │  │  @MainActor                                              │   │
 │  │  class UserProfile {                                     │   │
 │  │      // GUARANTEED to run on main thread                 │   │
 │  │      // No data races possible for this class           │   │
 │  │  }                                                       │   │
 │  └─────────────────────────────────────────────────────────┘   │
 │                                                                 │
 │  @MainActor = "This code runs on the main thread"              │
 │  nonisolated = "This specific method can run anywhere"          │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### Playground Issue

 Playgrounds have **stricter concurrency checking** by default. In a real Xcode project, you might not see this error unless you enable strict concurrency:

 ```swift
 // In a real UIViewController, this would work:
 class MyViewController: UIViewController {
 @IBOutlet weak var nameLabel: UILabel!

 func loadData() {
 fetchData { [weak self] name in
 DispatchQueue.main.async {
 self?.nameLabel.text = name  // Usually works in Xcode
 }
 }
 }
 }
 ```

 ---

 ## 📝 Question 5: Difference Between `?` and `!` and `Optional<>`

 ```swift
 var label1: UILabel?           // Regular Optional
 var label2: UILabel!           // Implicitly Unwrapped Optional
 var label3: Optional<UILabel>  // Same as label1 (different syntax)
 ```

 ### Complete Comparison

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    Optional Syntax Comparison                   │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  SYNTAX                    MEANING                              │
 │  ─────────────────────────────────────────────────────────────  │
 │                                                                 │
 │  var label: UILabel?       Regular Optional                     │
 │  var label: Optional<UILabel>  ← SAME THING (generic syntax)   │
 │                                                                 │
 │  var label: UILabel!       Implicitly Unwrapped Optional        │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ### What is Optional?

 ```swift
 // Optional is just an enum!
 enum Optional<Wrapped> {
 case none           // nil
 case some(Wrapped)  // has value
 }

 // So:
 var label: UILabel? = nil
 // Is actually:
 var label: Optional<UILabel> = .none

 var label: UILabel? = UILabel()
 // Is actually:
 var label: Optional<UILabel> = .some(UILabel())
 ```

 ### Accessing Values

 ```swift
 var label1: UILabel? = UILabel()
 var label2: UILabel! = UILabel()
 var label3: Optional<UILabel> = UILabel()

 // ACCESSING:
 label1?.text = "Hi"     // Optional chaining (safe)
 label1!.text = "Hi"     // Force unwrap (crashes if nil)

 label2.text = "Hi"      // Auto-unwrapped (crashes if nil)
 label2?.text = "Hi"     // You can still use ? for safety

 label3?.text = "Hi"     // Same as label1
 ```

 ### When to Use Each

 ```swift
 // UILabel? - When value might be nil at any time
 var optionalLabel: UILabel?
 if let label = optionalLabel {
 label.text = "Hi"
 }

 // UILabel! - When value will DEFINITELY be set before first use
 @IBOutlet weak var storyboardLabel: UILabel!  // Set by IB before viewDidLoad

 // Optional<UILabel> - Same as UILabel?, just verbose
 // Used mainly in generic code
 func process<T>(_ value: Optional<T>) { ... }
 ```

 ---

 ## 📊 Complete Summary

 | Topic | Answer |
 |-------|--------|
 | Why no `init` for `UILabel!`? | IUO is still Optional, defaults to nil |
 | Can `!` be nil? | YES! It's an Optional that auto-unwraps |
 | Main thread for UI? | YES! Use `DispatchQueue.main.async` or `@MainActor` |
 | Can `text` take nil? | YES! `UILabel.text` is `String?` |
 | Data race error? | Swift 6 concurrency - use `@MainActor` |
 | `UILabel?` vs `UILabel!`? | Same storage, different access (auto-unwrap vs manual) |
 | `Optional<T>` vs `T?`? | Identical! Just different syntax |

 ---

 ## ✅ Fixed Code (Swift 6 Compatible)

 ```swift
 import UIKit

 @MainActor  // ← Guarantees main thread access
 class UserProfile {
 @IBOutlet weak var nameLabel: UILabel!

 func getUserProfileData() {
 Task {
 do {
 let name = try await getDataFromAPI()
 nameLabel.text = name  // ✅ Safe, on MainActor
 } catch {
 nameLabel.text = "Error"
 }
 }
 }

 nonisolated func getDataFromAPI() async throws -> String {
 // Simulated network call
 try await Task.sleep(nanoseconds: 1_000_000_000)
 return "John"
 }
 }
 ```

 Or with completion handler style:

 ```swift
 import UIKit

 @MainActor
 class UserProfile {
 @IBOutlet weak var nameLabel: UILabel!

 func getUserProfileData() {
 getDataFromAPI { [weak self] name in
 // Already on @MainActor, safe to update UI
 self?.nameLabel.text = name
 }
 }

 nonisolated func getDataFromAPI(completion: @escaping @Sendable (String) -> Void) {
 DispatchQueue.global().async {
 // Simulate API call
 sleep(1)
 Task { @MainActor in
 completion("John")
 }
 }
 }
 }
 ```

 This is a complex topic combining optionals, memory management, and modern Swift concurrency! 🎉
 */

//MARK: Question 7
//Building your own customMap for an array
/*
 Next question that was asked to me was how exactly an custom higher order function let's take an example compactMap has been built by Apple , built your own
 I wasn't able to build this fully but wrote this code :

 extension Array {
     func myCustomCompactMap<T>(completionHandler:(T)->T?) -> Array<T> {
         var resultArr : [T] = []
         for element in self {
             if let validElement = element as? T,
                 let val = completionHandler(
                 validElement
             ){
                 resultArr.append(validElement)
             }
         }
         return resultArr
     }
 }

 var arr = ["1","2","3","Swapnil"]
 var onlyIntArr = arr.compactMap { val in
     Int(val)
 }
 print(onlyIntArr)
 var customOnlyIntArr = arr.myCustomCompactMap { val in
     Int(val)
 }
 print(customOnlyIntArr)

 But my customOnlyIntArr printed []
 Also another doubt what would happen if I say [1,2,3,"Swapnil"].customMap {$0 in Int($0)} like arr is having Int and string both
 */

//MARK: Answer 7
/*
 # Understanding Higher-Order Functions: Building Custom `compactMap`

 Let me break this down step by step, explaining what went wrong and how to fix it!

 ---

 ## 🎯 What is `compactMap`?

 **In Simple Terms:**
 `compactMap` does two things in one step:
 1. **Transforms** each element using your closure
 2. **Filters out** any `nil` results automatically

 ```
 Input Array:  ["1", "2", "3", "Swapnil"]
                 ↓      ↓     ↓        ↓
 Transform:    Int(1)  Int(2) Int(3)   nil  ← "Swapnil" can't become Int
                 ↓      ↓     ↓        ✗
 Output:       [1,     2,     3]            ← nil is removed!
 ```

 ---

 ## 🔍 Why Your Implementation Didn't Work

 Let's analyze your code step by step:

 ```swift
 extension Array {
     func myCustomCompactMap<T>(completionHandler:(T)->T?) -> Array<T> {
         //                                        ↑    ↑
         //                          PROBLEM 1: Takes T, returns T?
         //                          Should be: Takes Element, returns T?

         var resultArr : [T] = []
         for element in self {
             if let validElement = element as? T,
             //                              ↑
             //              PROBLEM 2: Casting to OUTPUT type T
             //              But element is INPUT type (String in your case)
             //              String as? Int will ALWAYS fail!

                 let val = completionHandler(validElement) {
                 resultArr.append(validElement)
                 //                ↑
                 //   PROBLEM 3: Appending original, not transformed value!
             }
         }
         return resultArr
     }
 }
 ```

 ### The Core Issues:

 | Problem | Your Code | What It Should Be |
 |---------|-----------|-------------------|
 | Closure input | `(T) -> T?` | `(Element) -> T?` |
 | Casting | `element as? T` (String as? Int = nil) | No casting needed |
 | Appending | `validElement` (original) | `val` (transformed) |

 ---

 ## ✅ The Correct Implementation

 ```swift
 extension Array {
     func myCustomCompactMap<T>(_ transform: (Element) -> T?) -> [T] {
         //                        ↑              ↑         ↑
         //                   Generic type    Array's     Returns
         //                   for OUTPUT      element     optional T
         //                                   type

         var resultArr: [T] = []

         for element in self {
             // Call the transform closure
             // element is of type Element (String in your case)
             // transform returns T? (Int? in your case)
             if let transformedValue = transform(element) {
                 // Only append if transform didn't return nil
                 resultArr.append(transformedValue)
             }
         }

         return resultArr
     }
 }
 ```

 ### Let's Trace Through It:

 ```swift
 var arr = ["1", "2", "3", "Swapnil"]

 var customOnlyIntArr = arr.myCustomCompactMap { val in
     Int(val)  // String -> Int?
 }

 // Step by step:
 // Element type = String
 // T (output type) = Int (inferred from Int(val))

 // Iteration 1: element = "1"
 //   transform("1") = Int("1") = Optional(1) ✓
 //   Append 1

 // Iteration 2: element = "2"
 //   transform("2") = Int("2") = Optional(2) ✓
 //   Append 2

 // Iteration 3: element = "3"
 //   transform("3") = Int("3") = Optional(3) ✓
 //   Append 3

 // Iteration 4: element = "Swapnil"
 //   transform("Swapnil") = Int("Swapnil") = nil ✗
 //   Skip (don't append)

 // Result: [1, 2, 3]
 print(customOnlyIntArr)  // [1, 2, 3]
 ```

 ---

 ## 🧠 Understanding `Element` - The Key Insight

 ```swift
 extension Array {
     // Array is actually Array<Element>
     // Element is a "phantom" generic type that represents
     // whatever type the array holds

     func myCustomCompactMap<T>(_ transform: (Element) -> T?) -> [T] {
         // ...
     }
 }
 ```

 **Visual:**
 ```
 Array<String>     →  Element = String
 Array<Int>        →  Element = Int
 Array<User>       →  Element = User

 ["1", "2", "3"]   →  Element = String
 [1, 2, 3]         →  Element = Int
 ```

 ---

 ## 🎨 Your Second Question: Mixed Type Array

 ```swift
 [1, 2, 3, "Swapnil"]  // What type is this?
 ```

 **Answer:** This becomes `[Any]` because Swift needs a common type!

 ```swift
 let mixedArr = [1, 2, 3, "Swapnil"]  // Type: [Any]

 // If you try:
 let result = mixedArr.myCustomCompactMap { element in
     Int(element)  // ❌ ERROR!
 }
 // Error: Cannot convert value of type 'Any' to expected argument type 'String'
 ```

 **Why?** `Int(_:)` initializer expects a `String`, but `element` is `Any`.

 ### How to Handle Mixed Arrays:

 ```swift
 let mixedArr: [Any] = [1, 2, 3, "Swapnil", "5"]

 // Option 1: Check if already Int, or try to convert String
 let result = mixedArr.myCustomCompactMap { element -> Int? in
     // If it's already an Int, return it
     if let intValue = element as? Int {
         return intValue
     }
     // If it's a String, try to convert
     if let stringValue = element as? String {
         return Int(stringValue)
     }
     // Otherwise, return nil
     return nil
 }

 print(result)  // [1, 2, 3, 5]
 ```

 ---

 ## 📚 Complete Working Example

 ```swift
 import Foundation

 // MARK: - Custom CompactMap Implementation
 extension Array {
     /// Custom implementation of compactMap
     /// - Parameter transform: A closure that takes an Element and returns an optional T
     /// - Returns: An array of non-nil transformed values
     func myCustomCompactMap<T>(_ transform: (Element) -> T?) -> [T] {
         var resultArr: [T] = []

         for element in self {
             // Apply transform and unwrap
             if let transformedValue = transform(element) {
                 resultArr.append(transformedValue)
             }
         }

         return resultArr
     }
 }

 // MARK: - Test Cases

 // Test 1: String to Int (your original example)
 let stringArr = ["1", "2", "3", "Swapnil"]
 let intArr = stringArr.myCustomCompactMap { Int($0) }
 print("Test 1: \(intArr)")  // [1, 2, 3]

 // Test 2: Get only even numbers
 let numbers = [1, 2, 3, 4, 5, 6]
 let evenNumbers = numbers.myCustomCompactMap { num -> Int? in
     num % 2 == 0 ? num : nil
 }
 print("Test 2: \(evenNumbers)")  // [2, 4, 6]

 // Test 3: Extract valid URLs
 let urlStrings = ["https://apple.com", "invalid-url", "https://google.com"]
 let validURLs = urlStrings.myCustomCompactMap { URL(string: $0) }
 print("Test 3: \(validURLs)")  // [URL objects for apple.com and google.com]

 // Test 4: Mixed array handling
 let mixedArr: [Any] = [1, 2, 3, "Swapnil", "5", 10.5]
 let extractedInts = mixedArr.myCustomCompactMap { element -> Int? in
     if let intVal = element as? Int { return intVal }
     if let strVal = element as? String { return Int(strVal) }
     return nil
 }
 print("Test 4: \(extractedInts)")  // [1, 2, 3, 5]
 ```
 ## 📊 Summary Diagram

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    How compactMap Works                          │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                  │
 │   ["1", "2", "3", "Swapnil"]                                    │
 │       │     │     │      │                                       │
 │       ▼     ▼     ▼      ▼                                       │
 │   ┌─────────────────────────────────────┐                       │
 │   │  transform: (String) -> Int?        │                       │
 │   │                                     │                       │
 │   │  Int("1")      → Optional(1)   ✓   │                       │
 │   │  Int("2")      → Optional(2)   ✓   │                       │
 │   │  Int("3")      → Optional(3)   ✓   │                       │
 │   │  Int("Swapnil") → nil          ✗   │                       │
 │   └─────────────────────────────────────┘                       │
 │       │     │     │      │                                       │
 │       ▼     ▼     ▼      ✗ (filtered out)                       │
 │                                                                  │
 │   Result: [1, 2, 3]                                             │
 │                                                                  │
 └─────────────────────────────────────────────────────────────────┘

 ┌─────────────────────────────────────────────────────────────────┐
 │              Your Bug vs Correct Version                         │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                  │
 │  YOUR CODE:     (T) -> T?        ← Wrong! T is output type      │
 │                  ↓                                               │
 │                 element as? T     ← String as? Int = nil always │
 │                  ↓                                               │
 │                 append(validElement) ← Wrong variable            │
 │                                                                  │
 │  CORRECT:       (Element) -> T?  ← Element is input type        │
 │                  ↓                                               │
 │                 transform(element) ← Call closure directly       │
 │                  ↓                                               │
 │                 append(transformedValue) ← Right variable        │
 │                                                                  │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🎯 Key Takeaways

 1. **`Element`** is the type of items already in the array
 2. **`T`** is the type of items you want in the result
 3. **The closure signature** must be `(Element) -> T?` — takes input type, returns optional output type
 4. **Append the transformed value**, not the original
 5. **Mixed type arrays** become `[Any]` and need explicit type checking

 */

//MARK: Question 8
/*
 Interviewer asked there are two async calls happening let's fetchUserProfile and fetchUserAddress and now I want to
 wait for both the async calls to happen and then update my UI. So I told him we should be using DispatchGroup here
 like
 let group = DispatchGroup()
 group.enter()
 DispatchQueue.global().async {
    fetchUserProfile {}
    group.leave()
 }

 group.enter()
 DispatchQueue.gloabl().async {
    fetchUserAddress{}
    group.leave()
 }

 group.notify(queue:.main){
    //here both the Async API have been finished now we can update the UI
 }

 On this the follow up question that he asked was how exactly this dispatchGroup would actually works, to which I said
 that using Counter logic like enter will increase the counter += 1 and leave will be doing it -= 1 and once it reaches zero it will notify

 On the follow up he asked the question which confused me a lot, he said let's say there's an bug by which fetchUserProfile {} completionHandler gets called twice now what do you think will happen this got me confused I said probably the first response of fetchUserProfile will be read , second response will be ignored and fetchUserAddress response will be read (counter + = 1 and then -= 1) but I wasn't able to understand the concept and was confused what would actually happen in that scenario
 */
//MARK: Answer 8
/*
 # Understanding DispatchGroup: The "Double Completion" Bug

 This is a **fantastic interview question** because it tests your understanding of DispatchGroup internals and edge cases. Let me explain exactly what happens!

 ---

 ## 🎯 Quick Recap: How DispatchGroup Works

 You were correct about the counter logic:

 ```
 ┌──────────────────────────────────────────────────────────────┐
 │                  DispatchGroup Counter Logic                  │
 ├──────────────────────────────────────────────────────────────┤
 │                                                              │
 │   group.enter()   →   counter += 1                          │
 │   group.leave()   →   counter -= 1                          │
 │                                                              │
 │   When counter reaches 0  →  notify() block executes        │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🐛 The Bug Scenario: Completion Called Twice

 Let's trace through exactly what happens:

 ```swift
 let group = DispatchGroup()

 // Step 1: Enter for fetchUserProfile
 group.enter()  // counter = 1

 // Step 2: Enter for fetchUserAddress
 group.enter()  // counter = 2

 // Step 3: Start both async calls
 DispatchQueue.global().async {
     fetchUserProfile { result in
         // BUG: This completion is called TWICE!
         group.leave()  // First call:  counter = 1
         // ... some time later ...
         group.leave()  // Second call: counter = 0 ← notify fires!
     }
 }

 DispatchQueue.global().async {
     fetchUserAddress { result in
         group.leave()  // This might happen AFTER notify already fired
                        // counter = -1 ← 💥 CRASH!
     }
 }

 group.notify(queue: .main) {
     // This might execute BEFORE fetchUserAddress completes!
     updateUI()
 }
 ```

 ---

 ## 💥 What Actually Happens: TWO Major Problems

 ### Problem 1: Premature `notify()` Execution

 ```
 Timeline:
 ─────────────────────────────────────────────────────────────────►

 counter: 0    1         2         1         0         -1
               │         │         │         │          │
               │         │         │         │          │
          enter()   enter()   leave()   leave()    leave()
          (Profile) (Address) (Profile  (Profile   (Address)
                               1st call) 2nd call)
                                         │
                                         ▼
                                    notify() fires! 🚨
                                    (But Address not done!)

                                                     💥 CRASH!
                                               (counter goes negative)
 ```

 ### Problem 2: CRASH - Unbalanced Leave

 **This is the critical part the interviewer wanted you to understand:**

 > **Calling `leave()` more times than `enter()` causes a CRASH!**

 ```swift
 // Apple's documentation states:
 // "Calling this function more times than enter() is called
 //  results in a negative count, which causes a crash."
 ```

 The actual error you'd see:

 ```
 EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP)
 // or
 BUG IN CLIENT OF LIBDISPATCH: Unbalanced call to dispatch_group_leave()
 ```

 ---

 ## 📊 Visual Timeline of the Bug

 ```
 ┌─────────────────────────────────────────────────────────────────────┐
 │                         BUGGY SCENARIO                               │
 ├─────────────────────────────────────────────────────────────────────┤
 │                                                                      │
 │  Time ──────────────────────────────────────────────────────────►   │
 │                                                                      │
 │  ┌─────────┐                                                        │
 │  │ enter() │ counter = 1  (for Profile)                             │
 │  └────┬────┘                                                        │
 │       │                                                              │
 │  ┌────▼────┐                                                        │
 │  │ enter() │ counter = 2  (for Address)                             │
 │  └────┬────┘                                                        │
 │       │                                                              │
 │       ├──────────────┬──────────────────────────────────────────    │
 │       │              │                                               │
 │       ▼              ▼                                               │
 │  ┌─────────┐    ┌─────────┐                                         │
 │  │ Profile │    │ Address │  (Both start)                           │
 │  │ API     │    │ API     │                                         │
 │  └────┬────┘    └────┬────┘                                         │
 │       │              │                                               │
 │  ┌────▼────┐         │                                               │
 │  │ leave() │         │   counter = 1  (Profile completes 1st time)  │
 │  └────┬────┘         │                                               │
 │       │              │                                               │
 │  ┌────▼────┐         │                                               │
 │  │ leave() │ 🐛      │   counter = 0  (Profile completes 2nd time!) │
 │  └────┬────┘         │                                               │
 │       │              │                                               │
 │  ┌────▼─────────┐    │                                               │
 │  │   notify()   │ ⚠️ │   UI updates but Address not done yet!       │
 │  │ (premature!) │    │                                               │
 │  └──────────────┘    │                                               │
 │                      │                                               │
 │                 ┌────▼────┐                                          │
 │                 │ leave() │  counter = -1                            │
 │                 └────┬────┘                                          │
 │                      │                                               │
 │                      ▼                                               │
 │                  💥 CRASH!                                           │
 │                  "Unbalanced call to dispatch_group_leave()"         │
 │                                                                      │
 └─────────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🛡️ How to Prevent This Bug

 ### Solution 1: Use a Flag to Ensure Single Completion

 ```swift
 let group = DispatchGroup()

 group.enter()
 var profileCompleted = false  // Guard flag
 DispatchQueue.global().async {
     fetchUserProfile { result in
         // Ensure leave() is called only once
         guard !profileCompleted else { return }
         profileCompleted = true

         // Process result...
         group.leave()
     }
 }

 group.enter()
 var addressCompleted = false
 DispatchQueue.global().async {
     fetchUserAddress { result in
         guard !addressCompleted else { return }
         addressCompleted = true

         // Process result...
         group.leave()
     }
 }

 group.notify(queue: .main) {
     updateUI()
 }
 ```

 ### Solution 2: Thread-Safe Flag with Lock (Better)

 ```swift
 class OnceFlag {
     private var executed = false
     private let lock = NSLock()

     func execute(_ block: () -> Void) {
         lock.lock()
         defer { lock.unlock() }

         guard !executed else { return }
         executed = true
         block()
     }
 }

 let group = DispatchGroup()
 let profileOnce = OnceFlag()
 let addressOnce = OnceFlag()

 group.enter()
 DispatchQueue.global().async {
     fetchUserProfile { result in
         profileOnce.execute {
             // Process result...
             group.leave()
         }
     }
 }
 ```

 ### Solution 3: Use `async/await` (Modern Swift - Best!)

 ```swift
 func loadUserData() async throws -> (UserProfile, UserAddress) {
     // Both run concurrently, both must complete
     async let profile = fetchUserProfile()
     async let address = fetchUserAddress()

     // Wait for both - no counter management needed!
     return try await (profile, address)
 }

 // Usage
 Task {
     do {
         let (profile, address) = try await loadUserData()
         await MainActor.run {
             updateUI(profile: profile, address: address)
         }
     } catch {
         // Handle error
     }
 }
 ```

 ### Solution 4: Use `TaskGroup` for Dynamic Number of Tasks

 ```swift
 func loadAllData() async throws -> (UserProfile, UserAddress) {
     try await withThrowingTaskGroup(of: Any.self) { group in
         var profile: UserProfile?
         var address: UserAddress?

         group.addTask { try await self.fetchUserProfile() }
         group.addTask { try await self.fetchUserAddress() }

         for try await result in group {
             if let p = result as? UserProfile { profile = p }
             if let a = result as? UserAddress { address = a }
         }

         guard let p = profile, let a = address else {
             throw DataError.missingData
         }
         return (p, a)
     }
 }
 ```

 ---

 ## 🎯 The Correct Interview Answer

 When the interviewer asks: *"What happens if fetchUserProfile completion is called twice?"*

 **Your Answer Should Be:**

 > "Two things would happen:
 >
 > 1. **Premature notify()**: When the completion is called the second time, `leave()` would be called twice for Profile. This means the counter would hit 0 before Address completes, causing `notify()` to fire prematurely. Our UI would update with incomplete data.
 >
 > 2. **App Crash**: When Address eventually completes and calls `leave()`, the counter would go negative (-1). DispatchGroup doesn't allow unbalanced leave calls - it will crash with 'Unbalanced call to dispatch_group_leave()'.
 >
 > To prevent this, I would use a guard flag to ensure each `leave()` is only called once, or better yet, migrate to `async/await` with `async let` which handles this automatically."

 ---

 ## 📝 Summary Table

 | Scenario | Counter Flow | Result |
 |----------|-------------|--------|
 | Normal (1 completion each) | 0→1→2→1→0 | ✅ Works correctly |
 | Profile called twice | 0→1→2→1→0→-1 | 💥 Crash + premature notify |
 | Address called twice | 0→1→2→1→0→-1 | 💥 Crash + premature notify |
 | Both called twice | 0→1→2→1→0→-1→-2 | 💥 Multiple crashes |

 ---

 ## 🔑 Key Takeaways

 1. **DispatchGroup uses a counter** - enter increments, leave decrements
 2. **Counter going negative = CRASH** - this is by design to catch bugs
 3. **notify() fires at counter = 0** - regardless of which tasks are actually done
 4. **Always guard your leave() calls** - especially with third-party APIs
 5. **Prefer async/await** - it's safer and doesn't have this issue

 Would you like me to explain more about `async let` or how `TaskGroup` works internally?

 # Understanding `await` vs `async let` - The Key Difference

 This is one of the **most confusing concepts** in Swift Concurrency! Let me clarify everything step by step.

 ---

 ## 🎯 The Core Question: Does `await` Block?

 **Short Answer:**
 - `await` **suspends your function** (the function pauses there)
 - `await` **does NOT block the thread** (thread can do other work like UI)

 Think of it like this:

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                    BLOCKING vs SUSPENDING                        │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                  │
 │   BLOCKING (Bad - like sync wait):                              │
 │   ┌──────────────────────────────────────────────┐              │
 │   │ Thread: ████████ FROZEN ████████             │              │
 │   │         Can't do ANYTHING - UI freezes!      │              │
 │   └──────────────────────────────────────────────┘              │
 │                                                                  │
 │   SUSPENDING (Good - await):                                    │
 │   ┌──────────────────────────────────────────────┐              │
 │   │ Thread: 🏃 Free to do other work! 🏃         │              │
 │   │ Task:   💤 Sleeping, waiting for response    │              │
 │   │         UI works fine, scrolling works!      │              │
 │   └──────────────────────────────────────────────┘              │
 │                                                                  │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 📖 The Difference: `await` vs `async let`

 ### Option 1: Sequential with `await`

 ```swift
 func loadData() async {
     // Line 1: Start Profile, WAIT until done
     let profile = await fetchUserProfile()  // ⏸️ Suspend here ~2 seconds

     // Line 2: Only AFTER profile is done, start Address
     let address = await fetchUserAddress()  // ⏸️ Suspend here ~2 seconds

     // Total time: 4 seconds (2 + 2)
     updateUI(profile, address)
 }
 ```

 **Visual Timeline:**
 ```
 Time:     0s        1s        2s        3s        4s
           │         │         │         │         │
 Profile:  ████████████████████│         │         │
                               ▼         │         │
 Address:                      ████████████████████│
                                                   ▼
 UI:                                               ✅ Update
 ```

 ### Option 2: Concurrent with `async let`

 ```swift
 func loadData() async {
     // Both start IMMEDIATELY, run in PARALLEL
     async let profile = fetchUserProfile()  // 🚀 Starts NOW
     async let address = fetchUserAddress()  // 🚀 Starts NOW (same time!)

     // WAIT for BOTH to complete
     let (p, a) = await (profile, address)   // ⏸️ Wait for both

     // Total time: 2 seconds (max of 2, 2)
     updateUI(p, a)
 }
 ```

 **Visual Timeline:**
 ```
 Time:     0s        1s        2s
           │         │         │
 Profile:  ████████████████████│
 Address:  ████████████████████│
                               ▼
 UI:                           ✅ Update (2x faster!)
 ```

 ---

 ## 🧠 What is `async let` Really?

 ```swift
 async let profile = fetchUserProfile()
 ```

 This is saying:
 > "Start this task **right now**, but I'll collect the result **later**"

 It's like placing an order at a restaurant:
 - `async let` = "I'll have the pizza" (order placed, kitchen starts cooking)
 - `await profile` = "Is my pizza ready?" (you wait to receive it)

 ```swift
 // This is what happens internally:
 async let profile = fetchUserProfile()
 //         ↓
 //    ┌────────────────────────────────────┐
 //    │ Child Task Created                 │
 //    │ Started immediately                │
 //    │ Runs concurrently with parent      │
 //    │ Result stored for later            │
 //    └────────────────────────────────────┘

 // Later when you need the result:
 let p = await profile  // Now we actually wait for it
 ```

 ---

 ## 🔄 Comparison: GCD vs async/await

 ### GCD Approach (Old Way)

 ```swift
 func loadDataGCD() {
     var profile: UserProfile?
     var address: UserAddress?
     let group = DispatchGroup()

     group.enter()
     DispatchQueue.global().async {
         fetchUserProfile { result in
             profile = result
             group.leave()
         }
     }

     group.enter()
     DispatchQueue.global().async {
         fetchUserAddress { result in
             address = result
             group.leave()
         }
     }

     group.notify(queue: .main) {
         // Both done, update UI
         updateUI(profile!, address!)
     }
 }
 ```

 ### async/await Approach (Modern Way)

 ```swift
 func loadData() async {
     async let profile = fetchUserProfile()
     async let address = fetchUserAddress()

     let (p, a) = await (profile, address)

     await MainActor.run {
         updateUI(p, a)
     }
 }
 ```

 **Same behavior, much cleaner!**

 ---

 ## 🤔 Your Question: "Can I do other things while awaiting?"

 ### Within the SAME function: NO

 ```swift
 func loadData() async {
     let profile = await fetchUserProfile()
     // ↑ Function is PAUSED here
     // Code below won't run until profile is ready

     print("This prints AFTER profile loads")
 }
 ```

 ### But the THREAD is free: YES!

 ```swift
 // On Main Thread
 Task {
     let profile = await fetchUserProfile()  // Takes 2 seconds
     // Main thread is NOT frozen during these 2 seconds
     // UI can scroll, buttons can be tapped
 }

 // User scrolls the table view - WORKS! ✅
 // User taps a button - WORKS! ✅
 // Animations play - WORKS! ✅
 ```

 ---

 ## 📊 The Key Mental Model

 ```
 ┌─────────────────────────────────────────────────────────────────┐
 │                     THREAD vs TASK                               │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                  │
 │   Think of it like a RESTAURANT:                                │
 │                                                                  │
 │   THREAD = Waiter                                                │
 │   TASK = Your Order                                              │
 │                                                                  │
 │   ┌─────────────────────────────────────────────────┐           │
 │   │ YOU: "I'll have a pizza" (await fetchPizza)     │           │
 │   │                                                  │           │
 │   │ WAITER: Takes your order to kitchen             │           │
 │   │         Doesn't stand next to you frozen!       │           │
 │   │         Goes to serve other tables              │ ← FREE!   │
 │   │                                                  │           │
 │   │ KITCHEN: Cooking pizza... (async operation)     │           │
 │   │                                                  │           │
 │   │ WAITER: Comes back when pizza is ready          │           │
 │   │         "Here's your pizza!" (resume)           │           │
 │   └─────────────────────────────────────────────────┘           │
 │                                                                  │
 │   Your ORDER (task) is waiting                                  │
 │   The WAITER (thread) is NOT waiting                            │
 │                                                                  │
 └─────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🧪 Proof: Thread is Free During await

 ```swift
 class ViewController: UIViewController {

     override func viewDidLoad() {
         super.viewDidLoad()

         // Start a long async operation
         Task {
             print("Starting fetch...")
             let data = await slowNetworkCall()  // Takes 5 seconds
             print("Fetch complete: \(data)")
         }

         print("viewDidLoad finished!")  // This prints IMMEDIATELY
     }

     func slowNetworkCall() async -> String {
         try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds
         return "Data loaded"
     }
 }

 // OUTPUT:
 // Starting fetch...
 // viewDidLoad finished!     ← Prints immediately, doesn't wait!
 // (5 seconds later)
 // Fetch complete: Data loaded

 // During those 5 seconds: UI is fully responsive! ✅
 ```

 ---

 ## 📋 Summary: Your Questions Answered

 ### Q1: "Can we have `async let` variable?"
 **YES!** It's a special syntax that starts the task immediately but lets you await the result later.

 ```swift
 async let x = someAsyncFunction()  // Starts NOW
 // ... do other setup ...
 let result = await x               // Collect result later
 ```

 ### Q2: "If I write `let profile = await fetchUserProfile()`, can I do other things?"
 **Within that function: NO** - the function pauses at that line.
 **On the thread: YES** - thread is free, UI works.

 ### Q3: "Is `await` similar to `DispatchQueue.global().async{}`?"
 **Not quite:**

 | Aspect | `DispatchQueue.async` | `await` |
 |--------|----------------------|---------|
 | Code continues? | Yes, immediately | No, function pauses |
 | Thread blocked? | No | No |
 | Result handling | Completion handler | Direct return |
 | Sequential code? | Nested callbacks | Linear, readable |

 ### Q4: "Are we waiting and can't do other work like UI scroll?"
 **The FUNCTION waits, the THREAD doesn't!**
 - Your `loadData()` function suspends at `await`
 - But the main thread can still handle UI events
 - User can scroll, tap, interact normally

 ---

 ## 🎯 Visual Summary

 ```
 ┌────────────────────────────────────────────────────────────────┐
 │              let x = await fetch()                              │
 │              vs                                                 │
 │              async let x = fetch()                              │
 ├────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │   SEQUENTIAL (let x = await):                                  │
 │   ─────────────────────────────────────────────────────────    │
 │   Task A:  ████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓           │
 │                            ↑                    ↑               │
 │                         await A              await B            │
 │                        (wait for A)    (THEN start B)           │
 │                                                                 │
 │   Total time = Time(A) + Time(B)                               │
 │                                                                 │
 │   ─────────────────────────────────────────────────────────    │
 │                                                                 │
 │   CONCURRENT (async let):                                       │
 │   ─────────────────────────────────────────────────────────    │
 │   Task A:  ████████████████                                    │
 │   Task B:  ████████████████████████  (started at same time!)   │
 │                            ↑                                    │
 │                     await (A, B)                                │
 │                  (wait for BOTH)                                │
 │                                                                 │
 │   Total time = max(Time(A), Time(B))                           │
 │                                                                 │
 └────────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 💡 Quick Reference

 ```swift
 // ❌ SLOW: One after another (4 seconds total)
 let a = await fetchA()  // 2 sec
 let b = await fetchB()  // 2 sec

 // ✅ FAST: Both at once (2 seconds total)
 async let a = fetchA()  // starts immediately
 async let b = fetchB()  // starts immediately
 let (resultA, resultB) = await (a, b)  // wait for both
 ```

 Does this clarify the difference? Would you like me to explain `Task`, `TaskGroup`, or how suspension points work under the hood?
 */

//MARK: Question 9
/*
 Next question that was asked to me was : How would you implement your own personal dispatch group now for that I said race condition of counter should be kept in mind, thus I am proposing to use actor here meaning each thread can access this once at a time and was proposing this sort of solution:

 actor PersonalDispatchGroup {
     private var counter : Int = 0
     func enter() {
         counter += 1
     }
     func leave() {
         counter -= 1
         if counter <= 0 {
             notify(<#() -> Void#>)
         }
     }
     func notify(_ notifyHandler: @escaping ()->Void) {
         notifyHandler()
     }
 }
*/
//MARK: Answer 9
/*
 # Building Your Own DispatchGroup with Actor

 Great thinking using `actor` for thread safety! Your approach is correct, but there are a few issues. Let me show you the problems and the fix.

 ---

 ## 🐛 Issues with Your Code

 ```swift
 actor PersonalDispatchGroup {
     private var counter: Int = 0

     func enter() {
         counter += 1
     }

     func leave() {
         counter -= 1
         if counter <= 0 {
             notify(/* ❌ What goes here? No handler stored! */)
         }
     }

     func notify(_ notifyHandler: @escaping () -> Void) {
         notifyHandler()  // ❌ This just runs it immediately
     }
 }
 ```

 **Problems:**
 1. `notify()` should **store** the handler, not run it immediately
 2. When `leave()` is called, there's no stored handler to call
 3. Need to specify which queue to run the handler on

 ---

 ## ✅ Corrected Implementation

 ```swift
 actor PersonalDispatchGroup {
     private var counter: Int = 0
     private var notifyHandler: (() -> Void)?
     private var notifyQueue: DispatchQueue?

     func enter() {
         counter += 1
     }

     func leave() {
         counter -= 1
         checkAndNotify()
     }

     // Store the handler for later
     func notify(queue: DispatchQueue, handler: @escaping () -> Void) {
         self.notifyQueue = queue
         self.notifyHandler = handler
         checkAndNotify()  // In case counter is already 0
     }

     private func checkAndNotify() {
         // Only notify when counter reaches 0 AND handler exists
         if counter == 0, let handler = notifyHandler, let queue = notifyQueue {
             notifyHandler = nil  // Clear so it only fires once
             queue.async {
                 handler()
             }
         }
     }
 }
 ```

 ---

 ## 📊 How It Works

 ```
 ┌─────────────────────────────────────────────────────────────┐
 │                    Flow Diagram                              │
 ├─────────────────────────────────────────────────────────────┤
 │                                                              │
 │   enter()          enter()         notify()                 │
 │      │                │               │                      │
 │      ▼                ▼               ▼                      │
 │   counter=1      counter=2      handler stored              │
 │                                                              │
 │                                                              │
 │   leave()          leave()                                  │
 │      │                │                                      │
 │      ▼                ▼                                      │
 │   counter=1      counter=0  ──────► handler() fires!        │
 │                                                              │
 └─────────────────────────────────────────────────────────────┘
 ```

 ---

 ## 🧪 Usage Example

 ```swift
 let group = PersonalDispatchGroup()

 Task {
     await group.enter()
     // Simulate async work
     try? await Task.sleep(nanoseconds: 1_000_000_000)
     print("Task 1 done")
     await group.leave()
 }

 Task {
     await group.enter()
     try? await Task.sleep(nanoseconds: 2_000_000_000)
     print("Task 2 done")
     await group.leave()
 }

 await group.notify(queue: .main) {
     print("✅ All tasks complete!")
 }

 // Output:
 // Task 1 done
 // Task 2 done
 // ✅ All tasks complete!
 ```

 ---

 ## 🔑 Why Actor Works Here

 ```swift
 actor PersonalDispatchGroup {
     private var counter: Int = 0  // ✅ Protected automatically!
 }
 ```

 | Without Actor | With Actor |
 |--------------|------------|
 | Two threads modify `counter` at same time | Only one access at a time |
 | Race condition: counter = garbage | Always correct value |
 | Need manual locks (`NSLock`) | Automatic isolation |

 ---

 ## 💡 Key Interview Points

 1. **Why actor?** → Automatic thread safety for `counter`
 2. **Store handler** → `notify()` saves it, `leave()` triggers it
 3. **Check `== 0` not `<= 0`** → Avoid multiple notifications
 4. **Clear handler after use** → Prevent duplicate calls

 Your intuition about using `actor` was spot on! The main fix was storing the handler instead of trying to pass it at call time.
 */


/*
 Tomorrow at 2:15 PM, I have a Hiring Manager round of Meesho for iOS SDE II refer to the image of what would be expected from that interview, I have attached my resume also, I want to prepared for this round thoroughly, for this in
 1. Thorough understanding of the projects contributed to, in the current organization : I would like to explain 1. Native Implementation of Post Purchase Flow for (Canada, Mexico) market (i.e. so for this I want to become all well aware of all the things from this Glass Repo we have
 2. Ownership taken in the current organisation to build on a project/ a feature && Clarity about roles and responsibilities of the role.: For this I want to extend the above Native Implementation of Post Purchase and also would like to add :
 Led ideation and launch of OMNI ID for global markets, increasing order verification
 efficiency by 40% and streamlining pick-up and delivery workflows from the resume so would just brush the OMNI ID concept.
 3. Cultural fitment process:- Growth mindset, understanding of Meesho's business and inclination towards contributing to Meesho’s growth. : Help me prepare for these questions, have thorough understanding of how Meesho works, in this I want to add that concept of Foundation Model introduced by Apple in WWDC 25 , if we can use the local models for our Meesho flow and how exactly that would happen (NOTE: I don't have any understanding of how FoundationModel from Apple work and how we can integrate in iOS app but actually wanted to pitch those ideas so it feel that I am eager to learn and adaptive along with completing all the iOS tasks and ready to take initiatives)
 */


