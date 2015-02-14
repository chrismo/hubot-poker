_ = require('underscore')
Game = require ('./base-game')
GameCommand = require('../poker/game-command')
Player = require('../poker/player')
Pot = require('../poker/pot')
Rounds = require('../poker/round')
CardPoker = require('./core')
Hand = require('./hand')

# TODO: split pot (if multiple players best hand are the community cards)
module.exports = class TexasHoldEm extends Game.BaseGame
  @help: ->
    [
      "Texas Hold 'em",
      '',
      'deal       - Have hubot deal you a hand',
      "bet [xx]   - When it's time to bet, optionally bet a number of points.",
      "call       - When it's time to bet or settle up, match your bet to the highest bet.",
      "fold       - When it's time to bet or settle up, fold your hand."
      '',
      "Game goes in 3 phases: play phase where anyone can are dealt your 2 card hand,",
      "bet phase when you can bet, call or fold, and settle phase where only call or",
      "fold are allowed. Community cards are shown at the beginning of the round (all at"
      "once for now). The best hand out of each player's cards",
      "plus the community cards will be assigned to each player and the best",
      "hand wins. If you do not fold, you will automatically call the highest bet."
    ].join("\n")

  constructor: (@store, @time) ->
    super(@store, @time)
    @playerStore = @store.playerStore ||= []
    @time ||= new Rounds.TimeProvider
    this.setNewPlayState(new HandsPlayState(this, this.startBetting))
    @pot = new Pot(1)
    @communityDurations = 0.333
    @settleDuration = 0.5
    @endDuration = 0.1
    @playerStartingPoints = 100
    @dealCommand = new GameCommand(/^deal$/i, this.deal, => ("deal"))
    # TODO: random provider removed - AI still tries to use it here, though
    @betCommand = new GameCommand(/^bet (\d+)$/i, this.bet, => ("bet #{this.randomProvider.randomInt(20)}"))
    @foldCommand = new GameCommand(/^fold$/i, this.fold, => ("fold"))
    @callCommand = new GameCommand(/^call$/i, this.call, => ("call"))

  diagnostic: ->
    "\nTexasHoldEm\n\n" +
        "@playState: #{@playState.name}\n" +
        "@playerStore: #{([player.name, player.points] for player in @playerStore).join(',')}\n" +
        (if @playState.diagnostic then @playState.diagnostic() else '') +
        (if @pot.diagnostic then @pot.diagnostic() else '')

  commands: ->
    @playState.commands()

  deal: (playerName) ->
    this.vetPlayerForPlaying(playerName)
    player = this.ensurePlayerInStore(playerName)
    playerHand = @deck.deal(2)
    this.storeHandResult(new HandResult(player, playerHand, null))
    this.pushToPlayer(playerName, playerHand.display())
    this.pushBoard()
    null # to indicate no reply is necessary, the board will be pushed

  bet: (playerName, bet) ->
    @pot.bet(this.vetPlayerForBetting(playerName, 'bet'), bet)
    this.pushBoard() unless this.allBetsSettled()
    null

  fold: (playerName) ->
    player = this.vetPlayerForBetting(playerName, 'fold')
    @pot.fold(player)
    @boardStore[player.name].folded = true
    this.pushBoard() unless this.checkForLoneWinner() || this.allBetsSettled()
    null

  call: (playerName) ->
    @pot.call(this.vetPlayerForBetting(playerName, 'call'))
    this.pushBoard() unless this.allBetsSettled()
    null

  vetPlayerForPlaying: (playerName) ->
    # TODO: allow folding at anytime, but have to workaround checkForLoneWinner and call it again at the start of betting.
    @playState.vetAction('play')
    player = this.getPlayerFromStore(playerName)
    throw "Send the bot a DM in order to have a hand dealt to you." unless this.canPushToPlayer(playerName)
    throw "No dough, no show." if player && player.points == 0
    throw "You already have a hand, #{playerName}" if this.isPlayerOnBoard(playerName)
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

  allBetsSettled: ->
    this.finishRound() if @playState.name == 'settle' && @pot.allBetsSettled()

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

  isPlayerOnBoard: (playerName) ->
    @boardStore && @boardStore[playerName] != undefined

  pushBoard: ->
    this.pushStatus(this.showBoard())

  storeHandResult: (handResult) ->
    @boardStore[handResult.playerName] = handResult

  isStarted: ->
    @playState.isStarted()

  isOver: ->
    @playState.isOver()

  startNewRound: ->
    this.setNewPlayState(new HandsPlayState(this, this.startBetting))

  startRound: ->
    super
    @boardStore = @store.boardStore = {}
    this.newDeck()
    @holeCards = @deck.deal(5)
    @hiddenHoleCards = 5
    @winningHandResult = null
    this.pushStatus("1 point ante.")

  newDeck: ->
    @deck = new CardPoker.Deck()
    @deck.shuffle()

  startBetting: ->
    this.setNewPlayState(new BetPlayState(this, this.settleUp))
    this.pushBoard()

  finishRound: ->
    super
    this.applyCommunityCards()
    @winningHandResult = this.handsInWinningOrder()[0]
    @pot.settleUp()
    @pot.goesTo(@winningHandResult.player) if @winningHandResult
    this.setNewPlayState(new GameOverState(this, this.startNewRound))
    this.pushStatus(this.showBoard())

  settleUp: ->
    # TODO - if highest bets are even, if players have either bet or called, could finish
    # the game immediately at this stage.
    this.setNewPlayState(new SettlePlayState(this, this.finishRound))

  applyCommunityCards: ->
    for playerName, handResult of @boardStore
      handPlusHoles = handResult.playerHand.cards.concat(@holeCards.cards)
      matchedHand = @matcher.matchHighest(new Hand.PlayerHand(handPlusHoles))
      handResult.matchedHand = matchedHand
      this.storeHandResult(handResult)

  handsInWinningOrder: ->
    handResults = for playerName, handResult of @boardStore
      handResult
    handResults.sort (a, b) -> a.compare(b)

  showBoard: ->
    communityCards = this.formatHoleCards()

    status = if @winningHandResult?
      "Winner: #{@winningHandResult.playerName}"
    else
      @playState.status()
    title = "Texas Hold 'em: #{status}"

    boardInstructions = if this.isOver() then '' else @playState.boardInstructions()

    header = [title]
    header.push(boardInstructions) if boardInstructions.length > 1
    header.push(communityCards)

    hands = (this.formatHandResult handResult for handResult in this.handsInWinningOrder())
    header.concat(hands)

  formatHoleCards: ->
    show = (@holeCards.cards[i].display() for i in [0..(4-@hiddenHoleCards)] by 1)
    hide = ('[X]' for i in [1..@hiddenHoleCards] by 1)
    "#{show.join(' ')}#{hide.join('')}"

  revealMoreHoleCards: ->
    if @hiddenHoleCards == 5
      @hiddenHoleCards = 2
    else if @hiddenHoleCards == 2
      @hiddenHoleCards = 1
    else
      @hiddenHoleCards = 0

  formatHandResult: (handResult) ->
    if this.isOver()
      handNameDisplay = if handResult.folded then '* FOLDED *' else "*#{handResult.matchedHand.hand.name}*"
      handDisplay = "#{handResult.playerHand.display()} — Best Hand: #{handResult.matchedHand.playerHand.display()}  —"
    else
      handNameDisplay = if handResult.folded then '* FOLDED *' else ''
      handDisplay = '[X][X]'

    points = "#{handResult.player.totalBet} / #{handResult.player.points}"
    "#{handDisplay} #{handNameDisplay}  #{points}  *#{handResult.playerName}*"

  getStatus: ->
    this.showBoard()

  setNewPlayState: (newState) ->
    @playState.cleanUp() if @playState
    @playState = newState


class HandResult
  constructor: (@player, @playerHand) ->
    @folded = false
    @playerName = @player.name

  foldedAsSortInt: ->
    if @folded then 1 else 0

  compare: (other) ->
    if @folded != other.folded
      this.foldedAsSortInt() - other.foldedAsSortInt()
    else if @matchedHand && other.matchedHand
      @matchedHand.compare(other.matchedHand)
    else # still in play - could sort by player name? or amount bet?
      0


class PlayState
  constructor: (@game, nextState) ->
    this.onNextState = nextState

  nextRound: ->
    this.cleanUp()
    @round = @rounds.shift()
    if @round == undefined
      this.onNextState.call(@game)
    else
      @round.start()
      @round.addListener(this)
      @game.addListener(@round)

  onRoundStateChange: (state) ->
    this.nextRound() if @round.isOver()

  isStarted: ->
    @round.isStarted()

  isOver: ->
    @round.isOver()

  cleanUp: ->
    @round.cleanUp() if @round


class HandsPlayState extends PlayState
  constructor: (@game, nextState) ->
    super(@game, nextState)
    @name = 'play'
    @rounds = [new Rounds.WaitForPlayersRound, new Rounds.TimedRound(1, @game.time)]
    this.nextRound()

  status: ->
    'Play'

  boardInstructions: ->
    'deal | bet [xx] | call | fold'

  vetAction: (action) ->


  commands: ->
    [@game.dealCommand, @game.betCommand, @game.foldCommand, @game.callCommand]


class BetPlayState extends PlayState
  constructor: (@game, nextState) ->
    super(@game, nextState)
    @name = 'bet'
    @game.pushStatus ["No new players. Flop, turn and river 20 seconds apart.",
                      "`bet [xx]`, `call` or `fold` at any time. *Doing nothing will automatically call*"].join("\n")
    @rounds = [
      new Rounds.TimedRound(@game.communityDurations, @game.time),
      new Rounds.TimedRound(@game.communityDurations, @game.time),
      new Rounds.TimedRound(@game.communityDurations, @game.time),
    ]
    this.nextRound()

  nextRound: ->
    super
    @game.pot.settleUp()
    @game.revealMoreHoleCards()

    # this conditional is really important and hard to explain.
    # the FIRST time through, this code is executed as part of
    # a timeout callback ending the HandsPlayState and creating
    # the BetPlayState. @game.playState is still HandsPlayState
    # which has an undefined @round instance. Requesting a board
    # push then FAILS because @game.isOver() breaks due to the
    # HandsPlayState.round being undefined. In that case we
    # don't need to push the board because startBetting will
    # handle it.
    #
    # Subsequent times through this code, nothing is happening
    # within the game instance, so we need to ensure the board
    # is pushed, showing the newly revealed community cards.
    @game.pushBoard() if @rounds.length < 2

  status: ->
    'Bet'

  boardInstructions: ->
    'bet [xx] | call | fold ||  *auto-call in effect every 20 seconds*'

  vetAction: (action, betAction) ->
    throw "Hands are locked." if action == 'play'

  commands: ->
    [@game.betCommand, @game.foldCommand, @game.callCommand]


class SettlePlayState extends PlayState
  constructor: (@game, nextState) ->
    super(@game, nextState)
    @name = 'settle'
    @game.pushStatus ["No new bets. Time to settle up. ",
                      "`call` or `fold`. *Doing nothing will automatically call*"].join("\n")
    @rounds = [new Rounds.TimedRound(@game.settleDuration, @game.time)]
    this.nextRound()

  status: ->
    'Settle'

  boardInstructions: ->
    'call | fold  ||  *auto-call in effect*'

  vetAction: (action, betAction) ->
    throw "Hands are locked." if action == 'play'
    throw "No new bets." if betAction == 'bet'

  commands: ->
    [@game.foldCommand, @game.callCommand]


class GameOverState extends PlayState
  constructor: (@game, nextState) ->
    super(@game, nextState)
    @name = 'end'
    @rounds = [new Rounds.TimedRound(@game.endDuration, @game.time)]
    this.nextRound()

  isStarted: ->
    false

  isOver: ->
    true

  status: ->
    ''

  boardInstructions: ->
    ''

  vetAction: (action, betAction) ->
    throw "Patience. A new game will start momentarily."

  commands: ->
    []
