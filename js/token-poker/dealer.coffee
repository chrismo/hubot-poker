Stockpile = require('./stockpile')
ReverseHoldEm = require('./reverse-hold-em')
_ = require('underscore')

module.exports = class Dealer
  constructor: (@store, @id, @gameClasses) ->
    @store ||= {}
    @store.tokenPoker ||= {}
    @dealerStore = @store.tokenPoker[@id] ||= {}
    @gameClasses ||= [ReverseHoldEm, Stockpile]
    @currentGameClass = @gameClasses[0]

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

  startNewGame: ->
    gameName = @currentGameClass.name
    gameName = gameName[0] + gameName.substr(1)
    gameStore = (@dealerStore[gameName] ||= {})
    @game = new @currentGameClass(gameStore)
    @game.setListener(this)
    @game

  play: (player, playerHand) ->
    this.startNewGame() if not @game
    @game.play(player, playerHand)

  bet: (player, bet) ->
    @game.bet(player, bet) if @game

  fundPlayer: (playerName, amount) ->
    @game.fundPlayer(playerName, amount) if @game and @game.fundPlayer

  getStatus: ->
    this.startNewGame() if not @game
    @game.getStatus()

  onStatus: (status) ->
    @listener.onStatus(status) if @listener

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
