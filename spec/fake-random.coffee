Core = require('../js/token-poker/core')

module.exports = class FakeRandom
  constructor: ->
    @digits = []

  randomDigit: ->
    @digits.shift()

  pushFakeHand: (playerHand) ->
    @digits.push digit for digit in Core.Hand.toDigitArray(playerHand)
