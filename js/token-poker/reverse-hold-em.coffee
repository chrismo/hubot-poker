_ = require('underscore')
Game = require ('./base-game')
GameCommand = require('../poker/game-command')
Player = require('../poker/player')
Pot = require('../poker/pot')
Rounds = require('../poker/round')
TokenPoker = require('./core')

# TODO support separate Board and Score commands, so the board could be shown, but also overall players point list
module.exports = class ReverseHoldEm extends Game.BaseGame
  @help: ->
    [
      "Reverse Hold 'em",
      '',
      '<6 digits> - Enter a 6 digit token',
      'deal       - Have hubot deal you a random hand',
      "bet [xx]   - When it's time to bet, optionally bet a number of points.",
      "call       - When it's time to bet or settle up, match your bet to the highest bet.",
      "fold       - When it's time to bet or settle up, fold your hand."
      '',
      "Game goes in 3 phases: play phase where anyone can enter their 6 digit token,",
      "bet phase when you can bet, call or fold, and settle phase where only call or",
      "fold are allowed. Two community hole cards (random digits) are held until the"
      "very end of the hand. When revealed, the best hand out of each player's 6",
      "digits plus the 2 community digits will be assigned to each player and the best",
      "hand wins. If you do not fold, you will automatically call the highest bet."
    ].join("\n")

  constructor: (@store, @time) ->
    super(@store, @time)
    @playerStore = @store.playerStore ||= []
    @time ||= new Rounds.TimeProvider
    this.setNewPlayState(new HandsPlayState(this, this.startBetting))
    @pot = new Pot(1)
    @betDuration = 0.5
    @settleDuration = 0.5
    @endDuration = 0.1
    @playerStartingPoints = 100
    @playCommand = new GameCommand(/^((\d{6})|(\d{3} \d{3}))$/i, this.play, => (this.randomHand()))
    @dealCommand = new GameCommand(/^deal$/i, this.deal, => ("deal"))
    @betCommand = new GameCommand(/^bet (\d+)$/i, this.bet, => ("bet #{this.randomProvider.randomInt(20)}"))
    @foldCommand = new GameCommand(/^fold$/i, this.fold, => ("fold"))
    @callCommand = new GameCommand(/^call$/i, this.call, => ("call"))

  diagnostic: ->
    "\nReverseHoldEm\n\n" +
    "@playState: #{@playState.name}\n" +
    "@playerStore: #{([player.name, player.points] for player in @playerStore).join(',')}\n" +
    (if @playState.diagnostic then @playState.diagnostic() else '') +
    (if @pot.diagnostic then @pot.diagnostic() else '')

  commands: ->
    @playState.commands()

  deal: (playerName) ->
    this.play(playerName, this.randomHand())

  play: (playerName, playerHand) ->
    this.vetPlayerForPlaying(playerName)
    player = this.ensurePlayerInStore(playerName)
    this.storeHandResult(new HandResult(player, playerHand, @matcher.matchHighest(playerHand)))
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
    this.finishRound() if @pot.allBetsSettled()

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
    @holeDigits = [this.randomDigit(), this.randomDigit()]
    this.pushStatus("1 point ante.")

  startBetting: ->
    this.setNewPlayState(new BetPlayState(this, this.settleUp))
    this.pushBoard()

  finishRound: ->
    this.applyHoleDigits()
    @winningHandResult = this.handsInWinningOrder()[0]
    @pot.settleUp()
    @pot.goesTo(@winningHandResult.player) if @winningHandResult
    this.setNewPlayState(new GameOverState(this, this.startNewRound))
    this.pushStatus(this.showBoard())

  abortGame: ->
    @playState.cleanUp()

  settleUp: ->
    # TODO - if highest bets are even, if players have either bet or called, could finish
    # the game immediately at this stage.
    this.setNewPlayState(new SettlePlayState(this, this.finishRound))

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

    holeDigits = if this.isOver() then @holeDigits.join(' ') else 'X X'
    title = "Reverse Hold 'em       Hole: #{holeDigits}"

    status = if this.isOver()
      "Winner: #{@winningHandResult.playerName}".rjust(width - title.length)
    else
      @playState.status().rjust(width - title.length)

    boardInstructions = if this.isOver() then '' else @playState.boardInstructions()

    header = [
      "#{title}#{status}",
      boardInstructions.center(width),
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

  setNewPlayState: (newState) ->
    @playState.cleanUp() if @playState
    @playState = newState


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
    ''

  vetAction: (action) ->
    throw "You can't bet now." if action == 'bet'

  commands: ->
    [ @game.playCommand, @game.dealCommand ]


class BetPlayState extends PlayState
  constructor: (@game, nextState) ->
    super(@game, nextState)
    @name = 'bet'
    @game.pushStatus ["Hands are locked. Time to bet. Type 'bet' and a number.",
                      "Type 'call' to match the highest bid so far.",
                      "Type 'fold' to fold and forfeit anything bet already."].join("\n")
    @rounds = [new Rounds.TimedRound(@game.betDuration, @game.time)]
    this.nextRound()

  status: ->
    'Bet'

  boardInstructions: ->
    'bet [xx] | call | fold'

  vetAction: (action, betAction) ->
    throw "Hands are locked" if action == 'play'

  commands: ->
    [ @game.betCommand, @game.foldCommand, @game.callCommand  ]


class SettlePlayState extends PlayState
  constructor: (@game, nextState) ->
    super(@game, nextState)
    @name = 'settle'
    @game.pushStatus ["No new bets. Time to settle up. ",
                      "Type 'call' to match the highest bid and stay in.",
                      "Type 'fold' to fold and forfeit anything bet already.",
                      "* Doing nothing will automatically call *"].join("\n")
    @rounds = [new Rounds.TimedRound(@game.settleDuration, @game.time)]
    this.nextRound()

  status: ->
    'Settle'

  boardInstructions: ->
    'call | fold  ||  ** auto-call in effect **'

  vetAction: (action, betAction) ->
    throw "Hands are locked." if action == 'play'
    throw "No new bets." if betAction == 'bet'

  commands: ->
    [ @game.foldCommand, @game.callCommand  ]


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
