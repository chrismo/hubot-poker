PileMeister = require('../js/token-poker/pile-meister')
Fakes = require('./fake-time')
Rounds = require('../js/token-poker/round')
FakeRandom = require('./fake-random')

describe 'PileMeister', ->
  store = game = null
  builder = time = round = null
  rand = null

  beforeEach ->
    store = {}
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    round = new Rounds.TimedRound(60, time)
    game = new PileMeister(store, round)
    rand = new FakeRandom
    game.randomProvider = rand

  it 'deals hands for you', ->
    rand.pushFakeHand('112357')
    playerHand = game.deal('chrismo')
    expect(playerHand.playerDigits).toBe '112357'
    expect(playerHand.score).toBe 2
    expect(playerHand.player.points).toBe 2
    expect(playerHand.player.rank).toBe 1

  it 'should limit number of plays in a time period', ->
    game.deal('chrismo')
    expect(-> game.deal('chrismo')).toThrow 'too soon chrismo'
    time.now = builder.withMinute(1).build()
    game.deal('chrismo')

  it 'should chain two deals together and split the points', ->
    rand.pushFakeHand('112357', '555555')
    a = game.deal('chrismo', 'chain')
    expect(a.playerDigits).toBe '112357'
    expect(a.score).toBe 2
    expect(a.player.points).toBe 0
    expect(a.player.rank).toBe 1
    expect(game.chain.length).toBe 1
    b = game.deal('romer')
    expect(b.playerDigits).toBe '555555'
    expect(b.score).toBe 100000
    expect(a.player.points).toBe (50001)
    expect(b.player.points).toBe (50001)

  it 'should allow same player to keep chaining'

  it 'should allow the player to break the chain for their turn', ->
    # player can play bust for their turn with a number of points.
    # the chain ends, the player busting loses the number of points,
    # but so does the chain. Any remaining in the chain is split
    # with the players in the chain.


