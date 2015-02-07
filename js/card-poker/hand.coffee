CardPoker = require('./core')
_ = require('underscore')


module.exports.PlayerHand = class PlayerHand
  constructor: (@cards) ->

  display: ->
    (c.display() for c in @cards).join(' ')

  codes: ->
    "[#{(c.code() for c in @cards).join(',')}]"

  sort: ->
    @cards = @cards.sort((a, b) -> a.compare(b))
    this


module.exports.Hand = class Hand
  constructor: ->

  sortCards: (playerHand) ->
    playerHand.sort()

  compare: (aPlayerHand, bPlayerHand) ->
    aMatches = this.matches(aPlayerHand)
    bMatches = this.matches(bPlayerHand)
    throw "player hands do not match hand" unless aMatches && bMatches

    this.sortCards(aPlayerHand)
    this.sortCards(bPlayerHand)

    zipped = _.zip(aPlayerHand.cards, bPlayerHand.cards)
    for pair in zipped
      aRank = pair[0].rank.value
      bRank = pair[1].rank.value
      return bRank - aRank unless aRank == bRank
    return 0


module.exports.GroupedHand = class GroupedHand extends Hand
  constructor: (@name, @groupingFingerprint, @rank) ->

  matches: (playerHand) ->
    this.matchesCards(playerHand.cards)

  matchesCards: (cards) ->
    GroupedHand.groupings(cards) == @groupingFingerprint

  @groups: (cards) ->
    cards.reduce((prev, card) ->
      _ranks = Object.keys(prev).map (c) -> parseInt(c)
      if (card.rank.value in _ranks)
        prev[card.rank.value]++
      else
        prev[card.rank.value] = 1
      prev
    , {})

  @groupings: (cards) ->
    groups = GroupedHand.groups(cards)

    counts = for digit, count of groups
      count
    counts = counts.sort (a, b) -> b - a
    counts = _.select(counts, (c) -> c > 1)
    counts.join('')

  @sortCards: (hand) ->
    groups = GroupedHand.groups(hand.cards)
    hand.cards = hand.cards.sort((a, b) ->
      weightedByGroupDiff = groups[b.rank.value] - groups[a.rank.value]
      if weightedByGroupDiff == 0
        a.compare(b)
      else
        weightedByGroupDiff
    )

  sortCards: (hand) ->
    GroupedHand.sortCards(hand)



module.exports.StraightHand = class StraightHand extends Hand
  constructor: (@name, count = 5, @rank) ->
    @count = count - 1

  matches: (playerHand) ->
    this.matchesCards(playerHand.cards)

  matchesCards: (cards) ->
    StraightHand.countOfOneIntervals(cards) == @count

  @countOfOneIntervals: (cards) ->
    ranks = cards.map (c) -> c.rank.value
    sorted = ranks.sort (a, b) -> a - b
    uniq = _.uniq(sorted)
    intervals = uniq.map (d, index) -> uniq[index + 1] - uniq[index]
    x = intervals.join('').match(/1+/)
    if x then x[0].length else 0


module.exports.FlushHand = class FlushHand extends Hand
  constructor: (@name, @rank) ->

  matches: (playerHand) ->
    this.matchesCards(playerHand.cards)

  matchesCards: (cards) ->
    suits = _.map(cards, (c) -> c.suit.value)
    uniq = _.uniq(suits)
    uniq.length == 1


module.exports.StraightFlushHand = class StraightFlushHand extends Hand
  constructor: (@name, count = 5, @rank) ->
    @sh = new StraightHand('', count)
    @fh = new FlushHand()

  matches: (playerHand) ->
    this.matchesCards(playerHand.cards)

  matchesCards: (cards) ->
    @sh.matchesCards(cards) && @fh.matchesCards(cards)


module.exports.HandRegistry = class HandRegistry
  constructor: ->
    @hands = [
      new StraightFlushHand('Straight Flush', 5, 1),
      new GroupedHand('Four of a Kind', '4', 2),
      new GroupedHand('Full House', '32', 3),
      new FlushHand('Flush', 4),
      new StraightHand('Straight', 5, 5),
      new GroupedHand('Three of a Kind', '3', 6),
      new GroupedHand('Two Pair', '22', 7),
      new GroupedHand('One Pair', '2', 8),
      new GroupedHand('High Card', '', 9),
    ]


module.exports.MatchedHand = class MatchedHand
  constructor: (@hand, @playerHand) ->
    throw "playerHand does not match hand" unless @hand.matches(@playerHand)
    @hand.sortCards(@playerHand)

  compare: (other) ->
    handDiff = @hand.rank - other.hand.rank
    if handDiff == 0 then @hand.compare(@playerHand, other.playerHand) else handDiff


module.exports.HandMatcher = class HandMatcher
  constructor: (@registry = new HandRegistry()) ->

  matchAll: (playerHand) ->
    matchedHands = []
    for comb in this.combinations(playerHand.cards)
      matchedHand = (new MatchedHand(hand, new PlayerHand(comb)) for hand in @registry.hands when hand.matchesCards(comb))
      matchedHands.push matchedHand
    matchedHands = _.flatten(matchedHands)
    matchedHands.sort((a, b) -> a.compare(b))

  matchHighest: (playerHand) ->
    this.matchAll(playerHand)[0]

  # combinations are not order dependent, permutations are.
  # ripped from ruby array.c
  combinations: (cards, max) ->
    max ||= 5
    results = []
    length = cards.length
    return [cards] if length <= max

    # skipping special cases for max == 0 && max == 1

    # /me wishes Array(max).map(function() {0}) worked, but don't
    stack = []
    _.times(max, () -> (stack.push(0)))
    stack[0] = -1

    chosen = Array(max)
    allDone = false
    lev = 0

    while true
      chosen[lev] = cards[stack[lev + 1]]
      lev += 1
      for lev in [lev...max] by 1 # redundant by 1 to reduce js mess
        stack[lev + 1] = stack[lev] + 1
        chosen[lev] = cards[stack[lev + 1]]
      results.push chosen.slice(0) # hack for cloning the array
      while true
        if (lev == 0)
          allDone = true # no goto in this lang
          break
        stack[lev] += 1
        lev -= 1
        break if ((stack[lev + 1] + max) != (length + lev + 1))

      break if (lev == 0) && allDone

    results
