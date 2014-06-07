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

  it 'should limit number of plays in a time period'
    # or change to deal the hand automatically, so you don't need a fob

  it 'should allow optional chain command', ->
    # anyone at anytime can be dealt a hand, plus chain, which means
    # they will be linked to the next hand dealt normally and split
    # the points. But anyone can play chain as well after, and thus
    # add themselves on to the wagon.

  it 'should allow same player to keep chaining'

  it 'should allow the player to break the chain for their turn', ->
    # player can play bust for their turn with a number of points.
    # the chain ends, the player busting loses the number of points,
    # but so does the chain. Any remaining in the chain is split
    # with the players in the chain.


