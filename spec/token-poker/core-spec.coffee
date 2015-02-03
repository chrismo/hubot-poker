TokenPoker = require('../../js/token-poker/core')
_ = require('underscore')

describe 'HandMatcher', ->
  matcher = null

  beforeEach ->
    matcher = new TokenPoker.HandMatcher(new TokenPoker.HandRegistry([
      new TokenPoker.GroupedHand('One Pair', '21111', 4),
      new TokenPoker.GroupedHand('Two Pair', '2211', 3),
      new TokenPoker.StraightHand('5 Straight', 5, 2),
      new TokenPoker.StraightHand('6 Straight', 6, 1),
    ]))

  it 'can detect one pair', ->
    result = matcher.matchHighest '112 468'
    expect(result.name).toBe 'One Pair'
    result = matcher.matchAll '112 468'
    expect(result[0].name).toBe 'One Pair'

  it 'can detect two pair', ->
    result = matcher.matchHighest '112 279'
    expect(result.name).toBe 'Two Pair'
    result = matcher.matchAll '112 279'
    expect(result[0].name).toBe 'Two Pair'

  it 'matches 5 straight', ->
    result = matcher.matchHighest '123459'
    expect(result.name).toBe '5 Straight'

  it 'only matches 6 straights in matchAll', ->
    result = matcher.matchAll '123456'
    expect(result.length).toBe 1
    expect(result[0].name).toBe '6 Straight'

  it 'matches one pair and 5 straight in matchAll', ->
    result = matcher.matchAll '112345'
    expect(result.length).toBe 2
    expect(result[0].name).toBe '5 Straight'
    expect(result[1].name).toBe 'One Pair'

  it 'matches only 5 straight in matchHighest', ->
    result = matcher.matchHighest '347 456'
    expect(result.name).toBe '5 Straight'

  it 'matches all 4 hands from combinations of 8 digits', ->
    result = matcher.matchAll '112 234 56'
    expect(result.length).toBe 4
    expect(result[0].name).toBe '6 Straight'
    expect(result[1].name).toBe '5 Straight'
    expect(result[2].name).toBe 'Two Pair'
    expect(result[3].name).toBe 'One Pair'

describe 'HandMatcher combinations', ->
  matcher = null

  beforeEach ->
    matcher = new TokenPoker.HandMatcher([])

  it 'finds all combinations of 2 from 3', ->
    result = matcher.combinations([1,2,3], 2)
    expect(_.isEqual(result[0], [1,2])).toBe true
    expect(_.isEqual(result[1], [1,3])).toBe true
    expect(_.isEqual(result[2], [2,3])).toBe true

describe 'GroupedHand', ->
  onePair = null

  beforeEach ->
    onePair = new TokenPoker.GroupedHand('One Pair', '21111')

  it 'strips any non-digits, grouping 6 ones to 6', ->
    expect(onePair.matches('1-1-2 3*5*9')).toBe true

  it 'matches one pair', ->
    expect(onePair.matches('112357')).toBe true
    expect(onePair.matches('572311')).toBe true

  it 'matches two pair', ->
    twoPair = new TokenPoker.GroupedHand('Two Pair', '2211')
    expect(twoPair.matches('112337')).toBe true

  it 'matches crowded house', ->
    crowded = new TokenPoker.GroupedHand('Crowded House', '321')
    expect(crowded.matches('131 339')).toBe true

  it 'matches full house', ->
    crowded = new TokenPoker.GroupedHand('Full House', '42')
    expect(crowded.matches('131 333')).toBe true

  it 'matches 6 of a kind', ->
    six = new TokenPoker.GroupedHand('6 of a Kind', '6')
    expect(six.matches('000 000')).toBe true
    expect(six.matches('222 222')).toBe true

describe 'StraightHand', ->
  it 'handles no numbers one apart', ->
    five = new TokenPoker.StraightHand('5 Straight', 5)
    expect(five.matches('020202')).toBe false

  it 'matches 5 straight', ->
    five = new TokenPoker.StraightHand('5 Straight', 5)
    expect(five.matches('234-568')).toBe true
    expect(five.matches('234-567')).toBe false
    expect(five.matches('234-610')).toBe true
    expect(five.matches('167890')).toBe false

  it 'matches 5 straight - pair in the middle', ->
    five = new TokenPoker.StraightHand('5 Straight', 5)
    expect(five.matches('347 456')).toBe true

  it 'matches 3 straight', ->
    three = new TokenPoker.StraightHand('3 Straight', 3)
    expect(three.matches('828348')).toBe true
    expect(three.matches('012 777')).toBe true
    expect(three.matches('890 333')).toBe false

  it 'matches 6 straight', ->
    six = new TokenPoker.StraightHand('6 Straight', 6)
    expect(six.matches('321 456')).toBe true
    expect(six.matches('210 354')).toBe true
    expect(six.matches('980 765')).toBe false
    expect(six.matches('890 123')).toBe false

describe 'OddsCalculator', ->
  it 'ranks 3 grouped hands', ->
    snowflake = new TokenPoker.GroupedHand('One of a Kind', '111')
    onePair = new TokenPoker.GroupedHand('One Pair', '21')
    threeKind = new TokenPoker.GroupedHand('Three of a Kind', '3')

    odds = new TokenPoker.OddsCalculator(new TokenPoker.HandRegistry([snowflake, onePair, threeKind]), 999)
    expect(odds.pad).toBe '000'
    odds.calculate()

    expect(threeKind.matchCount).toBe 10
    expect(onePair.matchCount).toBe 270
    expect(snowflake.matchCount).toBe 720

  it 'ranks a straight hand', ->
    twoStraight = new TokenPoker.StraightHand('2 Straight', 2)
    odds = new TokenPoker.OddsCalculator(new TokenPoker.HandRegistry([twoStraight]), 999)
    odds.calculate()
    expect(twoStraight.matchCount).toBe 390

describe 'HandRegistry', ->
  it 'sorts by match count', ->
    a = new TokenPoker.GroupedHand('a')
    a.matchCount = 10
    b = new TokenPoker.GroupedHand('b')
    b.matchCount = 3
    reg = new TokenPoker.HandRegistry([a, b])
    reg.sortByMatchCount()
    expect(reg.hands[0]).toBe b
    expect(reg.hands[1]).toBe a
