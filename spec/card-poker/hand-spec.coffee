Core = require('../../js/card-poker/core')
CardPoker = require('../../js/card-poker/hand')
_ = require('underscore')

describe 'GroupedHand', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should group ranks together to make fingerprint', ->
    hand = d.findAll(['2C', '2D'])
    expect(CardPoker.GroupedHand.groupings(hand)).toBe '2'

  it 'should strip single counts from fingerprint', ->
    hand = d.findAll(['2C', '2D', '3C'])
    expect(CardPoker.GroupedHand.groupings(hand)).toBe '2'

  it 'should generate correct two pair fingerprint', ->
    hand = d.findAll(['2C', '2D', '3C', '3D'])
    expect(CardPoker.GroupedHand.groupings(hand)).toBe '22'

  it 'should match one pair', ->
    gh = new CardPoker.GroupedHand('One Pair', '2')
    expect(gh.matches(new CardPoker.PlayerHand(d.findAll(['2C', '2D'])))).toBe true

  it 'should match two pair', ->
    gh = new CardPoker.GroupedHand('Two Pair', '22')
    hand = d.findAll(['2C', '2D', '4S', '4C'])
    expect(gh.matches(new CardPoker.PlayerHand(hand))).toBe true
