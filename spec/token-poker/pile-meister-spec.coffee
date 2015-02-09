Fakes = require('./../poker/fake-time')
FakeRandom = require('./fake-random')
PileMeister = require('../../js/token-poker/pile-meister')
Rounds = require('../../js/poker/round')

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
    playerHand = game.deal('chrismo').playerHand
    expect(playerHand.playerDigits).toBe '112357'
    expect(playerHand.score).toBe 2
    expect(playerHand.player.points).toBe 2
    expect(playerHand.player.rank).toBe 1

  it 'should handle empty args from hubot', ->
    # new parsing doesn't yield undefined as a second arg, but nested empty string array
    rand.pushFakeHand('112357')
    playerHand = game.deal('chrismo', [['']]).playerHand
    expect(playerHand.player.points).toBe 2

  it 'should limit number of deals in a time period', ->
    game.deal('chrismo')
    expect(-> game.deal('chrismo')).toThrow 'too soon chrismo'
    time.now = builder.withMinute(1).build()
    game.deal('chrismo')

  it 'should limit number of breaks in a time period', ->
    game.break('chrismo')
    expect(-> game.break('chrismo')).toThrow 'too soon chrismo'
    time.now = builder.withMinute(1).build()
    game.break('chrismo')

  it 'should chain two deals together and split the points', ->
    rand.pushFakeHand('112357', '555555')
    a = game.deal('chrismo', 'chain').playerHand
    expect(a.playerDigits).toBe '112357'
    expect(a.score).toBe 2
    expect(a.player.points).toBe 0
    expect(a.player.rank).toBe 1
    expect(game.chain.length).toBe 1
    b = game.deal('romer')[0].playerHand
    expect(b.playerDigits).toBe '555555'
    expect(b.score).toBe 100000
    expect(a.player.points).toBe (50001)
    expect(b.player.points).toBe (50001)
    expect(game.chain.length).toBe 0

  it 'should allow same player in chain multiple times', ->
    rand.pushFakeHand('112357', '112357', '112357')
    game.deal('chrismo', 'chain')
    game.deal('romer', 'chain')
    time.now = builder.withMinute(1).build()
    game.deal('chrismo')
    expect(game.playerStore[0].points).toBe 3
    expect(game.playerStore[1].points).toBe 3

  it 'should round down chain total', ->
    rand.pushFakeHand('123579', '112357', '112357')
    game.deal('chrismo', 'chain')
    game.deal('romer', 'chain')
    time.now = builder.withMinute(1).build()
    game.deal('chrismo')
    expect(game.playerStore[0].points).toBe 5
    expect(game.playerStore[1].points).toBe 5

  it 'should distribute chain points if broken with no points', ->
    rand.pushFakeHand('112357')
    game.deal('chrismo', 'chain')
    expect(game.playerStore[0].points).toBe 0
    game.break('romer')
    expect(game.playerStore[0].points).toBe 2
    expect(game.playerStore[1].points).toBe 0

  it 'should deduct points from player and chain if broken with points', ->
    rand.pushFakeHand('112357', '112257')
    game.deal('romer')
    game.deal('chrismo', 'chain')
    expect(game.playerStore[0].points).toBe 2
    time.now = builder.withMinute(1).build()
    game.break('romer', '2')
    expect(game.playerStore[0].points).toBe 0
    expect(game.playerStore[1].points).toBe 2

  it 'should cap break points to player available points', ->
    rand.pushFakeHand('112357', '112257')
    game.deal('romer')
    game.deal('chrismo', 'chain')
    expect(game.playerStore[0].points).toBe 2
    time.now = builder.withMinute(1).build()
    game.break('romer', '4')
    expect(game.playerStore[0].points).toBe 0
    expect(game.playerStore[1].points).toBe 2

  it 'should not cap break points to chain total', ->
    # for now, a deliberate decision - if you as a player
    # decide to spend too many points to break the chain
    # yer still losing all those points.
    rand.pushFakeHand('112257', '112357')
    game.sendCommand('romer', 'deal')
    game.sendCommand('chrismo', 'deal chain')
    expect(game.playerStore[0].points).toBe 4
    time.now = builder.withMinute(1).build()
    game.sendCommand('romer', 'break 4')
    expect(game.playerStore[0].points).toBe 0
    expect(game.playerStore[1].points).toBe 0

  it 'should handle break call on empty chain', ->
    breakResult = game.break('chrismo')
    expect(breakResult.chainTotal).toBe 0
