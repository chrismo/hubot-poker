CardPoker = require('./core')
_ = require('underscore')


module.exports.PlayerHand = class PlayerHand
  constructor: (@cards) ->


module.exports.Hand = class Hand
  constructor: ->


module.exports.GroupedHand = class GroupedHand extends Hand
  constructor: (@name, @groupingFingerprint) ->

  matches: (playerHand) ->
    GroupedHand.groupings(playerHand.cards) == @groupingFingerprint

  @groupings: (cards) ->
    groups = cards.reduce((prev, card) ->
      _ranks = Object.keys(prev).map (c) -> parseInt(c)
      if (card.rank.value in _ranks)
        prev[card.rank.value]++
      else
        prev[card.rank.value] = 1
      prev
    , {})

    counts = for digit, count of groups
      count
    counts = counts.sort (a, b) -> b - a
    counts = _.select(counts, (c) -> c > 1)
    counts.join('')


module.exports.StraightHand = class StraightHand extends Hand
  constructor: (@name, count=5) ->
    @count = count - 1

  matches: (playerHand) ->
    StraightHand.countOfOneIntervals(playerHand.cards) == @count

  @countOfOneIntervals: (cards) ->
    ranks = cards.map (c) -> c.rank.value
    sorted = ranks.sort (a, b) -> a - b
    uniq = _.uniq(sorted)
    intervals = uniq.map (d, index) -> uniq[index + 1] - uniq[index]
    x = intervals.join('').match(/1+/)
    if x then x[0].length else 0



module.exports.HandRegistry = class HandRegistry
  constructor: (@hands) ->


