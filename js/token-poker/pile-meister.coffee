_ = require('underscore')
Game = require ('./base-game')
GameCommand = require('../poker/game-command')
TokenPoker = require('./core')
Player = require('../poker/player')
PlayerHand = require('./player-hand')
Rounds = require('../poker/round')

module.exports = class PileMeister extends Game.BaseGame
  @help: ->
    [
      'PileMeister - accumulate as many points by end of round.',
      '',
      'deal [chain] - Be dealt a hand and optionally chain it to the next play.',
      'break [xx]   - Break the current chain and optionally remove [xx] points from it.'
      '',
      "When a chain of hands is broken, all points in the chain are distributed evenly",
      "to all players in the chain. The 'deal' command w/o the chain option will add",
      "your hand to the chain and break it. All points sent to 'break' command will be",
      "removed from your points total, even if it's more points than are in the chain,",
      "then subtracted from the chain before distributed to players in the chain. Only",
      "one command per player per 30 seconds by default. Scores include game config."
    ].join("\n")

  constructor: (@store, @round) ->
    super(@store, @round)
    @playerStore = @store.playerStore ||= []
    @round ||= new Rounds.TimedRound(30)
    @lengthOfRoundInMinutes = @round.total
    @secondsToWaitBetweenPlays = @lengthOfRoundInMinutes
    @chain = []

  isStarted: ->
    @round.isStarted()

  startRound: ->
    super
    @round.start()
    this.resetScores()

  resetScores: ->
    @playerStore = []

  commands: -> [
    (new GameCommand(/^deal ?(chain)?$/i, this.deal, => (["deal", "deal chain"][this.randomProvider.randomInt(2)]))),
    (new GameCommand(/^break (\d+)$/i, this.break, => ("break #{this.randomProvider.randomInt(10)}")))
  ]

  deal: (playerName, chain) ->
    chain = this.processOptArg(chain)
    this.ensureRoundStarted()
    player = this.ensurePlayerInStore(playerName)
    this.vetTimeToPlay(player)
    digits = this.randomHand()
    playerHand = new PlayerHand(player, digits, @matcher.matchHighest(digits))
    playerHand.score = Math.floor(1000000 / playerHand.matchedHand.matchCount)
    player.rank = this.playerRank(playerName)

    if chain == 'chain'
      @chain.push playerHand
    else
      if @chain.length == 0
        playerHand.player.points += playerHand.score
      else
        @chain.push playerHand
        chainTotal = this.applyChain()
        this.pushScores()
        return [new DealResult(playerHand), new BreakResult(chainTotal)]

    new DealResult(playerHand, chain)

  break: (playerName, points) ->
    points = this.processOptArg(points)
    this.ensureRoundStarted()
    player = this.ensurePlayerInStore(playerName)
    this.vetTimeToPlay(player)
    penalty = if points == '' then 0 else parseInt(points)
    penalty = Math.min(penalty, player.points)
    player.points -= penalty
    chainTotal = this.applyChain(penalty)
    this.pushScores()
    new BreakResult(chainTotal)

  processOptArg: (arg) ->
    arg ||= ''
    arg = _.flatten([arg]).join()

  vetTimeToPlay: (player) ->
    if player.lastPlay == undefined
      player.lastPlay = @round.now()
    else
      seconds = (@round.now() - player.lastPlay) / 1000
      throw "too soon #{player.name}" if seconds < @secondsToWaitBetweenPlays

  applyChain: (penalty) ->
    players = (playerHand.player for playerHand in @chain)
    players = _.uniq(players)
    if @chain.length > 0
      chainTotal = (ph.score for ph in @chain).reduce (t, s) -> t + s
    else
      chainTotal = 0
    chainTotal -= penalty unless penalty == undefined
    chainTotal = Math.max(chainTotal, 0)
    (player.points += Math.floor(chainTotal / players.length) for player in players)
    @chain = []
    chainTotal

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
    @round.end()
    @winner = this.scoresInWinningOrder()[0]
    this.pushScores()

  getStatus: ->
    this.scoreboard()

  scoreboard: ->
    s = []

    header = [
      'PileMeister',
      'deal [chain] | break [xx] | poker help',
      "One command per player per #{@secondsToWaitBetweenPlays} seconds."
      '---'
    ]
    header.push (
      switch
        when @winner
          ["** WINNER **: #{@winner[0]}", '']
        else
          ["Time Left: #{@round.minutesLeft()} minutes", '']
    )
    header = _.flatten(header)

    for player in this.scoresInWinningOrder()
      s.push "#{player.name}: #{player.points}"
    s = header.concat(if s.length == 0 then ['[NO SCORES YET]'] else s)
    s.join("\n")

  scoresInWinningOrder: ->
    (p for p in @playerStore).sort (a, b) -> b.points - a.points

  playerRank: (playerName) ->
    rank = null
    _.forEach(this.scoresInWinningOrder(), (e, i) -> (rank = i + 1 if e.name == playerName))
    rank

  pushScores: ->
    this.pushStatus(this.scoreboard())


class DealResult
  constructor: (@playerHand, @chained) ->

  toStatus: ->
    ph = @playerHand
    ch = if @chained == 'chain' then '-=CHAINED=-' else ''
    "#{ph.playerDigits} => #{ph.matchedHand.name}. #{ph.score} points. #{ch} Player Total: #{ph.player.points}. Place: #{ph.player.rank}"

class BreakResult
  constructor: (@chainTotal) ->

  toStatus: ->
    if @chainTotal > 0
      "CHAIN BROKEN. #{@chainTotal} points split among chained players."
    else
      "No chain to break. If you spent points to do it, they still gone. D'oh!"
