//
//  TaskHandler.swift
//  
//
//  Created by Nikhil Nigade on 19/12/22.
//

import Foundation

internal final class DataTaskHandler {
  typealias Completion = (Result<(Data?, URLResponse), Error>) -> Void
  
  var data: Data?
  var completion: Completion?
  
  internal init(_ completion: DataTaskHandler.Completion? = nil) {
    self.completion = completion
  }
}

internal final class TaskHandlersDictionary {
  private let lock = NSLock()
  private var handlers = [URLSessionTask: DataTaskHandler]()
  
  subscript(task: URLSessionTask) -> DataTaskHandler? {
    get {
      lock.lock()
      defer { lock.unlock() }
      return handlers[task]
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      handlers[task] = newValue
    }
  }
}

/// TaskHandler manages delegate calls from the URLSession and dispatching of success/failure callbacks as tasks are completed.
///
/// This is internally handled by the `DZURLSession` class and shouldn't be required to use directly unless you're subclassing `DZURLSession`.
public final class TaskHandler: NSObject {
  var completionHandler: (() -> Void)?
  
  var handlers = TaskHandlersDictionary()  
}

// MARK: - URLSessionDelegate
extension TaskHandler: URLSessionDelegate {
  public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    completionHandler?()
    completionHandler = nil
  }
}

// MARK: - URLSessionTaskDelegate
extension TaskHandler: URLSessionTaskDelegate {
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let handler = handlers[task] else {
      return
    }
    
    // consume the handler so it cannot be called again
    handlers[task] = nil
    
    if let error = error {
      handler.completion?(.failure(error))
    }
    else {
      handler.completion?(.success((handler.data, task.response!)))
    }
  }
}

// MARK: - URLSessionDataTaskDelegate
extension TaskHandler: URLSessionDataDelegate {
  
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
    return .allow
  }
  
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    guard let response = dataTask.response as? HTTPURLResponse,
          response.statusCode != 304 else {
      return
    }
    
    guard let handler = handlers[dataTask] else {
      assertionFailure("No handler registered for this task")
      return
    }
    
    var newData = handler.data ?? Data()
    newData.append(data)
    
    handler.data = newData
  }
  
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
    guard let handler = handlers[dataTask] else {
      return
    }
    
    handlers[downloadTask] = handler
    handlers[dataTask] = nil
  }
  
}

// MARK: - URLSessionDownloadDelegate
extension TaskHandler: URLSessionDownloadDelegate {
  
  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let response = downloadTask.response as? HTTPURLResponse,
          response.statusCode != 304 else {
      return
    }
    
    guard let handler = handlers[downloadTask] else {
      assertionFailure("No handler registered for this task")
      return
    }
    
    if let data = try? Data(contentsOf: location) {
      var newData = handler.data ?? Data()
      newData.append(data)
      
      handler.data = newData
    }
  }
  
}
