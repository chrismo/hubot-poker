_ = require('underscore')

# This first shot has nothing to do with intelligence and
# everything to do with needing to simulate multiple
# players in the hubot Shell adapter for exploratory testing.
module.exports = class AiPlayer
  constructor: (@name, @game) ->
    @functions = []
    @functions.push (-> (@game.play(@name, this.randomHand()))) if @game.play
    @functions.push (-> (@game.bet(@name, (Math.floor(Math.random() * 5))))) if @game.bet
    @functions.push (-> (@game.fold(@name))) if @game.fold
    @functions.push (-> (@game.call(@name))) if @game.call

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

    index = (Math.floor(Math.random() * @functions.length)) if index == undefined
    try
      @functions[index].call(this)
    catch error
      @game.pushStatus(error)
    finally
      seconds = (Math.random() * 15) + 15
      that = this
      callback = this.doSomething
      setTimeout((-> (callback.call(that))), seconds * 1000)

  die: ->
    @alive = false
