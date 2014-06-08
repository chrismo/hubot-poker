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
    @chain = []

  startRound: ->
    super
    this.resetScores()

  resetScores: ->
    @playerStore = []

  deal: (playerName, chain) ->
    this.ensureRoundStarted()
    player = this.ensurePlayerInStore(playerName)
    this.vetTimeToPlay(player)
    digits = this.randomHand()
    playerHand = new PlayerHand(player, digits, @matcher.matchHighest(digits))
    playerHand.score = Math.floor(1000000 / playerHand.matchedHand.matchCount)
    player.rank = this.playerRank(playerName)
    if chain == undefined
      if @chain.length == 0
        playerHand.player.points += playerHand.score
      else
        @chain.push playerHand
        this.applyChain()
    else
      @chain.push playerHand
    playerHand

  vetTimeToPlay: (player) ->
    if player.lastPlay == undefined
      player.lastPlay = @round.now()
    else
      seconds = (@round.now() - player.lastPlay) / 1000
      throw "too soon #{player.name}" if seconds < 60

  applyChain: ->
    players = (playerHand.player for playerHand in @chain)
    players = _.uniq(players)
    chainTotal = (ph.score for ph in @chain).reduce (t, s) -> t + s
    (player.points += (chainTotal / players.length) for player in players)
    @chain = []

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
