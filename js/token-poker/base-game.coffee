GameCommand = require('./game-command')
TokenPoker = require('./core')
_ = require('underscore')

module.exports = class BaseGame
  constructor: (@store, @round) ->
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

    this.setCache(1)

  setCache: (minimumPlayers) ->
    @playCache = new PlayCache(this, minimumPlayers)

  sendCommand: (playerName, args) ->
    try
      commandResults = []
      # TODO: remove coupling into TimedRound class
      # smell - because we're caching plays, but now can no longer just
      # allow the Round instance to throw when it's too soon, so now
      # the Game class is having to have Round knowledge - which is wrong.
      # if we ever wanted a non-Timed round - this is wrong. We're
      # screwing with the nature of things.
      @round.throwIfNotRestartable() if @round.restartDelaySecondsLeft() > 0
      return if !this.matchedGameCommand(args)
      playerCommands = @playCache.sendCommand(playerName, args)
      this.ensureRoundStarted()
      for playerCommand in playerCommands
        [result, gameCommand] = this.matchedGameCommand(playerCommand.args)
        commandResults.push gameCommand.callback.call(this, playerCommand.playerName, result[1..]...)
      switch
        when commandResults.length > 1
          commandResults
        when commandResults.length == 1
          commandResults[0]
        else
          undefined
    catch error
      error

  matchedGameCommand: (args) ->
    for gameCommand in this.commands()
      if result = gameCommand.regexp.exec(args)
        return [result, gameCommand]

  ensureRoundStarted: ->
    this.startRound() if !@round.isStarted()

  startRound: ->
    @round.start()
    this.setAlarms() if this.setAlarms
    @winner = undefined

  finishRound: ->
    @listener.onFinishRound() if @listener
    @round.end()

  randomDigit: ->
    @randomProvider.randomDigit()

  randomHand: ->
    hand = []
    _.times(6, (n) => (hand.push(this.randomDigit())))
    hand.join('')

  setListener: (@listener) ->

  pushStatus: (text) ->
    @listener.onStatus(text) if @listener


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