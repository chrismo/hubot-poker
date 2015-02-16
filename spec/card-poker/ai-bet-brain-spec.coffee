Brain = require('../../js/card-poker/ai-bet-brain')
Hand = require('../../js/card-poker/hand')
Core = require('../../js/card-poker/core')
Pot = require('../../js/poker/pot')

describe 'AiBetBrain', ->
  deck = null

  beforeEach ->
    deck = new Core.Deck()

  describe 'no community cards', ->
    makeBrain = (player) ->
      brain = new Brain(player, new Hand.PlayerHand([]), new Pot())
      brain.fixedBetAmount = 1
      brain

    it 'does not fold with a pair', ->
      cards = deck.findAll(['2C', '2H'])
      brain = makeBrain(cards, [])
      expect(brain.action()).toBe 'bet 1'

    it 'does not fold with same suit', ->
      cards = deck.findAll(['2C', '9C'])
      brain = makeBrain(cards, [])
      expect(brain.action()).toBe 'bet 1'

    it 'does not fold with ranks within straight', ->
      cards = deck.findAll(['2C', '6H'])
      brain = makeBrain(cards, [])
      expect(brain.action()).toBe 'bet 1'

    it 'folds when all else fails', ->
      cards = deck.findAll(['2C', '7H'])
      brain = makeBrain(cards, [])
      expect(brain.action()).toBe 'fold'



