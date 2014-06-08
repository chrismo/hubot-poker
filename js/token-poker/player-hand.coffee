# this will cause confusion at first - many instances of vars
# named playerHand and it's just a string.
#
# this class is responsible for
# - the submitted digits,
# - any community digits as well
# - the highest matching hand type
# - and a compare method against other player hands
module.exports = class PlayerHand
  constructor: (@player, @playerDigits, @matchedHand) ->
