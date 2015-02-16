Core = require('./core')
Hand = require('./hand')
_ = require('underscore')

module.exports = class AiBetBrain
  constructor: (@playerHand, @communityCards, @pot) ->
    @fixedBetAmount = null
    @matcher = new Hand.HandMatcher()

  action: ->
    this.createAnalysis()
    switch
      when this.shouldFold() then 'fold'
      else
        "bet #{this.betAmount()}"

  createAnalysis: ->
    matches = @matcher.matchAll(@playerHand)
    @analysis = new HandAnalysis(matches)

  betAmount: ->
    return @fixedBetAmount if @fixedBetAmount?

  shouldFold: ->
    switch
      when this.possibleGroupHand() then false
      when this.possibleStraight() then false
      when this.possibleFlush() then false
      else
        true

  possibleGroupHand: ->
    @analysis.anyGrouped()

  possibleStraight: ->
    @analysis.anyStraight()

  possibleFlush: ->
    @analysis.anyFlush()

class HandAnalysis
  constructor: (@matches) ->

  anyGrouped: ->
    _.any(@matches,
      (m) -> m.hand instanceof Hand.GroupedHand && m.hand.name != 'High Card')

  anyStraight: ->
    _.any(@matches, (m) -> m.hand instanceof Hand.StraightHand)

  anyFlush: ->
    _.any(@matches, (m) -> m.hand instanceof Hand.FlushHand)
