Core = require('../../js/token-poker/core')
_ = require('underscore')

module.exports = class FakeRandom
  constructor: ->
    @digits = []

  randomDigit: ->
    if @digits.length > 0
      @digits.shift()
    else
      Math.floor(Math.random() * 10)

  pushFakeHand: (playerHands...) ->
    for playerHand in playerHands
      @digits.push digit for digit in Core.Hand.toDigitArray(playerHand)
