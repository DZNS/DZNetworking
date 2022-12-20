//
//  DZURLSession.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation

public typealias RequestModifierBlock = (_ urlRequest: NSMutableURLRequest) -> NSMutableURLRequest
public typealias RedirectModifierBlock = (_ task: URLSessionTask, _ request: URLRequest, _ redirectResponse: HTTPURLResponse) -> URLRequest

/// `DZURLSession` is the base class for all REST API networking.
///
/// It can be used as-is, or you can subclass it to override various features of the reciever.
///
/// You can use the shared session for general networking in your apps, however, it is strongly recommended to create your own instance with a configuration satisfying the model's requirements.
///
/// Example:
/// ```
/// let session = DZURLSession()
/// session.baseURL = URL(string:"http://api.myapp.com/")!
///
/// let (data, _) = try await session.GET("/posts", query: ["userID": "1"])
/// ```
/// 
open class DZURLSession: NSObject {
  // MARK: Public
  
  /// shared instance, configured with `URLSessionConfiguration.default` and a privately managed operation queue
  public static let shared = DZURLSession()
  
  /// the `URLSession` configuration
  public let configuration: URLSessionConfiguration
  
  /// when setting `true`, use the appropriate `URLSessionConfiguration.background(withIdentifier:)` initialiser for the configuration parameter
  public let isBackgroundSession: Bool
  
  /// delegate of the receiever, to handle optionally implemented protocol methods.
  ///
  /// Some `URLSession.Delegate` invocations are also forwarded to this implementation.
  public weak var delegate: URLSessionDelegate? = nil
  
  /// the base URL to use for all requests.
  ///
  /// Example: https://api.example.com/v3/
  public var baseURL: URL? = nil
  
  /// common HTTP headers for all requests sent from the receiver
  ///
  /// Example: Authentication headers
  public var httpHeaders: [String: AnyHashable] = [:]
  
  /// the maximum HTTP status code value to be treated as a successful response. Responses with status code values above this threshold will be treated as an error.
  ///
  /// Example: 304
  /// Default: 399
  public var maxSuccessStatusCode: Int = 399
  
  /// The request modifier block, if provided, is called before the `URLRequest` is actually used in a request. You can utilize this block to add additional data to the request if required.
  ///
  /// Example: adding authentication query parameters to the URL which are dynamically generated (Flickr oAuth API).
  public var requestModifier: RequestModifierBlock? = nil
  
  /// The redirect modifier block, if provided, is called when a redirection is occuring. You can utilize this block to add additional data to the request if required or simply inspect it.
  public var redirectModifier: RedirectModifierBlock? = nil
  
  /// The response parser for HTTP payloads
  ///
  /// When `nil`, the response object will always be `Data` when non-nil.
  ///
  /// When a parser value is set, the result type will be determined by the response parser's output type
  public var responseParser: DZResponseParser? = nil
  
  /// the background completion handler received by the app for background data/download tasks
  public var backgroundCompletionHandler: (() -> Void)? {
    get {
      taskHandler.completionHandler
    }
    set {
      taskHandler.completionHandler = newValue
    }
  }
  
  // MARK: Private
  internal let taskHandler = TaskHandler()
  
  /// internal private operation queue
  private let operationQueue: OperationQueue
  
  internal lazy var session: URLSession = {
    let session = URLSession(configuration: configuration, delegate: taskHandler, delegateQueue: operationQueue)
    session.sessionDescription = "DZURLSession Managed: \(UUID().uuidString)"
    return session
  }()

  // MARK: Initialisers
  
  /// Create a new instance of the receiver
  /// - Parameters:
  ///   - configuration: configuration for the internal `URLSession` object
  ///   - operationQueue: operation queue on which network requests will be initiated, must not be the `main` operation queue. You can use the `DZURLSession.defaultOperationQueue(for:)` class method to obtain one as well.
  ///   - isBackgroundSession: `true` for sessions which should handle requests when the app is in the background
  ///   - delegate: optional object that handles `URLSessionDelegate` invocations on behalf of the receiver
  public init(configuration: URLSessionConfiguration, operationQueue: OperationQueue, isBackgroundSession: Bool, delegate: URLSessionDelegate? = nil) {
    precondition(operationQueue != .main, "Should not use the main operation queue")
    configuration.shouldUseExtendedBackgroundIdleMode = true
    
    self.configuration = configuration
    self.operationQueue = operationQueue
    self.isBackgroundSession = isBackgroundSession
    self.delegate = delegate
    
    super.init()
  }
  
  /// Convenience initialiser that creates an ephemeral session.
  ///
  /// This should only be used when you need an ad-hoc instance of the receiver.
  convenience public override init() {
    self.init(
      configuration: .ephemeral,
      operationQueue: DZURLSession.defaultOperationQueue(),
      isBackgroundSession: false
    )
  }
  
  // MARK: Public
  
  /// Default operation queue to use for the receiver
  ///
  /// You can create and use your own, or use this prepared one for convenience
  /// - Parameter backgroundSession: when `true`, limits the number of simultaneous requests to `1`
  /// - Returns: operation queue for the internal `URLSession`
  public class func defaultOperationQueue(for backgroundSession: Bool = false) -> OperationQueue {
    let opQueue = OperationQueue()
    opQueue.maxConcurrentOperationCount = backgroundSession ? 1 : 5
    return opQueue
  }
  
  open override var description: String {
    "\(super.description); session: \(session); operationQueue: \(operationQueue);"
  }
}
