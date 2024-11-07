import GameKit
import SpriteKit

extension Notification.Name {
    static let connectedPlayersDidChange = Notification.Name("connectedPlayersDidChange")
}

class GameSessionManager: NSObject, GKMatchDelegate, GKLocalPlayerListener {
    var match: GKMatch?
    var partyCode: String?
    var playerCount: Int = 2
    var isHost: Bool = false

    static let shared = GameSessionManager()


    private override init() {
        super.init()
    }

    var connectedPlayers: [GKPlayer] {
        match?.players ?? []
    }

    func authenticatePlayer(completion: @escaping (Bool) -> Void) {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if let error = error {
                print("Error authenticating player: \(error.localizedDescription)")
                completion(false)
                return
            }

            if GKLocalPlayer.local.isAuthenticated {
                GKLocalPlayer.local.register(self)
                print("Player authenticated and registered for Game Center.")
                completion(!GKLocalPlayer.local.isMultiplayerGamingRestricted)
            } else {
                completion(false)
            }
        }
    }

    // Host creates a game session with a unique party code
    func hostGameSession(playerCount: Int, completion: @escaping (Result<String, Error>) -> Void) {
        guard (2...4).contains(playerCount) else {
            let error = NSError(domain: "GameSessionManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player count must be between 2 and 4."])
            completion(.failure(error))
            return
        }

        self.playerCount = playerCount
        self.partyCode = String(format: "%04d", Int.random(in: 1000...9999))
        self.isHost = true
        print("Party Code for session: \(partyCode!)")

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        request.queueName = "com.maya.sudoko.PartyCodeQueue"
        request.properties = ["partyCode": self.partyCode!]

        GKMatchmaker.shared().findMatch(for: request) { match, error in
            if let error = error {
                print("Error creating match: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let match = match else {
                let error = NSError(domain: "GameSessionManagerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create match."])
                completion(.failure(error))
                return
            }

            self.match = match
            self.match?.delegate = self
            print("Match created. Waiting for players to join using the party code.")
            completion(.success(self.partyCode!))
        }
    }

    // Other players join the game session using the party code
    func joinGameSession(with partyCode: String) {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        request.queueName = "com.maya.sudoko.PartyCodeQueue"
        request.properties = ["partyCode": partyCode]

        GKMatchmaker.shared().findMatch(for: request) { match, error in
            if let error = error {
                print("Error joining match: \(error.localizedDescription)")
                return
            }
            self.match = match
            self.match?.delegate = self
            print("Successfully joined match with party code: \(partyCode)")
            self.waitForGameStart()
        }
    }

    // Host monitors connected players and starts the match when ready
    private func monitorPlayers() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            print("Connected players: \(self.connectedPlayers.map { $0.displayName })")
            if self.connectedPlayers.count == self.playerCount {
                print("All players joined. Starting match.")
                self.startMatch()
                timer.invalidate()
            }
        }
    }

    // Starts the match for all players (host calls this)
    private func startMatch() {
        GKMatchmaker.shared().finishMatchmaking(for: match!)
        if isHost {
            sendDataToAllPlayers(message: "startGame")
            print("Game started by host.")
            // Game-specific start logic goes here
        }
    }

    // Called by joining players to wait until the host starts the game
    private func waitForGameStart() {
        print("Waiting for the host to start the game...")
    }

    // Cancel the session if needed
    func cancelSession() {
        match?.disconnect()
        match = nil
        partyCode = nil
        print("Session canceled.")
    }

    // MARK: - GKMatchDelegate Methods

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        if let error = error {
            print("Match error: \(error.localizedDescription)")
        }
    }

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if let message = String(data: data, encoding: .utf8), message == "startGame" {
            print("Game starting signal received.")
            // Game-specific start logic for joining players goes here
        }
    }

    func match(_ match: GKMatch, player playerID: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            print("\(playerID.displayName) connected")
            notifyConnectedPlayersChanged()
        case .disconnected:
            print("\(playerID.displayName) disconnected")
            notifyConnectedPlayersChanged()
        default:
            break
        }
    }

    // MARK: - Sending Data to Players

    func sendDataToAllPlayers(message: String) {
        guard let match = match, let data = message.data(using: .utf8) else { return }
        do {
            try match.sendData(toAllPlayers: data, with: .reliable)
            print("Sent message to all players: \(message)")
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }

    // MARK: - GKLocalPlayerListener Method for accepting invitations

    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        GKMatchmaker.shared().match(for: invite) { match, error in
            if let error = error {
                print("Error accepting invitation: \(error.localizedDescription)")
                return
            }
            self.match = match
            self.match?.delegate = self
            print("Joined match from invitation.")
        }
    }

    private func notifyConnectedPlayersChanged() {
        // Perform any updates here when connectedPlayers changes
        print("Connected players updated: \(connectedPlayers.map { $0.displayName })")
        NotificationCenter.default.post(name: .connectedPlayersDidChange, object: nil, userInfo: ["connectedPlayers": connectedPlayers])
    }
}

