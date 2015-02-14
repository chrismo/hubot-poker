_ = require('underscore')
Rounds = require('../poker/round')

module.exports = class AiPlayer
  constructor: (@name, @game, @time) ->
    @game.addListener(this)
    @time ||= new Rounds.TimeProvider
    @timeouts = []
    @hand = null

  canPushToPlayer: (playerName) ->
    @name == playerName

  onPushToPlayer: (playerName, msg) ->
    # msg is hand.display(), so rather than rev engineer it, we'll get our
    # cards from the game.
    return unless playerName == @name
    @hand = @game.boardStore[@name].playerHand

  onGameCommand: (playerCommand, parsedCommand, commandResult) ->
    this.queueCommand('deal') unless @hand?

  queueCommand: (gameCommand, seconds) ->
    # need to space out the commands to not overwhelm the game
    seconds ||= this.randomInt(3)
    @nextQueuedMsecs = seconds * 1000
    callback = => (@game.sendCommand(@name, gameCommand))
    @timeouts.push @time.setTimeout(callback, @nextQueuedMsecs)

  randomInt: (maxExclusive) ->
    Math.floor(Math.random() * maxExclusive)

  onFinishRound: ->
    @hand = null
