AiPlayer = require('../../js/card-poker/ai-player')
Game = require('../../js/card-poker/texas-hold-em')
Fakes = require('../poker/fake-time')
Core = require('../../js/card-poker/core')

describe 'AiPlayer', ->
  game = ai = time = builder = deck = null

  beforeEach ->
    store = {}
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    listener = new FakeListener()
    game = new Game(store, time)
    game.playerStartingPoints = 25
    game.addListener(listener)
    game.deck = deck = new Core.Deck()
    # override so we have an unshuffled deck
    game.newDeck = -> deck
    ai = new AiPlayer('foobar', game, time)

  it 'should request deal at start of round', ->
    game.sendCommand('chrismo', 'deal')
    time.execNextCallback()
    expect(game.playerStore.length).toBe 2
    # with unshuffled deck, 2S-6S are community cards, 7S,8S go to chrismo, ai gets 9S,10S
    expect(ai.hand.codes()).toBe '[9S,10S]'

  it 'should not re-request a deal once dealt', ->
    game.sendCommand('sara', 'deal')
    time.execNextCallback()
    beforeCount = time.callbacks.length
    game.sendCommand('glv', 'deal')
    expect(time.callbacks.length).toBe beforeCount

  it 'should reset at round end so it can deal again when 1st player is dealt', ->
    game.sendCommand('monica', 'deal')
    time.execNextCallback()
    game.finishRound()
    expect(ai.hand?).toBe false

  it 'should know when '

class FakeListener
  canPushToPlayer: (playerName) ->
    true
