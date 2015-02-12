GameCommand = require('../poker/game-command')
CardPoker = require('./core')
Hand = require('./hand')
_ = require('underscore')

module.exports.BaseGame = class BaseGame
  constructor: (@store) ->
    @matcher = new Hand.HandMatcher()

    @listeners = []

  sendCommand: (playerName, args) ->
    return if !this.matchedGameCommand(args)
    this.ensureRoundStarted()
    try
      playerCommand = {playerName: playerName, args: args}
      parsedCommand = this.matchedGameCommand(playerCommand.args)
      commandResult = parsedCommand.callback.call(this, playerCommand.playerName, parsedCommand.parsedArgs[1..]...)
      (l.onGameCommand(playerCommand, parsedCommand, commandResult) if l.onGameCommand) for l in @listeners
      commandResult
    catch error
      console.log(error.stack)
      error

  matchedGameCommand: (args) ->
    for gameCommand in this.commands()
      parsed = gameCommand.execute(args)
      return parsed if parsed

  ensureRoundStarted: ->
    this.startRound() if !this.isStarted()

  startRound: ->
    (l.onStartRound() if l.onStartRound) for l in @listeners
    @winner = undefined

  finishRound: ->
    (l.onFinishRound() if l.onFinishRound) for l in @listeners

  abortGame: ->

  addListener: (listener) ->
    @listeners.push(listener)

  pushStatus: (text) ->
    (l.onStatus(text) if l.onStatus) for l in @listeners

  canPushToPlayer: (playerName) ->
    for l in @listeners
      if l.canPushToPlayer
        return l.canPushToPlayer(playerName)
      else
        false

  pushToPlayer: (playerName, msg) ->
    for l in @listeners
      if l.onPushToPlayer && l.canPushToPlayer
        if l.canPushToPlayer(playerName)
          l.onPushToPlayer(playerName, msg)


`
// http://snipplr.com/view.php?codeview&id=709
String.prototype.ljust = function( width, padding ) {
	padding = padding || " ";
	padding = padding.substr( 0, 1 );
	if( this.length < width )
		return this + padding.repeat( width - this.length );
	else
		return this;
}
String.prototype.rjust = function( width, padding ) {
	padding = padding || " ";
	padding = padding.substr( 0, 1 );
	if( this.length < width )
		return padding.repeat( width - this.length ) + this;
	else
		return this;
}
String.prototype.center = function( width, padding ) {
	padding = padding || " ";
	padding = padding.substr( 0, 1 );
	if( this.length < width ) {
		var len		= width - this.length;
		var remain	= ( len % 2 == 0 ) ? "" : padding;
		var pads	= padding.repeat( parseInt( len / 2 ) );
		return pads + this + pads + remain;
	}
	else
		return this;
}

String.prototype.repeat = function( num ) {
	for( var i = 0, buf = ""; i < num; i++ ) buf += this;
	return buf;
}
`
