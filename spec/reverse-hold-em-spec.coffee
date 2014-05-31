ReverseHoldEm = require('../js/token-poker/reverse-hold-em')
Fakes = require('./fake-time')
Rounds = require('../js/token-poker/round')
Player = require('../js/token-poker/player')

describe 'ReverseHoldEm', ->
  store = game = null
  builder = time = round = null

  beforeEach ->
    store = {}
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    round = new Rounds.TimedRound(2, time)
    game = new ReverseHoldEm(store, round)

  it 'basic gameplay with play round and bet round', ->
    game.play('chrismo', '112 234')
    game.play('romer', '555 964')
    game.play('sara', '219 008')
    game.play('glv', '134 998')
    expect(game.boardStore.romer.hand.name).toBe "Three of a Kind"
    expect(game.boardStore.chrismo.hand.name).toBe "Two Pair"
    game.holeDigits = ['5', '6']

    time.now = builder.withMinute(1).build()
    time.execCallback()

    expect(game.playState).toBe 'bet'

    expect(-> game.bet('woodall', '10')).toThrow "Can't bet if you haven't played."
    # TODO: ok - bet and fold can be done same time, but then bet has to be disabled
    # and a time period for only call or fold with auto-fold or auto-call
    # (feature toggle?) kicking in.
    game.bet('chrismo', '10') # demo auto-call
    game.bet('romer', '12')
    game.fold('sara')
    game.call('glv')

    time.now = builder.withMinute(2).build()
    time.execCallback()

    expect(game.winningHandResult.playerName).toBe 'romer'
    expect(game.winningHandResult.hand.name).toBe 'Full House'
    expect(game.playerStore[0].name).toBe 'chrismo'
    expect(game.playerStore[0].points).toBe 25-1-12
    expect(game.playerStore[1].name).toBe 'romer'
    expect(game.playerStore[1].points).toBe 25-1-12+(1+1+1+1+12+12+12)
    expect(game.playerStore[2].name).toBe 'sara'
    expect(game.playerStore[2].points).toBe 25-1
    expect(game.playerStore[3].name).toBe 'glv'
    expect(game.playerStore[3].points).toBe 25-1-12

    expect(game.playState).toBe 'play'

  it 'should show board during play', ->
    game.play('chrismo', '112234')
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: X X      Time to Bet: 1 min\n" +
          "                                                        \n" +
          "                                                 POT/ALL\n" +
          "chrismo              112 234  Two Pair            1 / 24"
    )
    game.play('romer', ' 555  964')
    time.now = builder.withMinute(1).build()
    time.execCallback()
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: X X     Time to Flop: 1 min\n" +
          " bet [xx] | call | fold  ||  ** auto-call in effect **  \n" +
          "                                                 POT/ALL\n" +
          "romer                555 964  Three of a Kind     1 / 24\n" +
          "chrismo              112 234  Two Pair            1 / 24"
    )
    game.holeDigits = ['5', '6']
    time.now = builder.withMinute(2).withSecond(0).build()
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: X X      Time to Flop: soon\n" +
          " bet [xx] | call | fold  ||  ** auto-call in effect **  \n" +
          "                                                 POT/ALL\n" +
          "romer                555 964  Three of a Kind     1 / 24\n" +
          "chrismo              112 234  Two Pair            1 / 24"
    )
    time.execCallback()
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: 5 6           Winner: romer\n" +
          "                                                        \n" +
          "                                                 POT/ALL\n" +
          "romer                555 964  Full House          0 / 26\n" +
          "chrismo              112 234  Six Straight        0 / 24"
    )

  it 'should respond to getStatus', ->
    game.getStatus()

  it 'should default new players with 25 points', ->
    game.play('chrismo', '112357')
    expect(game.playerStore.length).toBe 1
    expect(game.playerStore[0].name).toBe 'chrismo'

  it 'should persist players across games', ->
    game.play('chrismo', '112357')
    chrismo = game.playerStore[0]
    chrismo.points = 45
    expect(game.pot.players.length).toBe 1

    newRound = new Rounds.TimedRound(2, time)
    game = new ReverseHoldEm(store, newRound)
    expect(game.playerStore[0].name).toBe 'chrismo'
    expect(game.playerStore[0].points).toBe 45
    game.play('chrismo', '112357')
    expect(game.pot.players.length).toBe 1

  it 'should push notice of when time to bet', ->
    listener = new FakeListener()
    game.setListener(listener)
    game.play('chrismo', '112357')
    time.now = builder.withMinute(1).build()
    time.execCallback()
    expect(listener.msgs[0]).toBe "1 point ante."
    expect(listener.msgs[2]).toBe "Hands are locked. Time to bet. Type 'bet' and a number."
    # not going to expect the remaining instructions - this test is
    # more for the push at all, not the content itself.

  it 'should allow direct funding to a player', ->
    game.play('chrismo', '112357')
    game.playState = 'bet'
    game.bet('chrismo', '20')
    expect(game.playerStore[0].points).toBe 25-1-20
    game.fundPlayer('chrismo', '30')
    expect(game.playerStore[0].points).toBe 30


class FakeListener
  constructor: ->
    @msgs = []

  onStatus: (msg) ->
    @msgs.push msg