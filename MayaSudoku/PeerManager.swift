import Foundation
import MultipeerConnectivity

let service = "sudoko-p2p"

class PeerManager: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    var peerID: MCPeerID!
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?

    override init() {
        super.init()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    deinit {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
    }

    // Function to create and advertise session
    func createSession() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: service)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("Advertising started. Waiting for peers to connect...")
    }

    // Function to join and browse for session
    func joinSession() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: service)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("Browsing for peers to join...")
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }

    // MARK: - MCNearbyServiceBrowserDelegate

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost connection to \(peerID.displayName)")
    }

    // MARK: - MCSessionDelegate

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected to \(peerID.displayName)")
        case .connecting:
            print("Connecting to \(peerID.displayName)...")
        case .notConnected:
            print("Disconnected from \(peerID.displayName)")
        @unknown default:
            fatalError("Unknown state received: \(state)")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data here
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle received stream here
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Handle start of resource receiving
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Handle end of resource receiving
    }
}
