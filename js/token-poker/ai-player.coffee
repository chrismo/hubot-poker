_ = require('underscore')

# This first shot has nothing to do with intelligence and
# everything to do with needing to simulate multiple
# players in the hubot Shell adapter for exploratory testing.
module.exports = class AiPlayer
  constructor: (@name, @dealer) ->
    @alive = true
    @limit = 20
    @actions = 0
    @nextQueuedMsecs = null

  diagnostic: () ->
    "- #{@name}: @alive <#{@alive}>, @limit <#{@limit}>, @actions <#{@actions}>, @nextQueuedMsecs <#{@nextQueuedMsecs}>"

  randomHand: ->
    hand = []
    _.times(6, (n) -> (hand.push(Math.floor(Math.random() * 10))))
    hand.join('')

  doSomething: (index) ->
    return if this.gameCommands().length == 0
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
      seconds = (Math.random() * 30) + 30
      this.queueSomething(seconds)

  queueSomething: (seconds) ->
    @nextQueuedMsecs = seconds * 1000
    that = this
    callback = this.doSomething
    # TODO: fat arrow simplify this?
    setTimeout((-> (callback.call(that))), @nextQueuedMsecs)

  die: ->
    @alive = false

  gameCommands: ->
    @dealer.game.commands()

  randomInt: (maxExclusive) ->
    Math.floor(Math.random() * maxExclusive)
