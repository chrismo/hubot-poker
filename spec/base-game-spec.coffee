BaseGame = require('../js/token-poker/base-game')
GameCommand = require('../js/token-poker/game-command')
Round = require('../js/token-poker/round')

describe 'BaseGame', ->
  game = store = round = null

  beforeEach ->
    store = {}
    round = new Round.TimedRound(10)
    game = new BaseGame(store, round)
    game.play = (@playPlayerName, @playArgs) ->
      console.log("#{@playPlayerName} #{@playArgs}")
    game.commands = -> [new GameCommand(/foo/i, game.play)]

  it 'should cache commands until min players reached', ->
    game.setCache(2)
    result = game.sendCommand('chrismo', 'foo')
    expect(game.playPlayerName).toBe undefined
    expect(result).toBe "Need 2 players to start the next round."

    result = game.sendCommand('chrismo', 'foo')
    expect(game.playPlayerName).toBe undefined

    game.sendCommand('romer', 'foo')
    expect(game.playPlayerName).toBe 'romer'

    game.sendCommand('sara', 'foo')
    expect(game.playPlayerName).toBe 'sara'

  it 'should not cache play command that is not a game command', ->
    result = game.sendCommand('woodall', 'bar')
    expect(result).toBe undefined

  it 'should not cache play command that is not a game command', ->
    game.setCache(2)
    result = game.sendCommand('woodall', 'bar')
    expect(result).toBe undefined