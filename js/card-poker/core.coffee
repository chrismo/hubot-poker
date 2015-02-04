_ = require('underscore')
Hand = require('./hand')


module.exports.Card = class Card
  constructor: (@rank, @suit) ->

  to_s: ->
    "#{@rank.label}#{@suit.value}"

  code: ->
    this.to_s()

  display: ->
    "#{@rank.label}#{@suit.label}"

  compare: (other) ->
    rankDiff = other.rank.value - @rank.value
    if rankDiff == 0 then @suit.sort - other.suit.sort else rankDiff



module.exports.Rank = class Rank
  constructor: (@value, @label) ->


module.exports.Suit = class Suit
  constructor: (@value, @label, @sort) ->


module.exports.Deck = class Deck
  constructor: ->
    ranks = (new Rank(r, r) for r in [2..10])
    ranks.push new Rank(11, 'J')
    ranks.push new Rank(12, 'Q')
    ranks.push new Rank(13, 'K')
    ranks.push new Rank(14, 'A')

    suits = (new Suit(pair[0], pair[1], pair[2]) for pair in _.zip(
        ['S', 'H', 'C', 'D'],
        ['♠', '♥', '♣', '♦︎'],
        [1, 2, 3, 4]
    )
    )

    @cards = _.flatten(new Card(r, s) for r in ranks for s in suits)

  shuffle: ->
    @cards = _.shuffle(@cards)

  deal: (count = 1) ->
    new Hand.PlayerHand(@cards.shift() for [1..count])

  find: (code) ->
    _.detect(@cards, (c) -> c.to_s() == code)

  findAll: (codes) ->
    new Hand.PlayerHand((this.find(s) for s in codes))
