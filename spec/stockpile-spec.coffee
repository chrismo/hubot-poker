Stockpile = require('../js/token-poker/stockpile')
Fakes = require('./fake-time')
Rounds = require('../js/token-poker/round')

describe 'Stockpile', ->
  store = game = null
  builder = time = round = null

  beforeEach ->
    store = {}
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    round = new Rounds.TimedRound(120, time)
    game = new Stockpile(store, round)

  it 'should match highest', ->
    result = game.play('chrismo', '112345')
    expect(result.name).toBe 'Five Straight'
    result = game.play('chrismo', '347 456')
    expect(result.name).toBe 'Five Straight'

  it 'should tally scores', ->
    result = game.play('chrismo', '112345')
    expect(result.score).toBe 34
    expect(result.playerName).toBe 'chrismo'
    expect(result.playerRoundScore).toBe 34
    expect(game.scoreStorage.chrismo).toBe 34

    result = game.play('chrismo', '113674')
    expect(result.score).toBe 2
    expect(result.playerName).toBe 'chrismo'
    expect(result.playerRoundScore).toBe 36
    expect(result.playerRank).toBe 1
    expect(game.scoreStorage.chrismo).toBe 36

    result = game.play('romer', '224 359')
    expect(result.score).toBe 2
    expect(result.playerName).toBe 'romer'
    expect(result.playerRoundScore).toBe 2
    expect(result.playerRank).toBe 2

  it 'should have a scoreboard', ->
    game.scoreStorage =
      chrismo: 999
      romer: 1000
      sara: 1001
    expect(game.scoreboard()).toBe 'Time Left: 120 minutes\n\nsara: 1001\nromer: 1000\nchrismo: 999'

  it 'should reset the scoreboard', ->
    game.scoreStorage =
      chrismo: 999
      romer: 1000
      sara: 1001
    game.resetScores()
    expect(game.scoreboard()).toBe 'Time Left: 120 minutes\n\n[NO SCORES YET]'

  it 'should handle end of a timed round', ->
    expect(round.isStarted()).toBe false
    game.play('chrismo', '112234')
    expect(round.isStarted()).toBe true

    game.play('romer', '333444')
    game.play('sara', '555 555')

    time.now = builder.withHour(3).build()
    time.execCallback()

    expect(round.isOver()).toBe true
    expect(game.winner[0]).toBe 'sara'
    expect(game.winner[1]).toBe 100000

  it 'new hand during post-end delay should throw', ->
    game.play('chrismo', '111222')
    time.now = builder.withHour(3).build()
    time.execCallback()
    expect(round.isOver()).toBe true
    expect(game.winner[0]).toBe 'chrismo'
    expect(-> (game.play('chrismo', '111222'))).toThrow(new Error('Next round starts in 10 seconds.'))
    time.now = builder.withSecond(7).build()
    expect(-> (game.play('chrismo', '111222'))).toThrow(new Error('Next round starts in 3 seconds.'))
    time.now = builder.withMinute(1).withSecond(0).build()
    expect(game.play('chrismo', '111222').playerName).toBe 'chrismo'
    time.now = builder.withMinute(1).withSecond(30).build()
    expect(game.play('romer', '111222').playerName).toBe 'romer'

  it 'should periodically push score display', ->
    listener = new FakeListener()
    game.setListener(listener)
    game.play('chrismo', '112 369')
    time.now = builder.withHour(2).build()
    time.execCallback()
    expect(listener.scoreboardText).toBe 'Time Left: 60 minutes\n\nchrismo: 2'

    time.now = builder.withHour(2).withMinute(30).build()
    time.execCallback()
    expect(listener.scoreboardText).toBe 'Time Left: 30 minutes\n\nchrismo: 2'

    time.now = builder.withHour(2).withMinute(45).build()
    time.execCallback()
    expect(listener.scoreboardText).toBe 'Time Left: 15 minutes\n\nchrismo: 2'

    time.now = builder.withHour(3).withMinute(0).build()
    time.execCallback()
    expect(listener.scoreboardText).toBe '** WINNER **: chrismo\n\nchrismo: 2'

  it 'maybe should display NEW LEADER when that happens?'

  it 'should be named high-hand-accumulate or something?'

  it 'should track submitted hands per player so curves can be applied'

  it 'should dilute points of players over the median'

  it 'should maybe not dilute points of players over the median but losing?'
  # if i'm trying to catch up and need to play lots of small hands to do so,
  # i have no incentive to try this as whatever points i get on a lot of
  # one-pair, two-pair hands will then be diluted.
  #
  # or is that just tough darts when a single play of a good hand dominates

  it 'should not affect points of players at or under the median'

class FakeListener
  onStatus: (@scoreboardText) ->
