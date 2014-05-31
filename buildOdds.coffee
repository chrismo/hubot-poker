TokenPoker = require('./js/token-poker/high-hand-game')
TPCore = require('./js/token-poker/core')

class GameOddsCalculator
  execute: ->
    game = new TokenPoker.Stockpile({})
    if true
      game.calculateOdds()
    else # a fast executing version to test output and such
      registry = game.registry
      odds = new TPCore.OddsCalculator(registry, 999)
      odds.calculate()

    game.registry.sortByMatchCount()

    process.stdout.write("\n")
    this.dumpHand hand for hand in game.registry.hands

  dumpHand: (hand) ->
    process.stdout.write("#{hand.codeGen()}\n")

(new GameOddsCalculator).execute()