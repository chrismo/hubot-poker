GameCommand = require('../poker/game-command')
TokenPoker = require('./core')
_ = require('underscore')

module.exports.BaseGame = class BaseGame
  constructor: (@store) ->
    @registry = new TokenPoker.HandRegistry([
      new TokenPoker.GroupedHand('Six of a Kind', '6', 10),
      new TokenPoker.GroupedHand('Five of a Kind', '51', 540),
      new TokenPoker.GroupedHand('Deuce Trips', '33', 900),
      new TokenPoker.GroupedHand('Full House', '42', 1350),
      new TokenPoker.StraightHand('Six Straight', 6, 3600),
      new TokenPoker.GroupedHand('Three Pair', '222', 10800),
      new TokenPoker.GroupedHand('Four of a Kind', '411', 10800),
      new TokenPoker.StraightHand('Five Straight', 5, 25184),
      new TokenPoker.GroupedHand('Crowded House', '321', 43200),
      new TokenPoker.GroupedHand('Three of a Kind', '3111', 100800),
      new TokenPoker.GroupedHand('Snowflake', '111111', 133216),
      new TokenPoker.GroupedHand('Two Pair', '2211', 226800),
      new TokenPoker.GroupedHand('One Pair', '21111', 442800)
    ])
    @matcher = new TokenPoker.HandMatcher(@registry)
    @randomProvider ||= new RandomProvider

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
      error

  matchedGameCommand: (args) ->
    for gameCommand in this.commands()
      parsed = gameCommand.execute(args)
      return parsed if parsed

  ensureRoundStarted: ->
    this.startRound() if !this.isStarted()

  startRound: ->
    (l.onStartRound() if l.onStartRound) for l in @listeners
    # TODO: make subclass game get this as a listener to remove this hack - is it a hack?
    # it is a hack in the Base game, because alarms presumes a TimedRound, which has been
    # an ok to presume, but design-wise, base game shouldn't know/care about it.
    #
    # BaseGame may not need to care about rounds at all now that the push is on to get
    # all of the minPlayer/time mgmt into ReverseHoldEm.
    this.setAlarms() if this.setAlarms
    @winner = undefined

  finishRound: ->
    (l.onFinishRound() if l.onFinishRound) for l in @listeners

  abortGame: ->

  randomDigit: ->
    @randomProvider.randomDigit()

  randomHand: ->
    hand = []
    _.times(6, (n) => (hand.push(this.randomDigit())))
    hand.join('')

  setListener: (listener) ->
    @listeners.push(listener)

  addListener: (listener) ->
    @listeners.push(listener)

  pushStatus: (text) ->
    (l.onStatus(text) if l.onStatus) for l in @listeners


class RandomProvider
  randomDigit: ->
    this.randomInt(10)

  randomInt: (max) ->
    Math.floor(Math.random() * max)


class PlayCache
  constructor: (@game, @minimumPlayers) ->
    @playCache = []

  sendCommand: (playerName, args) ->
    @playCache.push {playerName: playerName, args: args}
    if this.minimumHavePlayed()
      results = []
      while @playCache.length > 0
        thisPlay = @playCache.shift()
        results.push thisPlay
      results
    else
      throw "Need #{@minimumPlayers} players to start the next round."

  minimumHavePlayed: ->
    @game.round.isStarted() ||
      this.playersInPlayCache() >= @minimumPlayers

  playersInPlayCache: ->
    players = (play.playerName for play in @playCache)
    _.uniq(players).length

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
