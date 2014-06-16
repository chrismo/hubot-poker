_ = require('underscore')

# taking general direction from http://en.wikipedia.org/wiki/Betting_in_poker
#
# with notable differences:
#
# - players can join and bet at any time. Players joining will automatically be
# deducted the ante. The class has no sense of rounds or time, so the calling
# class is responsible for informing the pot of a player folding and remembering
# to call settleUp to force the remaining points owed by other players into the
# pot. The class itself cannot enforce consistency in that sense.
#
# For example, if bets have been made and settleUp has been called, then a new
# player added, that player will not have been settled up unless/until settleUp
# is called again.
module.exports = class Pot
  constructor: (@ante) ->
    this.resetPot()

  diagnostic: ->
    ["\nPot\n",
     "@players: <#{(p.name for p in @players).join(',')}>",
     "@points: #{@points}"].join("\n")

  resetPot: ->
    @players = []
    @points = 0

  addPlayer: (player) ->
    unless this.playerAlreadyAdded(player)
      throw 'no dough, no show' if player.points < 1
      @players.push(player)
      player.totalBet = 0
      this.addToPot(player, @ante)

  bet: (player, amount) ->
    throw "player #{player.name} not added." unless this.playerAlreadyAdded(player)
    this.addToPot(player, parseInt(amount))

  call: (player) ->
    throw "player #{player.name} not added." unless this.playerAlreadyAdded(player)
    owed = this.maxBet() - player.totalBet
    this.bet(player, owed)

  playerAlreadyAdded: (player) ->
    _.find(@players, (p) -> (p.name == player.name)) != undefined

  settleUp: ->
    maxAmount = this.maxBet()
    for player in @players
      owed = maxAmount - player.totalBet
      owed = Math.min(player.points, owed)
      this.addToPot(player, owed)

  maxBet: ->
    playerAmounts = (player.totalBet for player in @players)
    _.max(playerAmounts)

  fold: (player) ->
    @players = _.without(@players, player)

  goesTo: (player) ->
    player.points += @points
    for player in @players
      player.totalBet = 0
    this.resetPot();

  addToPot: (player, amount) ->
    amount = Math.min(player.points, amount)
    amount = Math.max(0, amount)
    player.points -= amount
    player.totalBet += amount
    @points += amount

  allBetsSettled: ->
    maxAmount = this.maxBet()
    result = maxAmount > @ante
    for player in @players
      owed = maxAmount - player.totalBet
      result = false if owed > 0 && player.points > 0
    result