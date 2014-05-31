TokenPoker = require('./core')
BaseGame = require ('./base-game')
Rounds = require('./round')
Player = require('./player')
Pot = require('./pot')
_ = require('underscore')

module.exports = class ReverseHoldEm extends BaseGame
  constructor: (@store, @round) ->
    super(@store, @round)
    @playerStore = @store.playerStore ||= []
    @round ||= new Rounds.TimedRound(2)
    @playState = 'play'
    @pot = new Pot(1)

  diagnostic: ->
    "\nReverseHoldEm\n\n" +
    "@playState: #{@playState}\n" +
    "@playerStore: #{([player.name, player.points] for player in @playerStore).join(',')}\n" +
    (if @round.diagnostic then @round.diagnostic() else '') +
    (if @pot.diagnostic then @pot.diagnostic() else '')

  play: (playerName, playerHand) ->
    throw "Hands are locked. Time to bet." unless @playState == 'play'
    this.ensureRoundStarted()
    player = this.ensurePlayerInStore(playerName)
    this.storeHandResult(new HandResult(player, playerHand, @matcher.matchHighest(playerHand)))
    this.pushBoard()
    null # to indicate no reply is necessary, the board will be pushed

  bet: (playerName, bet) ->
    throw "No bets yet." unless @playState == 'bet'
    player = this.getPlayerFromStore(playerName)
    throw "Can't bet if you haven't played." unless player && @boardStore[playerName]
    if bet == 'fold' then @pot.fold(player) else @pot.bet(player, bet)
    this.pushBoard()
    null

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

  # TODO: possibly could push just time remaining instead of the whole board.
  # Would be good to investigate underscore functions like throttle.
  setAlarms: ->
    @round.setAlarm(1, this, this.startBetting)
    @round.setAlarm(0, this, this.finishRound)

  startBetting: ->
    @playState = 'bet'
    this.pushStatus("Hands are locked. Time to bet. Type 'bet' and a number.")

  finishRound: ->
    @round.end()
    this.applyHoleDigits()
    @winningHandResult = this.handsInWinningOrder()[0]
    @pot.settleUp()
    @pot.goesTo(@winningHandResult.player) if @winningHandResult
    this.pushStatus(this.showBoard())
    @playState = 'play'

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
    # TODO: push up hole on the same line. have width to spare.
    width = 56
    title = "Reverse Hold 'em"
    remaining = @round.minutesLeft()
    remainingText = switch
      when (remaining >= 1) then "#{remaining} min"
      else
        "..."
    status = if @round.isOver()
      "Winner: #{@winningHandResult.playerName}".rjust(width - title.length)
    else
      action = if @playState == 'play' then 'Bet' else 'Flop'
      # TODO: Time to bet shows total time, not total minus 1
      "Time to #{action}: #{remainingText}".rjust(width - title.length)
    holeDigits = if @round.isOver() then @holeDigits.join(' ') else 'X X'
    header = [
      "#{title}#{status}",
      "Hole: #{holeDigits}".center(width),
      '', '']
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