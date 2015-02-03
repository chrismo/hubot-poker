Core = require('../../js/card-poker/core')
_ = require('underscore')

describe 'Deck', ->
  d = null

  beforeEach ->
    d = new Core.Deck()

  it 'should have 52 cards', ->
    expect(d.cards.length).toBe 52
    expect(d.cards[0].to_s()).toBe '2S'
    expect(d.cards[0].display()).toBe '[2:spades:]'
    expect(d.cards[51].to_s()).toBe 'AD'
    expect(d.cards[51].display()).toBe '[A:diamonds:]'

  it 'should shuffle', ->
    d = new Core.Deck()
    d.shuffle()
    expect(d.cards.length).toBe 52
    # gold standard with fixed seed?

  it 'should deal', ->
    assertHand(d.deal(), ['2S'])
    assertHand(d.deal(), ['3S'])
    assertHand(d.deal(2), ['4S', '5S'])


assertHand = (hand, expected) ->
  expect(_.map(hand, (c) -> c.to_s())).toEqual expected
