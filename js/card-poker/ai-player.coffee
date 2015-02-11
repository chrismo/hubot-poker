_ = require('underscore')
Rounds = require('../poker/round')

module.exports = class AiPlayer
  constructor: (@name, @game, @time) ->
    @game.addListener(this)
    @time ||= new Rounds.TimeProvider
    @timeouts = []

  onGameCommand: (playerCommand, parsedCommand, commandResult) ->
    this.queueCommand('deal')

  queueCommand: (gameCommand, seconds) ->
    # need to space out the commands to not overwhelm the game
    seconds ||= this.randomInt(3)
    @nextQueuedMsecs = seconds * 1000
    callback = => (@game.sendCommand(@name, gameCommand))
    @timeouts.push @time.setTimeout(callback, @nextQueuedMsecs)

  randomInt: (maxExclusive) ->
    Math.floor(Math.random() * maxExclusive)
