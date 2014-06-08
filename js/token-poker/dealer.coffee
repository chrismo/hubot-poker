AiPlayer = require('./ai-player')
PileMeister = require('./pile-meister')
ReverseHoldEm = require('./reverse-hold-em')
Stockpile = require('./stockpile')
_ = require('underscore')

module.exports = class Dealer
  constructor: (@store, @id, @gameClasses) ->
    @store ||= {}
    @store.tokenPoker ||= {}
    @dealerStore = @store.tokenPoker[@id] ||= {}
    @gameClasses ||= [PileMeister, ReverseHoldEm, Stockpile]
    @currentGameClass = @gameClasses[0]
    @playCache = []
    @ais = []

  diagnostic: ->
    ["@gameClasses: #{(gameClass.name for gameClass in @gameClasses).join(',')}",
     "@id: #{@id}",
     "@playCache: #{([play.player, play.playerHand] for play in @playCache).join(',')}",
     (if (@game && @game.diagnostic) then @game.diagnostic() else '')].join("\n")

  listGames: ->
    for gameClass in @gameClasses
      this.toListName(gameClass)

  toListName: (gameClass) ->
    gameClass.name.
    split(/(?=[A-Z])/).
    map((s) -> s.toLowerCase()).
    join(' ')

  help: ->
    @currentGameClass.help()

  startNewGame: ->
    gameName = @currentGameClass.name
    gameName = gameName[0] + gameName.substr(1)
    gameStore = (@dealerStore[gameName] ||= {})
    @game = new @currentGameClass(gameStore)
    @game.setListener(this)
    @game

  play: (playerName, playerHand) ->
    this.startNewGame() if not @game
    return unless @game.play
    if !@game.round.isStarted()
      @game.vetPlayerForPlaying(playerName) if @game.vetPlayerForPlaying
      @playCache.push {player: playerName, playerHand: playerHand}
      if this.playersInPlayCache() > 1
        results = []
        while @playCache.length > 0
          thisPlay = @playCache.shift()
          results.push @game.play(thisPlay.player, thisPlay.playerHand)
        results
      else
        "Need a second player to start the next round."
    else
      @game.play(playerName, playerHand)

  playersInPlayCache: ->
    players = (play.player for play in @playCache)
    _.uniq(players).length

  # TODO: need a dynamic way for a game to register its commands

  bet: (playerName, bet) ->
    this.startNewGame() if not @game
    @game.bet(playerName, bet) if @game.bet

  call: (playerName) ->
    this.startNewGame() if not @game
    @game.call(playerName) if @game.call

  fold: (playerName) ->
    this.startNewGame() if not @game
    @game.fold(playerName) if @game.fold

  deal: (playerName, args...) ->
    this.startNewGame() if not @game
    @game.deal(playerName, args) if @game.deal

  break: (playerName, args...) ->
    this.startNewGame() if not @game
    @game.break(playerName, args) if @game.break

  fundPlayer: (playerName, amount) ->
    this.startNewGame() if not @game
    @game.fundPlayer(playerName, amount) if @game.fundPlayer

  addAi: (playerName) ->
    ai = new AiPlayer(playerName, this)
    ai.doSomething(0)
    @ais.push ai

  killAi: (playerName) ->
    ai = _.find(@ais, (ai) -> (ai.name == playerName))
    if ai
      ai.die()
      @ais = _.without(@ais, ai)

  getStatus: ->
    this.startNewGame() if not @game
    @game.getStatus()

  onStatus: (status) ->
    @listener.onStatus(status) if @listener

  onFinishRound: ->
    @listener.onFinishRound() if @listener

  # TODO: allow anyone to change game if a current game is not active
  adminChangeGame: (name, newGameName) ->
    this.checkIsAdmin(name)
    re = new RegExp(newGameName, 'i')
    hits = (gameClass for gameClass in @gameClasses when gameClass.name.match(re))
    switch
      when hits.length == 0
        throw "Cannot find a game matching <#{newGameName}>"
      when hits.length > 1
        throw "Be more specific, more than one name matches <#{newGameName}>"
      else
        newGameClass = hits[0]
        if newGameClass != @currentGameClass
          @currentGameClass = newGameClass
          @game.finishRound() if @game
          this.startNewGame()
          "New game of #{this.toListName(newGameClass)} started."
        else
          "We're already playing #{this.toListName(@currentGameClass)}"


  # TODO: move admin functions up to hubot instead of coupled inside the game?
  checkIsAdmin: (name) ->
    admins = ['chrismo', 'Shell']
    unless _.contains(admins, name)
      throw "#{name} is not an Admin. Only admins can change the game."

  setListener: (@listener) ->
