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
    @gameClasses ||= [ReverseHoldEm, PileMeister, Stockpile]
    @currentGameClass = @gameClasses[0]
    @ais = []
    this.startNewGame()

  diagnostic: ->
    ["@gameClasses: #{(gameClass.name for gameClass in @gameClasses).join(',')}",
     "@id: #{@id}",
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

  sendToGame: (playerName, args) ->
    @game.sendCommand(playerName, args)

  fundPlayer: (playerName, amount) ->
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
    @game.getStatus()

  onStatus: (status) ->
    @listener.onStatus(status) if @listener

  onFinishRound: ->
    @listener.onFinishRound() if @listener

  changeGame: (name, newGameName) ->
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

  setListener: (@listener) ->
