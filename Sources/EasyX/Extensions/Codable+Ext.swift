import Foundation

// MARK: - Encodable Extensions

public extension Encodable {
    /// Converts the encodable object to Data
    /// - Parameter encoder: JSONEncoder to use (default is JSONEncoder with default settings)
    /// - Returns: Data representation of the object
    /// - Throws: Encoding errors
    func toData(using encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        return try encoder.encode(self)
    }
    
    /// Converts the encodable object to a JSON string
    /// - Parameter encoder: JSONEncoder to use (default is JSONEncoder with default settings)
    /// - Returns: JSON string representation of the object
    /// - Throws: Encoding errors
    func toJSONString(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        let data = try toData(using: encoder)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: [], debugDescription: "Failed to convert encoded data to UTF-8 string"))
        }
        return string
    }
    
    /// Converts the encodable object to a JSON string, returning nil if encoding fails
    /// - Parameters:
    ///   - prettyPrinted: Whether to format the JSON with indentation and line breaks
    ///   - sortedKeys: Whether to sort the keys in the JSON output
    /// - Returns: JSON string representation of the object or nil if encoding fails
    func toJSONString(prettyPrinted: Bool = false, sortedKeys: Bool = false) -> String? {
        let encoder = JSONEncoder()
        var formatting: JSONEncoder.OutputFormatting = []
        
        if prettyPrinted {
            formatting.insert(.prettyPrinted)
        }
        
        if sortedKeys {
            formatting.insert(.sortedKeys)
        }
        
        encoder.outputFormatting = formatting
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    /// Converts the encodable object to a dictionary
    /// - Parameter encoder: JSONEncoder to use (default is JSONEncoder with default settings)
    /// - Returns: Dictionary representation of the object
    /// - Throws: Encoding errors
    func toDictionary(using encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try toData(using: encoder)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: [], debugDescription: "Failed to convert encoded data to dictionary"))
        }
        return dictionary
    }
}

// MARK: - Decodable Extensions

public extension Decodable {
    /// Creates a new instance from JSON data
    /// - Parameters:
    ///   - data: JSON data to decode
    ///   - decoder: JSONDecoder to use (default is JSONDecoder with default settings)
    /// - Returns: Instance of the decodable type
    /// - Throws: Decoding errors
    static func from(data: Data, using decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        return try decoder.decode(Self.self, from: data)
    }
    
    /// Creates a new instance from a JSON string
    /// - Parameters:
    ///   - string: JSON string to decode
    ///   - decoder: JSONDecoder to use (default is JSONDecoder with default settings)
    /// - Returns: Instance of the decodable type
    /// - Throws: Decoding errors
    static func from(jsonString string: String, using decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        guard let data = string.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [], debugDescription: "Failed to convert string to UTF-8 data"))
        }
        return try from(data: data, using: decoder)
    }
    
    /// Creates a new instance from a dictionary
    /// - Parameters:
    ///   - dictionary: Dictionary to decode
    ///   ///   - decoder: JSONDecoder to use (default is JSONDecoder with default settings)
    /// - Returns: Instance of the decodable type
    /// - Throws: Decoding errors
    static func from(dictionary: [String: Any], using decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try from(data: data, using: decoder)
    }
}

// MARK: - Deep Copy Extension (for types that conform to both Encodable and Decodable)

public extension Encodable where Self: Decodable {
    /// Creates a deep copy of the object by encoding and decoding
    /// - Returns: A new instance with the same data
    /// - Throws: Encoding/decoding errors
    func deepCopy() throws -> Self {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

// MARK: - Swift 6 Sendable Encoder/Decoder Factories

/// Factory for creating configured JSONEncoders
/// Thread-safe by design - creates a new encoder instance each time
public enum JSONEncoderFactory {
    public enum DateEncodingStrategy {
        case iso8601
        case secondsSince1970
        case millisecondsSince1970
        case formatted(DateFormatter)
    }
    
    /// Creates a new JSONEncoder with specified configuration
    /// - Parameters:
    ///   - dateStrategy: Strategy for encoding Date values
    ///   - keyEncodingStrategy: Strategy for encoding keys
    ///   - outputFormatting: JSON output formatting options
    /// - Returns: A newly configured JSONEncoder
    public static func makeEncoder(
        dateStrategy: DateEncodingStrategy = .iso8601,
        keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
        outputFormatting: JSONEncoder.OutputFormatting = []
    ) -> JSONEncoder {
        let encoder = JSONEncoder()
        
        // Configure date encoding strategy
        switch dateStrategy {
        case .iso8601:
            encoder.dateEncodingStrategy = .iso8601
        case .secondsSince1970:
            encoder.dateEncodingStrategy = .secondsSince1970
        case .millisecondsSince1970:
            encoder.dateEncodingStrategy = .millisecondsSince1970
        case .formatted(let formatter):
            encoder.dateEncodingStrategy = .formatted(formatter)
        }
        
        // Configure key encoding strategy
        encoder.keyEncodingStrategy = keyEncodingStrategy
        
        // Configure output formatting
        encoder.outputFormatting = outputFormatting
        
        return encoder
    }
}

/// Factory for creating configured JSONDecoders
/// Thread-safe by design - creates a new decoder instance each time
public enum JSONDecoderFactory {
    public enum DateDecodingStrategy {
        case iso8601
        case secondsSince1970
        case millisecondsSince1970
        case formatted(DateFormatter)
    }
    
    /// Creates a new JSONDecoder with specified configuration
    /// - Parameters:
    ///   - dateStrategy: Strategy for decoding Date values
    ///   - keyDecodingStrategy: Strategy for decoding keys
    /// - Returns: A newly configured JSONDecoder
    public static func makeDecoder(
        dateStrategy: DateDecodingStrategy = .iso8601,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Configure date decoding strategy
        switch dateStrategy {
        case .iso8601:
            decoder.dateDecodingStrategy = .iso8601
        case .secondsSince1970:
            decoder.dateDecodingStrategy = .secondsSince1970
        case .millisecondsSince1970:
            decoder.dateDecodingStrategy = .millisecondsSince1970
        case .formatted(let formatter):
            decoder.dateDecodingStrategy = .formatted(formatter)
        }
        
        // Configure key decoding strategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        
        return decoder
    }
}

/*
// MARK: - Usage Examples

// Example of a struct implementing Codable
struct User: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
    let createdAt: Date
    
    // Custom coding keys example
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case createdAt = "created_at"
    }
}

// Example use

 // Creating an object
 let user = User(id: 1, name: "John Doe", email: "john@example.com", createdAt: Date())
 
 // Encoding examples
 do {
     // To JSON Data
     let jsonData = try user.toData()
     
     // To JSON String (throws version)
     let jsonString = try user.toJSONString()
     print(jsonString)
     
     // To JSON String (non-throwing version with pretty printing)
     if let prettyJson = user.toJSONString(prettyPrinted: true) {
         print(prettyJson)
     }
     
     // To JSON String (non-throwing with pretty printing and sorted keys)
     if let formattedJson = user.toJSONString(prettyPrinted: true, sortedKeys: true) {
         print(formattedJson)
     }
     
     // To Dictionary
     let dictionary = try user.toDictionary()
     print(dictionary)
     
     // Create a deep copy (works because User conforms to both Encodable and Decodable)
     let userCopy = try user.deepCopy()
 } catch {
     print("Encoding error: \(error)")
 }
 
 // Decoding examples
 do {
     // From JSON Data
     let jsonData: Data = ... // some JSON data
     let userFromData = try User.from(data: jsonData)
     
     // From JSON String
     let jsonString = #"{"id":1,"name":"John Doe","email":"john@example.com","created_at":"2023-06-12T10:30:00Z"}"#
     let userFromString = try User.from(jsonString: jsonString)
     
     // From Dictionary
     let dictionary: [String: Any] = ["id": 1, "name": "John Doe", "email": "john@example.com", "created_at": "2023-06-12T10:30:00Z"]
     let userFromDict = try User.from(dictionary: dictionary)
 } catch {
     print("Decoding error: \(error)")
 }
 
 // Using Swift 6 Sendable-friendly factories
 let encoder = JSONEncoderFactory.makeEncoder(
     dateStrategy: .iso8601,
     keyEncodingStrategy: .convertToSnakeCase,
     outputFormatting: [.prettyPrinted, .sortedKeys]
 )
 
 let decoder = JSONDecoderFactory.makeDecoder(
     dateStrategy: .iso8601,
     keyDecodingStrategy: .convertFromSnakeCase
 )
 */
