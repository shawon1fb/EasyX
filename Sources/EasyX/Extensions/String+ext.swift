//
//  File.swift
//
//
//  Created by Shahanul Haque on 7/13/24.
//

import CryptoKit
import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#elseif canImport(MobileCoreServices)
import MobileCoreServices
#endif


//base64
extension String {
  public func toBase64() -> String {
    return Data(self.utf8).base64EncodedString()
  }
}

//Hashing
extension String {
  public func basicHash() -> String {
    return self.hash.description
  }

  public func sha256() -> String? {
    guard let data = self.data(using: .utf8) else {
      return nil
    }
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }
}
// URL utils
extension String {

  // Check if the string is a valid URL with http or https scheme
  public var isWebURL: Bool {
    guard let url = URL(string: self) else { return false }
    return url.scheme == "http" || url.scheme == "https"
  }

  // Convert the string to a URL object with a valid web scheme
  public var toWebURL: URL? {
    guard self.isWebURL else { return nil }
    return URL(string: self)
  }

  // Get the absolute string of the URL
  public var webUrlString: String? {
    self.toWebURL?.absoluteString
  }
}
extension String {
   public func mimeType() -> String {
        // Safely unwrap the URL
        guard let url = URL(string: self) else {
            return "application/octet-stream"
        }
        
        let pathExtension = url.pathExtension

        #if canImport(UniformTypeIdentifiers)
        // Use UniformTypeIdentifiers if available (iOS 14+/macOS 11+)
        if let uti = UTType(filenameExtension: pathExtension),
           let mimeType = uti.preferredMIMEType {
            return mimeType
        }
        #elseif canImport(MobileCoreServices)
        // Fallback to MobileCoreServices (iOS/macOS earlier versions)
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
           let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() as String? {
            return mimeType
        }
        #endif

        return "application/octet-stream"
    }
}
