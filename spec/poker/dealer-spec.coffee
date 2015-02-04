Game = require('../../js/token-poker/base-game')
Dealer = require('../../js/poker/dealer')
GameCommand = require('../../js/poker/game-command')
Rounds = require('../../js/poker/round')

describe 'Dealer', ->
  dealer = null
  storage = {}
  id = 'dlr'

  beforeEach ->
    dealer = new Dealer(storage, id, [KillEmAll, LoserWins])

  it 'should know about games', ->
    game = dealer.listGames()
    expect(game[0]).toBe "kill em all"
    expect(game[1]).toBe "loser wins"

  it 'should default current to first in list', ->
    expect(dealer.currentGameClass).toBe KillEmAll

  it 'should start a new game by default', ->
    expect(dealer.game.constructor.name).toBe 'KillEmAll'

  it 'should return status of current game', ->
    result = dealer.getStatus()
    expect(result).toBe "game status"

  it 'should change the game', ->
    dealer.changeGame('chrismo', 'loser')
    expect(dealer.game.constructor.name).toBe 'LoserWins'

  it 'should throw on change game when name is not found', ->
    expect(-> dealer.changeGame('chrismo', 'nope')).toThrow 'Cannot find a game matching <nope>'

  it 'should throw on change game when too many hits', ->
    expect(-> dealer.changeGame('chrismo', 'i')).toThrow 'Be more specific, more than one name matches <i>'

  it 'should finishRound on the current game if new game is different', ->
    listener = new FakeListener
    dealer.addListener(listener)
    dealer.sendToGame('chrismo', '123123')
    dealer.sendToGame('romer', '123123')
    firstGame = dealer.game
    expect(firstGame.round.isStarted()).toBe true

    dealer.changeGame('chrismo', 'loser')
    expect(dealer.game.constructor.name).toBe 'LoserWins'
    expect(firstGame.round.isOver()).toBe true
    expect(listener.finishRound).toBe true

  it 'should do nothing if the requested game is already in play', ->
    dealer.sendToGame('chrismo', '123123')
    dealer.sendToGame('romer', '123123')
    firstGame = dealer.game
    expect(firstGame.round.isStarted()).toBe true

    dealer.changeGame('chrismo', 'kill')
    expect(firstGame.round.isOver()).toBe false
    expect(firstGame).toBe dealer.game

  it 'should listen to game events and push to its listener', ->
    listener = new FakeListener
    dealer.addListener(listener)
    game = dealer.game
    game.pushStatus('foobar')
    expect(listener.lastStatus).toBe 'foobar'

  it 'should handle a bet game command', ->
    res = dealer.sendToGame('chrismo', 'bet 12')
    expect(res).toBe 'chrismo bet 12'

  it 'should handle a second game command', ->
    res = dealer.sendToGame('chrismo', 'fund 12')
    expect(res).toBe "chrismo funded 12"

  it 'should handle a multiple argument command', ->
    res = dealer.sendToGame('chrismo', 'many foo bar')
    expect(res).toBe "chrismo foo bar"

  it 'should manage ai players', ->
    dealer.addAi('foo')
    dealer.addAi('bar')
    expect(dealer.ais.length).toBe 2
    expect(dealer.ais[0].name).toBe 'foo'
    expect(dealer.ais[1].name).toBe 'bar'
    dealer.killAi('bar')
    expect(dealer.ais.length).toBe 1
    expect(dealer.ais[0].name).toBe 'foo'
    dealer.killAi('foo')
    expect(dealer.ais.length).toBe 0


class KillEmAll extends Game.BaseGame
  constructor: ->
    super
    @round = new Rounds.TimedRound(1)

  commands: -> [
    new GameCommand(/^(\d{6})$/i, this.play),
    new GameCommand(/^bet (\d+)$/i, this.bet),
    new GameCommand(/^fund (\d+)$/i, this.fundPlayer),
    new GameCommand(/^many (\w+) (\w+)/i, this.manyArgumentCommand)
  ]

  isStarted: ->
    @round.isStarted()

  startRound: ->
    super
    @round.start()

  finishRound: ->
    super
    @round.end()

  abortGame: ->
    this.finishRound()

  play: (player, hand) ->
    this.ensureRoundStarted()
    "#{player} played #{hand}"

  bet: (player, bet) ->
    "#{player} bet #{bet}"

  fundPlayer: (player, amount) ->
    "#{player} funded #{amount}"

  manyArgumentCommand: (player, one, two) ->
    "#{player} #{one} #{two}"

  getStatus: ->
    "game status"


class LoserWins extends Game.BaseGame


class FakeListener
  onStatus: (@lastStatus) ->
  onStartRound: ->
    @startRound = true
  onFinishRound: ->
    @finishRound = true
