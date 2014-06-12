Dealer = require('../js/token-poker/dealer')
BaseGame = require('../js/token-poker/base-game')
Rounds = require('../js/token-poker/round')

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

  it 'should create a new game', ->
    game = dealer.startNewGame()
    expect(game.constructor.name).toBe 'KillEmAll'

  it 'should return status of current game', ->
    result = dealer.getStatus()
    expect(result).toBe "game status"

  it 'should allow admin to change the game', ->
    dealer.changeGame('chrismo', 'loser')
    expect(dealer.game.constructor.name).toBe 'LoserWins'

  it 'should throw on change game when name is not found', ->
    expect(-> dealer.changeGame('chrismo', 'nope')).toThrow 'Cannot find a game matching <nope>'

  it 'should throw on change game when too many hits', ->
    expect(-> dealer.changeGame('chrismo', 'i')).toThrow 'Be more specific, more than one name matches <i>'

  it 'should finishRound on the current game if new game is different', ->
    listener = new FakeListener
    dealer.setListener(listener)
    dealer.play('chrismo', '123123')
    dealer.play('romer', '123123')
    firstGame = dealer.game
    expect(firstGame.round.isStarted()).toBe true

    dealer.changeGame('chrismo', 'loser')
    expect(dealer.game.constructor.name).toBe 'LoserWins'
    expect(firstGame.round.isOver()).toBe true
    expect(listener.finishRound).toBe true

  it 'should do nothing if the requested game is already in play', ->
    dealer.play('chrismo', '123123')
    dealer.play('romer', '123123')
    firstGame = dealer.game
    expect(firstGame.round.isStarted()).toBe true

    dealer.changeGame('chrismo', 'kill')
    expect(firstGame.round.isOver()).toBe false
    expect(firstGame).toBe dealer.game

  it 'should listen to game events and push to its listener', ->
    listener = new FakeListener
    dealer.setListener(listener)
    game = dealer.startNewGame()
    game.pushStatus('foobar')
    expect(listener.lastStatus).toBe 'foobar'

  it 'should handle betting', ->
    dealer.startNewGame()
    res = dealer.bet('chrismo', '12')
    expect(res).toBe 'chrismo bet 12'

  it 'should pass-through fund call to game', ->
    dealer.startNewGame()
    res = dealer.fundPlayer('chrismo', '12')
    expect(res).toBe "chrismo funded 12"

  it 'should manage ai players', ->
    dealer.startNewGame()
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

  it 'should hold first player plays on a new round until second player', ->
    result = dealer.play('romer', '243243')
    expect(result).toBe 'Need a second player to start the next round.'
    result = dealer.play('romer', '555666')
    expect(result).toBe 'Need a second player to start the next round.'
    result = dealer.play('chrismo', '123123')
    expect(result.join("\n")).toBe 'romer played 243243\nromer played 555666\nchrismo played 123123'
    result = dealer.play('sara', '343434')
    expect(result).toBe "sara played 343434"

  it 'should ask the game to vet the player if it supports it', ->
    dealer.currentGameClass = VetPlayerGame
    dealer.startNewGame()
    dealer.game.denyPlayerName = 'chrismo'
    result = dealer.play('romer', '243243')
    expect(result).toBe 'Need a second player to start the next round.'
    expect(-> dealer.play('chrismo', '123123')).toThrow "No can do for chrismo"
    result = dealer.play('romer', '243243')
    expect(result).toBe 'Need a second player to start the next round.'


class KillEmAll extends BaseGame
  constructor: ->
    @round = new Rounds.TimedRound(1)

  play: (player, hand) ->
    this.ensureRoundStarted()
    "#{player} played #{hand}"

  bet: (player, bet) ->
    "#{player} bet #{bet}"

  fundPlayer: (player, amount) ->
    "#{player} funded #{amount}"

  getStatus: ->
    "game status"


class LoserWins extends BaseGame


class VetPlayerGame extends BaseGame
  constructor: (@denyPlayerName) ->
    @round = new Rounds.TimedRound(1)

  vetPlayerForPlaying: (playerName) ->
    throw "No can do for #{playerName}" if playerName == @denyPlayerName

  play: (@playerName, @playerHand) ->


class FakeListener
  onStatus: (@lastStatus) ->
  onFinishRound: ->
    @finishRound = true