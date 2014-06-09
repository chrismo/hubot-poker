_ = require('underscore')

# This first shot has nothing to do with intelligence and
# everything to do with needing to simulate multiple
# players in the hubot Shell adapter for exploratory testing.
module.exports = class AiPlayer
  constructor: (@name, @dealer) ->
    @functions = []
    @functions.push (-> (@dealer.play(@name, this.randomHand()))) if @dealer.game.play
    @functions.push (-> (@dealer.bet(@name, this.randomInt(20)))) if @dealer.game.bet
    @functions.push (-> (@dealer.fold(@name))) if @dealer.game.fold
    @functions.push (-> (@dealer.call(@name))) if @dealer.game.call
    @functions.push (-> (@dealer.deal(@name, ['chain', undefined][this.randomInt(2)]))) if @dealer.game.deal
    @functions.push (-> (@dealer.break(@name, this.randomInt(20)))) if @dealer.game.break

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
      # console.log("#{@name} calling function index #{index}")
      result = @functions[index].call(this)
      for result in _.flatten([result])
        if result
          @dealer.onStatus(if result.toStatus then result.toStatus() else result)
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

  randomInt: (maxExclusive) ->
    Math.floor(Math.random() * maxExclusive)