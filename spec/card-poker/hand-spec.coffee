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


describe 'StraightHand', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should get count of one intervals', ->
    hand = d.findAll(['2C', '3D', '5S', '6C', '4H'])
    expect(CardPoker.StraightHand.countOfOneIntervals(hand.cards)).toBe 4

  it 'should match 5 straight', ->
    hand = d.findAll(['2C', '3D', '5S', '6C', '4H'])
    sh = new CardPoker.StraightHand('Straight')
    expect(sh.matches(hand)).toBe true

  it 'should match 5 straight face cards', ->
    hand = d.findAll(['AC', '10D', 'JS', 'QC', 'KH'])
    sh = new CardPoker.StraightHand('Straight')
    expect(sh.matches(hand)).toBe true


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
    expect(all[0].comb).toEqual d.findAll(['7S', '7H', '7C', 'AC', '7D']).cards

  it 'should match all straight flush with community cards', ->
    matcher = new CardPoker.HandMatcher()
    hand = d.findAll(['5D', '6D', '7D', '8D', '9D', 'AC', '2H'])
    all = matcher.matchAll(hand)
    expect(all.length).toBe 24
    expect(all[0].hand.name).toBe 'Straight Flush'
    expect(all[1].hand.name).toBe 'Flush'
    expect(all[2].hand.name).toBe 'Straight'
    expect(all[3].hand.name).toBe 'High Card'


describe 'PlayerHand', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should handle display', ->
    expect(d.findAll(['2D', '4C']).display()).toBe '[2♦︎][4♣]'

  it 'should handle codes', ->
    expect(d.findAll(['2D', '4C']).codes()).toBe '[2D,4C]'
