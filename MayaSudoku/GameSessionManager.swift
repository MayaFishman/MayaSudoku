import GameKit
import SpriteKit

extension Notification.Name {
    static let connectedPlayersDidChange = Notification.Name("connectedPlayersDidChange")
    static let gameStarted = Notification.Name("gameStarted")
    static let gameEnded = Notification.Name("gameEnded")
}

class GameSessionManager: NSObject, GKMatchDelegate, GKLocalPlayerListener {
    var match: GKMatch?
    var partyCode: String?
    var isHost: Bool = false
    var matchPlayers: [GKPlayer] = []
    var scores: [GKPlayer : (Int, Int, Bool)] = [:]
    var playersAdded: Bool = false
    var gameStarted: Bool = false

    static let shared = GameSessionManager()


    private override init() {
        super.init()
    }

    var connectedPlayers: [GKPlayer] {
        match?.players ?? []
    }

    func score(player: GKPlayer) -> (Int, Int, Bool) {
        return scores[player] ?? (0, 0, false)
    }

    func sortedPlayersByScore() -> [(GKPlayer, (Int, Int, Bool))] {
        return scores.sorted { $0.value.0 > $1.value.0 }
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
    func hostGameSession(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        self.partyCode = code
        self.isHost = true
        print("Party Code for session: \(partyCode!)")

        gameStarted = false
        GKMatchmaker.shared().cancel()
        match?.disconnect()
        match?.delegate = nil

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

            print("Match created. Waiting for players to join using the party code, expected ", match.expectedPlayerCount )
            completion(.success(self.partyCode!))
        }
    }

    // Other players join the game session using the party code
    func joinGameSession(with partyCode: String, completion: @escaping (Result<GKMatch, Error>) -> Void) {
        self.partyCode = partyCode
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4
        request.queueName = "com.maya.sudoko.PartyCodeQueue"
        request.properties = ["partyCode": partyCode]

        gameStarted = false
        GKMatchmaker.shared().cancel()
        match?.disconnect()
        match?.delegate = nil

        GKMatchmaker.shared().findMatch(for: request) { match, error in
            if let error = error {
                print("Error joining match: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            self.match = match
            self.match?.delegate = self

            print("Successfully joined match with party code: \(partyCode)")
            completion(.success(match!))

            self.addPlayers()
        }
    }

    // Workaround for matchmakier not working with more than 2 players, why???
    private func addPlayers() {
        guard self.match != nil && self.partyCode != nil && !playersAdded && !gameStarted else { return }
        if match!.players.count < 4{
            Task {
                self.playersAdded = true
                print("addPlayers", match!.players.count)
                let request = GKMatchRequest()
                request.maxPlayers = 4
                request.queueName = "com.maya.sudoko.PartyCodeQueue"
                request.properties = ["partyCode": self.partyCode!]
                request.minPlayers = 3
                do {
                    try await GKMatchmaker.shared().addPlayers(to: match!, matchRequest: request)
                } catch {
                    print("Failed to add players to the match: \(error)")
                    return
                }
                if gameStarted {
                    return
                }

                request.minPlayers = 4
                do {
                    try await GKMatchmaker.shared().addPlayers(to: match!, matchRequest: request)
                } catch {
                    print("Failed to add players to the match: \(error)")
                    return
                }
            }
        }
    }

    // Starts the match for all players (host calls this)
    func startMatch(board: SudokuBoard, initialScore: Int) {
        GKMatchmaker.shared().finishMatchmaking(for: match!)
        gameStarted = true
        matchPlayers = connectedPlayers
        matchPlayers.append(GKLocalPlayer.local)
        scores[GKLocalPlayer.local] = (initialScore, 0, false)

        if isHost {
            let jsonObject: [String: Any] = [
                "msg": "startGame",
                "player": GKLocalPlayer.local.displayName,
                "solvedBoard":board.getSolved(),
                "unsolvedBoard": board.getUnsolved(),
                "score": initialScore
            ]

            guard let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else { return }
            sendDataToAllPlayers(data: data)
            print("Game started by host.")
        }
    }

    func sendScore(score: Int, mistakes: Int, isComplete: Bool) {
        let jsonObject: [String: Any] = [
            "msg": "scoreChanged",
            "score": score,
            "mistakes": mistakes,
            "complete": isComplete
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else { return }
        sendDataToAllPlayers(data: data)
        scores[GKLocalPlayer.local] = (score, mistakes, isComplete)
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
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let jsonDict = jsonObject as? [String: Any],
           let msg = jsonDict["msg"] as? String {
            if msg == "startGame" {
                print("Starting game as guest...")
                GKMatchmaker.shared().finishMatchmaking(for: match)
                gameStarted = true
                matchPlayers = connectedPlayers
                matchPlayers.append(GKLocalPlayer.local)
                notifyGameStarted(solvedBoard: jsonDict["solvedBoard"] as! [Int],
                                  unsolvedBoard: jsonDict["unsolvedBoard"] as! [Int],
                                  initialScore: jsonDict["score"] as! Int)
                for player in matchPlayers {
                    scores[player] = (
                        jsonDict["score"] as? Int ?? 0,      // Default to 0 if score is nil
                        jsonDict["mistakes"] as? Int ?? 0,    // Default to 0 if mistakes is nil
                        jsonDict["complete"] as? Bool ?? false
                    )
                }
            } else if msg == "scoreChanged" {
                let score = jsonDict["score"] as! Int
                let mistakes = jsonDict["mistakes"] as! Int
                let isComplete = jsonDict["complete"] as! Bool
                print("Score changed to \(score)")
                scores[player] = (score, mistakes, isComplete)
            }
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

    func sendDataToAllPlayers(data: Data) {
        guard let match = match else { return }
        do {
            try match.sendData(toAllPlayers: data, with: .reliable)
            print("Sent message to all players: \(data)")
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }

    func disconnect() {
        match?.disconnect()
        match?.delegate = nil
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

    private func notifyGameStarted(solvedBoard: [Int], unsolvedBoard: [Int], initialScore: Int) {
        print("Game started")
        NotificationCenter.default.post(name: .gameStarted, object: nil,
                                        userInfo: ["solvedBoard": solvedBoard,
                                                   "unsolvedBoard": unsolvedBoard,
                                                   "initialScore": initialScore])
    }
}

