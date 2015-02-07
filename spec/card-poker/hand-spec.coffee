Core = require('../../js/card-poker/core')
CardPoker = require('../../js/card-poker/hand')
_ = require('underscore')

describe 'GroupedHand', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should group ranks together to make fingerprint', ->
    hand = d.findAll(['2C', '2D'])
    expect(CardPoker.GroupedHand.groupings(hand.cards)).toBe '2'

  it 'should strip single counts from fingerprint', ->
    hand = d.findAll(['2C', '2D', '3C'])
    expect(CardPoker.GroupedHand.groupings(hand.cards)).toBe '2'

  it 'should generate correct two pair fingerprint', ->
    hand = d.findAll(['2C', '2D', '3C', '3D'])
    expect(CardPoker.GroupedHand.groupings(hand.cards)).toBe '22'

  it 'should match one pair', ->
    gh = new CardPoker.GroupedHand('One Pair', '2')
    expect(gh.matches(d.findAll(['2C', '2D']))).toBe true

  it 'should match two pair', ->
    gh = new CardPoker.GroupedHand('Two Pair', '22')
    hand = d.findAll(['2C', '2D', '4S', '4C'])
    expect(gh.matches(hand)).toBe true

  it 'should match no pair', ->
    gh = new CardPoker.GroupedHand('High Card', '')
    hand = d.findAll(['2C', '3D', '4S', '7C', 'AH'])
    expect(gh.matches(hand)).toBe true

  it 'should sort One Pair first, then kickers in descending', ->
    pHand = d.findAll(['2C', '3C', '2H', '4C', 'AD'])
    sortedCards = CardPoker.GroupedHand.sortCards(pHand)
    sortedHand = new CardPoker.PlayerHand(sortedCards)
    expect(sortedHand.codes()).toEqual '[2H,2C,AD,4C,3C]'

  it 'should compare two One Pair hands, one pair higher', ->
    a = d.findAll(['2C', '2D', '3C', '4C', 'AD'])
    b = d.findAll(['5C', '5D', '3H', '4H', '7H'])

    hand = new CardPoker.GroupedHand('One Pair', '2', 2)
    expect(hand.compare(a, b)).toBe 3

  it 'should compare two One Pair hands, same pairs, different kickers', ->
    a = d.findAll(['2C', '2D', '3C', '4C', 'AD'])
    b = d.findAll(['2S', '2H', '3H', '4H', '7H'])

    hand = new CardPoker.GroupedHand('One Pair', '2', 2)
    expect(hand.compare(a, b)).toBe -7

  it 'should sort full house cards properly', ->
    playerHand = d.findAll(['KH', '8H', '8S', 'KS', 'KC', '7D', '9D'])
    hand = new CardPoker.GroupedHand('Full House', '32', 2)
    hand.sortCards(playerHand)
    expect(playerHand.codes()).toBe '[KS,KH,KC,8S,8H,9D,7D]'


describe 'StraightHand', ->
  d = sh = null

  beforeEach ->
    d = new Core.Deck()
    sh = new CardPoker.StraightHand('Straight')

  it 'should get count of one intervals', ->
    hand = d.findAll(['2C', '3D', '5S', '6C', '4H'])
    expect(CardPoker.StraightHand.countOfOneIntervals(hand.cards)).toBe 4

  it 'should match 5 straight', ->
    hand = d.findAll(['2C', '3D', '5S', '6C', '4H'])
    expect(sh.matches(hand)).toBe true

  it 'should match 5 straight face cards', ->
    hand = d.findAll(['AC', '10D', 'JS', 'QC', 'KH'])
    expect(sh.matches(hand)).toBe true

  it 'sorts cards by rank only', ->
    hand = d.findAll(['AC', '10D', 'JS', 'QC', 'KH'])
    sh.sortCards(hand)
    expect(hand.codes()).toBe '[AC,KH,QC,JS,10D]'

  it 'compares two Straights sorting by rank', ->
    a = d.findAll(['2C', '3D', '5S', '6C', '4H'])
    b = d.findAll(['AC', '10D', 'JS', 'QC', 'KH'])
    expect(sh.compare(a, b)).toBe 8


describe 'FlushHand', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should match when all 5', ->
    fh = new CardPoker.FlushHand('Flush')
    hand = d.findAll(['2H', '3H', '5H', '8H', 'QH'])
    expect(fh.matches(hand)).toBe true

  it 'should not match when less than 5', ->
    fh = new CardPoker.FlushHand('Flush')
    hand = d.findAll(['2H', '3H', '5D', '8H', 'QH'])
    expect(fh.matches(hand)).toBe false


describe 'StraightFlushHand', ->
  d = sfh = null

  beforeEach ->
    d = new Core.Deck()
    sfh = new CardPoker.StraightFlushHand('Straight Flush')

  it 'should match when all 5', ->
    hand = d.findAll(['2H', '3H', '5H', '4H', '6H'])
    expect(sfh.matches(hand)).toBe true

  it 'should not match when straight but not flush', ->
    hand = d.findAll(['2H', '3H', '5H', '4H', '6C'])
    expect(sfh.matches(hand)).toBe false

  it 'should not match when flush but not straight', ->
    hand = d.findAll(['2H', '3H', '5H', '4H', '7H'])
    expect(sfh.matches(hand)).toBe false


describe 'HandMatcher', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should match all 4 of a kind case', ->
    matcher = new CardPoker.HandMatcher()
    hand = d.findAll(['7S', '7H', '7C', '7D', 'AH'])
    all = matcher.matchAll(hand)
    expect(all.length).toBe 1
    expect(all[0].hand.name).toBe 'Four of a Kind'

  it 'should match all 4 of a kind with community cards', ->
    matcher = new CardPoker.HandMatcher()
    hand = d.findAll(['7S', '7H', '7C', 'AC', 'AH', 'AD', '7D'])
    all = matcher.matchAll(hand)
    expect(all.length).toBe 21
    expect(all[0].hand.name).toBe 'Four of a Kind'
    expect(all[0].playerHand.codes()).toBe d.findAll(['7S', '7H', '7C', '7D', 'AC']).codes()

  it 'should match all straight flush with community cards', ->
    matcher = new CardPoker.HandMatcher()
    hand = d.findAll(['5D', '6D', '7D', '8D', '9D', 'AC', '2H'])
    all = matcher.matchAll(hand)
    expect(all.length).toBe 24
    expect(all[0].hand.name).toBe 'Straight Flush'
    expect(all[1].hand.name).toBe 'Flush'
    expect(all[2].hand.name).toBe 'Straight'
    expect(all[3].hand.name).toBe 'High Card'

  it 'should sort best hand if full house', ->
    matcher = new CardPoker.HandMatcher()
    playerHand = d.findAll(['KH', '8H', '8S', 'KS', 'KC', '7D', '9D'])
    highestMatch = matcher.matchHighest(playerHand)
    expect(highestMatch.playerHand.codes()).toBe '[KS,KH,KC,8S,8H]'


describe 'PlayerHand', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should handle display', ->
    expect(d.findAll(['2D', '4C']).display()).toEqual '2♦︎ 4♣'

  it 'should handle codes', ->
    expect(d.findAll(['2D', '4C']).codes()).toBe '[2D,4C]'

  it 'should sort', ->
    expect(d.findAll(['4D', '6C', '3H']).sort().codes()).toBe '[6C,4D,3H]'
    expect(d.findAll(['4D', '4S', '4H', '4C']).sort().codes()).toBe '[4S,4H,4C,4D]'
