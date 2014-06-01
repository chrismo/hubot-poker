_ = require('underscore')
AiPlayer = require('../js/token-poker/ai-player')

describe 'AiPlayer', ->
  game = null

  beforeEach ->
    game = new FakeGame

  it 'plays rest of game at random when added to it', ->
    ai = new AiPlayer('foo', game)
    ai.doSomething(0)
    expect(game.playPlayerName).toBe 'foo'
    expect(game.playHand).toNotBe 'undefined'
    expect(game.playHand.length).toBe 6

    ai.doSomething(1)
    expect(game.betPlayerName).toBe 'foo'
    expect(game.betAmount).toNotBe 'undefined'
    expect(game.betAmount).toBeLessThan 5

    ai.doSomething(2)
    expect(game.foldPlayerName).toBe 'foo'

    ai.doSomething(3)
    expect(game.callPlayerName).toBe 'foo'

  it 'calls things at random when not fed a function index', ->
    game = new FakeAllIsOne
    ai = new AiPlayer('bar', game)
    _.times(20, ->
      ai.doSomething()
      expect(game.playerName).toBe 'bar'
      game.playerName = undefined
    )

  it 'dies when killed', ->
    game = new FakeAllIsOne
    ai = new AiPlayer('bar', game)
    ai.doSomething()
    expect(game.playerName).toBe 'bar'
    game.playerName = undefined
    ai.die()
    ai.doSomething()
    expect(game.playerName).toBe undefined

  it 'stops acting after a limit', ->
    game = new FakeAllIsOne
    ai = new AiPlayer('bar', game)
    _.times(20, ->
      ai.doSomething()
      expect(ai.alive).toBe true
    )
    ai.doSomething()
    expect(ai.alive).toBe false

  it 'only calls method that game has', ->
    game = new LimitedGame
    ai = new AiPlayer('bar', game)
    _.times(20, ->
      ai.doSomething()
      expect(ai.alive).toBe true
    )


class FakeGame
  play: (@playPlayerName, @playHand) ->

  bet: (@betPlayerName, @betAmount) ->

  fold: (@foldPlayerName) ->

  call: (@callPlayerName) ->


class FakeAllIsOne
  play: (@playerName) ->

  bet: (@playerName) ->

  fold: (@playerName) ->

  call: (@playerName) ->

class LimitedGame
  play: (@playerName) ->
  bet: (@playerName) ->