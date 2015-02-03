_ = require('underscore')
Game = require ('./base-game')
GameCommand = require('../poker/game-command')
Rounds = require('../poker/round')
TokenPoker = require('./core')

module.exports = class Stockpile extends Game.BaseGame
  @help: ->
    [
      'Stockpile - accumulate as many points by end of round.',
      '',
      '<6 digits> - Enter a 6 digit token',
    ].join("\n")

  constructor: (@store, roundDuration, @time) ->
    super(@store)
    @scoreStorage = @store.scores ||= {}
    @round = new Rounds.TimedRound(roundDuration || 60, @time)
    @round.addListener(this)

  onRoundStateChange: (state) ->
    this.finishRound() if state == 'over'

  calculateOdds: ->
    new TokenPoker.OddsCalculator(@registry, 999999).calculate()

  isStarted: ->
    @round.isStarted()

  startRound: ->
    super
    @round.start()
    this.resetScores()

  resetScores: ->
    @scoreStorage = {}

  commands: -> [
    new GameCommand(/^((\d{6})|(\d{3} \d{3}))$/i, this.play, => (this.randomHand()))
  ]

  play: (playerName, playerHand) ->
    this.ensureRoundStarted()
    result = new HandResult(playerName, @matcher.matchHighest(playerHand))
    roundTotal = this.addScore(result)
    result.setPlayerRoundScore(roundTotal)
    result.setPlayerRank(this.playerRank(playerName))
    result.setPlayerHand(playerHand)
    result

  setAlarms: ->
    @round.setAlarm(@round.total / 2, this, this.pushScores)
    @round.setAlarm(@round.total / 4, this, this.pushScores)
    @round.setAlarm(@round.total / 8, this, this.pushScores)
    @round.setAlarm(2, this, this.pushScores)
    @round.setAlarm(1, this, this.pushScores)
    #@round.setAlarm(0, this, this.finishRound)

  finishRound: ->
    super
    @winner = this.scoresInWinningOrder()[0]
    this.pushScores()

  addScore: (handResult) ->
    @scoreStorage[handResult.playerName] ||= 0
    @scoreStorage[handResult.playerName] += handResult.score

  getStatus: ->
    this.scoreboard()

  scoreboard: ->
    s = []

    header = switch
      when @winner
        ["** WINNER **: #{@winner[0]}", '']
      else
        ["Time Left: #{@round.minutesLeft()} minutes", '']

    # TODO: re-use Player class for scoruple
    for scoruple in this.scoresInWinningOrder()
      s.push "#{scoruple[0]}: #{scoruple[1]}"
    s = header.concat(if s.length == 0 then ['[NO SCORES YET]'] else s)
    s.join("\n")

  scoresInWinningOrder: ->
    scores = for playerName, score of @scoreStorage
      [playerName, score]

    scores.sort (a, b) ->
      b[1] - a[1]

  playerRank: (player) ->
    rank = null
    _.forEach(this.scoresInWinningOrder(), (e, i) -> (rank = i+1 if e[0] == player))
    rank

  pushScores: ->
    this.pushStatus(this.scoreboard())

class HandResult
  constructor: (@playerName, @hand) ->
    @name = @hand.name
    @score = Math.floor(1000000 / @hand.matchCount)

  setPlayerRoundScore: (@playerRoundScore) ->

  setPlayerRank: (@playerRank) ->

  setPlayerHand: (@playerHand) ->

  toStatus: ->
    "#{this.playerHand} => #{this.name}. #{this.score} points. Player Total: #{this.playerRoundScore}. Place: #{this.playerRank}"
