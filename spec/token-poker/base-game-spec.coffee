Game = require('../../js/token-poker/base-game')
GameCommand = require('../../js/poker/game-command')
Round = require('../../js/poker/round')

describe 'BaseGame', ->
  game = store = round = null

  beforeEach ->
    store = {}
    round = new Round.TimedRound(10)
    game = new Game.BaseGame(store, round)
    game.play = (@playPlayerName, @playArgs) ->
      console.log("#{@playPlayerName} #{@playArgs}")
    game.commands = -> [new GameCommand(/foo/i, game.play)]
    game.isStarted = -> false

  it 'should pass commands through to game', ->
    game.sendCommand('romer', 'foo')
    expect(game.playPlayerName).toBe 'romer'

    game.sendCommand('sara', 'foo')
    expect(game.playPlayerName).toBe 'sara'

  # TODO: add event on sendCommand, so bots can be smarter.

  it 'should notify listener of round start and end', ->
    listener = new FakeListener()
    game.setListener(listener)
    game.startRound()
    game.finishRound()
    expect(listener.roundStarted).toBe true
    expect(listener.roundOver).toBe true

  it 'should notify listener of status', ->
    listener = new FakeListener()
    game.setListener(listener)
    game.pushStatus('text')
    expect(listener.msgs[0]).toBe 'text'


class FakeListener
  constructor: ->
    @msgs = []

  onStatus: (msg) ->
    @msgs.push msg

  onStartRound: () ->
    @roundStarted = true

  onFinishRound: () ->
    @roundOver = true

