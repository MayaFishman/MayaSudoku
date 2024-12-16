# Maya Sudoku

## About the Project

This game started as a fun project to work on with my daughter, Maya, who is learning to code. We chose Sudoku because it’s simple, enjoyable, and perfectly suited for iOS. To make it even more exciting, we added a multiplayer mode so we could compete against each other.

However, Maya eventually lost interest in the project (not too surprising!), so I decided to finish it myself and release it for fun. The entire game was developed in less than a week, with most of the tedious parts (like the graphics) assisted by ChatGPT. this was my first time working with Swift

## Sudoku Board Algorithm

The algorithm for generating Sudoku boards was created after some quick research. It works like this:

1. **Generate a Completed Board:** Randomly fill the board, using backtracking when needed.
2. **Create Holes:** Remove numbers from the board one at a time, ensuring that the puzzle still has a unique solution.
3. **Repeat:** Continue step 2 until no more numbers can be removed without creating ambiguity.

For solving puzzles, the algorithm selects an empty cell with the fewest possible candidates, progressing until the board is complete. Backtracking is used if necessary.

## Multiplayer Mode

The multiplayer functionality was the most challenging part of the project. The game allows the host to invite up to three other players using a party code. Custom matchmaker rules were implemented following [Apple Game Center Documentation](https://developer.apple.com/documentation/appstoreconnectapi/game-center).

Initially, I encountered bugs—such as multiplayer not functioning with more than two players. After troubleshooting and finding workarounds, it now works as intended.

## Scoring System

The scoring system is designed to reward accuracy and speed:

- Start with **1000 points**.
- Lose **10 points** every 10 seconds without a correct guess.
- Gain **10 points** for each correct placement.
- Lose points for incorrect placements (game ends after 4 incorrect guesses).
- Complete the puzzle within **10 minutes** for a **bonus score**.

## Feel Free to Use!

This project is open-source and available for anyone to clone, modify, or learn from.

