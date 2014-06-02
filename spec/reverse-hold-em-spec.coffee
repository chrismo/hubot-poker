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
    round = new Rounds.TimedRound(3, time)
    game = new ReverseHoldEm(store, round)

  it 'basic gameplay with play, bet and settle rounds', ->
    game.play('chrismo', '112 234')
    game.play('romer', '555 964')
    game.play('sara', '219 008')
    game.play('glv', '134 998')
    game.play('bogdan', '774 208')
    expect(game.boardStore.romer.hand.name).toBe "Three of a Kind"
    expect(game.boardStore.chrismo.hand.name).toBe "Two Pair"
    game.holeDigits = ['5', '6']

    game.startBetting()

    expect(-> game.bet('woodall', '10')).toThrow "Can't bet if you haven't played."
    game.bet('bogdan', '3')
    game.bet('chrismo', '10') # demo auto-call
    game.bet('romer', '12')
    game.fold('sara')
    expect(-> game.call('glv')).toThrow "You can't call yet."

    game.settleUp()

    expect(-> game.bet('romer', '5')).toThrow "No new bets."
    game.call('glv')
    game.fold('bogdan')
    # chrismo does nothing and auto-calls

    game.finishRound()

    expect(game.winningHandResult.playerName).toBe 'romer'
    expect(game.winningHandResult.hand.name).toBe 'Full House'
    expect(game.playerStore[0].name).toBe 'chrismo'
    expect(game.playerStore[0].points).toBe 25 - 1 - 12
    expect(game.playerStore[1].name).toBe 'romer'
    expect(game.playerStore[1].points).toBe 25 - 1 - 12 + (1 + 1 + 1 + 1 + 1) + (12 + 12 + 12 + 3)
    expect(game.playerStore[2].name).toBe 'sara'
    expect(game.playerStore[2].points).toBe 25 - 1
    expect(game.playerStore[3].name).toBe 'glv'
    expect(game.playerStore[3].points).toBe 25 - 1 - 12
    expect(game.playerStore[4].name).toBe 'bogdan'
    expect(game.playerStore[4].points).toBe 25 - 1 - 3

    # folded players should be marked
    expect(game.boardStore.sara.folded).toBe true
    expect(game.boardStore.bogdan.folded).toBe true

    expect(game.playState.name).toBe 'play'

  it 'should show board during play', ->
    game.play('chrismo', '112234')
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: X X         Bet In: 1.5 min\n" +
          "                                                        \n" +
          "                                               POT / ALL\n" +
          "chrismo              112 234  Two Pair           1 /  24"
    )
    game.play('romer', ' 555  964')
    time.now = builder.withMinute(1).withSecond(30).build()
    time.execCallback()
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: X X      Settle In: 1.5 min\n" +
          "                    bet [xx] | fold                     \n" +
          "                                               POT / ALL\n" +
          "romer                555 964  Three of a Kind    1 /  24\n" +
          "chrismo              112 234  Two Pair           1 /  24"
    )
    game.holeDigits = ['5', '6']
    time.now = builder.withMinute(2).withSecond(30).build()
    time.execCallback()
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: X X          Flop In: 1 min\n" +
          "       call | fold  ||  ** auto-call in effect **       \n" +
          "                                               POT / ALL\n" +
          "romer                555 964  Three of a Kind    1 /  24\n" +
          "chrismo              112 234  Two Pair           1 /  24"
    )
    time.now = builder.withMinute(3).withSecond(0).build()
    time.execCallback()
    expect(game.showBoard()).toBe (
          "Reverse Hold 'em       Hole: 5 6           Winner: romer\n" +
          "                                                        \n" +
          "                                               POT / ALL\n" +
          "romer                555 964  Full House         0 /  26\n" +
          "chrismo              112 234  Six Straight       0 /  24"
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
    game.startBetting()
    expect(listener.msgs[0]).toBe "1 point ante."
    # not going to expect the remaining instructions - this test is
    # more for the push at all, not the content itself.
    expect(listener.msgs[2]).toBe "Hands are locked. Time to bet. Type 'bet' and a number."

  it 'should allow direct funding to a player', ->
    game.play('chrismo', '112357')
    game.startBetting()
    game.bet('chrismo', '20')
    expect(game.playerStore[0].points).toBe 25 - 1 - 20
    game.fundPlayer('chrismo', '30')
    expect(game.playerStore[0].points).toBe 30

  it 'should declare a winner if everyone but one player folds'
  it 'should not allow a folded player to win', ->
    game.play('chrismo', '123456')
    game.play('romer', '112357')
    game.startBetting()
    expect(game.boardStore.romer.folded).toBe false
    expect(game.boardStore.chrismo.folded).toBe false
    game.fold('chrismo')
    expect(game.boardStore.chrismo.folded).toBe true
    expect(game.winningHandResult.playerName).toBe 'romer'

  it 'should not allow a folded player to call', ->
    # it doesn't but it's a thrown err out of the pot
    # which is a little confusing to display there, but
    # it doesn't cause any problems.

  it 'should not show folded player amount in pot after win', ->
    # the player is not in the pot to have their totalBet
    # value reset to 0. So ... maybe the POT needs to track
    # folded players, instead of the game?




class FakeListener
  constructor: ->
    @msgs = []

  onStatus: (msg) ->
    @msgs.push msg