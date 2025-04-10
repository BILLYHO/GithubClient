import Foundation
import KeychainAccess

class KeychainService {
  static let shared = KeychainService()
  private let keychain = Keychain(service: "com.githubclient")

  private init() {}

  func save(key: String, data: Data) -> Bool {
    do {
      try keychain.set(data, key: key)
      return true
    } catch {
      print("Error saving to keychain: \(error)")
      return false
    }
  }

  func load(key: String) -> Data? {
    do {
      return try keychain.getData(key)
    } catch {
      print("Error loading from keychain: \(error)")
      return nil
    }
  }

  func delete(key: String) -> Bool {
    do {
      try keychain.remove(key)
      return true
    } catch {
      print("Error deleting from keychain: \(error)")
      return false
    }
  }
}
