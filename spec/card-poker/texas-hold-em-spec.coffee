Core = require('../../js/card-poker/core')
TexasHoldEm = require('../../js/card-poker/texas-hold-em')
Fakes = require('../poker/fake-time')
Rounds = require('../../js/poker/round')
Player = require('../../js/poker/player')
_ = require('underscore')

describe 'TexasHoldEm', ->
  store = game = null
  builder = time = null

  beforeEach ->
    store = {}
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    game = new TexasHoldEm(store, time)
    game.playerStartingPoints = 25

  it 'basic gameplay with play, bet and settle rounds', ->
    game.startRound()
    game.playState.round.onGameCommand({playerName: 'ghost'})

    game.deck = new Core.Deck()
    game.holeCards = game.deck.findAll(['5C', '8C', '8D', '9H', 'JC'])

    playerCards = game.deck.findAll(['2S','4S','5S','5H','QC','3D','10H','KH','AS','7S']).cards
    game.deck.cards.unshift playerCards
    game.deck.cards = _.flatten(game.deck.cards)

    game.sendCommand('chrismo', 'deal')
    game.sendCommand('romer', 'deal')
    game.sendCommand('sara', 'deal')
    game.sendCommand('glv', 'deal')
    game.sendCommand('bogdan', 'deal')

    game.startBetting()

    expect(-> game.bet('woodall', '10')).toThrow "Can't bet if you haven't played."
    game.sendCommand('bogdan', 'bet 3')
    game.sendCommand('chrismo', 'bet 10') # demo auto-call
    game.sendCommand('romer', 'bet 12')
    game.sendCommand('sara', 'fold')
    # player can call at this point now. It's potentially confusing if the player
    # has a strict expectation that call either means no higher bets can be made
    # or that the call command will be sticky, meaning it auto-adjusts to higher
    # bets. Play testing so far has shown players to be more confused over not
    # being able to issue this command at this point, presuming it would be
    # simply synonymous with "bet #{highest}".
    game.sendCommand('glv', 'call')

    game.settleUp()

    expect(-> game.bet('romer', '5')).toThrow "No new bets."
    game.sendCommand('glv', 'call')
    game.sendCommand('bogdan', 'fold')
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

    expect(game.playState.name).toBe 'end'

    game.startNewRound()

    expect(game.playState.name).toBe 'play'


class FakeListener
  constructor: ->
    @msgs = []

  onStartRound: ->

  onStatus: (msg) ->
    @msgs.push msg
