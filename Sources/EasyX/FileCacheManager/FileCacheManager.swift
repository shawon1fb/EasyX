//
//  FileCacheManager.swift
//
//
//  Created by Shahanul Haque on 7/13/24.
//

import Foundation

//MARK: protocal
public protocol BaseCacheManager {
  func getSingleFile(url: String, key: String?, headers: [String: String]?) async throws
    -> URL
  func preloads(urls: [String], headers: [String: String]?) async
}

public actor FileCacheManager: BaseCacheManager {

  private let cacheDirectory: URL
  private let cacheExpirationInterval: TimeInterval 

  public init(directory: URL? = nil, expirationInterval: TimeInterval? = nil) {
    if let directory = directory {
      cacheDirectory = directory
    } else {
      let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
      cacheDirectory = paths[0]
    }
    if let expirationInterval = expirationInterval {
      cacheExpirationInterval = expirationInterval
    } else {
      cacheExpirationInterval = 7 * 24 * 60 * 60  // 7 days
    }

    Task {
      await cleanUpOldFiles()
    }
  }

  public func getSingleFile(url: String, key: String?, headers: [String: String]?) async throws
    -> URL
  {
    let cacheKey = key ?? url
    let cacheFileURL = cacheDirectory.appendingPathComponent(cacheKey.toBase64())

    // Check if file is cached and not too old
    if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: cacheFileURL.path),
      let modificationDate = fileAttributes[.modificationDate] as? Date,
      modificationDate.timeIntervalSinceNow > -cacheExpirationInterval
    {
      return cacheFileURL
    }

    // File is not cached or is too old, download it
    guard let requestURL = URL(string: url) else {
      throw NSError(domain: "InvalidURL", code: 0, userInfo: nil)
    }

    var request = URLRequest(url: requestURL)
    headers?.forEach { key, value in
      request.setValue(value, forHTTPHeaderField: key)
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode
    else {
      throw NSError(domain: "InvalidResponse", code: 0, userInfo: nil)
    }

    try data.write(to: cacheFileURL)
    return cacheFileURL
  }

  public func preloads(urls: [String], headers: [String: String]? = nil) async {
    await withTaskGroup(of: Void.self) { taskGroup in
      for url in urls {
        taskGroup.addTask {
          do {
            _ = try await self.getSingleFile(url: url, key: nil, headers: headers)
          } catch {
            print("Failed to preload URL: \(url), error: \(error)")
          }
        }
      }
    }
  }

  public func cleanUpOldFiles() {
    let fileManager = FileManager.default
    let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey]
    let directoryEnumerator = fileManager.enumerator(
      at: cacheDirectory, includingPropertiesForKeys: Array(resourceKeys),
      options: .skipsHiddenFiles)!

    for case let fileURL as URL in directoryEnumerator {
      do {
        let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
        if let modificationDate = resourceValues.contentModificationDate,
          modificationDate.timeIntervalSinceNow < -cacheExpirationInterval
        {
          try fileManager.removeItem(at: fileURL)
        }
      } catch {
        print("Failed to remove file: \(fileURL), error: \(error)")
      }
    }
  }
}
