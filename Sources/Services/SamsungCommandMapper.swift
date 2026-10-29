import Foundation

/// Encodes the public Samsung `ms.remote.control` channel payloads.
/// Key delivery is fire-and-forget: the TV does not acknowledge every key.
enum SamsungCommandMapper {
    static func payload(for command: RemoteCommand) throws -> [String: Any] {
        switch command {
        case .launchApplication(let app):
            var data: [String: Any] = ["appId": app.id, "action_type": "DEEP_LINK"]
            if let deepLink = app.deepLink, !deepLink.isEmpty { data["metaTag"] = deepLink }
            return [
                "method": "ms.channel.emit",
                "params": ["event": "ed.apps.launch", "to": "host", "data": data]
            ]
        case .typeText(let text):
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RemoteError.unsupportedCommand
            }
            return ["method": "ms.remote.control", "params": [
                "Cmd": Data(text.utf8).base64EncodedString(),
                "DataOfCmd": "base64",
                "TypeOfRemote": "SendInputString"
            ]]
        default:
            guard let key = key(for: command) else { throw RemoteError.unsupportedCommand }
            return remotePayload(command: "Click", data: key, remoteType: "SendRemoteKey")
        }
    }

    static func data(for command: RemoteCommand) throws -> Data {
        try JSONSerialization.data(withJSONObject: payload(for: command), options: [])
    }

    static func textSessionStartedData() throws -> Data {
        try JSONSerialization.data(withJSONObject: ["method": "ms.channel.emit", "params": [
            "event": "custom.remote.textReceived", "to": "broadcast"
        ]], options: [])
    }

    static func textSessionEndedData() throws -> Data {
        try JSONSerialization.data(withJSONObject: ["method": "ms.remote.control", "params": [
            "TypeOfRemote": "SendInputEnd"
        ]], options: [])
    }

    static func installedApplicationsData() throws -> Data {
        try JSONSerialization.data(withJSONObject: ["method": "ms.channel.emit", "params": [
            "event": "ed.installedApp.get", "to": "host"
        ]], options: [])
    }

    private static func remotePayload(command: String, data: String, remoteType: String) -> [String: Any] {
        ["method": "ms.remote.control", "params": [
            "Cmd": command,
            "DataOfCmd": data,
            "Option": "false",
            "TypeOfRemote": remoteType
        ]]
    }

    private static func key(for command: RemoteCommand) -> String? {
        switch command {
        case .up: return "KEY_UP"
        case .down: return "KEY_DOWN"
        case .left: return "KEY_LEFT"
        case .right: return "KEY_RIGHT"
        case .select: return "KEY_ENTER"
        case .back: return "KEY_RETURN"
        case .home: return "KEY_HOME"
        case .menu: return "KEY_MENU"
        case .power: return "KEY_POWER"
        case .volumeUp: return "KEY_VOLUP"
        case .volumeDown: return "KEY_VOLDOWN"
        case .mute: return "KEY_MUTE"
        case .play: return "KEY_PLAY"
        case .pause: return "KEY_PAUSE"
        // Samsung documents distinct KEY_PLAY and KEY_PAUSE keys for this channel.
        // A universal toggle key is not established for the target model.
        case .playPause: return nil
        case .rewind: return "KEY_REWIND"
        case .fastForward: return "KEY_FF"
        case .channelUp: return "KEY_CHUP"
        case .channelDown: return "KEY_CHDOWN"
        case .launchApplication, .typeText: return nil
        }
    }
}
