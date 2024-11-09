import Foundation

protocol ScoreDelegate: AnyObject {
    func scoreDidUpdate(newScore: Int)
}

class Score {
    weak var delegate: ScoreDelegate?

    public var maxMistakes: Int = 3
    public var mistakePenalties = [20, 50, 100]
    public var clueBonus: Int = 10

    private var timer: Timer?
    private var startTime: Date?

    private(set) var score: Int = 1000 {
        didSet {
            // If score becomes negative, set to 0 and complete the game
            if score < 0 {
                score = 0
                complete()
            } else {
                // Notify the delegate whenever the score changes
                delegate?.scoreDidUpdate(newScore: score)
            }
        }
    }

    public func setInitialScore(score: Int) {
        self.score = score
    }

    private(set) var mistakes: Int = 0
    private var isCompleted: Bool = false

    // Starts the timer to deduct 1 point per second
    private func startTimer() {
        startTime = Date()
        resetTimer()
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.deductPointPerSecond()
        }
    }

    // Deducts 1 point every second
    private func deductPointPerSecond() {
        guard !isCompleted else { return }
        score -= 10
    }

    // Stop timer, finalize score, and notify the delegate when completed
    private func complete() {
        guard !isCompleted else { return }
        isCompleted = true
        timer?.invalidate()
    }

    func start() {
        startTimer()
    }

    func addPointsForCorrectPlacement() {
        guard !isCompleted else { return }
        score += clueBonus
        resetTimer()
    }

    // Handle mistakes with point deduction and limits
    func registerMistake() {
        guard !isCompleted && mistakes < maxMistakes else { return }
        score -= mistakePenalties[mistakes]
        mistakes += 1

        // Optional: Handle maximum mistakes reached if needed
        if mistakes >= maxMistakes {
            print("Maximum mistakes reached! You can't make more mistakes.")
        }
    }

    func maxPossibleScore(remainingClues: Int) -> Int {
        guard !isCompleted else { return score}
        return score + remainingClues * clueBonus
    }

    deinit {
        timer?.invalidate()
    }
}