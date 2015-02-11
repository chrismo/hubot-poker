AiPlayer = require('../../js/card-poker/ai-player')
Game = require('../../js/card-poker/texas-hold-em')
Fakes = require('../poker/fake-time')

describe 'AiPlayer', ->
  game = ai = time = builder = null

  beforeEach ->
    store = {}
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    listener = new FakeListener()
    game = new Game(store, time)
    game.playerStartingPoints = 25
    game.addListener(listener)
    ai = new AiPlayer('foobar', game, time)

  it 'should request deal at start of round', ->
    game.sendCommand('chrismo', 'deal')
    time.execNextCallback()
    expect(game.playerStore.length).toBe 2

  it 'should not re-request a deal once dealt'

  it 'should reset at round end so it can deal again when 1st player is dealt'

  it 'should know when '

class FakeListener
  canPushToPlayer: (playerName) ->
    true
