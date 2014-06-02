TokenPoker = require('./core')

module.exports = class BaseGame
  constructor: (@store, @round) ->
    @registry = new TokenPoker.HandRegistry([
      new TokenPoker.GroupedHand('Six of a Kind', '6', 10),
      new TokenPoker.GroupedHand('Five of a Kind', '51', 540),
      new TokenPoker.GroupedHand('Deuce Trips', '33', 900),
      new TokenPoker.GroupedHand('Full House', '42', 1350),
      new TokenPoker.StraightHand('Six Straight', 6, 4320),
      new TokenPoker.GroupedHand('Three Pair', '222', 10800),
      new TokenPoker.GroupedHand('Four of a Kind', '411', 10800),
      new TokenPoker.StraightHand('Five Straight', 5, 29144),
      new TokenPoker.GroupedHand('Crowded House', '321', 43200),
      new TokenPoker.GroupedHand('Three of a Kind', '3111', 100800),
      new TokenPoker.GroupedHand('Snowflake', '111111', 130336),
      new TokenPoker.GroupedHand('Two Pair', '2211', 226800),
      new TokenPoker.GroupedHand('One Pair', '21111', 441000)
    ])
    @matcher = new TokenPoker.HandMatcher(@registry)

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
    # 0 - 9
    Math.floor(Math.random() * 10)

  setListener: (@listener) ->

  pushStatus: (text) ->
    @listener.onStatus(text) if @listener


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