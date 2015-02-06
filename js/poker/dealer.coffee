AiPlayer = require('./../token-poker/ai-player')
PileMeister = require('./../token-poker/pile-meister')
ReverseHoldEm = require('./../token-poker/reverse-hold-em')
Stockpile = require('./../token-poker/stockpile')
TexasHoldEm = require('./../card-poker/texas-hold-em')
_ = require('underscore')

module.exports = class Dealer
  constructor: (@store, @id, @gameClasses) ->
    @store ||= {}
    @store.tokenPoker ||= {}
    @dealerStore = @store.tokenPoker[@id] ||= {}
    @gameClasses ||= [TexasHoldEm, ReverseHoldEm, PileMeister, Stockpile]
    @currentGameClass = @gameClasses[0]
    @ais = []
    @listeners = []
    this.startNewGame()

  diagnostic: ->
    ["@gameClasses: #{(gameClass.name for gameClass in @gameClasses).join(',')}",
     "@id: #{@id}",
     "@ais: \n#{(ai.diagnostic() for ai in @ais).join("\n")}",
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
    @game.addListener(this)
    @game

  sendToGame: (playerName, args) ->
    @game.sendCommand(playerName, args)

  fundPlayer: (playerName, amount) ->
    @game.fundPlayer(playerName, amount) if @game.fundPlayer

  addAi: (playerName) ->
    ai = new AiPlayer(playerName, this)
    @ais.push ai
    ai

  killAi: (playerName) ->
    ai = _.find(@ais, (ai) -> (ai.name == playerName))
    if ai
      ai.die()
      @ais = _.without(@ais, ai)

  killAllAis: () ->
    ai.die() for ai in @ais
    @ais = []

  getStatus: ->
    @game.getStatus()

  onStatus: (status) ->
    l.onStatus(status) for l in @listeners

  canPushToPlayer: (playerName) ->
    l.canPushToPlayer(playerName) for l in @listeners

  onPushToPlayer: (playerName, msg) ->
    l.onPushToPlayer(playerName, msg) for l in @listeners

  onStartRound: ->
    l.onStartRound() for l in @listeners

  onFinishRound: ->
    l.onFinishRound() for l in @listeners

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
          @game.abortGame() if @game
          this.startNewGame()
          "New game of #{this.toListName(newGameClass)} started."
        else
          "We're already playing #{this.toListName(@currentGameClass)}"

  addListener: (listener) ->
    @listeners.push(listener)
