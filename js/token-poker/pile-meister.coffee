TokenPoker = require('./core')
BaseGame = require ('./base-game')
Rounds = require('./round')
PlayerHand = require('./player-hand')
Player = require('./player')
_ = require('underscore')

module.exports = class PileMeister extends BaseGame
  constructor: (@store, @round) ->
    super(@store, @round)
    @playerStore = @store.playerStore ||= []

    @round ||= new Rounds.TimedRound(60)

  startRound: ->
    super
    this.resetScores()

  resetScores: ->
    @playerStore = []

  deal: (playerName) ->
    this.ensureRoundStarted()
    player = this.ensurePlayerInStore(playerName)
    digits = this.randomHand()
    playerHand = new PlayerHand(player, digits, @matcher.matchHighest(digits))
    playerHand.score = Math.floor(1000000 / playerHand.matchedHand.matchCount)
    playerHand.player.points += playerHand.score
    player.rank = this.playerRank(playerName)
    playerHand

  ensurePlayerInStore: (playerName) ->
    player = this.getPlayerFromStore(playerName)
    unless player
      player = new Player(playerName, 0)
      @playerStore.push(player)

    player

  getPlayerFromStore: (playerName) ->
    _.find(@playerStore, (p) -> (p.name == playerName))

  setAlarms: ->
    @round.setAlarm(@round.total / 2, this, this.pushScores)
    @round.setAlarm(@round.total / 4, this, this.pushScores)
    @round.setAlarm(@round.total / 8, this, this.pushScores)
    @round.setAlarm(2, this, this.pushScores)
    @round.setAlarm(1, this, this.pushScores)
    @round.setAlarm(0, this, this.finishRound)

  finishRound: ->
    super
    @winner = this.scoresInWinningOrder()[0]
    this.pushScores()

  addScore: (playerHand) ->
    playerHand.player.score ||= 0

    @scoreStorage[playerHand.player.name] ||= 0
    @scoreStorage[playerHand.player.name] += playerHand.score

  getStatus: ->
    this.scoreboard()

  scoreboard: ->
    s = []

    header = switch
      when @winner
        ["** WINNER **: #{@winner[0]}", '']
      else
        ["Time Left: #{@round.minutesLeft()} minutes", '']

    for player in this.scoresInWinningOrder()
      s.push "#{player.name}: #{player.points}"
    s = header.concat(if s.length == 0 then ['[NO SCORES YET]'] else s)
    s.join("\n")

  scoresInWinningOrder: ->
    @playerStore.sort (a, b) -> b.points - a.points

  playerRank: (playerName) ->
    rank = null
    _.forEach(this.scoresInWinningOrder(), (e, i) -> (rank = i+1 if e.name == playerName))
    rank

  pushScores: ->
    this.pushStatus(this.scoreboard())
