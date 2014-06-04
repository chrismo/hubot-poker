_ = require('underscore')
BaseGame = require ('./base-game')
Player = require('./player')
Pot = require('./pot')
Rounds = require('./round')
TokenPoker = require('./core')

module.exports = class ReverseHoldEm extends BaseGame
  constructor: (@store, @round) ->
    super(@store, @round)
    @playerStore = @store.playerStore ||= []
    @round ||= new Rounds.TimedRound(2)
    @playState = new HandsPlayState(this)
    @pot = new Pot(1)
    # there's a smell around these durations and the play state classes.
    # there's a more elegant way to string these together, i can feel it
    @betDuration = 0.5
    @settleDuration = 0.5
    @timeouts = []
    @playerStartingPoints = 100

  diagnostic: ->
    "\nReverseHoldEm\n\n" +
    "@playState: #{@playState.name}\n" +
    "@playerStore: #{([player.name, player.points] for player in @playerStore).join(',')}\n" +
    (if @round.diagnostic then @round.diagnostic() else '') +
    (if @pot.diagnostic then @pot.diagnostic() else '')

  play: (playerName, playerHand) ->
    this.vetPlayerForPlaying(playerName)
    this.ensureRoundStarted()
    player = this.ensurePlayerInStore(playerName)
    this.storeHandResult(new HandResult(player, playerHand, @matcher.matchHighest(playerHand)))
    this.pushBoard()
    null # to indicate no reply is necessary, the board will be pushed

  bet: (playerName, bet) ->
    @pot.bet(this.vetPlayerForBetting(playerName, 'bet'), bet)
    this.pushBoard()
    null

  fold: (playerName) ->
    player = this.vetPlayerForBetting(playerName, 'fold')
    @pot.fold(player)
    @boardStore[player.name].folded = true
    this.pushBoard() unless this.checkForLoneWinner()
    null

  call: (playerName) ->
    @pot.call(this.vetPlayerForBetting(playerName, 'call'))
    this.pushBoard()
    null

  vetPlayerForPlaying: (playerName) ->
    # TODO: allow folding at anytime, but have to workaround checkForLoneWinner and call it again at the start of betting.
    @playState.vetAction('play')
    player = this.getPlayerFromStore(playerName)
    throw "No dough, no show." if player && player.points == 0
    true

  vetPlayerForBetting: (playerName, betAction) ->
    @playState.vetAction('bet', betAction)
    player = this.getPlayerFromStore(playerName)
    throw "Can't bet if you haven't played." unless player && @boardStore[playerName]
    return player

  checkForLoneWinner: ->
    unfoldedHandResults = (handResult for handResult in this.handsInWinningOrder() when handResult.folded == false)
    if unfoldedHandResults.length == 1
      this.finishRound()
      true
    else
      false

  fundPlayer: (playerName, amount) ->
    player = this.getPlayerFromStore(playerName)
    player.points = parseInt(amount)

  ensurePlayerInStore: (playerName) ->
    player = this.getPlayerFromStore(playerName)
    unless player
      player = new Player(playerName, @playerStartingPoints)
      @playerStore.push(player)

    # always add player to pot - call is idempotent
    @pot.addPlayer(player)
    player

  getPlayerFromStore: (playerName) ->
    _.find(@playerStore, (p) -> (p.name == playerName))

  pushBoard: ->
    this.pushStatus(this.showBoard())

  storeHandResult: (handResult) ->
    @boardStore[handResult.playerName] = handResult

  startRound: ->
    super
    @boardStore = @store.boardStore = {}
    @holeDigits = [this.randomDigit(), this.randomDigit()]
    this.pushStatus("1 point ante.")

  setAlarms: ->
    @timeouts.push @round.setAlarm(@betDuration + @settleDuration, this, this.startBetting)
    @timeouts.push @round.setAlarm(@settleDuration, this, this.settleUp)
    @timeouts.push @round.setAlarm(0, this, this.finishRound)

  startBetting: ->
    @playState = new BetPlayState(this)
    this.pushBoard()

  finishRound: ->
    @round.end()
    this.applyHoleDigits()
    @winningHandResult = this.handsInWinningOrder()[0]
    @pot.settleUp()
    @pot.goesTo(@winningHandResult.player) if @winningHandResult
    # TODO: don't show instructions on win board
    this.pushStatus(this.showBoard())
    this.clearTimeouts()
    @playState = new HandsPlayState(this)

  clearTimeouts: ->
    clearTimeout timeout for timeout in @timeouts
    @timeouts = []

  settleUp: ->
    # TODO - if highest bets are even, if players have either bet or called, could finish
    # the game immediately at this stage.
    @playState = new SettlePlayState(this)

  applyHoleDigits: ->
    for playerName, handResult of @boardStore
      handPlusHoles = handResult.playerHand + @holeDigits.join('')
      handResult.hand = @matcher.matchHighest(handPlusHoles)
      this.storeHandResult(handResult)

  handsInWinningOrder: ->
    handResults = for playerName, handResult of @boardStore
      handResult
    handResults.sort (a, b) -> a.compare(b)

  showBoard: ->
    width = 56
    remaining = @playState.remainingMinutes()
    remainingText = if (remaining >= 1) then "#{remaining} min" else "soon"

    holeDigits = if @round.isOver() then @holeDigits.join(' ') else 'X X'
    title = "Reverse Hold 'em       Hole: #{holeDigits}"

    status = if @round.isOver()
      "Winner: #{@winningHandResult.playerName}".rjust(width - title.length)
    else
      action = @playState.nextStateLabel()
      "#{action} In: #{remainingText}".rjust(width - title.length)

    header = [
      "#{title}#{status}",
      @playState.boardInstructions().center(width),
      "POT / ALL".rjust(width),
      ''
    ]

    hands = (this.formatHandResult handResult, width for handResult in this.handsInWinningOrder())
    header.join('\n') + hands.join('\n')

  formatHandResult: (handResult, width) ->
    handDisplay = if handResult.folded then '* FOLDED *' else handResult.hand.name
    left = "#{handResult.playerName.substr(0, 20).ljust(20)} #{handResult.playerHand}  #{handDisplay}"
    right = "#{(handResult.player.totalBet + '').rjust(3)} / #{(handResult.player.points + '').rjust(3)}"
    right = right.rjust(width - left.length)
    "#{left}#{right}"

  getStatus: ->
    this.showBoard()


class HandResult
  constructor: (@player, @playerHand, @hand) ->
    @folded = false
    @playerName = @player.name
    @playerHand = @playerHand.replace(/\s+/g, '').replace(/\d\d\d/, "$& ")

  foldedAsSortInt: ->
    if @folded then 1 else 0

  playerHandSorted: ->
    ((TokenPoker.Hand.toDigitArray(@playerHand)).sort (a, b) -> b - a).join('')

  compare: (other) ->
    if @folded != other.folded
      this.foldedAsSortInt() - other.foldedAsSortInt()
    else if @hand.matchCount != other.hand.matchCount
      @hand.matchCount - other.hand.matchCount
    else
      other.playerHandSorted() - this.playerHandSorted()


class HandsPlayState
  constructor: (@game) ->
    @name = 'play'

  remainingMinutes: ->
    @game.round.minutesLeft() - @game.betDuration - @game.settleDuration

  nextStateLabel: ->
    'Bet'

  boardInstructions: ->
    ''

  vetAction: (action) ->
    throw "You can't bet now." if action == 'bet'


class BetPlayState
  constructor: (@game) ->
    @name = 'bet'
    @game.pushStatus ["Hands are locked. Time to bet. Type 'bet' and a number.",
                      "Type 'call' to match the highest bid so far.",
                      "Type 'fold' to fold and forfeit anything bet already."].join("\n")

  remainingMinutes: ->
    @game.round.minutesLeft() - @game.settleDuration

  nextStateLabel: ->
    'Settle'

  boardInstructions: ->
    'bet [xx] | call | fold'

  vetAction: (action, betAction) ->
    throw "Hands are locked" if action == 'play'


class SettlePlayState
  constructor: (@game) ->
    @name = 'settle'
    @game.pushStatus ["No new bets. Time to settle up. ",
                      "Type 'call' to match the highest bid and stay in.",
                      "Type 'fold' to fold and forfeit anything bet already.",
                      "* Doing nothing will automatically call *."].join("\n")

  remainingMinutes: ->
    @game.round.minutesLeft()

  nextStateLabel: ->
    'Flop'

  boardInstructions: ->
    'call | fold  ||  ** auto-call in effect **'

  vetAction: (action, betAction) ->
    throw "Hands are locked." if action == 'play'
    throw "No new bets." if betAction == 'bet'