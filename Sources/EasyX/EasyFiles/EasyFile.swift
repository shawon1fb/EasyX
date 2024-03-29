//
//  EasyFile.swift
//
//
//  Created by shahanul on 3/2/24.
//

import Foundation

public enum FileError: Error {
    case readingFailed, decodingFailed, encodingFailed,fileAlreadyExists
}
public enum FileMode {
    /// The mode for opening a file only for reading.
    case read
    
    /// Mode for opening a file for reading and writing. The file is
    /// overwritten if it already exists. The file is created if it does not
    /// already exist.
    case write
    
    /// Mode for opening a file for reading and writing to the
    /// end of it. The file is created if it does not already exist.
    case append
    
    /// Mode for opening a file for writing *only*. The file is
    /// overwritten if it already exists. The file is created if it does not
    /// already exist.
    case writeOnly
    
    /// Mode for opening a file for writing *only* to the
    /// end of it. The file is created if it does not already exist.
    case writeOnlyAppend
}

public protocol IFile:Codable,Sendable{
    func exists() -> Bool
    func delete() -> Bool
    func readAsBytes() throws -> Data
    func readAsString() throws -> String
    func getPath() -> String
    func writeAsBytes(_ bytes: Data, mode: FileMode  )  throws -> IFile
    func writeAsString(_ string: String, mode: FileMode )  throws -> IFile
    func createSync( recursive:Bool,  exclusive:Bool ) throws
}

public  struct File: IFile {
    
    public  func createSync(recursive: Bool, exclusive: Bool) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            if exclusive {
                throw FileError.fileAlreadyExists
            } else {
                return // File already exists, no action needed
            }
        }
        // Create intermediate directories if necessary
        if recursive {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        
        // Create the file itself
        FileManager.default.createFile(atPath: url.path, contents: nil)
    }
    
    
    
    private let url: URL
    
    func getUrl()->URL{
        return url
    }
    
    public init(url: URL) {
        self.url = url
    }
    
    public func exists() -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func readAsBytes() throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw FileError.readingFailed
        }
    }
    
    public  func readAsString() throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw FileError.readingFailed
        }
    }
    
    public func getPath() -> String {
        return url.path
    }
    
    public func writeAsBytes(_ bytes: Data, mode: FileMode = .write) throws -> IFile {
        do {
            
            if exists() == false{
                try createSync(recursive: true, exclusive: false)
            }
            
            switch mode {
            case .write, .writeOnly:
                try bytes.write(to: url)
            case .append, .writeOnlyAppend:
                let fileHandle = try FileHandle(forWritingTo: url)
                defer {
                    fileHandle.closeFile()
                }
                fileHandle.seekToEndOfFile()
                fileHandle.write(bytes)
            default:
                break
            }
            return self
        } catch {
            throw FileError.encodingFailed
        }
    }
    
    public func writeAsString(_ string: String, mode: FileMode = .write) throws -> IFile {
        guard let data = string.data(using: .utf8) else {
            throw FileError.encodingFailed
        }
        return try writeAsBytes(data, mode: mode)
    }
    
    public func delete() -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            // Handle any errors occurring during file deletion
            return false
        }
    }
}
extension File:ReferenceConvertible{
    public func _bridgeToObjectiveC() -> NSURL {
        return NSURL(fileURLWithPath: url.path, isDirectory: false)
    }
    
    public static func _forceBridgeFromObjectiveC(_ source: NSURL, result: inout File?) {
        result = File(url: source as URL)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSURL, result: inout File?) -> Bool {
        result = File(url: source as URL)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSURL?) -> File {
        return File(url: source! as URL)
    }
    
    public var debugDescription: String {
        return "\(url.path)"
    }
    
    public var description: String {
        return "\(url.path)"
    }
    
    public typealias _ObjectiveCType = NSURL
    
    public typealias ReferenceType = NSURL
}

extension File:Equatable{
    public static func == (lhs: File, rhs: File) -> Bool {
        return  lhs.getUrl() == rhs.getUrl()
    }
    
}
