import Foundation

class SudokuBoard {
    enum Difficulty: String {
        case beginner
        case intermediate
        case hard
        case veryHard = "very hard"
    }
    
    private var solvedBoard: [Int] = Array(repeating: 0, count: 81)
    private var unsolvedBoard: [Int] = Array(repeating: 0, count: 81)
    
    static func checkBoard(_ board: [Int], _ i: Int, _ n: Int) -> Bool {
        let row = i / 9
        let col = i % 9

        // check column
        for c in 0..<9 {
            if board[row * 9 + c] == n {
                return false
            }
        }
        // check row
        for r in 0..<9 {
            if board[r * 9 + col] == n {
                return false
            }
        }
        
        // check 3x3 box
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<(boxRow + 3) {
            for c in boxCol..<(boxCol + 3) {
                if board[r * 9 + c] == n {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func fillBoard(_ board: inout [Int], _ k: Int, _ refBoard: [Int]? = nil) -> Bool {
        var k = k
        if k == 0 {
            k = SudokuBoard.countPieces(board)
        }
        if k == 81 {
            // we're looking for a solution different from refBoard if provided
            return board != refBoard
        }
        
        var numbers = Array(1...9)
        numbers.shuffle()
        
        // for each cell, find how many solutions avaialble and choose the cell with the least ones
        var stat = [Int: [Int]]()
        var minI = -1
        var minLen = 10
        
        for i in 0..<81 {
            if board[i] != 0 {
                continue
            }
            stat[i] = []
            for n in numbers {
                if SudokuBoard.checkBoard(board, i, n) {
                    stat[i]?.append(n)
                }
            }
            if let len = stat[i]?.count, len < minLen {
                minLen = len
                minI = i
            }
            // only a single solution available
            if stat[i]?.count == 1 {
                break
            }
        }
        let i = minI
        guard let p = stat[i] else { return false }
        
        for n in p {
            board[i] = n
            if fillBoard(&board, k + 1, refBoard) {
                return true
            }
        }
        board[i] = 0
        return false
    }
    
    func generate(difficulty: Difficulty) {
        _ = fillBoard(&solvedBoard, 0)
        
        unsolvedBoard = solvedBoard
        var numbers = Array(0..<81)
        numbers.shuffle()
        
        let targetCount: Int
        switch difficulty {
        case .beginner:
            targetCount = Int.random(in: 50...60)
        case .intermediate:
            targetCount = Int.random(in: 40...49)
        case .hard:
            targetCount = Int.random(in: 30...39)
        case .veryHard:
            targetCount = 0
        }
        
        for cell in numbers {
            let originalValue = unsolvedBoard[cell]
            unsolvedBoard[cell] = 0
            var tmp = unsolvedBoard
            
            if fillBoard(&tmp, 0, solvedBoard) {
                unsolvedBoard[cell] = originalValue
            }
            if SudokuBoard.countPieces(unsolvedBoard) <= targetCount {
                return
            }
        }
    }
 
    func getSolved() -> [Int] {
        return solvedBoard
    }
    
    func getUnsolved() -> [Int] {
        return unsolvedBoard
    }
    
    static func printBoard(_ board: [Int]) {
        for i in 0..<9 {
            print(board[i*9..<(i*9+9)].map { String($0) }.joined(separator: " "))
        }
    }
    
    static func countPieces(_ board: [Int]) -> Int {
        return board.filter { $0 != 0 }.count
    }
    
    func setValue(index: Int, val: Int) -> Bool{
        if solvedBoard[index] == val {
            unsolvedBoard[index] = val
            return true
        }
        return false
    }
    func isSolved() -> Bool {
        return solvedBoard == unsolvedBoard
    }
    
    func isSolvedForVal(val: Int) ->Bool {
        let count = unsolvedBoard.filter { $0 == val }.count
        return count == 9
    }
}





