_ = require('underscore')
AiPlayer = require('../js/token-poker/ai-player')

describe 'AiPlayer', ->
  dealer = null

  beforeEach ->
    dealer = new FakeDealer

  it 'plays rest of game at random when added to it', ->
    ai = new AiPlayer('foo', dealer)
    ai.doSomething(0)
    expect(dealer.playPlayerName).toBe 'foo'
    expect(dealer.playHand).toNotBe 'undefined'
    expect(dealer.playHand.length).toBe 6

    ai.doSomething(1)
    expect(dealer.betPlayerName).toBe 'foo'
    expect(dealer.betAmount).toNotBe 'undefined'
    expect(dealer.betAmount).toBeLessThan 5

    ai.doSomething(2)
    expect(dealer.foldPlayerName).toBe 'foo'

    ai.doSomething(3)
    expect(dealer.callPlayerName).toBe 'foo'

  it 'calls things at random when not fed a function index', ->
    dealer = new FakeAllIsOne
    ai = new AiPlayer('bar', dealer)
    _.times(20, ->
      ai.doSomething()
      expect(dealer.playerName).toBe 'bar'
      dealer.playerName = undefined
    )

  it 'dies when killed', ->
    dealer = new FakeAllIsOne
    ai = new AiPlayer('bar', dealer)
    ai.doSomething()
    expect(dealer.playerName).toBe 'bar'
    dealer.playerName = undefined
    ai.die()
    ai.doSomething()
    expect(dealer.playerName).toBe undefined

  it 'stops acting after a limit', ->
    dealer = new FakeAllIsOne
    ai = new AiPlayer('bar', dealer)
    _.times(20, ->
      ai.doSomething()
      expect(ai.alive).toBe true
    )
    ai.doSomething()
    expect(ai.alive).toBe false

  it 'only calls method that game has', ->
    dealer = new FakeDealer
    dealer.game = new LimitedGame
    ai = new AiPlayer('bar', dealer)
    _.times(20, ->
      ai.doSomething()
      expect(ai.alive).toBe true
    )


class FakeDealer
  constructor: ->
    @game = new FakeGame

  play: (@playPlayerName, @playHand) ->

  bet: (@betPlayerName, @betAmount) ->

  fold: (@foldPlayerName) ->

  call: (@callPlayerName) ->


class FakeAllIsOne
  constructor: ->
    @game = new FakeGame

  play: (@playerName) ->

  bet: (@playerName) ->

  fold: (@playerName) ->

  call: (@playerName) ->

class FakeGame
  play: (@playPlayerName, @playHand) ->

  bet: (@betPlayerName, @betAmount) ->

  fold: (@foldPlayerName) ->

  call: (@callPlayerName) ->

class LimitedGame
  play: (@playerName) ->
  bet: (@playerName) ->