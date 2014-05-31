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
    @betDuration = 1 # minute

  diagnostic: ->
    "\nReverseHoldEm\n\n" +
    "@playState: #{@playState.name}\n" +
    "@playerStore: #{([player.name, player.points] for player in @playerStore).join(',')}\n" +
    (if @round.diagnostic then @round.diagnostic() else '') +
    (if @pot.diagnostic then @pot.diagnostic() else '')

  play: (playerName, playerHand) ->
    throw "Hands are locked. Time to bet." unless @playState.name == 'play'
    this.ensureRoundStarted()
    player = this.ensurePlayerInStore(playerName)
    this.storeHandResult(new HandResult(player, playerHand, @matcher.matchHighest(playerHand)))
    this.pushBoard()
    null # to indicate no reply is necessary, the board will be pushed

  bet: (playerName, bet) ->
    @pot.bet(this.vetPlayerForBetting(playerName), bet)
    this.pushBoard()
    null

  fold: (playerName) ->
    @pot.fold(this.vetPlayerForBetting(playerName))
    this.pushBoard()
    null

  call: (playerName) ->
    @pot.call(this.vetPlayerForBetting(playerName))
    this.pushBoard()
    null

  vetPlayerForBetting: (playerName) ->
    throw "No bets yet." unless @playState.name == 'bet'
    player = this.getPlayerFromStore(playerName)
    throw "Can't bet if you haven't played." unless player && @boardStore[playerName]
    return player

  fundPlayer: (playerName, amount) ->
    player = this.getPlayerFromStore(playerName)
    player.points = parseInt(amount)

  ensurePlayerInStore: (playerName) ->
    player = this.getPlayerFromStore(playerName)
    unless player
      player = new Player(playerName, 25)
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

  # TODO: don't start until 2 players have played. needs 'paused' state in round.
  # Note - be best to overhaul Round class with a good state machine implementation,
  # as adding 'paused' would be a 4th state, and it's already a mess.
  startRound: ->
    super
    @boardStore = @store.boardStore = {}
    @holeDigits = [this.randomDigit(), this.randomDigit()]
    this.pushStatus("1 point ante.")

  # TODO: possibly could push just time remaining instead of the whole board.
  # Would be good to investigate underscore functions like throttle.
  setAlarms: ->
    @round.setAlarm(1, this, this.startBetting)
    @round.setAlarm(0, this, this.finishRound)

  startBetting: ->
    @playState = new BetPlayState(this)
    this.pushStatus("Hands are locked. Time to bet. Type 'bet' and a number.")
    this.pushStatus("Type 'call' to stay in by matching highest bet.")
    this.pushStatus("Type 'fold' to fold and forfeit anything bet already.")
    this.pushStatus("* Doing nothing will auto-call and match highest bet! *")

  finishRound: ->
    @round.end()
    this.applyHoleDigits()
    @winningHandResult = this.handsInWinningOrder()[0]
    @pot.settleUp()
    @pot.goesTo(@winningHandResult.player) if @winningHandResult
    this.pushStatus(this.showBoard())
    @playState = new HandsPlayState(this)

  applyHoleDigits: ->
    for playerName, handResult of @boardStore
      handPlusHoles = handResult.playerHand + @holeDigits.join('')
      handResult.hand = @matcher.matchHighest(handPlusHoles)
      this.storeHandResult(handResult)

  handsInWinningOrder: ->
    handResults = for playerName, handResult of @boardStore
      handResult
    handResults.sort (a, b) ->
      a.hand.matchCount - b.hand.matchCount

  showBoard: ->
    # TODO: trim player name
    width = 56
    remaining = @playState.remainingMinutes()
    remainingText = if (remaining >= 1) then "#{remaining} min" else "soon"

    holeDigits = if @round.isOver() then @holeDigits.join(' ') else 'X X'
    title = "Reverse Hold 'em       Hole: #{holeDigits}"

    status = if @round.isOver()
      "Winner: #{@winningHandResult.playerName}".rjust(width - title.length)
    else
      action = @playState.nextStateLabel()
      "Time to #{action}: #{remainingText}".rjust(width - title.length)

    header = [
      "#{title}#{status}",
      @playState.boardInstructions().center(width),
      "                                                 POT/ALL",
      ''
    ]

    hands = (this.formatHandResult handResult, width for handResult in this.handsInWinningOrder())
    header.join('\n') + hands.join('\n')

  formatHandResult: (handResult, width) ->
    left = "#{handResult.playerName.ljust(20)} #{handResult.playerHand}  #{handResult.hand.name}"
    right = "#{handResult.player.totalBet} / #{handResult.player.points}"
    right = right.rjust(width - left.length)
    "#{left}#{right}"

  getStatus: ->
    this.showBoard()

class HandResult
  constructor: (@player, @playerHand, @hand) ->
    @playerName = @player.name
    @playerHand = @playerHand.replace(/\s+/g, '').replace(/\d\d\d/, "$& ")

class HandsPlayState
  constructor: (@game) ->
    @name = 'play'

  remainingMinutes: ->
    @game.round.minutesLeft() - @game.betDuration

  nextStateLabel: ->
    'Bet'

  boardInstructions: ->
    ''

class BetPlayState
  constructor: (@game) ->
    @name = 'bet'

  remainingMinutes: ->
    @game.round.minutesLeft()

  nextStateLabel: ->
    'Flop'

  boardInstructions: ->
    'bet [xx] | call | fold  ||  ** auto-call in effect **'
