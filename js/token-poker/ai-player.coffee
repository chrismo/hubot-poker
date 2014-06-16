_ = require('underscore')

# This first shot has nothing to do with intelligence and
# everything to do with needing to simulate multiple
# players in the hubot Shell adapter for exploratory testing.
module.exports = class AiPlayer
  constructor: (@name, @dealer) ->
    @alive = true
    @limit = 20
    @actions = 0

  randomHand: ->
    hand = []
    _.times(6, (n) -> (hand.push(Math.floor(Math.random() * 10))))
    hand.join('')

  doSomething: (index) ->
    @actions += 1
    this.die() if @actions > @limit
    return if not @alive

    index = (Math.floor(Math.random() * this.gameCommands().length)) if index == undefined
    try
      # console.log("#{@name} calling function index #{index}")
      commandText = this.gameCommands()[index].ai()
      @dealer.onStatus("#{@name} #{commandText}")
      result = @dealer.sendToGame(@name, commandText)
      for result in _.flatten([result])
        if result
          @dealer.onStatus(if result.toStatus then result.toStatus() else result)
      result
    catch error
      @dealer.onStatus(error)
    finally
      seconds = (Math.random() * 5) + 59
      that = this
      callback = this.doSomething
      # TODO: fat arrow simplify this?
      setTimeout((-> (callback.call(that))), seconds * 1000)

  die: ->
    @alive = false

  gameCommands: ->
    @dealer.game.commands()

  randomInt: (maxExclusive) ->
    Math.floor(Math.random() * maxExclusive)