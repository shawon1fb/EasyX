//
//  KeychainManager.swift
//  EasyX
//
//  Created by shahanul on 11/20/24.
//

import Foundation
import Security

// MARK: - KeychainManager
public final class KeychainManager: Sendable {
  public static let shared = KeychainManager()

  private init() {}

  public func save(_ value: String, forKey key: String) -> OSStatus {
    if let data = value.data(using: .utf8) {
      let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
      ]

      // First try to delete any existing item
      SecItemDelete(query as CFDictionary)

      // Then add the new item
      return SecItemAdd(query as CFDictionary, nil)
    }
    return errSecParam
  }

  public func get(forKey key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess {
      if let data = dataTypeRef as? Data,
        let value = String(data: data, encoding: .utf8)
      {
        return value
      }
    }
    return nil
  }
}

// MARK: - KeychainManager Extension
extension KeychainManager {
  public func delete(forKey key: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]
    SecItemDelete(query as CFDictionary)
  }
}

public final class DeviceIDManager: Sendable {
  public static let shared = DeviceIDManager()

  private let keychainManager = KeychainManager.shared
  private let deviceIDKey = "com.app.unique.device.id"
  //private let defaults = UserDefaults.standard

  private init() {}

  public func getDeviceID() -> String {
    // First try: Check Keychain
    if let existingID = keychainManager.get(forKey: deviceIDKey) {
      // Found in Keychain - ensure it's also in UserDefaults as backup
      UserDefaults.standard.set(existingID, forKey: deviceIDKey)
      return existingID
    }

    // Second try: Check UserDefaults if Keychain failed
    if let fallbackID = UserDefaults.standard.string(forKey: deviceIDKey) {
      // Found in UserDefaults - try to save it back to Keychain
      let saveStatus = keychainManager.save(fallbackID, forKey: deviceIDKey)
      if saveStatus == errSecSuccess {
        print("Successfully restored Keychain from UserDefaults backup")
      }
      return fallbackID
    }

    // If neither exists, generate new ID
    let newID = UUID().uuidString

    // Try to save in Keychain first
    let saveStatus = keychainManager.save(newID, forKey: deviceIDKey)

    if saveStatus != errSecSuccess {
      print("Warning: Failed to save device ID to Keychain. Status: \(saveStatus)")
    }

    // Always save to UserDefaults as backup
    UserDefaults.standard.set(newID, forKey: deviceIDKey)

    return newID
  }

  // Optional: Method to clear device ID (for testing or reset scenarios)
  public func resetDeviceID() {
    keychainManager.delete(forKey: deviceIDKey)
    UserDefaults.standard.removeObject(forKey: deviceIDKey)
  }
}
