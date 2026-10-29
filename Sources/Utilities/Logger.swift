import Foundation
import os

enum AppLog {
    static let network = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "network")
    static let protocolEvents = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "protocol")
}
