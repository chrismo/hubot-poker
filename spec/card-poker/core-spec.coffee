Core = require('../../js/card-poker/core')
_ = require('underscore')

describe 'Deck', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should have 52 cards', ->
    expect(d.cards.length).toBe 52
    expect(d.cards[0].to_s()).toBe '2S'
    expect(d.cards[0].display()).toBe '2♠'
    expect(d.cards[51].code()).toBe 'AD'
    expect(d.cards[51].display()).toBe 'A♦︎'

  it 'should shuffle', ->
    d = new Core.Deck()
    d.shuffle()
    expect(d.cards.length).toBe 52
  # gold standard with fixed seed?

  it 'should deal', ->
    assertHand(d.deal(), '[2S]')
    assertHand(d.deal(), '[3S]')
    assertHand(d.deal(2), '[4S,5S]')

  it 'should find card', ->
    card = d.find('KC')
    expect(card.display()).toBe 'K♣'
    expect(card.rank.value).toBe 13

  it 'should find cards', ->
    cards = d.findAll(['5D','6C'])
    assertHand(cards, '[5D,6C]')

assertHand = (hand, expected) ->
  expect(hand.codes()).toEqual expected
