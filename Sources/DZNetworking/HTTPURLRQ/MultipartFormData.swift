//
//  MultipartFormData.swift
//  
//
//  Created by Nikhil Nigade on 21/11/22.
//

import Foundation

/// Internal class used to manage multi-part form data for `POST` and `PUT` requests, especially those involving files. 
public final class MultipartFormData {
  public let boundary = String(format: "------------------------%08X%08X", arc4random(), arc4random())
  public let lineEnding = "\r\n"
  
  private(set) public var body = Data()
  
  public func add(payload: Data, name: String, filename: String?, contentType: String?) {
    if !body.isEmpty {
      // if we already added something then we need an additional newline
      body.append(lineEnding.data(using: .utf8)!)
    }
    
    let line1 = String(format: "--%@%@", boundary, lineEnding)
    let line2: String = {
      var line = "Content-Disposition: form-data; "
      line = line.appendingFormat("name=\"%@\"", name)
      
      if let filename, !filename.isEmpty {
        line = line.appendingFormat("; filename=\"%@\"", filename)
        line.append(lineEnding)
      }
      
      if let contentType, !contentType.isEmpty {
        line = line.appendingFormat("Content-Type: %@%@", contentType, lineEnding)
      }
      
      return line
    }()
    
    body.append(line1.data(using: .utf8)!)
    body.append(line2.data(using: .utf8)!)
    body.append(payload)
  }
  
  public func add(file: Data, name: String, filename: String, contentType: String = "application/octet-stream") {
    add(payload: file, name: name, filename: filename, contentType: contentType)
  }
  
  public func add(text: String, parameterName: String) {
    guard let payload = text.data(using: .utf8) else {
      return
    }
    
    add(payload: payload, name: parameterName, filename: nil, contentType: nil)
  }
  
  public func add(parameters: [String:String]) {
    parameters.forEach { (key: String, value: String) in
      add(text: key, parameterName: value)
    }
  }
}
