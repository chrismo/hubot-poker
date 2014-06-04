Util = require('util')
_ = require('underscore')

module.exports.HandMatcher = class HandMatcher
  # TODO: compare same hand, decide winner on higher cards in hand (22 beats 11 as One Pair)
  constructor: (@registry) ->

  matchAll: (playerHand) ->
    digits = playerHand.replace(/\D/g, '').split('').map (c) -> parseInt(c)
    hands = []
    for comb in this.combinations(digits)
      combHands = (hand for hand in @registry.hands when hand.matchesFromDigits(comb))
      hands.push combHands
    hands = _.flatten(hands)
    sorted = hands.sort (a, b) -> a.matchCount - b.matchCount
    _.uniq(sorted, true)

  matchHighest: (playerHand) ->
    this.matchAll(playerHand)[0]

  # combinations are not order dependent, permutations are.
  # ripped from ruby array.c
  combinations: (digits, max) ->
    max ||= 6
    results = []
    length = digits.length
    return [digits] if length <= max

    # skipping special cases for max == 0 && max == 1

    # /me wishes Array(max).map(function() {0}) worked, but don't
    stack = []
    _.times(max, () -> (stack.push(0)))
    stack[0] = -1

    chosen = Array(max)
    allDone = false
    lev = 0

    while true
      chosen[lev] = digits[stack[lev + 1]]
      lev += 1
      for lev in [lev...max] by 1 # redundant by 1 to reduce js mess
        stack[lev + 1] = stack[lev] + 1
        chosen[lev] = digits[stack[lev + 1]]
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


module.exports.HandRegistry = class HandRegistry
  constructor: (@hands) ->

  sortByMatchCount: ->
    @hands = @hands.sort (a, b) ->
      a.matchCount - b.matchCount


module.exports.Hand = class Hand
  constructor: ->
    @debug = false

  matches: (playerHand) ->
    digits = Hand.toDigitArray(playerHand)
    this.matchesFromDigits(digits)

  addMatch: (playerHand) ->
    @matchCount++
    console.log("#{@name}: #{playerHand}") if @debug

  codeGen: ->
    ''

  @toDigitArray: (playerHand) ->
    playerHand.replace(/\D/g, '').split('').map (c) -> parseInt(c)


module.exports.GroupedHand = class GroupedHand extends Hand
  constructor: (@name, @groupingFingerprint, @matchCount) ->
    @matchCount = 0 if @matchCount == undefined

  matchesFromDigits: (playerHandDigits) ->
    this.groupings(playerHandDigits) == @groupingFingerprint

  groupings: (digits) ->
    groups = digits.reduce (prev, item) ->
      _digits = Object.keys(prev).map (c) ->
        parseInt(c)
      if (item in _digits)
        prev[item]++
      else
        prev[item] = 1
      prev
    , {}

    counts = for digit, count of groups
      count
    counts = counts.sort (a, b) ->
      b - a
    counts.join('')

  codeGen: ->
    "new GroupedHand('#{@name}', '#{@groupingFingerprint}', #{@matchCount})"


module.exports.StraightHand = class StraightHand extends Hand
  constructor: (@name, count, @matchCount) ->
    @matchCount = 0 if @matchCount == undefined
    @count = count - 1

  matchesFromDigits: (playerHandDigits) ->
    this.countOfOneIntervals(playerHandDigits) == @count

  countOfOneIntervals: (playerHandDigits) ->
    sorted = playerHandDigits.sort (a, b) -> a - b
    uniq = _.uniq(sorted)
    intervals = uniq.map (d, index) ->
      uniq[index + 1] - uniq[index]
    x = intervals.join('').match(/1+/)
    if x then x[0].length else 0

  codeGen: ->
    "new StraightHand('#{@name}', #{@count + 1}, #{@matchCount})"


module.exports.OddsCalculator = class OddsCalculator
  constructor: (@registry, @high) ->
    @matcher = new HandMatcher(@registry)
    @pad = this.buildPad()

  calculate: ->
    for hand in @registry.hands
      hand.matchCount = 0
    this.calcHand hand for hand in [0..@high]

  calcHand: (handNumber) ->
    process.stdout.write('.') if (handNumber + 1) % 10000 == 0
    handNumberStr = ('' + handNumber)
    pad = '' + @pad
    playerHand = pad.substring(0, pad.length - handNumberStr.length) + handNumberStr
    highest = @matcher.matchHighest(playerHand)
    highest.addMatch(playerHand) if highest

  buildPad: ->
    pad = ''
    (pad += '0') for x in ('' + @high)
    pad
